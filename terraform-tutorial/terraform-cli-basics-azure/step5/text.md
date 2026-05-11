# 第五步：terraform force-unlock — 解除卡死的状态锁

## 背景

Terraform 在执行 plan / apply 等操作前，会向 Backend 申请一把**状态锁**，防止多进程并发写入。Backend 不同，锁的存储方式也不同：

- 本地 backend：通过对 `.terraform.tfstate.lock.info` 文件持有 OS 级别的 flock 来加锁
- azurerm backend（Azure Blob Storage）：在 state blob 上申请 lease 实现锁
- S3 backend（配合 DynamoDB 或原生 S3 锁）：在 DynamoDB 表/S3 对象中写入一条锁记录

当进程意外崩溃（Ctrl+C、断网、OOM kill…），锁可能残留，导致后续所有 Terraform 操作都被阻断。这时需要用 `terraform force-unlock` 手动释放。

本步骤使用预配置的 `lock-demo` 工作目录演示，该目录使用**本地 backend** + 一个会 sleep 60 秒的 `local-exec` provisioner。我们会先在后台启动一个 apply，然后用 `kill -9` 直接杀掉它来模拟崩溃，留下孤儿锁。

> 💡 这种"长时 apply + kill -9"的方式比单纯手动伪造锁文件更接近生产事故的真实场景：本地 backend 用的是 OS flock 而不是单纯检查文件是否存在，只有真正持有 flock 的进程被强制结束、锁信息文件被遗留，才是真正的孤儿锁。

## 进入演示工作目录

```bash
cd /root/workspace/lock-demo
ls -la
cat main.tf
```

可以看到只有一个 main.tf 与已经 init 完成的 .terraform 目录。

## 制造孤儿锁：apply 长时运行 + kill -9

在后台启动 apply（它会卡在 sleep 60 这一步，期间持有锁）：

```bash
nohup terraform apply -auto-approve > /tmp/apply.log 2>&1 &
APPLY_PID=$!
echo "apply 已在后台运行，PID=$APPLY_PID"
```

等待几秒，让 apply 完成 plan 阶段并开始执行 sleep（此时锁文件已写入磁盘）：

```bash
sleep 5
ls -la .terraform.tfstate.lock.info
cat .terraform.tfstate.lock.info
```

应该能看到一份完整的锁信息 JSON，里面有 ID、Operation、Who、Created 等字段。

现在直接用 SIGKILL 杀掉这个 apply 进程，模拟 OOM kill / 网络中断 / 容器被强制结束的场景：

```bash
kill -9 $APPLY_PID
sleep 1
echo "apply 进程已被强杀"
```

确认进程已不在，但锁信息文件依然存在（孤儿锁已就绪）：

```bash
ps -p $APPLY_PID 2>&1 | tail -1
ls -la .terraform.tfstate.lock.info
```

## 观察锁阻断错误

尝试执行 plan，Terraform 会发现无法获得锁并报错：

```bash
terraform plan -lock-timeout=0s
```

你会看到类似输出：

```text
╷
│ Error: Error acquiring the state lock
│
│ Error message: resource temporarily unavailable
│
│ Lock Info:
│   ID:        d361ef2a-73be-7897-69e8-60eedd745529
│   Path:      terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       root@host01
│   Version:   ...
│   Created:   ...
│   Info:
╵
```

错误信息中明确给出了 Lock ID，这正是解锁所需的参数。

## 运行 terraform force-unlock

直接从锁信息文件里把 ID 提取出来，避免手抄：

```bash
LOCK_ID=$(jq -r .ID .terraform.tfstate.lock.info)
echo "Lock ID: $LOCK_ID"
```

执行解锁（会要求输入 yes 二次确认，避免误操作）：

```bash
terraform force-unlock "$LOCK_ID"
```

输入 yes 后成功输出：

```text
Terraform state has been successfully unlocked!
```

## 确认锁文件已清除

```bash
ls -la .terraform.tfstate.lock.info 2>&1
```

返回 `No such file or directory` 说明锁已释放。

## 再次运行 plan 验证解锁生效

```bash
terraform plan
```

这次应该正常计划——Terraform 看到 null_resource.slow 仍然没有创建（因为之前的 apply 在 sleep 阶段被杀，事务并未完成），输出 `Plan: 1 to add`，不再报锁错误。

## 清理

把 apply.log 留作记录，后续若想跑完 lock-demo 也可以再来一次（apply 会真的等 60 秒，自行决定是否执行）：

```bash
tail -5 /tmp/apply.log
```

> ⚠️ 只在确认没有其他 Terraform 进程正在运行时才使用 force-unlock，否则可能导致并发写入损坏状态文件。生产环境推荐在 CI/CD 中加监控，自动检测残留锁并通知值班人员，而不是默认无人工确认就直接 force-unlock。

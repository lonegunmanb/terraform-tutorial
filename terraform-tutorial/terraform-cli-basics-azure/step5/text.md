# 第五步：terraform force-unlock — 解除卡死的状态锁

## 背景

Terraform 在执行 plan / apply 等操作前，会向 Backend 申请一把**状态锁**，防止多进程并发写入。Backend 不同，锁的存储方式也不同：

- 本地 backend：通过对 `.terraform.tfstate.lock.info` 文件持有 OS 级别的 flock 来加锁
- S3 backend（配合 DynamoDB）：在 DynamoDB 表中写入一条锁记录
- **azurerm backend（Azure Blob Storage）：在 state blob 上申请一个 lease，并把锁元信息写到 blob 的 `terraformlockid` metadata 上**

当进程意外崩溃（Ctrl+C、断网、OOM kill…），lease 没来得及释放就成了**孤儿锁**，后续所有 Terraform 操作都会被阻断。这时需要用 `terraform force-unlock` 强制把它打破。

本步骤使用预配置的 `blob-demo` 工作目录演示。它**真的用 azurerm backend** 把状态存到 miniblue 模拟的 Azure Blob Storage 里——和你在生产里用 Azure Storage Account 存远端 state 的代码结构完全一致。我们会绕开 Terraform，直接用 curl 在 state blob 上申请一个 lease，模拟"另一个 Terraform 进程持有锁但已经崩溃"的状态。

## 进入演示工作目录

```bash
cd /root/workspace/blob-demo
ls -la
cat main.tf
```

可以看到 `terraform { backend "azurerm" {} }` 块，state 已经存到 miniblue 里。验证一下：

```bash
terraform state list
```

应该看到 `null_resource.demo`——这条状态就保存在 `tfstateacct/tfstate/demo.tfstate` 这个 blob 里。

## 制造孤儿锁：直接给 state blob 申请一个 lease

正常情况下，Terraform 自己在 plan/apply 前后会成对调用 acquire/release lease。我们要模拟的是「Terraform 进程拿到了 lease，但因为 OOM kill / 网络中断没有来得及 release」的事故现场。

直接调 Azure Blob Storage 的 Lease Blob API（`?comp=lease` + `x-ms-lease-action: acquire`）就能复现：

```bash
LEASE_ID="aabb1234-dead-beef-cafe-001122334455"

curl -s -i -X PUT \
  "http://localhost:4566/blob/tfstateacct/tfstate/demo.tfstate?comp=lease" \
  -H "x-ms-lease-action: acquire" \
  -H "x-ms-lease-duration: -1" \
  -H "x-ms-proposed-lease-id: $LEASE_ID" \
  -H "x-ms-version: 2021-06-08" | head -15
```

应该看到 `HTTP/1.1 201 Created` 和 `x-ms-lease-id: aabb1234-...`。`x-ms-lease-duration: -1` 表示无限期持有，这正是孤儿锁的特征。

光有 lease 还不够——azurerm backend 在 force-unlock 时会去读 blob 的 `terraformlockid` metadata 来确认 ID 一致。我们顺手把这份元信息也写上：

```bash
LOCK_JSON='{"ID":"aabb1234-dead-beef-cafe-001122334455","Operation":"OperationTypePlan","Info":"","Who":"ghost@crashed-host","Version":"1.14.8","Created":"2026-05-12T00:00:00Z","Path":"tfstate/demo.tfstate"}'

LOCK_B64=$(printf '%s' "$LOCK_JSON" | base64 -w0)

curl -s -i -X PUT \
  "http://localhost:4566/blob/tfstateacct/tfstate/demo.tfstate?comp=metadata" \
  -H "x-ms-lease-id: $LEASE_ID" \
  -H "x-ms-meta-terraformlockid: $LOCK_B64" \
  -H "x-ms-version: 2021-06-08" | head -3
```

应该返回 `HTTP/1.1 200 OK`。

确认 blob 现在确实是 leased 状态：

```bash
curl -s -I "http://localhost:4566/blob/tfstateacct/tfstate/demo.tfstate" | grep -iE "lease|meta"
```

应该看到：

```text
X-Ms-Lease-Duration: infinite
X-Ms-Lease-State: leased
X-Ms-Lease-Status: locked
X-Ms-Meta-Terraformlockid: eyJJ...
```

孤儿锁就绪。

## 观察锁阻断错误

让 Terraform 试着拿锁——它会失败，并把锁信息打印出来：

```bash
terraform plan -lock-timeout=0s
```

输出类似：

```text
╷
│ Error: Error acquiring the state lock
│
│ Error message: state blob is already locked
│
│ Lock Info:
│   ID:        aabb1234-dead-beef-cafe-001122334455
│   Path:      tfstate/demo.tfstate
│   Operation: OperationTypePlan
│   Who:       ghost@crashed-host
│   Version:   1.14.8
│   Created:   2026-05-12 00:00:00 +0000 UTC
│   Info:
╵
```

这正是 azurerm backend 真实事故现场会看到的报错——`Lock Info` 块就是从 blob 的 `terraformlockid` metadata 里反序列化出来的。

## 运行 terraform force-unlock

把 Terraform 报告的 Lock ID 喂给 `force-unlock`（`-force` 跳过交互确认）：

```bash
terraform force-unlock -force aabb1234-dead-beef-cafe-001122334455
```

成功输出：

```text
Terraform state has been successfully unlocked!
```

它的内部动作是调 Azure Blob Storage 的 Lease Blob `?comp=lease` + `x-ms-lease-action: break`——把那个我们伪造的 lease 强行打破。

## 确认 lease 已释放

```bash
curl -s -I "http://localhost:4566/blob/tfstateacct/tfstate/demo.tfstate" | grep -iE "lease"
```

应该看到 `X-Ms-Lease-State: available` 和 `X-Ms-Lease-Status: unlocked`，锁已经回到可用状态。

## 再次运行 plan 验证解锁生效

```bash
terraform plan
```

这次能正常拿锁、刷新状态，并提示 `No changes`——说明 state 没坏，只是之前被孤儿锁挡住了入口。

> ⚠️ **生产警告**：只在确认没有其他 Terraform 进程正在运行时才使用 `force-unlock`。如果真有别的进程正持有这把锁，`break` 会让它的写入操作失败，state 文件可能在中途被覆盖。生产环境推荐在 CI/CD 中加监控，自动检测残留锁并通知值班人员，由人去判断到底是真孤儿还是误判。
# 第五步：terraform force-unlock — 解除卡死的状态锁

## 背景

Terraform 在执行 plan / apply 等操作前，会向 Backend 申请一把**状态锁**，防止多进程并发写入。Backend 不同，锁的存储方式也不同：

- 本地 backend：通过对 `.terraform.tfstate.lock.info` 文件持有 OS 级别的 flock 来加锁
- azurerm backend（Azure Blob Storage）：在 state blob 上申请 lease 实现锁
- S3 backend（配合 DynamoDB）：在 DynamoDB 表中写入一条锁记录

当进程意外崩溃（Ctrl+C、断网、OOM kill…），锁可能残留，导致后续所有 Terraform 操作都被阻断。这时需要用 `terraform force-unlock` 手动释放。

本步骤使用预配置的 `lock-demo` 工作目录演示，该目录使用**本地 backend** 和一个长时运行的 `local-exec` provisioner。我们会先在后台启动一个 apply，然后直接用 `kill -9` 杀掉它来模拟进程崩溃，留下孤儿锁。

> 💡 这种"长时运行的 apply + kill -9"的方式比单纯手动伪造锁文件更接近生产事故的真实场景。本地 backend 的锁使用 OS 提供的 flock 机制，只有真正持有 flock 的进程被强制结束且锁文件遗留，才会出现真正的孤儿锁。

## 进入演示工作目录

```bash
cd /root/workspace/lock-demo
ls -la
cat main.tf
```

可以看到这是一个简单的 Terraform 配置，包含一个 provisioner 会 sleep 60 秒。

## 制造孤儿锁：apply 长时运行 + kill -9

在后台启动 apply（它会在 sleep 60 秒的阶段持有锁）：

```bash
nohup terraform apply -auto-approve > /tmp/apply.log 2>&1 &
APPLY_PID=$!
echo "apply 已在后台运行，PID=$APPLY_PID"
```

等待几秒让 apply 完成 plan 阶段并开始执行 provisioner（此时锁文件已写入）：

```bash
sleep 5
ls -la .terraform.tfstate.lock.info
cat .terraform.tfstate.lock.info
```

应该能看到一份完整的 JSON 锁信息，包含 ID、Operation、Who、Created 等字段。

现在用 SIGKILL 直接杀掉这个进程，模拟 OOM kill / 网络中断 / 容器强制停止的场景：

```bash
kill -9 $APPLY_PID
sleep 1
ps -p $APPLY_PID 2>&1 | tail -1
```

确认进程已不存在，但锁信息文件仍然存在（孤儿锁已就绪）：

```bash
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
│   ID:        <锁的 ID>
│   Path:      terraform.tfstate
│   Operation: OperationTypeApply
│   Who:       <执行用户>
│   Version:   1.x.x
│   Created:   <创建时间>
│   Info:
╵
```

## 运行 terraform force-unlock

从锁信息文件中提取 Lock ID：

```bash
LOCK_ID=$(jq -r .ID .terraform.tfstate.lock.info)
echo "Lock ID: $LOCK_ID"
```

执行解锁命令（需要输入 yes 二次确认）：

```bash
terraform force-unlock "$LOCK_ID"
```

成功后输出：

```text
Terraform state has been successfully unlocked!
```

## 确认锁文件已清除

```bash
ls -la .terraform.tfstate.lock.info 2>&1
```

应该返回 `No such file or directory`，说明锁已释放。

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

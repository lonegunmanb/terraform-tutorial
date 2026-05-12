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

---
order: 98
title: import
group: Terraform CLI
group_order: 9
---

# terraform import

`terraform import` 将已有的基础设施资源导入到 Terraform 状态中，使 Terraform 接管该资源的后续管理。它是"先有基础设施、后引入 Terraform"场景的核心命令。

## 用法

```bash
terraform import [options] ADDRESS ID
```

- **ADDRESS**：目标资源在配置中的地址，如 `aws_s3_bucket.app`、`module.foo.aws_instance.bar`。
- **ID**：资源在云服务商中的唯一标识，格式因资源类型而异。例如 S3 桶使用桶名，EC2 实例使用实例 ID（`i-abcd1234`）。

`terraform import` 每次只能导入一个资源，不能批量导入。

## 工作流程

导入一个已有资源需要两步：

### 1. 在配置中声明资源

先在 `.tf` 文件中写一个空的（或部分填充的）resource 块：

```hcl
resource "aws_s3_bucket" "existing" {
  # 导入后再补全属性
}
```

配置中必须有对应的 resource 块，否则 import 会报错。

### 2. 执行 import 命令

```bash
terraform import aws_s3_bucket.existing my-existing-bucket
```

Terraform 通过 provider 查询远端资源的实际属性，并将其记录到状态文件中。

### 3. 补全配置

导入后运行 `terraform plan`，Terraform 会对比状态与配置的差异。根据 plan 的输出补全配置中的属性，直到 plan 显示 `No changes`：

```bash
terraform plan
# 根据差异补全 resource 块
terraform plan  # 再次验证直到 No changes
```

::: tip
从 Terraform v1.5 开始，可以使用声明式的 `import` 块替代命令行 `terraform import`，支持在 `terraform plan` 阶段预览导入效果，也更适合 CI/CD 自动化。详见下文 [import 块](#import-块声明式导入)。
:::

## 选项

### -var / -var-file

设置变量值，与 `terraform plan` 的同名选项行为一致：

```bash
terraform import -var="environment=prod" aws_s3_bucket.app my-prod-bucket
```

### -input=false

禁用交互式输入提示：

```bash
terraform import -input=false aws_s3_bucket.app my-bucket
```

### -lock / -lock-timeout

控制状态锁行为：

```bash
terraform import -lock-timeout=60s aws_s3_bucket.app my-bucket
```

### -no-color

禁用带颜色的输出。

### -parallelism

限制并发操作数量，默认为 `10`。

## 导入到不同位置

### 导入到根模块

```bash
terraform import aws_s3_bucket.app my-bucket
```

### 导入到子模块

```bash
terraform import module.storage.aws_s3_bucket.data my-data-bucket
```

### 导入到使用 count 的资源

```bash
terraform import 'aws_s3_bucket.buckets[0]' my-first-bucket
terraform import 'aws_s3_bucket.buckets[1]' my-second-bucket
```

### 导入到使用 for_each 的资源

```bash
terraform import 'aws_s3_bucket.envs["prod"]' my-prod-bucket
terraform import 'aws_s3_bucket.envs["staging"]' my-staging-bucket
```

::: warning
shell 中使用 `for_each` 的 key 时，注意引号的转义。Linux/macOS 中使用单引号包裹：`'aws_s3_bucket.envs["prod"]'`。
:::

## import 块（声明式导入）

从 Terraform v1.5 开始，可以在配置中使用 `import` 块声明要导入的资源，支持 `plan` 预览和批量导入。详见[代码重构 — import 块](/refactor_module#import-块)。

## 注意事项

- 每个远端资源只能导入到一个 Terraform 资源地址。重复导入同一资源会导致状态冲突。
- `terraform import` 不会自动生成配置，你需要手动编写 resource 块并补全属性。
- 导入后务必运行 `terraform plan` 验证配置与实际状态的一致性。plan 有差异时应补全配置，否则下一次 apply 可能会修改或销毁已导入的资源。
- provider 配置不能依赖 data source 的输出。

<KillercodaEmbed src="https://killercoda.com/lonegunman-terraform-tutorial/course/terraform-tutorial/terraform-cli-import" />

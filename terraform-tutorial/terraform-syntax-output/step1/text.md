# 第一步：output 基础与 description

输出值是 Terraform 的"返回值"。apply 成功后，所有 output 都会打印在命令行中。

## 查看示例代码

```bash
cd /root/workspace/step1
cat main.tf
```

观察代码中的几种输出值写法：

- 最简单的 output：只有 value
- 带 description 的 output：向调用者说明输出的含义
- 输出表达式：字符串插值、函数调用
- 输出复合类型：object、list

## 运行代码

```bash
terraform init
terraform apply -auto-approve
```

观察命令行输出中所有 output 的值。注意 app_info 是一个 object，Terraform 会以 JSON 格式显示。

## 使用 terraform output 命令

apply 完成后，你可以随时查看输出值：

```bash
terraform output
```

查看特定的输出值：

```bash
terraform output project_name
terraform output app_info
```

以 JSON 格式输出（适合脚本处理）：

```bash
terraform output -json
```

以原始格式输出（不含引号，适合 shell 脚本）：

```bash
terraform output -raw project_name
```

## 关键点

- output 块的 value 是必填参数，可以是任意合法的表达式
- 同一模块内所有 output 名称必须唯一
- description 面向模块调用者，不是代码注释
- 输出值只在 apply 后才会被计算，plan 不会计算输出值
- terraform output 命令读取的是状态文件中记录的值

✅ 你已经掌握了 output 的基础用法。

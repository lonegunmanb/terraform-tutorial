# 第二步：两步工作流——保存计划 + 执行计划文件

## 场景说明

在 CI/CD 流水线中，plan 和 apply 通常是两条独立的任务：

- plan 在 PR 阶段运行，供团队成员评审变更
- apply 在合并并审批后执行，使用的是已评审过的计划文件

terraform plan -out 和 terraform apply [plan-file] 正是为这个工作流设计的。

## 生成并查看计划文件

先制造一个变更——向 local.common_tags 中添加一个新标签：

```
cd /root/workspace
sed -i 's/ManagedBy   = "Terraform"/ManagedBy   = "Terraform"\n    Version     = "v1"/' main.tf
```

将计划保存到文件：

```
terraform plan -out=tfplan
```

计划文件是二进制格式，直接 cat 会乱码：

```
cat tfplan | head -3
```

## 保存计划模式的限制

在执行计划之前，先试试附加 -var 会怎样：

```
terraform apply -var 'environment=prod' tfplan
```

Terraform 会报错：规划选项只能在生成计划时指定，计划文件一旦生成就固定了所有决策，apply 时不能再修改。

## 执行保存的计划

执行已保存的计划——注意没有任何确认提示：

```
terraform apply tfplan
```

传入计划文件本身就代表已完成审批。输出与普通 apply 相同，但直接进入执行阶段，不会出现 "Do you want to perform these actions?" 提示。

检查输出：

```
Apply complete! Resources: 0 added, 3 changed, 0 destroyed.
```

## 清理

删除计划文件，恢复配置：

```
rm tfplan
sed -i '/Version.*v1/d' main.tf
terraform apply -auto-approve
```

确认显示 No changes 后进入下一步。

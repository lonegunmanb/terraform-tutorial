# 恭喜完成 terraform destroy 实战练习！

## 知识总结

| 功能 | 命令 / 参数 | 核心场景 |
|------|------------|---------|
| 销毁全部资源（交互确认） | terraform destroy | 清理临时环境 |
| 跳过确认 | terraform destroy -auto-approve | 自动化流水线中的清理步骤 |
| 预览销毁 | terraform plan -destroy | 在实际销毁前审查影响范围 |
| 定向销毁 | terraform destroy -target=ADDR | 只销毁指定资源，保留其他 |
| 传入变量 | terraform destroy -var-file=f.tfvars | 确保定位到正确的资源 |
| 两步销毁 | plan -destroy -out=plan + apply plan | CI/CD 中先审批再执行 |
| 等价命令 | terraform apply -destroy | 与 destroy 完全等价 |

## 重要提醒

- terraform destroy 不可撤销——输入 yes 后资源将被永久删除
- 销毁只影响远端资源和 state 文件，.tf 配置不会被修改，随时可以重新 apply 重建
- -target 销毁后 state 与配置不一致，需要后续的 apply 或手动删除 resource 块来对齐
- 在 CI/CD 中推荐两步流程：terraform plan -destroy -out=destroy.tfplan -> 审批 -> terraform apply destroy.tfplan

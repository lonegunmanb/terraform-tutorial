# 第四步：测验 — 综合模块调用

现在轮到你动手了！请根据要求编写模块调用代码，并使用 terraform test 验证答案。

## 查看题目

```bash
cd /root/workspace/step4
cat main.tf
```

main.tf 中已经包含了 provider 配置和题目要求（注释中）。你的任务是：

1. 使用 terraform-aws-modules/s3-bucket/aws 模块（version = "5.12.0"），创建 3 个桶：
   - 模块名称: web_assets，bucket: "quiz-web-assets"，tags: { Role = "frontend" }
   - 模块名称: api_data，bucket: "quiz-api-data"，tags: { Role = "backend" }
   - 模块名称: backups，bucket: "quiz-backups"，tags: { Role = "ops" }

2. 定义以下 output：
   - web_assets_id: 值为 module.web_assets.s3_bucket_id
   - api_data_arn: 值为 module.api_data.s3_bucket_arn
   - backups_id: 值为 module.backups.s3_bucket_id
   - all_bucket_ids: 值为包含三个桶 s3_bucket_id 的列表（顺序：web_assets, api_data, backups）

## 开始作答

在 main.tf 的 TODO 注释下方添加你的代码。你需要：
- 3 个 module 块
- 4 个 output 块

提示：回顾前面几步中 module 块的写法，每个 module 块需要 source、version、bucket 和 tags 四个参数。

## 验证答案

完成编写后，先初始化再运行测试：

```bash
terraform init
terraform test
```

如果你的代码正确，你会看到类似输出：

```
tests/module_call_test.tftest.hcl... in progress
  run "web_assets_bucket"... pass
  run "api_data_bucket"... pass
  run "backups_bucket"... pass
  run "outputs_correct"... pass
tests/module_call_test.tftest.hcl... tearing down
tests/module_call_test.tftest.hcl... pass

Success! 4 passed, 0 failed.
```

如果测试失败，根据错误信息检查：
- 每个 module 块的名称是否正确（web_assets、api_data、backups）？
- bucket 的值是否完全匹配？
- tags 是否包含正确的 Role 键值？
- output 的名称和值是否匹配要求？注意输出名是 s3_bucket_id 和 s3_bucket_arn
- all_bucket_ids 中三个桶的顺序是否正确？

修改后重新运行 terraform test 直到所有 4 个测试通过。

## 查看测试文件（可选）

好奇测试怎么写的？查看测试文件：

```bash
cat tests/module_call_test.tftest.hcl
```

这个测试文件包含 4 个 run 块，分别验证：
- web_assets 模块的 s3_bucket_id 和 s3_bucket_arn
- api_data 模块的 s3_bucket_id 和 s3_bucket_arn
- backups 模块的 s3_bucket_id
- 所有 output 的值和 all_bucket_ids 列表的顺序

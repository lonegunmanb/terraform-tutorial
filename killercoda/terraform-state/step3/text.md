# 第三步：理解状态文件结构

直接查看状态文件的 JSON 内容：

```bash
cat terraform.tfstate | head -60
```

状态文件的核心结构：

```json
{
  "version": 4,
  "serial": 3,
  "resources": [
    {
      "mode": "managed",
      "type": "aws_s3_bucket",
      "name": "data",
      "instances": [
        {
          "attributes": { "bucket": "my-app-data-bucket", ... }
        }
      ]
    }
  ]
}
```

关键字段：
- **`serial`**：每次写入递增，用于并发控制
- **`resources`**：所有被管理的资源列表
- **`instances[].attributes`**：资源的实际属性值

再用 `terraform show` 以人类可读的格式查看：

```bash
terraform show
```

🎉 现在你已经理解了状态文件的结构和作用。

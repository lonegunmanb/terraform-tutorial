# 第二步：常见错误类型

## 必填属性缺失

创建一个新文件，声明一个缺少必填属性的资源：

```
cat > extra.tf <<'EOF'
resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id
}
EOF
```

aws_s3_bucket_versioning 资源要求必须包含 versioning_configuration 块。运行 validate：

```
terraform validate
```

报错指出缺少必填的嵌套块或属性。

修复——补上必填块：

```
cat > extra.tf <<'EOF'
resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id
  versioning_configuration {
    status = "Enabled"
  }
}
EOF
terraform validate
```

确认通过。

## 引用不存在的资源

修改 extra.tf，引用一个不存在的资源：

```
cat > extra.tf <<'EOF'
resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.logs.id
  versioning_configuration {
    status = "Enabled"
  }
}
EOF
terraform validate
```

报错：

```
Error: Reference to undeclared resource
```

配置中没有声明过 aws_s3_bucket.logs，validate 精确定位了这个引用错误。

## validate 不检查远端状态

恢复 extra.tf 为正确配置并 validate：

```
cat > extra.tf <<'EOF'
resource "aws_s3_bucket_versioning" "app" {
  bucket = aws_s3_bucket.app.id
  versioning_configuration {
    status = "Enabled"
  }
}
EOF
terraform validate
```

validate 通过了。但此时 S3 桶还没有创建（我们没有运行过 apply）——validate 不关心远端资源的实际状态，它只检查配置文件本身的正确性。

运行 plan 对比远端状态：

```
terraform plan
```

plan 会连接远端，发现这些资源尚未创建，输出 Plan: 2 to add。这就是 validate 和 plan 的核心区别：validate 只做静态检查，plan 还会读取远端状态并计算差异。

清理 extra.tf：

```
rm extra.tf
terraform validate
```

确认 Success 后进入下一步。

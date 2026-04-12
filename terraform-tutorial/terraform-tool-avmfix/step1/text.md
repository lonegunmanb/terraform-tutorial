# 体验 avmfix 自动修复代码规范

## 查看"乱序"的代码

进入工作目录，看看当前的文件结构：

```
cd /root/workspace
ls -la *.tf
```

只有 main.tf 和 variables.tf，没有 outputs.tf——因为 output 块被写在了 main.tf 中。

### 查看 main.tf 中的问题

```
cat main.tf
```

注意以下问题：

1. aws_s3_bucket.logs：tags 写在 bucket 前面（应该按 Schema 顺序排列）
2. aws_s3_bucket.app：depends_on 写在最前面（应该在块末尾）
3. aws_dynamodb_table.sessions：tags 写在 hash_key 和 name 前面
4. locals 块：environment、common_tags、app_prefix 不是字母序
5. 三个 output 块写在 main.tf 中（应该在 outputs.tf）
6. variable "force_destroy" 写在 main.tf 中（应该在 variables.tf）
7. force_destroy 变量的 nullable = true（默认值，冗余）和 sensitive = false（默认值，冗余）

### 查看 variables.tf

```
cat variables.tf
```

变量的 type/default/description 属性顺序不一致：app_name 是 default、description、type，而标准顺序应该是 type、default、description。

## 用 git 跟踪变更

初始化 git，方便对比 avmfix 前后的差异：

```
git init
git add -A
git commit -m "before avmfix"
```

## 运行 avmfix

```
avmfix -folder .
```

看到 "DirectoryAutoFix completed successfully." 说明修复完成。

## 查看变更

```
git diff
```

变更很多！让我们逐一查看修复效果。

### 文件归位

```
ls -la *.tf
```

现在多了 outputs.tf——avmfix 把 main.tf 中的三个 output 块移到了 outputs.tf，并把 force_destroy 变量移到了 variables.tf。

```
cat outputs.tf
```

output 块按字母序排列：app_bucket、logs_bucket、sessions_table。

### resource 块排序

```
cat main.tf
```

观察 aws_s3_bucket.app 的变化：

- depends_on 移到了块末尾（之前在最前面）
- bucket 在前，force_destroy 在后，tags 在最后（按 Schema 顺序）

aws_dynamodb_table.sessions 也被重排：name、billing_mode、hash_key 在前，tags 在后。

### variable 块排序

```
cat variables.tf
```

每个变量块的属性顺序统一为：type → default → description。

注意 force_destroy 变量的 nullable = true 和 sensitive = false 被移除了——这些是默认值，声明它们属于冗余。

### locals 排序

在 main.tf 中查看 locals 块，现在按字母序排列：app_prefix、common_tags、environment。

## 格式化收尾

avmfix 不处理缩进和对齐（那是 terraform fmt 的事），所以最后运行一次 fmt：

```
terraform fmt
```

查看最终结果：

```
cat main.tf
```

代码现在整洁、规范、一致。

## 提交修复后的代码

```
git add -A
git diff --cached --stat
git commit -m "after avmfix + terraform fmt"
```

查看完整的变更统计。在实际项目中，这种格式修复应该作为独立的 commit 提交，方便代码审查。

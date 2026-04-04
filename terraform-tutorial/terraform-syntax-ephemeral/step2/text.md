# 第二步：ephemeral + Secrets Manager — 安全传递凭据

在这一步中，你将体验临时资源的实际应用：用 ephemeral 生成密码，搭配 AWS Secrets Manager 的 write-only 属性，实现端到端的"状态文件零敏感数据"。

## 查看代码

```bash
cd /root/workspace/step2
cat main.tf
```

代码中有两种方式：

**安全方式（ephemeral + write-only）：**
1. `ephemeral "random_password"` 生成密码 — 不保存到状态文件
2. `local` 中转密码，构建 JSON 凭据
3. `aws_secretsmanager_secret_version` 使用 `secret_string_wo` — write-only 属性，值发送给 API 但不记录到状态

**不安全方式（resource + 普通属性）：**
1. `resource "random_password"` 生成密码 — 保存到状态文件
2. `aws_secretsmanager_secret_version` 使用 `secret_string` — 普通属性，值记录到状态文件

## 执行 Apply

```bash
terraform apply -auto-approve
```

## 验证 Secret 内容

两种方式都成功创建了 Secret。用 AWS CLI 验证它们在 Secrets Manager 中的内容：

```bash
# 安全方式创建的 Secret
awslocal secretsmanager get-secret-value \
  --secret-id "prod/db-credentials" \
  --query 'SecretString' --output text | python3 -m json.tool

# 不安全方式创建的 Secret
awslocal secretsmanager get-secret-value \
  --secret-id "prod/db-credentials-insecure" \
  --query 'SecretString' --output text | python3 -m json.tool
```

两个 Secret 的内容格式相同，都包含 username、password、host、port。

## 对比状态文件

现在来看关键差异——状态文件中保存了什么：

```bash
# 不安全方式：密码完整地保存在状态文件中
terraform state show random_password.db_password_resource
```

你会看到密码的明文。再查看 secret_version 资源：

```bash
terraform state show aws_secretsmanager_secret_version.db_credentials_insecure
```

`secret_string` 字段中包含完整的 JSON 凭据（用户名、密码、主机等）——全部明文。

现在看安全方式：

```bash
terraform state show aws_secretsmanager_secret_version.db_credentials
```

注意 `secret_string_wo` 字段不在状态中——write-only 属性不会被持久化。再搜索临时密码：

```bash
cat terraform.tfstate | grep "ephemeral" || echo "状态文件中没有 ephemeral 的痕迹"
```

临时资源根本不存在于状态文件中。

## 汇总对比

```bash
echo "=== 不安全方式：状态文件中的敏感数据 ==="
cat terraform.tfstate | python3 -c "
import json, sys
state = json.load(sys.stdin)
for r in state.get('resources', []):
    if r.get('name') == 'db_password_resource':
        for inst in r.get('instances', []):
            pwd = inst.get('attributes', {}).get('result', '')
            print(f'  random_password.result = {pwd}')
    if r.get('name') == 'db_credentials_insecure' and r.get('type') == 'aws_secretsmanager_secret_version':
        for inst in r.get('instances', []):
            ss = inst.get('attributes', {}).get('secret_string', '')
            if ss:
                print(f'  secret_version.secret_string = {ss}')
"

echo ""
echo "=== 安全方式：状态文件中无敏感数据 ==="
echo "  ephemeral random_password: 不在状态中"
echo "  secret_string_wo: 不在状态中"
```

## 清理

```bash
terraform destroy -auto-approve
```

## 关键点

- ephemeral 生成的密码不保存到状态文件
- write-only 属性（secret_string_wo）将值发送给 API 但不记录到状态
- 两者结合实现了端到端的"状态文件零敏感数据"
- 不安全方式（resource + secret_string）的密码以明文存在于状态文件中
- 在实际项目中，状态文件往往存储在远程后端（S3、Terraform Cloud）——其中的敏感数据是安全隐患

完成后继续下一步。

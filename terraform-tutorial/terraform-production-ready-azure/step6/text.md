# 第六步：验证工作负载身份链端到端

前五步完成了模块化拆分和状态隔离。这一步不写新代码，而是手动跑一遍**运行时身份链**——看 step 4 用 Terraform 声明的 UAI + role_assignment + KV + secret 在数据面是不是真的能串起来。

## 1. 取出 vault 名和 secret 名

```bash
cd /root/workspace
VAULT=$(terragrunt --terragrunt-working-dir security output -raw key_vault_name)
SECRET=$(terragrunt --terragrunt-working-dir security output -raw db_credentials_secret_name)
echo "Vault=$VAULT  Secret=$SECRET"
```

## 2. 模拟“在 VM 内部”——从 IMDS 拿 token

```bash
TOKEN=$(curl -s -H "Metadata: true" \
  "http://localhost:4566/metadata/identity/oauth2/token?resource=https://vault.azure.net/" \
  | jq -r .access_token)
echo "Got token: ${TOKEN:0:24}..."
```

## 3. 用 token 调 Key Vault data plane 读 secret

```bash
curl -s -H "Authorization: Bearer $TOKEN" \
  "https://${VAULT}.vault.azure.net/secrets/${SECRET}?api-version=7.4" | jq .
```

返回值就是 step 4 中 azurerm_key_vault_secret.db_credentials 写入的 JSON 凭证。**整条链路完全由 Terraform 声明，运行时模拟真实 Azure VM 内的工作负载行为**。

## 思考题

如果把 step 4 的 azurerm_role_assignment.keyvault 删掉，第 3 步还会成功吗？

**答案**：在 miniblue 上会，因为它不强制鉴权（[miniblue RBAC docs](https://github.com/lonegunmanb/miniblue/blob/main/website/docs/services/rbac.md)）；在真实 Azure 上不会，会返回 403 Forbidden。这正是为什么生产代码必须把 role_assignment 作为架构的一等公民——miniblue 让你**练习写对的代码**，真实 Azure 才**惩罚你写错的代码**。

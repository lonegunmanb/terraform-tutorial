import json, sys

state = json.load(sys.stdin)

print("=== 不安全方式：状态文件中的敏感数据 ===")
for r in state.get("resources", []):
    if r.get("name") == "db_password_resource":
        for inst in r.get("instances", []):
            pwd = inst.get("attributes", {}).get("result", "")
            print(f"  random_password.result = {pwd}")
    if r.get("name") == "db_credentials_insecure" and r.get("type") == "aws_secretsmanager_secret_version":
        for inst in r.get("instances", []):
            ss = inst.get("attributes", {}).get("secret_string", "")
            if ss:
                print(f"  secret_version.secret_string = {ss}")

print()
print("=== 安全方式：状态文件中无敏感数据 ===")

has_ephemeral = False
for r in state.get("resources", []):
    if "ephemeral" in json.dumps(r):
        has_ephemeral = True
        break

if not has_ephemeral:
    print("  ephemeral random_password: 不在状态中")
print("  secret_string_wo: 不在状态中（write-only 属性不会被持久化）")

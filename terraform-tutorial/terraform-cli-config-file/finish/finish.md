# 恭喜完成！

你已经掌握了 Terraform CLI 配置文件的核心用法：

- **.terraformrc 文件**：在用户主目录下创建 CLI 全局配置
- **plugin_cache_dir**：启用插件缓存，避免重复下载，加速初始化
- **disable_checkpoint**：关闭联网版本检查，适用于离线或受限网络
- **provider_installation**：自定义 Provider 安装策略（filesystem_mirror / direct）
- **TF_CLI_CONFIG_FILE**：通过环境变量临时切换配置文件

## 延伸阅读

- [CLI Configuration File](https://developer.hashicorp.com/terraform/cli/config/config-file)
- [Provider Network Mirror Protocol](https://developer.hashicorp.com/terraform/internals/provider-network-mirror-protocol)

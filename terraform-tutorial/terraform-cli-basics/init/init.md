# Terraform CLI 基础命令实战

欢迎来到 Terraform CLI 基础命令实验！

本实验聚焦于那些不需要直接操作云资源、但同样重要的 Terraform CLI 命令：

1. **version 与 -chdir** —— 查看版本、安装自动补全、不切目录直接指定路径
2. **terraform fmt** —— 格式化代码，特意准备了一个缩进混乱的文件供你练习
3. **terraform console** —— 交互式计算 HCL 表达式，调试变量和内置函数
4. **terraform get 与 graph** —— 下载模块、生成资源依赖图

> 💡 本实验使用 null provider，无需任何云账号，环境启动速度显著更快。
> 
> `init`、`plan`、`apply`、`destroy` 等资源生命周期命令将在后续章节中分别讲解。

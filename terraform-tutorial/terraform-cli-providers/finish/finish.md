# 恭喜完成 terraform providers 实战练习！

## 知识总结

| 命令 | 用途 | 核心场景 |
|------|------|---------|
| terraform providers | 查看 provider 依赖树 | 排查"某个 provider 从哪来" |
| terraform providers schema -json | 输出完整的 provider schema | 开发自动化工具、查询属性定义 |
| terraform providers lock | 更新锁文件的校验和 | 跨平台支持、镜像源校验 |
| terraform providers mirror DIR | 下载 provider 到本地镜像 | 气隙环境、CI 缓存加速 |

## 关键要点

- terraform providers 不需要 init，直接分析配置文件
- providers schema -json 需要先 init（依赖已安装的 provider 插件）
- providers lock 只更新锁文件，不安装 provider
- providers mirror 只下载到镜像目录，不影响当前工作目录
- 使用本地镜像需要在 .terraformrc 中配置 filesystem_mirror

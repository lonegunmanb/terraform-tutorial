# Terraform 交互式教程

基于 **GitHub Pages + Killercoda** 的零成本交互式 Terraform 教程。

## 架构

| 层 | 技术 | 职责 |
|---|---|---|
| 前端展示层 | Vite + Tailwind CSS → GitHub Pages | 品牌页面、教程大纲、iframe 容器 |
| 交互实验层 | Killercoda (Ubuntu + Docker + LocalStack) | 真实终端 + Terraform CLI 沙盒 |
| CI/CD | GitHub Actions | 推送 main 自动构建部署 |

## 本地开发

```bash
npm install
npm run dev
```

## 构建部署

推送到 `main` 分支即可触发 GitHub Actions 自动部署到 GitHub Pages。

手动构建：

```bash
npm run build   # 输出到 dist/
```

## Killercoda 场景

场景定义位于 `terraform-tutorial/` 目录。将此仓库关联到你的 [Killercoda Creator](https://killercoda.com/creator) 账号后，场景会自动同步。

### 配置步骤

1. 在 `src/chapters.js` 中将 `YOUR_USERNAME` 替换为你的 Killercoda 用户名
2. 在 GitHub 仓库 Settings → Pages 中启用 GitHub Pages（Source: GitHub Actions）
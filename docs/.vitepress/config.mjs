import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Terraform 交互式教程',
  description: '基于 Killercoda 的零成本交互式 Terraform 教程',
  base: '/terraform-tutorial/',
  lang: 'zh-CN',
  sitemap: {
    hostname: 'https://lonegunmanb.github.io/terraform-tutorial/'
  },

  head: [
    ['link', { rel: 'icon', type: 'image/svg+xml', href: 'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100"><text y=".9em" font-size="90">🏗️</text></svg>' }],
  ],

  themeConfig: {
    nav: [
      { text: '首页', link: '/' },
      { text: '开始学习', link: '/intro' },
    ],

    // @auto-sidebar-start
    sidebar: [
      {
        text: '教程章节',
        items: [
          { text: '课程介绍', link: '/intro' },
          { text: '基础：Terraform 基本生命周期', link: '/basics' },
          { text: '状态管理', link: '/state' },
          { text: 'Backend 配置', link: '/backend' },
          { text: 'Terraform 语法', link: '/syntax' },
          { text: 'Provider 配置', link: '/provider' },
          { text: 'Terraform 模块', link: '/module' },
          { text: '代码重构', link: '/refactor_module' },
          {
            text: 'Terraform CLI',
            collapsed: false,
            items: [
              { text: 'CLI 基础命令', link: '/terraform-cli-basic' },
              { text: 'CLI 配置文件', link: '/terraform-cli-config-file' },
              { text: 'init', link: '/terraform-cli-init' },
              { text: 'plan', link: '/terraform-cli-plan' },
              { text: 'apply', link: '/terraform-cli-apply' },
              { text: 'destroy', link: '/terraform-cli-destroy' },
              { text: 'validate', link: '/terraform-cli-validate' },
              { text: 'show', link: '/terraform-cli-show' },
              { text: 'output', link: '/terraform-cli-output' },
              { text: 'import', link: '/terraform-cli-import' },
              { text: 'providers', link: '/terraform-cli-providers' },
              { text: 'state', link: '/terraform-cli-state' },
              { text: 'workspace', link: '/terraform-cli-workspace' }
            ]
          },
          { text: '批量导入资源', link: '/query_import' },
          { text: 'Terraform 测试', link: '/test' },
          {
            text: '周边工具',
            collapsed: false,
            items: [
              { text: 'hcledit', link: '/terraform-tool-hcledit' },
              { text: 'mapotf', link: '/terraform-tool-mapotf' },
              { text: 'avmfix', link: '/terraform-tool-avmfix' },
              { text: 'terraform-docs', link: '/terraform-tool-terraform-docs' },
              { text: 'tflint', link: '/terraform-tool-tflint' }
            ]
          }
        ],
      },
    ],
    // @auto-sidebar-end

    socialLinks: [
      { icon: 'github', link: 'https://github.com/lonegunmanb/terraform-tutorial' },
    ],

    outline: { label: '本页目录' },
    docFooter: { prev: '上一章', next: '下一章' },
    darkModeSwitchLabel: '主题',
    sidebarMenuLabel: '菜单',
    returnToTopLabel: '回到顶部',
  },
})

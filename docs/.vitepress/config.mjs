import { defineConfig } from 'vitepress'

export default defineConfig({
  title: 'Terraform 交互式教程',
  description: '基于 Killercoda 的零成本交互式 Terraform 教程',
  base: '/terraform-tutorial/',
  lang: 'zh-CN',

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
          { text: 'Terraform 模块', link: '/module' }
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

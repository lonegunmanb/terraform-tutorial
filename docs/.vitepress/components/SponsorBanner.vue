<template>
  <div class="sponsor-banner">
    <p class="sponsor-title">🙏 致谢</p>
    <p class="sponsor-text">
      本教程的交互式实验环境由
      <a href="https://killercoda.com" target="_blank" rel="noopener">Killercoda</a>
      免费提供 —— 打开浏览器即可获得真实的 Linux 环境，无需任何本地配置。
      AWS 云服务由
      <a href="https://www.localstack.cloud" target="_blank" rel="noopener">LocalStack</a>
      在本地完整模拟 —— 让开发者无需真实云账号即可快速构建和测试云应用。
      在需要使用 AWS Provider v6 的场景中，我们使用了
      <a href="https://github.com/ministackorg/ministack" target="_blank" rel="noopener">MiniStack</a>
      —— 一个轻量级的 AWS 模拟服务。
    </p>
    <p class="sponsor-text donate-hint">如果本教程对你有帮助，敬请微信打赏，您的打赏将成为后续更多教程的 Token 🪙</p>
    <div class="sponsor-qrcode">
      <img :src="qrcodeUrl" alt="微信打赏二维码" />
    </div>
  </div>
</template>

<script setup>
import { withBase } from 'vitepress'

const qrcodeUrl = withBase('/images/donate.png')
</script>

<style scoped>
.sponsor-banner {
  margin: 1.5rem 0;
  padding: 1rem 1.25rem;
  border-radius: 8px;
  border: 1px solid var(--vp-c-brand-1);
  background: var(--vp-c-brand-soft);
}
.sponsor-title {
  margin: 0 0 0.4rem;
  font-weight: 700;
  font-size: 0.95rem;
}
.sponsor-text {
  margin: 0;
  font-size: 0.9rem;
  line-height: 1.6;
}
.sponsor-text a {
  font-weight: 600;
  color: var(--vp-c-brand-1);
  text-decoration: underline;
}
.donate-hint {
  margin-top: 0.75rem;
  font-weight: 600;
}
.sponsor-qrcode {
  margin-top: 0.5rem;
  text-align: center;
}
.sponsor-qrcode img {
  max-width: 180px;
  border-radius: 8px;
}
</style>

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
    </p>
  </div>
</template>

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
</style>

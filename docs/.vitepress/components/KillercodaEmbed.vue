<script setup>
import { ref } from 'vue'

const props = defineProps({
  src: { type: String, required: true },
  title: { type: String, default: '实验环境' },
  height: { type: String, default: '70vh' },
})

const loading = ref(true)

function isValidUrl(url) {
  try {
    const parsed = new URL(url)
    return parsed.protocol === 'https:' && parsed.hostname.endsWith('killercoda.com')
  } catch {
    return false
  }
}

const safeSrc = isValidUrl(props.src) ? props.src : 'about:blank'
</script>

<template>
  <div class="killercoda-embed" :style="{ height }">
    <div v-if="loading" class="loading-overlay">
      <div class="loading-content">
        <p>⚙️ 正在为你准备真实的云端实验室...</p>
        <p class="hint">首次加载可能需要 15-30 秒</p>
      </div>
    </div>
    <iframe
      :src="safeSrc"
      :title="title"
      width="100%"
      height="100%"
      loading="lazy"
      @load="loading = false"
    />
  </div>
</template>

<style scoped>
.killercoda-embed {
  position: relative;
  border: 1px solid var(--vp-c-border);
  border-radius: 8px;
  overflow: hidden;
  margin: 16px 0;
}

.killercoda-embed iframe {
  border: none;
  display: block;
}

.loading-overlay {
  position: absolute;
  inset: 0;
  display: flex;
  align-items: center;
  justify-content: center;
  background: var(--vp-c-bg-soft);
  z-index: 10;
}

.loading-content {
  text-align: center;
  animation: pulse 2s ease-in-out infinite;
}

.loading-content p {
  margin: 0;
  font-size: 1.1rem;
}

.loading-content .hint {
  font-size: 0.85rem;
  color: var(--vp-c-text-3);
  margin-top: 4px;
}

@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: 0.5; }
}
</style>

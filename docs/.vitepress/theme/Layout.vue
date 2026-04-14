<script setup>
import DefaultTheme from 'vitepress/theme'
import SponsorBanner from '../components/SponsorBanner.vue'

const { Layout } = DefaultTheme
</script>

<template>
  <Layout>
    <!-- Shown on home page, between hero and features -->
    <template #home-features-before>
      <div class="sponsor-home-wrapper">
        <SponsorBanner />
      </div>
    </template>

    <!-- Shown on doc pages, before the article content -->
    <template #doc-before>
      <SponsorBanner />
    </template>
  </Layout>
</template>

<style scoped>
.sponsor-home-wrapper {
  max-width: 1152px;
  margin: 0 auto;
  padding: 0 24px;
}
@media (min-width: 640px) {
  .sponsor-home-wrapper {
    padding: 0 48px;
  }
}
@media (min-width: 960px) {
  .sponsor-home-wrapper {
    padding: 0 64px;
  }
}
</style>

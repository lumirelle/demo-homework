<script setup lang="ts">
import { NButton } from 'naive-ui'
import { useRouter } from 'vue-router'
const router = useRouter()
</script>

<template>
  <main class="wrap">
    <p class="code">404</p>
    <h1>Page Not Found</h1>
    <p>你访问的页面不存在或还没建。</p>
    <NButton type="primary" @click="router.push('/home')">回首页</NButton>
  </main>
</template>

<style scoped>
.wrap {
  min-height: 100vh;
  display: grid;
  place-content: center;
  text-align: center;
  gap: var(--sp-3);
}
.code {
  font-family: var(--font-mono);
  font-size: 84px;
  font-weight: var(--fw-bold);
  color: var(--brand-500);
  margin: 0;
  letter-spacing: -0.02em;
}
h1 {
  margin: 0;
  font-size: var(--fs-2xl);
  font-weight: var(--fw-bold);
}
p {
  color: var(--text-tertiary);
}
</style>

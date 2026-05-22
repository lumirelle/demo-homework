<script setup lang="ts">
import { NButton } from 'naive-ui'
import { useRouter } from 'vue-router'

const router = useRouter()
</script>

<template>
  <main
    min-h-screen
    grid place-content-center
    text-center
    gap-3
    class="pt-[60px]"
  >
    <p
      m-0
      font="mono bold"
      text="[84px] brand-500"
      tracking="[-0.02em]"
    >
      404
    </p>
    <h1 m-0 text-2xl font-bold>
      Page Not Found
    </h1>
    <p text-tertiary>
      你访问的页面不存在或还没建。
    </p>
    <NButton type="primary" @click="router.push('/home')">
      回首页
    </NButton>
  </main>
</template>

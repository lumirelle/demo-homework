<script setup lang="ts">
import { useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const auth = useAuthStore()

function goBack() {
  router.back()
}
function goHome() {
  router.replace('/home')
}
</script>

<template>
  <div min-h-screen flex-col flex="~ items-center justify-center" bg-app class="px-4 pt-[60px] text-center">
    <div class="text-[7rem] font-display font-bold leading-none text-gradient mb-4 select-none">
      403
    </div>
    <h1 text-2xl font-bold text-primary mb-3>
      无权访问
    </h1>
    <p text-tertiary mb-8 class="max-w-[360px]">
      您的角色（{{ auth.role ?? '未知' }}）没有访问此页面的权限。请联系管理员，或返回上一页。
    </p>
    <div flex="~ gap-3 items-center">
      <button
        class="px-5 py-2.5 rounded-xl border border-(--border) text-sm text-secondary hover:bg-(--bg-hover) transition-colors"
        @click="goBack"
      >
        返回上一页
      </button>
      <button
        class="px-5 py-2.5 rounded-xl bg-brand text-white text-sm font-medium hover:brightness-110 transition-all"
        @click="goHome"
      >
        回到首页
      </button>
    </div>
  </div>
</template>

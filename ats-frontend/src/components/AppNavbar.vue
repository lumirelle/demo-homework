<script setup lang="ts">
import { NDropdown, NIcon } from 'naive-ui'
import { computed, h } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useAuthStore } from '@/stores/auth'

const router = useRouter()
const route = useRoute()
const auth = useAuthStore()

const ROLE_LABEL: Record<string, string> = {
  ADMIN: '管理员',
  HR: 'HR',
  CANDIDATE: '候选人',
}

const ROLE_BADGE: Record<string, string> = {
  ADMIN: 'bg-[rgba(251,191,36,.15)] text-[#d97706]',
  HR: 'bg-[rgba(16,185,129,.15)] text-[#047857]',
  CANDIDATE: 'bg-[rgba(34,211,238,.15)] text-[#0891b2]',
}

const avatarBg = computed(() => {
  const role = auth.role ?? ''
  if (role === 'ADMIN')
    return 'linear-gradient(135deg,#fbbf24,#f97316)'
  if (role === 'HR')
    return 'linear-gradient(135deg,#34d399,#14b8a6)'
  return 'linear-gradient(135deg,#22d3ee,#3b82f6)'
})

const initial = computed(() => (auth.user?.fullName ?? 'U')[0].toUpperCase())

const navLinks = computed(() => [
  { to: '/home', label: '首页', icon: 'M3 12 L12 4 L21 12 M5 10 V20 H19 V10' },
])

function renderIcon(svg: string) {
  return () => h(NIcon, null, {
    default: () => h('svg', { viewBox: '0 0 24 24', fill: 'none' }, [
      h('path', { 'd': svg, 'stroke': 'currentColor', 'stroke-width': 1.6, 'stroke-linecap': 'round', 'stroke-linejoin': 'round' }),
    ]),
  })
}

const menuOptions = computed(() => [
  {
    key: 'header',
    type: 'render',
    render: () => h('div', { class: 'px-3 py-2.5 border-b border-(--border)' }, [
      h('p', { class: 'text-[11px] uppercase tracking-widest text-tertiary mb-0.5' }, '当前账户'),
      h('p', { class: 'text-sm font-semibold text-primary truncate' }, auth.user?.email ?? ''),
    ]),
  },
  {
    label: '个人资料',
    key: 'me',
    disabled: true,
    icon: renderIcon('M16 7a4 4 0 1 1-8 0 4 4 0 0 1 8 0ZM4 21a8 8 0 0 1 16 0'),
  },
  {
    label: '快捷键',
    key: 'shortcut',
    disabled: true,
    icon: renderIcon('M4 6 H20 V18 H4 Z M7 10 H7.01 M11 10 H11.01 M15 10 H15.01 M7 14 H17'),
  },
  { type: 'divider', key: 'd1' },
  {
    label: '退出登录',
    key: 'logout',
    icon: renderIcon('M15 12 H3 M3 12 L7 8 M3 12 L7 16 M11 4 H17 A2 2 0 0 1 19 6 V18 A2 2 0 0 1 17 20 H11'),
  },
])

async function handleSelect(key: string) {
  if (key === 'logout') {
    await auth.logout()
    router.replace('/login')
  }
}

function isActive(path: string) {
  return route.path.startsWith(path)
}
</script>

<template>
  <header class="group fixed inset-x-0 top-0 z-50 h-[60px]">
    <!-- 玻璃背景 -->
    <div class="navbar-glass absolute inset-0" />
    <!-- 顶部 1px 发光分隔条（hover navbar 出现） -->
    <div class="navbar-glow-line group-hover:opacity-100" />

    <div class="relative flex h-full items-center justify-between px-6">
      <!-- ── Logo ───────────────────────────────── -->
      <router-link to="/home" class="group/logo flex items-center gap-2.5 no-underline">
        <span class="logo-mark group-hover/logo:(rotate-[-8deg] scale-106 shadow-[0_0_24px_rgba(16,185,129,.6),inset_0_1px_0_rgba(255,255,255,.3)])">
          <svg width="14" height="14" viewBox="0 0 14 14" fill="none">
            <path d="M2 10 L7 3 L12 10" stroke="white" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
            <path d="M4.5 10 L7 6.5 L9.5 10" stroke="white" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" opacity="0.5" />
          </svg>
        </span>
        <span class="font-display text-base font-bold tracking-wide text-primary transition-opacity group-hover/logo:opacity-75">
          ATS
        </span>
        <span class="version-pill ml-1">v0.1</span>
      </router-link>

      <!-- ── Center nav ─────────────────────────── -->
      <nav v-if="auth.isLoggedIn" class="absolute left-1/2 flex -translate-x-1/2 items-center gap-1 rounded-xl border border-(--border) bg-(--bg-elevated)/40 p-1 backdrop-blur-sm">
        <router-link
          v-for="item in navLinks"
          :key="item.to"
          :to="item.to"
          class="relative flex items-center gap-1.5 rounded-lg px-3 py-1.5 text-sm font-medium no-underline transition-all"
          :class="isActive(item.to)
            ? 'text-primary bg-elevated shadow-[0_1px_2px_rgba(0,0,0,.05),inset_0_0_0_1px_var(--border)]'
            : 'text-tertiary hover:(text-secondary bg-hover)'"
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
            <path :d="item.icon" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          {{ item.label }}
        </router-link>
      </nav>

      <!-- ── Right ──────────────────────────────── -->
      <div class="flex items-center gap-3">
        <template v-if="auth.isLoggedIn">
          <NDropdown
            :options="menuOptions"
            trigger="click"
            placement="bottom-end"
            :show-arrow="true"
            @select="handleSelect"
          >
            <button class="user-trigger group/user">
              <span class="avatar" :style="`background:${avatarBg}`">{{ initial }}</span>
              <div class="hidden flex-col items-start leading-none sm:flex">
                <span class="text-[13px] font-semibold text-primary">{{ auth.user?.fullName }}</span>
                <span class="mt-0.5 inline-flex items-center gap-1">
                  <span
                    class="inline-block px-[5px] py-px text-[10px] font-semibold leading-tight rounded-[3px]"
                    :class="ROLE_BADGE[auth.role ?? '']"
                  >
                    {{ ROLE_LABEL[auth.role ?? ''] ?? auth.role }}
                  </span>
                </span>
              </div>
              <svg class="ml-0.5 text-tertiary opacity-60 transition-transform group-hover/user:rotate-180" width="12" height="12" viewBox="0 0 12 12" fill="none">
                <path d="M3 4.5 L6 7.5 L9 4.5" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
            </button>
          </NDropdown>
        </template>

        <template v-else>
          <router-link
            to="/login"
            class="px-[14px] py-2 text-[13px] font-medium rounded-[10px] no-underline text-secondary transition-all duration-base ease-out hover:(text-primary bg-hover)"
          >
            登录
          </router-link>
          <router-link to="/register" class="btn-cta group/cta">
            <span class="relative z-10">免费注册</span>
            <svg class="relative z-10 transition-transform group-hover/cta:translate-x-0.5" width="14" height="14" viewBox="0 0 14 14" fill="none">
              <path d="M3 7 H11 M7 3 L11 7 L7 11" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
            <span class="cta-glow" />
          </router-link>
        </template>
      </div>
    </div>
  </header>
</template>

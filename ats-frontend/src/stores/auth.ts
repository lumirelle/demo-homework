import { defineStore } from 'pinia'
import { ref, computed } from 'vue'
import { authApi } from '@/api/auth';
import type { MeVO } from '@/api/auth';

export type UserRole = 'ADMIN' | 'HR' | 'CANDIDATE'

export const useAuthStore = defineStore('auth', () => {
  const accessToken = ref<string | null>(null)
  const user = ref<MeVO | null>(null)

  const isLoggedIn = computed(() => !!accessToken.value)
  const role = computed<UserRole | null>(() => user.value?.role ?? null)
  const isAdmin = computed(() => role.value === 'ADMIN')
  const isHr = computed(() => role.value === 'HR')
  const isCandidate = computed(() => role.value === 'CANDIDATE')

  function setTokens(token: string, u: MeVO) {
    accessToken.value = token
    user.value = u
  }

  function clearTokens() {
    accessToken.value = null
    user.value = null
  }

  async function login(email: string, password: string) {
    const data = await authApi.login({ email, password })
    setTokens(data.accessToken, data.user)
    return data
  }

  async function logout() {
    try {
      await authApi.logout()
    }
    finally {
      clearTokens()
    }
  }

  /** silent refresh: 用 cookie 换新 access token，失败则清状态 */
  async function silentRefresh(): Promise<boolean> {
    try {
      const data = await authApi.refresh()
      setTokens(data.accessToken, data.user)
      return true
    }
    catch {
      clearTokens()
      return false
    }
  }

  /** 初始化时尝试恢复登录态（页面刷新后调用） */
  async function initialize() {
    if (isLoggedIn.value) return
    await silentRefresh()
  }

  return {
    accessToken,
    user,
    isLoggedIn,
    role,
    isAdmin,
    isHr,
    isCandidate,
    login,
    logout,
    silentRefresh,
    initialize,
    setTokens,
    clearTokens,
  }
})

import type { RouteRecordRaw } from 'vue-router'
import { createRouter, createWebHistory } from 'vue-router'

declare module 'vue-router' {
  interface RouteMeta {
    title?: string
    transition?: string
    requiresAuth?: boolean
    roles?: Array<'ADMIN' | 'HR' | 'CANDIDATE'>
    hideNavbar?: boolean
  }
}

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    redirect: '/home',
  },
  {
    path: '/home',
    name: 'Home',
    component: () => import('@/views/home.vue'),
    meta: { title: '首页', requiresAuth: false, transition: 'fade-slide' },
  },
  {
    path: '/health',
    name: 'Health',
    component: () => import('@/views/health.vue'),
    meta: { title: 'Health · M0', requiresAuth: false, transition: 'slide-up' },
  },
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/login.vue'),
    meta: { title: '登录', requiresAuth: false, hideNavbar: true, transition: 'slide-right' },
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('@/views/register.vue'),
    meta: { title: '注册', requiresAuth: false, hideNavbar: true, transition: 'slide-right' },
  },
  {
    path: '/403',
    name: 'Forbidden',
    component: () => import('@/views/forbidden.vue'),
    meta: { title: '无权访问', requiresAuth: false, transition: 'fade-scale' },
  },
  // ── M2 · 岗位市场（候选人 / 公开浏览）──
  {
    path: '/jobs',
    name: 'Jobs',
    component: () => import('@/views/jobs.vue'),
    meta: {
      title: '岗位市场',
      requiresAuth: false,
      transition: 'fade-slide',
    },
  },
  // ── M2 · 岗位管理（HR / Admin）──
  {
    path: '/hr/jobs',
    name: 'HrJobs',
    component: () => import('@/views/hr/jobs.vue'),
    meta: {
      title: 'HR · 岗位管理',
      requiresAuth: true,
      roles: ['HR', 'ADMIN'],
      transition: 'fade-slide',
    },
  },
  // ── M3 · 候选人「我的投递」──
  {
    path: '/me/applications',
    name: 'MyApplications',
    component: () => import('@/views/me/applications.vue'),
    meta: {
      title: '我的投递',
      requiresAuth: true,
      roles: ['CANDIDATE'],
      transition: 'fade-slide',
    },
  },
  // ── M3 · 招聘看板（HR / Admin · 状态机拖拽）──
  {
    path: '/hr/board',
    name: 'HrBoard',
    component: () => import('@/views/hr/board.vue'),
    meta: {
      title: 'HR · 招聘看板',
      requiresAuth: true,
      roles: ['HR', 'ADMIN'],
      transition: 'fade-slide',
    },
  },
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/not-found.vue'),
    meta: { transition: 'fade-scale' },
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
  scrollBehavior() {
    return { top: 0 }
  },
})

router.beforeEach(async (to, _from, next) => {
  if (typeof to.meta.title === 'string') {
    document.title = `${to.meta.title} · ATS`
  }

  // 延迟引入 store 避免循环依赖
  const { useAuthStore } = await import('@/stores/auth')
  const auth = useAuthStore()

  // 首次访问需要鉴权的页面 → 先 silent refresh 恢复登录态
  if (to.meta.requiresAuth !== false) {
    if (!auth.isLoggedIn) {
      await auth.initialize()
    }
  }

  const requiresAuth = to.meta.requiresAuth !== false // 默认需要登录
  const roles = to.meta.roles

  if (requiresAuth && !auth.isLoggedIn) {
    return next({ name: 'Login', query: { redirect: to.fullPath } })
  }

  if (roles && auth.role && !roles.includes(auth.role)) {
    return next({ name: 'Forbidden' })
  }

  // 已登录用户访问 login/register → 跳到首页
  if ((to.name === 'Login' || to.name === 'Register') && auth.isLoggedIn) {
    return next({ name: 'Home' })
  }

  next()
})

export default router

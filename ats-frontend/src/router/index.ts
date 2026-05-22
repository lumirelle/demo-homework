import type { RouteRecordRaw } from 'vue-router'
import { createRouter, createWebHistory } from 'vue-router'

const routes: RouteRecordRaw[] = [
  {
    path: '/',
    redirect: '/home',
  },
  {
    path: '/home',
    name: 'Home',
    component: () => import('@/views/HomeView.vue'),
    meta: { title: '首页', requiresAuth: false },
  },
  {
    path: '/health',
    name: 'Health',
    component: () => import('@/views/HealthView.vue'),
    meta: { title: 'Health · M0 联调', requiresAuth: false },
  },
  // M1 起补充：/login /register /jobs /hr/* 等
  {
    path: '/:pathMatch(.*)*',
    name: 'NotFound',
    component: () => import('@/views/NotFoundView.vue'),
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

router.beforeEach((to, _from, next) => {
  if (typeof to.meta.title === 'string') {
    document.title = `${to.meta.title} · ATS`
  }
  // M1 起在此挂鉴权 + 角色守卫
  next()
})

export default router

<script setup lang="ts">
import { dateZhCN, NConfigProvider, NDialogProvider, NLoadingBarProvider, NMessageProvider, NNotificationProvider, useLoadingBar, zhCN } from 'naive-ui'
import { defineComponent, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import AppNavbar from './components/AppNavbar.vue'
import { themeOverrides } from './theme'
import { loadingBarRef } from './utils/loading-bar'

const route = useRoute()

/**
 * NLoadingBar 必须在 NLoadingBarProvider 子树内通过 useLoadingBar() 取实例。
 * 内嵌一个微组件 InnerProviders 把实例桥接到 router/index.ts 用的全局 ref。
 */
const InnerProviders = defineComponent({
  setup(_, { slots }) {
    const loadingBar = useLoadingBar()
    onMounted(() => {
      loadingBarRef.value = loadingBar
    })
    return () => slots.default?.()
  },
})
</script>

<template>
  <NConfigProvider :theme-overrides="themeOverrides" :locale="zhCN" :date-locale="dateZhCN">
    <NLoadingBarProvider>
      <NDialogProvider>
        <NNotificationProvider>
          <NMessageProvider>
            <InnerProviders>
              <AppNavbar v-if="!route.meta.hideNavbar" />
              <RouterView v-slot="{ Component, route: r }">
                <Transition :name="(r.meta.transition as string) || 'fade-slide'" mode="out-in" appear>
                  <component :is="Component" :key="r.fullPath" />
                </Transition>
              </RouterView>
            </InnerProviders>
          </NMessageProvider>
        </NNotificationProvider>
      </NDialogProvider>
    </NLoadingBarProvider>
  </NConfigProvider>
</template>

<style>
/* App 级样式（极少）；其余请用 token */
</style>

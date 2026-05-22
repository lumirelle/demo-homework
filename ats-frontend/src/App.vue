<script setup lang="ts">
import { dateZhCN, NConfigProvider, NDialogProvider, NLoadingBarProvider, NMessageProvider, NNotificationProvider, zhCN } from 'naive-ui'
import { useRoute } from 'vue-router'
import { themeOverrides } from './theme'
import AppNavbar from './components/AppNavbar.vue'

const route = useRoute()
</script>

<template>
  <NConfigProvider :theme-overrides="themeOverrides" :locale="zhCN" :date-locale="dateZhCN">
    <NLoadingBarProvider>
      <NDialogProvider>
        <NNotificationProvider>
          <NMessageProvider>
            <AppNavbar v-if="!route.meta.hideNavbar" />
            <RouterView v-slot="{ Component, route: r }">
              <Transition :name="(r.meta.transition as string) || 'fade-slide'" mode="out-in" appear>
                <component :is="Component" :key="r.fullPath" />
              </Transition>
            </RouterView>
          </NMessageProvider>
        </NNotificationProvider>
      </NDialogProvider>
    </NLoadingBarProvider>
  </NConfigProvider>
</template>

<style>
/* App 级样式（极少）；其余请用 token */
</style>

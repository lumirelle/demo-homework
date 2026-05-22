<script setup lang="ts">
import { dateZhCN, NConfigProvider, NDialogProvider, NLoadingBarProvider, NMessageProvider, NNotificationProvider, zhCN } from 'naive-ui'
import { themeOverrides } from './theme'
</script>

<template>
  <NConfigProvider :theme-overrides="themeOverrides" :locale="zhCN" :date-locale="dateZhCN">
    <NLoadingBarProvider>
      <NDialogProvider>
        <NNotificationProvider>
          <NMessageProvider>
            <RouterView v-slot="{ Component, route }">
              <Transition :name="(route.meta.transition as string) || 'fade-slide'" mode="out-in" appear>
                <component :is="Component" :key="route.fullPath" />
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

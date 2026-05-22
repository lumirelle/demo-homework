<script setup lang="ts">
import type { HealthVO } from '@/api/health'
import { NButton, NCard, NDescriptions, NDescriptionsItem, NSpace, NSpin, NTag, useMessage } from 'naive-ui'
import { onMounted, ref } from 'vue'
import { getHealth } from '@/api/health'
import { BizError } from '@/api/request'

const loading = ref(false)
const data = ref<HealthVO | null>(null)
const err = ref<string | null>(null)
const message = useMessage()

async function fetch() {
  loading.value = true
  err.value = null
  try {
    data.value = await getHealth()
    message.success('健康检查通过')
  }
  catch (e) {
    err.value = e instanceof BizError ? `${e.code}: ${e.message}` : (e as Error).message
    message.error(err.value || '未知错误')
  }
  finally {
    loading.value = false
  }
}

onMounted(fetch)
</script>

<template>
  <main
    max-w="[760px]"
    mx-auto
    p="x-6"
    class="pb-12 pt-[calc(60px+2rem)]"
  >
    <header
      flex="~ items-end justify-between wrap"
      gap-4
      mb-6
    >
      <div>
        <p class="kicker" m="0 b-1">
          M0 · 联调验收
        </p>
        <h1 m-0 text-3xl font-bold tracking-tight>
          Health Check
        </h1>
        <p m="t-2 b-0" text="sm secondary">
          前端 → Vite proxy → Spring Boot → PostgreSQL / Redis
        </p>
      </div>
      <NButton type="primary" :loading="loading" @click="fetch">
        重新检查
      </NButton>
    </header>

    <NSpin :show="loading">
      <NCard size="medium" :bordered="true" embedded>
        <template v-if="data">
          <NDescriptions label-placement="left" :column="2" bordered size="small">
            <NDescriptionsItem label="服务">
              {{ data.app }}
            </NDescriptionsItem>
            <NDescriptionsItem label="时间">
              <span class="num">{{ data.time }}</span>
            </NDescriptionsItem>
            <NDescriptionsItem label="PostgreSQL">
              <NTag size="small" :type="data.db === 'UP' ? 'success' : 'error'" round>
                {{ data.db }}
              </NTag>
            </NDescriptionsItem>
            <NDescriptionsItem label="Redis">
              <NTag size="small" :type="data.redis === 'UP' ? 'success' : 'error'" round>
                {{ data.redis }}
              </NTag>
            </NDescriptionsItem>
          </NDescriptions>
        </template>
        <template v-else-if="err">
          <NSpace vertical size="small" align="center" py="8">
            <strong text-danger-500>{{ err }}</strong>
            <span text="sm tertiary">
              确认后端已启动：<code>bun run be:dev</code>
            </span>
          </NSpace>
        </template>
      </NCard>
    </NSpin>

    <p
      mt-6
      text="center sm tertiary"
    >
      M0 验收：上面 db / redis 都显示
      <strong text-success-500>UP</strong>
      即通过 ✓
    </p>
  </main>
</template>

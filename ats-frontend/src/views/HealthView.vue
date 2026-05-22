<script setup lang="ts">
import { onMounted, ref } from 'vue'
import { NCard, NTag, NSpace, NButton, NSpin, NDescriptions, NDescriptionsItem, useMessage } from 'naive-ui'
import { getHealth, type HealthVO } from '@/api/health'
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
  } catch (e) {
    err.value = e instanceof BizError ? `${e.code}: ${e.message}` : (e as Error).message
    message.error(err.value || '未知错误')
  } finally {
    loading.value = false
  }
}

onMounted(fetch)
</script>

<template>
  <main class="page">
    <header class="head">
      <div>
        <p class="kicker">M0 · 联调验收</p>
        <h1>Health Check</h1>
        <p class="sub">前端 → Vite proxy → Spring Boot → PostgreSQL / Redis</p>
      </div>
      <NButton type="primary" :loading="loading" @click="fetch">
        重新检查
      </NButton>
    </header>

    <NSpin :show="loading">
      <NCard size="medium" :bordered="true" embedded>
        <template v-if="data">
          <NDescriptions label-placement="left" :column="2" bordered size="small">
            <NDescriptionsItem label="服务">{{ data.app }}</NDescriptionsItem>
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
          <NSpace vertical size="small" align="center" style="padding: 32px 0">
            <strong style="color: var(--danger-500)">{{ err }}</strong>
            <span style="color: var(--text-tertiary); font-size: 13px">
              确认后端已启动：<code>bun run be:dev</code>
            </span>
          </NSpace>
        </template>
      </NCard>
    </NSpin>

    <p class="footer">
      M0 验收：上面 db / redis 都显示 <strong style="color: var(--success-500)">UP</strong> 即通过 ✓
    </p>
  </main>
</template>

<style scoped>
.page {
  max-width: 760px;
  margin: 0 auto;
  padding: var(--sp-12) var(--sp-6);
}
.head {
  display: flex;
  justify-content: space-between;
  align-items: flex-end;
  margin-bottom: var(--sp-6);
  gap: var(--sp-4);
  flex-wrap: wrap;
}
.kicker {
  font-family: var(--font-mono);
  font-size: var(--fs-xs);
  color: var(--brand-600);
  margin: 0 0 var(--sp-1);
  text-transform: uppercase;
  letter-spacing: 0.5px;
  font-weight: var(--fw-semibold);
}
h1 {
  margin: 0;
  font-size: var(--fs-3xl);
  font-weight: var(--fw-bold);
  letter-spacing: -0.02em;
}
.sub {
  margin: var(--sp-2) 0 0;
  color: var(--text-secondary);
  font-size: var(--fs-sm);
}
.footer {
  margin-top: var(--sp-6);
  text-align: center;
  font-size: var(--fs-sm);
  color: var(--text-tertiary);
}
</style>

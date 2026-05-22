<script setup lang="ts">
import { useRouter } from 'vue-router'

const router = useRouter()
</script>

<template>
  <main class="hero">
    <div class="hero-inner">
      <span class="badge">v0.1 · M0 Skeleton</span>
      <h1>
        Applicant
        <span class="hero-accent">Tracking</span>
        System
      </h1>
      <p class="lede">
        从投递到入职，一条流水线追到底。<br />
        Spring Boot 3 · Vue 3 · PostgreSQL · Redis · Naive UI.
      </p>

      <div class="actions">
        <button class="btn primary" @click="router.push('/health')">
          查看 Health 联调
          <span class="arrow">→</span>
        </button>
        <a class="btn ghost" href="/api/v1/health" target="_blank" rel="noreferrer">
          直接调后端
        </a>
      </div>

      <div class="grid">
        <div class="cell" v-for="m in milestones" :key="m.id">
          <div class="cell-head">
            <span class="cell-id">{{ m.id }}</span>
            <span class="cell-name">{{ m.name }}</span>
          </div>
          <p class="cell-desc">{{ m.desc }}</p>
          <span class="cell-status" :data-status="m.status">{{ m.status }}</span>
        </div>
      </div>
    </div>
  </main>
</template>

<script lang="ts">
const milestones = [
  { id: 'M0', name: '项目基建', desc: 'Skeleton + dev compose + /health', status: 'doing' },
  { id: 'M1', name: '认证模块', desc: 'JWT RS256 + register/login/refresh', status: 'todo' },
  { id: 'M2', name: '岗位 CRUD', desc: '状态机 + 全文搜索', status: 'todo' },
  { id: 'M3', name: '状态机看板', desc: '投递 + 拖拽 + 审计', status: 'todo' },
  { id: 'M4', name: '辅助模块', desc: '简历 + 面试 + Dashboard', status: 'todo' },
  { id: 'M5', name: '打磨交付', desc: 'UI 打磨 + 生产 compose', status: 'todo' },
]
export default { milestones }
</script>

<style scoped>
.hero {
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: var(--sp-12) var(--sp-6);
  background:
    radial-gradient(1200px 600px at 80% -10%, rgba(91, 107, 255, 0.10), transparent 60%),
    radial-gradient(800px 500px at -10% 110%, rgba(91, 107, 255, 0.06), transparent 60%),
    var(--bg-app);
}
.hero-inner {
  max-width: 920px;
  width: 100%;
}
.badge {
  display: inline-block;
  padding: 4px 10px;
  font-size: var(--fs-xs);
  font-weight: var(--fw-medium);
  color: var(--brand-700);
  background: var(--brand-50);
  border: 1px solid var(--brand-100);
  border-radius: var(--radius-full);
  letter-spacing: 0.3px;
}
h1 {
  margin: var(--sp-4) 0 var(--sp-3);
  font-size: clamp(36px, 6vw, 64px);
  line-height: 1.05;
  font-weight: var(--fw-bold);
  letter-spacing: -0.04em;
  color: var(--text-primary);
}
.hero-accent {
  background: linear-gradient(135deg, var(--brand-500), var(--brand-700));
  -webkit-background-clip: text;
  background-clip: text;
  color: transparent;
}
.lede {
  font-size: var(--fs-lg);
  color: var(--text-secondary);
  margin: 0 0 var(--sp-8);
  max-width: 560px;
  line-height: 1.6;
}
.actions {
  display: flex;
  gap: var(--sp-3);
  margin-bottom: var(--sp-12);
}
.btn {
  display: inline-flex;
  align-items: center;
  gap: var(--sp-2);
  padding: 10px 18px;
  font-family: var(--font-sans);
  font-size: var(--fs-md);
  font-weight: var(--fw-medium);
  border-radius: var(--radius-md);
  border: 1px solid transparent;
  cursor: pointer;
  transition: all var(--dur-base) var(--ease-out);
}
.btn.primary {
  background: var(--gray-900);
  color: var(--text-inverse);
}
.btn.primary:hover {
  background: var(--gray-800);
  transform: translateY(-1px);
}
.btn.ghost {
  background: transparent;
  color: var(--text-primary);
  border-color: var(--border-default);
}
.btn.ghost:hover {
  background: var(--bg-hover);
  border-color: var(--gray-400);
}
.arrow {
  transition: transform var(--dur-base) var(--ease-out);
}
.btn:hover .arrow {
  transform: translateX(3px);
}

.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: var(--sp-3);
}
.cell {
  background: var(--bg-elevated);
  border: 1px solid var(--border-subtle);
  border-radius: var(--radius-lg);
  padding: var(--sp-4);
  transition: all var(--dur-base) var(--ease-out);
}
.cell:hover {
  border-color: var(--gray-300);
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}
.cell-head {
  display: flex;
  align-items: center;
  gap: var(--sp-2);
  margin-bottom: var(--sp-2);
}
.cell-id {
  font-family: var(--font-mono);
  font-size: var(--fs-xs);
  font-weight: var(--fw-semibold);
  color: var(--brand-700);
  background: var(--brand-50);
  padding: 2px 6px;
  border-radius: var(--radius-sm);
}
.cell-name {
  font-size: var(--fs-md);
  font-weight: var(--fw-semibold);
}
.cell-desc {
  margin: 0;
  font-size: var(--fs-sm);
  color: var(--text-secondary);
  line-height: 1.5;
  min-height: 40px;
}
.cell-status {
  display: inline-block;
  margin-top: var(--sp-2);
  padding: 2px 8px;
  font-size: var(--fs-xs);
  font-weight: var(--fw-medium);
  border-radius: var(--radius-full);
  text-transform: uppercase;
  letter-spacing: 0.4px;
}
.cell-status[data-status='doing'] {
  background: var(--warning-50);
  color: var(--warning-700);
}
.cell-status[data-status='todo'] {
  background: var(--gray-100);
  color: var(--text-tertiary);
}
.cell-status[data-status='done'] {
  background: var(--success-50);
  color: var(--success-700);
}
</style>

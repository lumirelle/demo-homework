<script setup lang="ts">
import type { HealthVO } from '@/api/health'
import { computed, onMounted, onUnmounted, ref } from 'vue'
import { useRouter } from 'vue-router'
import { getHealth } from '@/api/health'
import { BizError } from '@/api/request'

const router = useRouter()

// 六个里程碑：颜色按"萌芽→茁壮→沉淀→流动→收获→入职"叙事递进
const milestones = [
  { id: 'M0', name: '基建', desc: 'Skeleton + dev compose + /health', status: 'done', accent: 'mint' },
  { id: 'M1', name: '认证', desc: 'JWT RS256 · 5 端点 · 43 单测全绿', status: 'done', accent: 'emerald' },
  { id: 'M2', name: '岗位', desc: 'CRUD + 状态机 + 全文搜索', status: 'doing', accent: 'teal' },
  { id: 'M3', name: '看板', desc: '投递 + 拖拽流转 + 审计日志', status: 'todo', accent: 'cyan' },
  { id: 'M4', name: '辅助', desc: '简历 · 面试 · Dashboard', status: 'todo', accent: 'amber' },
  { id: 'M5', name: '交付', desc: 'UI 打磨 + 生产 compose', status: 'todo', accent: 'lime' },
] as const

const stats = [
  { value: '7', unit: '张表', label: 'PostgreSQL schema' },
  { value: '85', unit: 'h', label: '预估工时' },
  { value: '6', unit: 'M', label: '里程碑' },
  { value: '10', unit: 'd', label: '冲刺天数' },
]

const health = ref<HealthVO | null>(null)
const healthErr = ref(false)
const healthState = computed(() =>
  healthErr.value ? 'down' : (health.value ? 'up' : 'pending'),
)
const healthLabel = computed(() =>
  healthErr.value ? 'API DOWN' : (health.value ? 'All systems normal' : 'Pinging…'),
)

const chipClass = computed(() => ({
  up: 'text-success-700 border-success-500/30',
  down: 'text-danger-700 border-danger-500/30',
  pending: '',
}[healthState.value]))
const dotClass = computed(() => ({
  up: 'bg-success-500 animate-pulse-ring',
  down: 'bg-danger-500',
  pending: 'bg-gray-400',
}[healthState.value]))

function statusTagClass(status: 'done' | 'doing' | 'todo') {
  return {
    done: 'bg-success-50 text-success-700',
    doing: 'bg-warning-50 text-warning-700',
    todo: 'bg-gray-100 text-tertiary',
  }[status]
}

async function ping() {
  try {
    health.value = await getHealth()
    healthErr.value = false
  }
  catch (e) {
    healthErr.value = true
    if (!(e instanceof BizError))
      console.warn(e)
  }
}

const heroRef = ref<HTMLElement | null>(null)
function onMouseMove(e: MouseEvent) {
  const el = heroRef.value
  if (!el)
    return
  const r = el.getBoundingClientRect()
  el.style.setProperty('--mx', `${((e.clientX - r.left) / r.width) * 100}%`)
  el.style.setProperty('--my', `${((e.clientY - r.top) / r.height) * 100}%`)
}

let io: IntersectionObserver | null = null
function setupReveal() {
  io = new IntersectionObserver(
    (entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          e.target.classList.add('is-visible')
          io?.unobserve(e.target)
        }
      })
    },
    { rootMargin: '-10% 0px' },
  )
  document.querySelectorAll('.reveal').forEach(el => io!.observe(el))
}

onMounted(() => {
  ping()
  setupReveal()
})
onUnmounted(() => io?.disconnect())
</script>

<template>
  <main min-h-screen bg-app class="pt-[60px]">
    <!-- ════════════ HERO ════════════ -->
    <section
      ref="heroRef"
      class="bg-hero with-noise"
      relative
      min-h-screen
      p-6
      overflow-hidden
      @mousemove="onMouseMove"
    >
      <div class="aurora-layer" aria-hidden="true" />
      <div class="cursor-glow" aria-hidden="true" />

      <!-- topbar -->
      <header
        relative
        z-1
        flex="~ items-center justify-center wrap"
        gap-4
        p="y-3 x-4"
      >
        <nav flex gap-5 text-sm font-medium max-sm:hidden>
          <a
            v-for="(item, idx) in [
              { label: '里程碑', href: '#milestones' },
              { label: 'Health', href: '/health' },
              { label: 'GitHub ↗', href: 'https://github.com', target: '_blank' },
            ]"
            :key="idx"
            :href="item.href"
            :target="item.target"
            :rel="item.target ? 'noreferrer' : undefined"
            class="after:transition-[right] after:duration-base after:ease-out"
            relative
            text-secondary
            transition-colors duration-base ease-out
            after="absolute left-0 right-full bottom-[-4px] h-2px content-empty bg-grad-spring"
            hover="text-primary after:right-0"
          >
            {{ item.label }}
          </a>
        </nav>

        <!-- status-chip（状态化 class 用 computed 动态绑定，零 scoped CSS） -->
        <div
          absolute
          top="1/2"
          translate-y="-1/2"
          right-4
          inline-flex items-center
          gap-2
          p="y-[6px] x-3"
          rounded-full
          bg-elevated
          border="~ subtle"
          shadow-sm
          text="xs secondary"
          font-medium
          transition-colors duration-base
          :class="chipClass"
        >
          <span w-2 h-2 rounded-full :class="dotClass" />
          <span>{{ healthLabel }}</span>
        </div>
      </header>

      <!-- hero body -->
      <div
        relative
        z-1
        max-w="[1200px]"
        mx-auto
        p="t-[8vh] b-[4vh] x-3"
        text-center
      >
        <p
          inline-block
          p="y-[6px] x-[14px]"
          mb-6
          rounded-full
          bg-elevated
          border="~ subtle"
          text="xs secondary"
          font="medium mono"
        >
          v0.2 · Phase 3 · M0 · M1 done ✓
        </p>

        <h1
          m-0
          text="display-lg gray-900"
          font-black
          tracking="[-0.05em]"
          leading="[0.95]"
        >
          <span inline-block>Grow&nbsp;</span>
          <span class="text-gradient" inline-block>talent.</span>
          <span inline-block text-gray-600>Hire every</span>
          <span class="text-gradient-bloom" inline-block pb-8>good seed.</span>
        </h1>

        <p
          m="t-6 x-auto"
          max-w="[560px]"
          text="lg secondary"
          leading="[1.6]"
        >
          一条流水线把候选人从投递追到入职。<br><br>
          Spring Boot 3 · Vue 3.5 · PostgreSQL · Redis · 在 10 天内跑完整个 MVP。
        </p>

        <!-- CTA -->
        <div inline-flex gap-3 mt-8>
          <!-- btn-bold · 张扬按钮（before 渐变层 + group-hover 联动 arrow） -->
          <button
            class="group transition-[transform,box-shadow] hover:-translate-y-[2px]"
            relative
            inline-flex items-center
            gap="[10px]"
            p="y-[14px] x-7"
            text="md white"
            font="sans semibold"
            rounded-full
            border-none
            cursor-pointer
            bg-gray-950
            shadow-md
            duration-base
            ease-out
            before="absolute inset-0 rounded-[inherit] bg-grad-spring opacity-0 transition-opacity duration-base ease-out content-empty"
            hover="shadow-glow-brand before:opacity-100"
            @click="router.push('/health')"
          >
            <span relative z-1>Launch Pipeline</span>
            <span
              relative
              z-1
              inline-block
              transition-transform duration-base ease-out
              group-hover:translate-x-1
            >→</span>
          </button>

          <!-- btn-ghost -->
          <a
            class="transition-[color,background-color,border-color,transform] hover:-translate-y-[2px]"
            inline-flex items-center
            p="y-[14px] x-6"
            text="md primary"
            font-medium
            rounded-full
            bg-transparent
            border="~ default"
            duration-fast
            ease-out
            hover="bg-hover border-gray-400"
            href="#milestones"
          >
            See the plan
          </a>
        </div>

        <!-- stat strip -->
        <ul
          list-none
          p="0 t-6"
          m="t-12 x-auto"
          max-w="[720px]"
          grid="~ cols-4"
          gap-2
          border="t subtle"
          max-sm="grid-cols-2 gap-4"
        >
          <li v-for="s in stats" :key="s.label" text-center>
            <span class="num" block text="[36px] primary" font-bold tracking="[-0.03em]">
              {{ s.value }}<small ml="[2px]" text="[14px] tertiary" font-medium>{{ s.unit }}</small>
            </span>
            <span block mt-1 text="xs tertiary uppercase" tracking="[0.5px]">
              {{ s.label }}
            </span>
          </li>
        </ul>
      </div>
    </section>

    <!-- ════════════ MILESTONES ════════════ -->
    <section id="milestones" max-w="[1200px]" mx-auto p="y-16 x-6">
      <div class="reveal" text-center mb-12>
        <p kicker mb-3>
          The roadmap
        </p>
        <h2
          m-0
          font-bold
          tracking="[-0.03em]"
          leading="[1.05]"
          text="[clamp(32px,5vw,56px)]"
        >
          从 M0 到 M5 ·
          <span class="text-gradient">六块拼图</span>
        </h2>
        <p m="t-4 x-auto" max-w="[540px]" text-secondary>
          每个里程碑都能跑、能演示一个完整场景；Mn 未通过验收禁止进入 Mn+1。
        </p>
      </div>

      <div grid gap-4 grid-cols="[repeat(auto-fill,minmax(260px,1fr))]">
        <!-- ms-card · accent 通过 :style 注入 var(--accent-color)，
             ::before 顶部进度条 + group-hover 联动 arrow 全部原子化 -->
        <article
          v-for="(m, i) in milestones"
          :key="m.id"
          class="reveal group transition-[transform,border-color,box-shadow]
                 hover:-translate-y-[4px]
                 before:transition-transform before:duration-260 before:ease-out"
          relative
          p-6
          rounded-lg
          overflow-hidden
          cursor-pointer
          bg-elevated
          border="~ subtle"
          shadow-sm
          duration-260
          ease-out
          before="absolute top-0 left-0 right-0 h-3px content-empty origin-left scale-x-[0.15]
                  bg-(--accent-color)"
          hover="border-transparent shadow-lg before:scale-x-100"
          :style="{
            'transitionDelay': `${i * 60}ms`,
            '--accent-color': `var(--accent-${m.accent})`,
          }"
        >
          <div flex="~ items-center justify-between" mb-4>
            <span
              font="mono bold"
              text="[24px]"
              tracking="[-0.02em]"
              :style="{ color: 'var(--accent-color)' }"
            >{{ m.id }}</span>
            <span
              text="[10px] uppercase"
              font-semibold
              tracking="[0.6px]"
              p="y-[3px] x-2"
              rounded-full
              :class="statusTagClass(m.status)"
            >{{ m.status }}</span>
          </div>
          <h3 m="0 b-2" font-bold text="[22px]" tracking="[-0.02em]">
            {{ m.name }}
          </h3>
          <p m-0 text="sm secondary" leading="[1.5]">
            {{ m.desc }}
          </p>
          <span
            class="transition-[opacity,transform] -translate-x-[6px]"
            absolute
            bottom-4
            right-4
            text="[20px]"
            inline-block
            op-0
            duration-base
            ease-out
            group-hover="op-100 translate-x-0"
            :style="{ color: 'var(--accent-color)' }"
          >→</span>
        </article>
      </div>
    </section>

    <!-- ════════════ FOOTER ════════════ -->
    <footer class="reveal" p="y-8 x-6" text="center sm tertiary" border="t subtle">
      <p>
        <span class="text-gradient">ATS · 招聘管理系统</span>
        · 2026 · Built with Claude in Cursor
      </p>
    </footer>
  </main>
</template>

<script setup lang="ts">
import type { ApplicationDetailVO, ApplicationListItemVO, ApplicationStage, BoardColumnVO, BoardVO, StageLogVO } from '@/api/applications'
import type { InterviewCreateReq, InterviewVO } from '@/api/interviews'
import type { JobListItemVO } from '@/api/jobs'
import type { SelectOption } from 'naive-ui'
import {
  NButton,
  NDrawer,
  NDrawerContent,
  NInput,
  NPopconfirm,
  NRate,
  NSelect,
  NSpin,
  NTag,
  NTimeline,
  NTimelineItem,
  useMessage,
} from 'naive-ui'
import { computed, onMounted, ref, watch } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import CopyButton from '@/components/CopyButton.vue'
import EmptyState from '@/components/EmptyState.vue'
import { isResumeFile, resumeDownloadUrl } from '@/utils/resume'
import {
  applicationsApi,
  canTransition,
  isTerminal,
  STAGE_LABEL,
  STAGE_TRANSITIONS,
} from '@/api/applications'
import {
  CONCLUSION_LABEL,
  CONCLUSION_TONE,
  interviewsApi,
} from '@/api/interviews'
import { jobsApi } from '@/api/jobs'
import { BizError } from '@/api/request'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const message = useMessage()
const route = useRoute()
const router = useRouter()

/** 从 dashboard 跳来时携带的 stage（用于高亮 / 滚动到对应列） */
const focusStage = computed<ApplicationStage | null>(() => {
  const s = route.query.stage
  if (typeof s !== 'string') return null
  // 简单白名单校验，避免 URL 注入非法 stage
  const valid: ApplicationStage[] = ['APPLIED', 'SCREENING_PASS', 'PHONE_INTERVIEW', 'TECH_INTERVIEW', 'HR_INTERVIEW', 'OFFER', 'HIRED', 'REJECTED']
  return valid.includes(s as ApplicationStage) ? s as ApplicationStage : null
})

function jumpToJobs() {
  router.push({ path: '/hr/jobs' })
}

// ───────────────────────── 范围选择（哪一个岗位的看板） ─────────────────────────

const myJobs = ref<JobListItemVO[]>([])
/** -1 = 所有岗位（汇总）；其余为具体 jobId。NSelect 的 value 必须是 number/string，不能是 null。 */
const selectedJobId = ref<number>(-1)

async function loadMyJobs() {
  try {
    const res = await jobsApi.list({
      mine: !auth.isAdmin, // Admin 看全部，HR 只看自己创建的
      page: 1,
      size: 100,
      sortBy: 'publishedAt',
      sortOrder: 'desc',
    })
    myJobs.value = res.items
  }
  catch (e) {
    if (e instanceof BizError) message.error(e.message)
    else throw e
  }
}

const ALL_JOBS_SENTINEL = -1

const jobOptions = computed<SelectOption[]>(() => [
  { label: '所有岗位（汇总）', value: ALL_JOBS_SENTINEL },
  ...myJobs.value.map(j => ({
    label: `${j.title}${j.location ? ` · ${j.location}` : ''}`,
    value: j.id,
  })),
])

// ───────────────────────── 看板加载 ─────────────────────────

const board = ref<BoardVO | null>(null)
const loading = ref(false)

const effectiveJobId = computed(() =>
  selectedJobId.value === null || selectedJobId.value === ALL_JOBS_SENTINEL
    ? undefined
    : selectedJobId.value,
)

async function fetchBoard() {
  loading.value = true
  try {
    board.value = await applicationsApi.board(effectiveJobId.value)
  }
  catch (e) {
    if (e instanceof BizError) message.error(e.message)
    else throw e
  }
  finally {
    loading.value = false
  }
}

watch(selectedJobId, () => fetchBoard())

// ───────────────────────── 拖拽 ─────────────────────────

interface DragState {
  applicationId: number
  fromStage: ApplicationStage
}

const dragState = ref<DragState | null>(null)
/** 当前 hover 的目标列（用于高亮）。 */
const hoverStage = ref<ApplicationStage | null>(null)

// 拒绝原因弹窗：状态先声明，避免被 onColumnDrop 引用时报 use-before-define
const rejectModalVisible = ref(false)
const rejectNote = ref('')
const pendingReject = ref<{ id: number, fromStage: ApplicationStage } | null>(null)

function onCardDragStart(e: DragEvent, item: ApplicationListItemVO) {
  if (isTerminal(item.stage)) {
    e.preventDefault()
    return
  }
  dragState.value = { applicationId: item.id, fromStage: item.stage }
  if (e.dataTransfer) {
    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData('text/plain', String(item.id))
  }
}

function onCardDragEnd() {
  dragState.value = null
  hoverStage.value = null
}

function onColumnDragOver(e: DragEvent, stage: ApplicationStage) {
  if (!dragState.value) return
  if (!canTransition(dragState.value.fromStage, stage)) return
  e.preventDefault()
  if (e.dataTransfer) e.dataTransfer.dropEffect = 'move'
  hoverStage.value = stage
}

function onColumnDragLeave(stage: ApplicationStage) {
  if (hoverStage.value === stage) hoverStage.value = null
}

async function onColumnDrop(e: DragEvent, target: ApplicationStage) {
  e.preventDefault()
  hoverStage.value = null
  const drag = dragState.value
  dragState.value = null
  if (!drag) return
  if (!canTransition(drag.fromStage, target)) {
    message.warning(`不能从「${STAGE_LABEL[drag.fromStage]}」流转到「${STAGE_LABEL[target]}」`)
    return
  }

  // REJECTED 必须填原因 → 弹小弹窗
  if (target === 'REJECTED') {
    pendingReject.value = { id: drag.applicationId, fromStage: drag.fromStage }
    rejectNote.value = ''
    rejectModalVisible.value = true
    return
  }

  await commitTransition(drag.applicationId, drag.fromStage, target, undefined)
}

async function commitTransition(
  id: number,
  from: ApplicationStage,
  target: ApplicationStage,
  note?: string,
) {
  // 乐观更新：先把卡片从旧列搬到新列
  const board0 = board.value
  if (!board0) return
  const fromCol = board0.columns.find(c => c.stage === from)
  const toCol = board0.columns.find(c => c.stage === target)
  if (!fromCol || !toCol) return

  const idx = fromCol.items.findIndex(i => i.id === id)
  if (idx < 0) return
  const moved = fromCol.items.splice(idx, 1)[0]
  moved.stage = target
  toCol.items.unshift(moved)
  fromCol.count -= 1
  toCol.count += 1

  try {
    await applicationsApi.transition(id, { toStage: target, note })
    message.success(`已流转：${STAGE_LABEL[from]} → ${STAGE_LABEL[target]}`)
  }
  catch (e) {
    // 失败回滚
    toCol.items.shift()
    moved.stage = from
    fromCol.items.splice(idx, 0, moved)
    fromCol.count += 1
    toCol.count -= 1
    if (e instanceof BizError) message.error(e.message)
    else throw e
  }
}

// ───────────────────────── Reject 弹窗 ─────────────────────────

async function submitReject() {
  if (!pendingReject.value) return
  if (!rejectNote.value.trim()) {
    message.warning('请填写拒绝原因')
    return
  }
  const { id, fromStage } = pendingReject.value
  rejectModalVisible.value = false
  await commitTransition(id, fromStage, 'REJECTED', rejectNote.value.trim())
  pendingReject.value = null
}

function cancelReject() {
  rejectModalVisible.value = false
  pendingReject.value = null
}

// ───────────────────────── Detail Drawer ─────────────────────────

const drawerVisible = ref(false)
const detail = ref<ApplicationDetailVO | null>(null)
const detailLoading = ref(false)

// 面试记录状态先声明（openDetail 会用到，setup script 顺序求值，否则 oxlint no-use-before-define）
const interviews = ref<InterviewVO[]>([])
const interviewFormVisible = ref(false)
const editingInterview = ref<InterviewVO | null>(null)
const interviewSubmitting = ref(false)
/** 表单 model — 与 InterviewCreateReq 同字段（rating 用 number 而非 short） */
const interviewForm = ref<InterviewCreateReq>({
  round: '',
  rating: 4,
  conclusion: 'PASS',
  strengths: '',
  weaknesses: '',
  notes: '',
})

const conclusionOptions: SelectOption[] = [
  { label: CONCLUSION_LABEL.PASS, value: 'PASS' },
  { label: CONCLUSION_LABEL.HOLD, value: 'HOLD' },
  { label: CONCLUSION_LABEL.REJECT, value: 'REJECT' },
]

async function openDetail(id: number) {
  drawerVisible.value = true
  detailLoading.value = true
  detail.value = null
  // 重置面试记录区
  interviews.value = []
  interviewFormVisible.value = false
  editingInterview.value = null
  try {
    const [d, ivs] = await Promise.all([
      applicationsApi.detail(id),
      interviewsApi.list(id),
    ])
    detail.value = d
    interviews.value = ivs
  }
  catch (e) {
    drawerVisible.value = false
    if (e instanceof BizError) message.error(e.message)
    else throw e
  }
  finally {
    detailLoading.value = false
  }
}

// ───────────────────────── 面试记录 actions ─────────────────────────

function openInterviewCreate() {
  editingInterview.value = null
  interviewForm.value = {
    round: '',
    rating: 4,
    conclusion: 'PASS',
    strengths: '',
    weaknesses: '',
    notes: '',
  }
  interviewFormVisible.value = true
}

function openInterviewEdit(iv: InterviewVO) {
  editingInterview.value = iv
  interviewForm.value = {
    round: iv.round,
    rating: iv.rating ?? 4,
    conclusion: iv.conclusion,
    strengths: iv.strengths ?? '',
    weaknesses: iv.weaknesses ?? '',
    notes: iv.notes ?? '',
  }
  interviewFormVisible.value = true
}

function cancelInterviewForm() {
  interviewFormVisible.value = false
  editingInterview.value = null
}

async function submitInterview() {
  if (!detail.value) return
  if (!interviewForm.value.round.trim()) {
    message.warning('请填写面试轮次')
    return
  }
  if (!interviewForm.value.rating || interviewForm.value.rating < 1) {
    message.warning('请给出 1-5 星评分')
    return
  }
  interviewSubmitting.value = true
  try {
    if (editingInterview.value) {
      const updated = await interviewsApi.update(editingInterview.value.id, interviewForm.value)
      // 就地替换：保持顺序
      const idx = interviews.value.findIndex(i => i.id === updated.id)
      if (idx >= 0) interviews.value.splice(idx, 1, updated)
      message.success('已更新面试评价')
    }
    else {
      const created = await interviewsApi.create(detail.value.id, interviewForm.value)
      interviews.value.push(created)
      message.success('已添加面试评价')
    }
    interviewFormVisible.value = false
    editingInterview.value = null
  }
  catch (e) {
    if (e instanceof BizError) message.error(e.message)
    else throw e
  }
  finally {
    interviewSubmitting.value = false
  }
}

// 简历 URL 工具迁移到 @/utils/resume，避免与 me/applications.vue 重复实现。

async function transitionFromDrawer(target: ApplicationStage) {
  if (!detail.value) return
  if (target === 'REJECTED') {
    pendingReject.value = { id: detail.value.id, fromStage: detail.value.stage }
    rejectNote.value = ''
    rejectModalVisible.value = true
    drawerVisible.value = false
    return
  }
  await commitTransition(detail.value.id, detail.value.stage, target)
  await openDetail(detail.value.id)
}

// ───────────────────────── helpers ─────────────────────────

const STAGE_ACCENT: Record<ApplicationStage, string> = {
  APPLIED: 'var(--gray-400)',
  SCREENING_PASS: 'var(--info-500)',
  PHONE_INTERVIEW: 'var(--accent-cyan)',
  TECH_INTERVIEW: 'var(--accent-teal)',
  HR_INTERVIEW: 'var(--accent-emerald)',
  OFFER: 'var(--warning-500)',
  HIRED: 'var(--success-500)',
  REJECTED: 'var(--danger-500)',
}

const STAGE_TONE: Record<ApplicationStage, 'success' | 'warning' | 'error' | 'info' | 'default'> = {
  APPLIED: 'default',
  SCREENING_PASS: 'info',
  PHONE_INTERVIEW: 'info',
  TECH_INTERVIEW: 'info',
  HR_INTERVIEW: 'info',
  OFFER: 'warning',
  HIRED: 'success',
  REJECTED: 'error',
}

function formatTime(iso: string | null) {
  if (!iso) return ''
  const d = new Date(iso)
  const diffH = (Date.now() - d.getTime()) / 36e5
  if (diffH < 1) return `${Math.max(1, Math.floor(diffH * 60))} 分钟前`
  if (diffH < 24) return `${Math.floor(diffH)} 小时前`
  if (diffH < 24 * 30) return `${Math.floor(diffH / 24)} 天前`
  return d.toISOString().slice(0, 10)
}

function stageLogTitle(log: StageLogVO) {
  if (!log.fromStage) return '候选人投递'
  return `${STAGE_LABEL[log.fromStage]} → ${STAGE_LABEL[log.toStage]}`
}

/** 是否在拖拽中：用来给除合法目标外的列降低亮度。 */
const isDragging = computed(() => dragState.value !== null)

/** 当前正在拖的卡片，其合法目标列集合（用于高亮）。 */
const allowedTargets = computed<Set<ApplicationStage>>(() => {
  if (!dragState.value) return new Set()
  return new Set(STAGE_TRANSITIONS[dragState.value.fromStage])
})

function isAllowedTarget(stage: ApplicationStage) {
  return allowedTargets.value.has(stage)
}

/**
 * 浮动拒绝区是否可放：当前在拖且 fromStage 允许转 REJECTED。
 * 终态卡片本来就 :draggable="false"，所以只要 isDragging 几乎永远为 true；
 * 多一层 canTransition 保险，未来状态机调整不破。
 */
const canRejectFromDrag = computed(() =>
  dragState.value !== null && canTransition(dragState.value.fromStage, 'REJECTED'),
)

function colClass(col: BoardColumnVO) {
  const dragging = isDragging.value
  const allowed = isAllowedTarget(col.stage)
  const hovered = hoverStage.value === col.stage
  return [
    'board-col',
    dragging && allowed && 'is-allowed',
    dragging && !allowed && 'is-dim',
    hovered && 'is-hover',
  ].filter(Boolean).join(' ')
}

// ───────────────────────── lifecycle ─────────────────────────

onMounted(async () => {
  await loadMyJobs()
  // 支持 /hr/board?jobId=xxx 跨页跳转：从 HR 岗位管理"看板"按钮带过来后自动选中
  const jobIdParam = route.query.jobId
  if (typeof jobIdParam === 'string' && /^\d+$/.test(jobIdParam)) {
    const jid = Number(jobIdParam)
    if (myJobs.value.some(j => j.id === jid)) {
      selectedJobId.value = jid
      // selectedJobId 的 watcher 会触发 fetchBoard
      return
    }
  }
  await fetchBoard()
})
</script>

<template>
  <main min-h-screen bg-app class="pt-[60px]">
    <!-- 顶部 -->
    <header max-w="[1500px]" mx-auto p="t-8 b-4 x-6">
      <div flex="~ items-end justify-between wrap" gap-4>
        <div>
          <p kicker mb-2>
            Hiring Pipeline · 招聘看板
          </p>
          <h1 m-0 text-3xl text-gray-900 font-black tracking="[-0.03em]" leading="tight">
            投递流转 · <span class="text-gradient">8 态状态机</span>
          </h1>
          <p mt-2 text-sm text-secondary leading="[1.6]">
            拖拽卡片到下一阶段即可推进 ·
            合法路径会高亮 · 拒绝需填写原因 · 终态（已入职 / 已拒绝）不可再变更
          </p>
        </div>

        <div flex="~ items-end" gap-3>
          <div min-w="[260px]">
            <label text-[10px] text-tertiary font-bold uppercase tracking-widest mb-1 block>
              查看范围
            </label>
            <NSelect
              v-model:value="selectedJobId"
              :options="jobOptions"
              filterable
              placeholder="选择岗位"
              :disabled="loading"
            />
          </div>
          <div text-right>
            <p text-[10px] text-tertiary font-bold uppercase tracking-widest m="0 b-1">
              投递总数
            </p>
            <p m-0 text-2xl text-primary text-font-mono font-bold>
              {{ board?.totalApplications ?? 0 }}
            </p>
          </div>
        </div>
      </div>
    </header>

    <!-- 看板 -->
    <section max-w="[1500px]" mx-auto p="b-8 x-6">
      <NSpin :show="loading">
        <EmptyState
          v-if="!loading && (!board || board.totalApplications === 0)"
          icon="inbox"
          title="当前范围下还没有投递记录"
          :description="selectedJobId === ALL_JOBS_SENTINEL ? '发布岗位后，候选人投递的简历会出现在这里。' : '尝试切换到「所有岗位（汇总）」查看，或先去岗位管理发布更多岗位。'"
        >
          <template #action>
            <NButton type="primary" @click="jumpToJobs">
              去岗位管理
            </NButton>
          </template>
        </EmptyState>

        <div v-else class="board-scroll">
          <div class="board-grid">
            <div
              v-for="col in board?.columns ?? []"
              :key="col.stage"
              :class="[colClass(col), focusStage === col.stage ? 'is-focus-target' : '']"
              :style="{ '--accent': STAGE_ACCENT[col.stage] }"
              @dragover="onColumnDragOver($event, col.stage)"
              @dragleave="onColumnDragLeave(col.stage)"
              @drop="onColumnDrop($event, col.stage)"
            >
              <header class="board-col-header">
                <span class="board-col-dot" />
                <span flex-1 font-bold text-sm>
                  {{ STAGE_LABEL[col.stage] }}
                </span>
                <span class="board-col-count font-mono">
                  {{ col.count }}
                </span>
              </header>

              <div class="board-col-body">
                <div v-if="col.items.length === 0 && !loading" class="board-col-empty">
                  <span text-[11px] text-tertiary>暂无</span>
                </div>

                <article
                  v-for="item in col.items"
                  :key="item.id"
                  :draggable="!isTerminal(item.stage)"
                  class="board-card"
                  :class="{ 'is-dragging': dragState?.applicationId === item.id }"
                  @dragstart="onCardDragStart($event, item)"
                  @dragend="onCardDragEnd"
                  @click="openDetail(item.id)"
                  @keydown.enter="openDetail(item.id)"
                  tabindex="0"
                  role="button"
                >
                  <div flex="~ items-center justify-between" mb-1.5>
                    <span class="font-semibold text-sm text-primary truncate">
                      {{ item.candidateName ?? '匿名' }}
                    </span>
                    <span v-if="item.yearsExp != null" text-[10px] text-tertiary text-font-mono>
                      {{ item.yearsExp }}y
                    </span>
                  </div>
                  <p v-if="!effectiveJobId" m-0 text-xs text-secondary class="truncate">
                    {{ item.jobTitle }}
                  </p>
                  <p m="t-1.5 b-0" text-[10px] text-tertiary text-font-mono>
                    {{ formatTime(item.updatedAt) }}
                  </p>
                </article>
              </div>
            </div>
          </div>
        </div>
      </NSpin>
    </section>

    <!-- ─────── 浮动拒绝投放区（拖拽时浮出，给小屏 / 流程靠前的卡片一条快路径） ─────── -->
    <aside
      v-show="canRejectFromDrag"
      class="reject-dropzone"
      :class="{ 'is-hover': hoverStage === 'REJECTED' }"
      role="region"
      aria-label="拖拽到此一键拒绝"
      @dragover="onColumnDragOver($event, 'REJECTED')"
      @dragleave="onColumnDragLeave('REJECTED')"
      @drop="onColumnDrop($event, 'REJECTED')"
    >
      <div class="reject-dropzone-icon" aria-hidden="true">
        ✕
      </div>
      <div class="reject-dropzone-text">
        <strong>拖到此处</strong>
        <span>一键拒绝（需填写原因）</span>
      </div>
    </aside>

    <!-- ─────── Reject Modal ─────── -->
    <NDrawer
      v-model:show="rejectModalVisible"
      :width="420"
      placement="right"
      @mask-click="cancelReject"
    >
      <NDrawerContent
        title="填写拒绝原因"
        :native-scrollbar="false"
        closable
      >
        <p text-sm text-secondary mb-4 leading="[1.65]">
          一旦拒绝，该投递将进入终态，<strong text-primary>不可再变更</strong>。请简述原因，候选人能在「我的投递」看到，体验会更好。
        </p>
        <NInput
          v-model:value="rejectNote"
          type="textarea"
          :rows="5"
          maxlength="500"
          show-count
          placeholder="例如：技术深度未达岗位预期 / 期望薪资超出预算 / 候选人主动放弃"
        />
        <template #footer>
          <div flex="~ items-center justify-end" gap-2 w-full>
            <NButton @click="cancelReject">
              取消
            </NButton>
            <NButton type="error" :disabled="!rejectNote.trim()" @click="submitReject">
              确认拒绝
            </NButton>
          </div>
        </template>
      </NDrawerContent>
    </NDrawer>

    <!-- ─────── Detail Drawer ─────── -->
    <NDrawer v-model:show="drawerVisible" :width="640" placement="right">
      <NDrawerContent
        :native-scrollbar="false"
        :title="detail?.candidateName ?? '投递详情'"
        closable
      >
        <NSpin :show="detailLoading">
          <template v-if="detail">
            <!-- 顶部信息 -->
            <div mb-6>
              <div flex="~ items-center wrap" gap-2 mb-3>
                <NTag :type="STAGE_TONE[detail.stage]" round :bordered="false">
                  {{ STAGE_LABEL[detail.stage] }}
                </NTag>
                <span text-xs text-tertiary>
                  投递于 {{ formatTime(detail.appliedAt) }}
                </span>
                <span class="op-40 text-xs">·</span>
                <span text-xs text-tertiary>
                  最近更新 {{ formatTime(detail.updatedAt) }}
                </span>
              </div>

              <p m-0 text-lg text-primary font-bold class="truncate">
                {{ detail.jobTitle }}
              </p>

              <div mt-3 grid grid-cols-2 gap-3 p-3 rounded-md bg-muted text-xs text-secondary>
                <div flex="~ items-center" gap-1 min-w-0>
                  <span text-tertiary shrink-0>邮箱 ·</span>
                  <span text-primary font-medium ml-1 class="truncate">{{ detail.candidateEmail ?? '—' }}</span>
                  <CopyButton
                    v-if="detail.candidateEmail"
                    :text="detail.candidateEmail"
                    hint="已复制邮箱"
                    tooltip="复制邮箱"
                    size="tiny"
                  />
                </div>
                <div flex="~ items-center" gap-1 min-w-0>
                  <span text-tertiary shrink-0>联系方式 ·</span>
                  <span text-primary font-medium ml-1 font-mono class="truncate">{{ detail.phone ?? '—' }}</span>
                  <CopyButton
                    v-if="detail.phone"
                    :text="detail.phone"
                    hint="已复制电话"
                    tooltip="复制电话"
                    size="tiny"
                  />
                </div>
                <div>
                  <span text-tertiary>工作年限 ·</span>
                  <span text-primary font-medium ml-1>{{ detail.yearsExp ?? '—' }} 年</span>
                </div>
                <div v-if="detail.resumeUrl" col-span-2 class="truncate">
                  <span text-tertiary>简历 ·</span>
                  <a
                    v-if="isResumeFile(detail.resumeUrl)"
                    :href="resumeDownloadUrl(detail.resumeUrl)"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="ml-1 inline-flex items-center gap-1 text-brand-700 hover:underline font-medium"
                  >
                    <span class="resume-pill">PDF</span> 在新标签页打开
                  </a>
                  <a
                    v-else
                    :href="detail.resumeUrl"
                    target="_blank"
                    rel="noopener noreferrer"
                    class="ml-1 text-brand-700 hover:underline font-medium"
                  >
                    {{ detail.resumeUrl }}
                  </a>
                </div>
              </div>

              <p
                v-if="detail.stage === 'REJECTED' && detail.rejectReason"
                class="mt-3 p-3 rounded-md bg-danger-50 border border-(--danger-500) text-sm text-danger-700"
              >
                <strong>未通过原因：</strong>{{ detail.rejectReason }}
              </p>
            </div>

            <!-- 时间线 -->
            <h3 text-[10px] text-tertiary text-uppercase tracking-widest m="0 b-3" font-bold>
              阶段时间线
            </h3>
            <NTimeline>
              <NTimelineItem
                v-for="log in detail.stageLogs"
                :key="log.id"
                :type="STAGE_TONE[log.toStage]"
                :title="stageLogTitle(log)"
                :time="formatTime(log.operatedAt)"
              >
                <p m-0 text-sm v-if="log.operatedByName">
                  操作人：<span text-primary>{{ log.operatedByName }}</span>
                  <span v-if="log.operatedByRole" text-tertiary text-xs ml-1>· {{ log.operatedByRole }}</span>
                </p>
                <p v-if="log.note" m="t-1 b-0" text-sm text-secondary leading="[1.65]">
                  {{ log.note }}
                </p>
              </NTimelineItem>
            </NTimeline>

            <!-- ─────────── 面试评价（M4） ─────────── -->
            <div mt-8>
              <header flex="~ items-center justify-between" mb-3>
                <h3 m-0 text-[10px] text-tertiary text-uppercase tracking-widest font-bold>
                  面试评价 · {{ interviews.length }}
                </h3>
                <NButton
                  v-if="!interviewFormVisible"
                  size="tiny"
                  type="primary"
                  ghost
                  @click="openInterviewCreate"
                >
                  + 添加评价
                </NButton>
              </header>

              <!-- 表单（添加 / 编辑共用） -->
              <div v-if="interviewFormVisible" class="iv-form">
                <p text-xs text-tertiary m="0 b-3" font-semibold uppercase tracking-wider>
                  {{ editingInterview ? '编辑评价' : '添加新评价' }}
                  <span v-if="editingInterview" text-tertiary>· 24h 内可改</span>
                </p>
                <div flex flex-col gap-3>
                  <div>
                    <label text-[11px] text-tertiary font-medium mb-1 block uppercase tracking-wider>
                      面试轮次
                    </label>
                    <NInput
                      v-model:value="interviewForm.round"
                      placeholder="如：技术一面 / HR 终面"
                      maxlength="100"
                    />
                  </div>
                  <div flex="~ items-center wrap" gap-4>
                    <div>
                      <label text-[11px] text-tertiary font-medium mb-1 block uppercase tracking-wider>
                        评分
                      </label>
                      <NRate v-model:value="interviewForm.rating" :count="5" />
                    </div>
                    <div flex-1 min-w="[180px]">
                      <label text-[11px] text-tertiary font-medium mb-1 block uppercase tracking-wider>
                        结论
                      </label>
                      <NSelect
                        v-model:value="interviewForm.conclusion"
                        :options="conclusionOptions"
                      />
                    </div>
                  </div>
                  <div>
                    <label text-[11px] text-tertiary font-medium mb-1 block uppercase tracking-wider>
                      优势
                    </label>
                    <NInput
                      v-model:value="interviewForm.strengths"
                      type="textarea"
                      :rows="2"
                      maxlength="2000"
                      show-count
                      placeholder="技术 / 软实力 / 业务亮点"
                    />
                  </div>
                  <div>
                    <label text-[11px] text-tertiary font-medium mb-1 block uppercase tracking-wider>
                      不足
                    </label>
                    <NInput
                      v-model:value="interviewForm.weaknesses"
                      type="textarea"
                      :rows="2"
                      maxlength="2000"
                      show-count
                      placeholder="待补 / 风险点"
                    />
                  </div>
                  <div>
                    <label text-[11px] text-tertiary font-medium mb-1 block uppercase tracking-wider>
                      备注（可选）
                    </label>
                    <NInput
                      v-model:value="interviewForm.notes"
                      type="textarea"
                      :rows="2"
                      maxlength="2000"
                    />
                  </div>
                  <div flex="~ items-center justify-end" gap-2>
                    <NButton size="small" @click="cancelInterviewForm">
                      取消
                    </NButton>
                    <NButton
                      size="small"
                      type="primary"
                      :loading="interviewSubmitting"
                      @click="submitInterview"
                    >
                      {{ editingInterview ? '保存修改' : '提交评价' }}
                    </NButton>
                  </div>
                </div>
              </div>

              <!-- 列表 -->
              <div v-if="interviews.length === 0 && !interviewFormVisible" class="iv-empty">
                <span text-xs text-tertiary>暂无面试评价</span>
              </div>
              <div v-else flex flex-col gap-3>
                <article
                  v-for="iv in interviews"
                  :key="iv.id"
                  class="iv-card"
                >
                  <header flex="~ items-center justify-between wrap" gap-2 mb-2>
                    <div flex="~ items-center" gap-2>
                      <span font-bold text-sm text-primary>{{ iv.round }}</span>
                      <NTag
                        :type="CONCLUSION_TONE[iv.conclusion]"
                        round
                        :bordered="false"
                        size="small"
                      >
                        {{ CONCLUSION_LABEL[iv.conclusion] }}
                      </NTag>
                    </div>
                    <div flex="~ items-center" gap-2>
                      <NRate
                        readonly
                        :value="iv.rating ?? 0"
                        :count="5"
                        size="small"
                      />
                      <NButton
                        v-if="iv.editable"
                        size="tiny"
                        quaternary
                        @click="openInterviewEdit(iv)"
                      >
                        编辑
                      </NButton>
                    </div>
                  </header>
                  <p v-if="iv.strengths" m="0 b-1" text-sm text-secondary leading="[1.6]">
                    <strong text-primary>优势 ·</strong> {{ iv.strengths }}
                  </p>
                  <p v-if="iv.weaknesses" m="0 b-1" text-sm text-secondary leading="[1.6]">
                    <strong text-primary>不足 ·</strong> {{ iv.weaknesses }}
                  </p>
                  <p v-if="iv.notes" m="0 b-1" text-sm text-secondary leading="[1.6]">
                    <strong text-primary>备注 ·</strong> {{ iv.notes }}
                  </p>
                  <footer flex="~ items-center justify-between wrap" gap-2 mt-2 text-[11px] text-tertiary>
                    <span>
                      面试官 · <span text-primary font-medium>{{ iv.interviewerName ?? '—' }}</span>
                      <span v-if="iv.interviewerRole" ml-1>· {{ iv.interviewerRole }}</span>
                    </span>
                    <span font-mono>{{ formatTime(iv.createdAt) }}</span>
                  </footer>
                </article>
              </div>
            </div>
          </template>
        </NSpin>

        <!-- 操作栏：动态推进按钮 -->
        <template #footer>
          <div flex="~ items-center justify-between wrap" gap-2 w-full>
            <span v-if="detail && isTerminal(detail.stage)" text-xs text-tertiary>
              已是终态，无法继续推进
            </span>
            <span v-else-if="detail" text-xs text-tertiary>
              下一步：
            </span>

            <div flex="~ items-center wrap" gap-2>
              <template v-if="detail && detail.allowedTransitions">
                <template
                  v-for="next in detail.allowedTransitions"
                  :key="next"
                >
                  <!-- 关键流转（OFFER / HIRED / REJECTED）走二次确认；中间过程直接推进 -->
                  <NPopconfirm
                    v-if="next === 'OFFER' || next === 'HIRED' || next === 'REJECTED'"
                    :positive-text="`确认 ${STAGE_LABEL[next]}`"
                    negative-text="取消"
                    :positive-button-props="{ type: next === 'REJECTED' ? 'error' : 'primary' }"
                    @positive-click="transitionFromDrawer(next)"
                  >
                    <template #trigger>
                      <NButton
                        size="small"
                        :type="next === 'REJECTED' ? 'error' : 'primary'"
                      >
                        → {{ STAGE_LABEL[next] }}
                      </NButton>
                    </template>
                    即将把 <strong>{{ detail.candidateName }}</strong> 流转到
                    <strong>{{ STAGE_LABEL[next] }}</strong>。
                    <span v-if="next === 'HIRED'">入职后该投递进入终态，不可再变更。</span>
                    <span v-else-if="next === 'REJECTED'">下一步会要求填写拒绝原因。</span>
                  </NPopconfirm>
                  <NButton
                    v-else
                    size="small"
                    type="default"
                    @click="transitionFromDrawer(next)"
                  >
                    → {{ STAGE_LABEL[next] }}
                  </NButton>
                </template>
              </template>
            </div>
          </div>
        </template>
      </NDrawerContent>
    </NDrawer>
  </main>
</template>

<style scoped>
/* 横向滚动容器：在小屏自然变成横向 swipe */
.board-scroll {
  overflow-x: auto;
  padding-bottom: 8px;
  scrollbar-width: thin;
}

.board-grid {
  display: grid;
  grid-template-columns: repeat(8, minmax(220px, 1fr));
  gap: 12px;
  min-width: 1120px; /* 8 列 × 140 最小可用宽度 */
}

@media (max-width: 1280px) {
  .board-grid {
    grid-template-columns: repeat(8, 240px);
  }
}

.board-col {
  display: flex;
  flex-direction: column;
  background: var(--bg-elevated);
  border: 1px solid var(--border-subtle);
  border-radius: 12px;
  min-height: 320px;
  max-height: calc(100vh - 240px);
  transition:
    border-color var(--dur-base) var(--ease-out),
    background var(--dur-base) var(--ease-out),
    transform var(--dur-base) var(--ease-out),
    opacity var(--dur-base) var(--ease-out);
}

/* 拖拽中：合法目标列高亮 */
.board-col.is-allowed {
  border-color: var(--accent);
  box-shadow: 0 0 0 1px var(--accent), 0 8px 22px -10px var(--accent);
}

/* 从 dashboard 跳来时携带 ?stage= 高亮对应列：使用 brand 色描边脉冲 */
.board-col.is-focus-target {
  border-color: var(--brand-500);
  box-shadow:
    0 0 0 2px rgba(16, 185, 129, 0.18),
    0 8px 24px -10px var(--brand-500);
  animation: focus-pulse 1.6s var(--ease-out) 2;
}
@keyframes focus-pulse {
  0%, 100% { box-shadow: 0 0 0 2px rgba(16, 185, 129, 0.18), 0 8px 24px -10px var(--brand-500); }
  50% { box-shadow: 0 0 0 6px rgba(16, 185, 129, 0.10), 0 12px 30px -8px var(--brand-500); }
}
@media (prefers-reduced-motion: reduce) {
  .board-col.is-focus-target { animation: none; }
}

/* 拖拽中：非法目标列变暗 */
.board-col.is-dim {
  opacity: 0.42;
}

/* hover 进入合法目标列：上扬 + 实色背景提示 */
.board-col.is-hover {
  background: color-mix(in oklab, var(--accent) 8%, var(--bg-elevated));
  transform: translateY(-1px);
}

.board-col-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 14px;
  border-bottom: 1px solid var(--border-subtle);
}

.board-col-dot {
  width: 8px;
  height: 8px;
  border-radius: 999px;
  background: var(--accent);
  flex-shrink: 0;
}

.board-col-count {
  font-size: 11px;
  font-weight: 700;
  padding: 2px 8px;
  border-radius: 999px;
  background: var(--bg-app);
  color: var(--text-tertiary);
  border: 1px solid var(--border-subtle);
  min-width: 28px;
  text-align: center;
}

.board-col-body {
  flex: 1;
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 10px;
  overflow-y: auto;
  scrollbar-width: thin;
}

.board-col-empty {
  padding: 24px 8px;
  text-align: center;
  color: var(--text-tertiary);
  border: 1px dashed var(--border-subtle);
  border-radius: 8px;
}

.board-card {
  position: relative;
  padding: 10px 12px;
  border-radius: 8px;
  background: var(--bg-app);
  border: 1px solid var(--border-subtle);
  cursor: grab;
  outline: none;
  transition:
    transform var(--dur-base) var(--ease-out),
    box-shadow var(--dur-base) var(--ease-out),
    border-color var(--dur-base) var(--ease-out),
    opacity var(--dur-base) var(--ease-out);
}

.board-card:hover,
.board-card:focus-visible {
  transform: translate3d(0, -1px, 0);
  border-color: var(--accent);
  box-shadow: 0 4px 12px -6px var(--accent);
}

.board-card:active {
  cursor: grabbing;
}

.board-card.is-dragging {
  opacity: 0.45;
  transform: scale(0.98);
}

/* ─────── 浮动拒绝投放区 ─────── */
.reject-dropzone {
  position: fixed;
  right: 24px;
  bottom: 24px;
  z-index: 1500; /* 高于看板内容、低于 NMessage（>= 4000） */
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 14px 18px;
  min-width: 240px;
  border-radius: 14px;
  background: color-mix(in oklab, var(--danger-500) 10%, var(--bg-elevated));
  border: 2px dashed color-mix(in oklab, var(--danger-500) 55%, transparent);
  color: var(--danger-700, var(--danger-500));
  box-shadow: 0 16px 40px -16px color-mix(in oklab, var(--danger-500) 60%, transparent);
  transition:
    background var(--dur-base) var(--ease-out),
    border-color var(--dur-base) var(--ease-out),
    transform var(--dur-base) var(--ease-out),
    box-shadow var(--dur-base) var(--ease-out);
  /* 入场柔和动画，避免突兀 */
  animation: rejectDropzoneIn 220ms var(--ease-out);
}

.reject-dropzone.is-hover {
  background: color-mix(in oklab, var(--danger-500) 22%, var(--bg-elevated));
  border-color: var(--danger-500);
  border-style: solid;
  transform: translateY(-2px) scale(1.03);
  box-shadow: 0 22px 48px -14px color-mix(in oklab, var(--danger-500) 70%, transparent);
}

.reject-dropzone-icon {
  width: 36px;
  height: 36px;
  border-radius: 999px;
  display: grid;
  place-items: center;
  background: var(--danger-500);
  color: #fff;
  font-weight: 700;
  font-size: 16px;
  flex-shrink: 0;
}

.reject-dropzone-text {
  display: flex;
  flex-direction: column;
  line-height: 1.3;
  font-size: 13px;
}

.reject-dropzone-text strong {
  font-weight: 700;
  font-size: 14px;
  color: var(--danger-700, var(--danger-500));
}

.reject-dropzone-text span {
  font-size: 11px;
  opacity: 0.78;
}

@keyframes rejectDropzoneIn {
  from { opacity: 0; transform: translateY(8px) scale(0.96); }
  to   { opacity: 1; transform: translateY(0) scale(1); }
}

/* 小屏：缩短宽度 + 贴底居中，避开列横滚条 */
@media (max-width: 640px) {
  .reject-dropzone {
    right: 12px;
    bottom: 12px;
    left: 12px;
    min-width: 0;
    justify-content: center;
  }
}

/* ─────── 面试评价（M4） ─────── */
.resume-pill {
  display: inline-grid;
  place-items: center;
  padding: 1px 6px;
  border-radius: 4px;
  background: color-mix(in oklab, var(--success-500) 14%, transparent);
  color: var(--success-700, var(--success-500));
  font-size: 10px;
  font-weight: 800;
  letter-spacing: 0.5px;
}

.iv-form {
  padding: 14px 16px;
  border: 1px solid var(--border-strong);
  border-radius: 10px;
  background: color-mix(in oklab, var(--brand-500) 4%, var(--bg-elevated));
  margin-bottom: 12px;
}

.iv-empty {
  padding: 18px;
  text-align: center;
  border: 1px dashed var(--border-subtle);
  border-radius: 8px;
}

.iv-card {
  padding: 12px 14px;
  border: 1px solid var(--border-subtle);
  border-radius: 10px;
  background: var(--bg-elevated);
  transition: border-color var(--dur-base) var(--ease-out);
}
.iv-card:hover {
  border-color: var(--border-strong);
}

@media (prefers-reduced-motion: reduce) {
  .board-col,
  .board-card,
  .reject-dropzone,
  .iv-card {
    transition: none !important;
    animation: none !important;
  }
  .board-col.is-hover,
  .board-card:hover,
  .reject-dropzone.is-hover {
    transform: none;
  }
}
</style>

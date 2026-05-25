<script setup lang="ts">
import type { DataTableColumns, FormInst, FormRules } from 'naive-ui'
import type {
  JobCreateReq,
  JobDetailVO,
  JobLevel,
  JobListItemVO,
  JobStatus,
  JobWorkType,
  TagVO,
} from '@/api/jobs'
import {
  NButton,
  NCheckbox,
  NDataTable,
  NDrawer,
  NDrawerContent,
  NDropdown,
  NForm,
  NFormItem,
  NInput,
  NInputGroup,
  NInputNumber,
  NSelect,
  NSpace,
  NTag,
  useDialog,
  useMessage,
} from 'naive-ui'
import { computed, h, onMounted, reactive, ref, watch } from 'vue'
import {
  jobsApi,
  LEVEL_LABEL,
  STATUS_LABEL,
  tagsApi,
  TAG_CATEGORY_LABEL,
  WORK_TYPE_LABEL,
} from '@/api/jobs'
import { BizError } from '@/api/request'
import { useAuthStore } from '@/stores/auth'

const auth = useAuthStore()
const message = useMessage()
const dialog = useDialog()

// ────────────────────────── filter / pagination 状态 ──────────────────────────

const STATUS_OPTIONS = (Object.keys(STATUS_LABEL) as JobStatus[]).map(v => ({ label: STATUS_LABEL[v], value: v }))
const WORK_TYPE_OPTIONS = (Object.keys(WORK_TYPE_LABEL) as JobWorkType[]).map(v => ({ label: WORK_TYPE_LABEL[v], value: v }))
const LEVEL_OPTIONS = (Object.keys(LEVEL_LABEL) as JobLevel[]).map(v => ({ label: LEVEL_LABEL[v], value: v }))

const filter = reactive({
  keyword: '',
  status: [] as JobStatus[],
  workType: [] as JobWorkType[],
  level: [] as JobLevel[],
  mine: true, // HR 默认看自己的
  includeArchived: false,
})

const page = ref(1)
const pageSize = ref(10)

const loading = ref(false)
const items = ref<JobListItemVO[]>([])
const total = ref(0)

async function fetchList() {
  loading.value = true
  try {
    const res = await jobsApi.list({
      keyword: filter.keyword.trim() || undefined,
      status: filter.status.length ? filter.status : undefined,
      workType: filter.workType.length ? filter.workType : undefined,
      level: filter.level.length ? filter.level : undefined,
      mine: filter.mine || undefined,
      includeArchived: filter.includeArchived || undefined,
      page: page.value,
      size: pageSize.value,
    })
    items.value = res.items
    total.value = res.total
  }
  catch (e) {
    if (e instanceof BizError) message.error(e.message)
    else throw e
  }
  finally {
    loading.value = false
  }
}

function resetAndFetch() {
  page.value = 1
  fetchList()
}

// ────────────────────────── tags 字典（一次加载）──────────────────────────

const tags = ref<TagVO[]>([])
async function loadTags() {
  try {
    tags.value = await tagsApi.listAll()
  }
  catch (e) {
    console.warn('load tags failed', e)
  }
}

/** 标签按 category 分组渲染（drawer 中复用） */
const tagOptionsGrouped = computed(() => {
  const groups = new Map<string, TagVO[]>()
  tags.value.forEach((t) => {
    if (!groups.has(t.category)) groups.set(t.category, [])
    groups.get(t.category)!.push(t)
  })
  return Array.from(groups.entries()).map(([cat, list]) => ({
    type: 'group' as const,
    label: TAG_CATEGORY_LABEL[cat as keyof typeof TAG_CATEGORY_LABEL] ?? cat,
    key: cat,
    children: list.map(t => ({ label: t.name, value: t.id })),
  }))
})

// ────────────────────────── 颜色映射（status / level）──────────────────────────

const STATUS_TAG_TYPE: Record<JobStatus, 'success' | 'warning' | 'error' | 'info' | 'default'> = {
  DRAFT: 'default',
  PUBLISHED: 'success',
  PAUSED: 'warning',
  CLOSED: 'error',
  ARCHIVED: 'info',
}

// ────────────────────────── 状态切换：行内组件 ──────────────────────────
// 必须定义在 columns 之前（columns.render 引用了它，oxlint no-use-before-define）

const StatusTransitionButton = {
  name: 'StatusTransitionButton',
  props: {
    row: { type: Object as () => JobListItemVO, required: true },
  },
  emits: ['transition'],
  setup(props: { row: JobListItemVO }, { emit }: { emit: (e: 'transition', to: JobStatus) => void }) {
    const loadingT = ref(false)
    const allowed = ref<JobStatus[]>([])

    /** 懒加载 detail.allowedTransitions（避免列表请求时额外往返） */
    async function loadAllowed() {
      if (allowed.value.length) return
      try {
        loadingT.value = true
        const d = await jobsApi.detail(props.row.id)
        allowed.value = d.allowedTransitions ?? []
      }
      finally {
        loadingT.value = false
      }
    }

    const options = computed(() => allowed.value.map(to => ({
      label: `→ ${STATUS_LABEL[to]}`,
      key: to,
    })))

    return () => h(NDropdown, {
      trigger: 'click',
      options: options.value,
      onClickoutside: () => null,
      onSelect: (key: JobStatus) => emit('transition', key),
      'placement': 'bottom-end',
    }, {
      default: () => h(NButton, {
        size: 'tiny',
        type: 'primary',
        secondary: true,
        loading: loadingT.value,
        disabled: false,
        onClick: () => loadAllowed(),
      }, { default: () => '状态' }),
    })
  },
}

// ────────────────────────── 表格列定义 ──────────────────────────

const columns: DataTableColumns<JobListItemVO> = [
  {
    title: '岗位',
    key: 'title',
    minWidth: 220,
    fixed: 'left',
    render: row => h('div', { class: 'flex flex-col gap-0.5' }, [
      h('span', { class: 'text-sm font-semibold text-primary' }, row.title),
      h('span', { class: 'text-xs text-tertiary' }, [
        row.departmentName ?? '未设部门',
        row.location ? ` · ${row.location}` : '',
      ]),
    ]),
  },
  {
    title: '状态',
    key: 'status',
    width: 100,
    render: row => h(NTag, { type: STATUS_TAG_TYPE[row.status], size: 'small', round: true, bordered: false }, {
      default: () => STATUS_LABEL[row.status],
    }),
  },
  {
    title: '工作类型',
    key: 'workType',
    width: 100,
    render: row => WORK_TYPE_LABEL[row.workType],
  },
  {
    title: '级别',
    key: 'level',
    width: 90,
    render: row => LEVEL_LABEL[row.level],
  },
  {
    title: '薪资',
    key: 'salaryRange',
    width: 120,
    render: row => h('span', { class: 'text-sm font-mono text-secondary' }, row.salaryRange ?? '面议'),
  },
  {
    title: '招聘',
    key: 'headcount',
    width: 70,
    align: 'center',
    render: row => `${row.headcount} 人`,
  },
  {
    title: '浏览',
    key: 'viewCount',
    width: 70,
    align: 'center',
    sorter: 'default',
    render: row => h('span', { class: 'text-tertiary' }, row.viewCount),
  },
  {
    title: '标签',
    key: 'tags',
    minWidth: 180,
    render: row => h('div', { class: 'flex gap-1 flex-wrap' }, row.tags.slice(0, 3).map(t =>
      h(NTag, { key: t.id, size: 'small', bordered: true, type: 'default' }, { default: () => t.name }),
    ).concat(row.tags.length > 3
      ? [h('span', { class: 'text-xs text-tertiary self-center' }, `+${row.tags.length - 3}`)]
      : [])),
  },
  {
    title: '更新于',
    key: 'updatedAt',
    width: 110,
    render: row => h('span', { class: 'text-xs text-tertiary' }, formatTime(row.updatedAt)),
  },
  {
    title: '操作',
    key: 'actions',
    width: 200,
    fixed: 'right',
    render: row => h(NSpace, { size: 'small' }, {
      default: () => [
        h(NButton, { size: 'tiny', secondary: true, onClick: () => openEdit(row.id) }, { default: () => '编辑' }),
        h(StatusTransitionButton, {
          row,
          onTransition: (to: JobStatus) => transitionJob(row, to),
        }),
        auth.isAdmin
          ? h(NButton, {
            size: 'tiny',
            tertiary: true,
            type: 'error',
            onClick: () => confirmDelete(row),
          }, { default: () => '删除' })
          : null,
      ],
    }),
  },
]

// ────────────────────────── 状态推进 / 删除 ──────────────────────────

async function transitionJob(row: JobListItemVO, to: JobStatus) {
  try {
    await jobsApi.transition(row.id, to)
    message.success(`已将「${row.title}」流转到 ${STATUS_LABEL[to]}`)
    fetchList()
  }
  catch (e) {
    if (e instanceof BizError) message.error(e.message)
    else throw e
  }
}

function confirmDelete(row: JobListItemVO) {
  dialog.warning({
    title: '确认软删除？',
    content: `「${row.title}」将被标记删除，仍保留在数据库中。该操作不可在 UI 上撤销，请确认。`,
    positiveText: '确认删除',
    negativeText: '取消',
    onPositiveClick: async () => {
      try {
        await jobsApi.remove(row.id)
        message.success('已软删除')
        fetchList()
      }
      catch (e) {
        if (e instanceof BizError) message.error(e.message)
      }
    },
  })
}

// ────────────────────────── Drawer · 创建/编辑 ──────────────────────────

const drawerVisible = ref(false)
const drawerMode = ref<'create' | 'edit'>('create')
const editingId = ref<number | null>(null)
const submitting = ref(false)
const formRef = ref<FormInst | null>(null)

const emptyForm = (): JobCreateReq => ({
  title: '',
  description: '',
  location: '',
  workType: 'FULL_TIME',
  level: 'MID',
  salaryMin: null,
  salaryMax: null,
  headcount: 1,
  departmentId: null,
  tagIds: [],
})

const form = reactive<JobCreateReq>(emptyForm())

const rules: FormRules = {
  title: [{ required: true, message: '岗位名称必填', trigger: 'blur' }],
  workType: [{ required: true, message: '请选择工作类型', trigger: 'change' }],
  level: [{ required: true, message: '请选择级别', trigger: 'change' }],
}

function openCreate() {
  drawerMode.value = 'create'
  editingId.value = null
  Object.assign(form, emptyForm())
  drawerVisible.value = true
}

async function openEdit(id: number) {
  drawerMode.value = 'edit'
  editingId.value = id
  drawerVisible.value = true
  try {
    const d: JobDetailVO = await jobsApi.detail(id)
    Object.assign(form, {
      title: d.title,
      description: d.description ?? '',
      location: d.location ?? '',
      workType: d.workType,
      level: d.level,
      salaryMin: d.salaryMin,
      salaryMax: d.salaryMax,
      headcount: d.headcount,
      departmentId: d.departmentId,
      tagIds: d.tags.map(t => t.id),
    })
  }
  catch (e) {
    if (e instanceof BizError) message.error(e.message)
    drawerVisible.value = false
  }
}

async function submitForm() {
  try {
    await formRef.value?.validate()
  }
  catch {
    return
  }

  // 前端先校验薪资区间，给更友好的提示（后端也会兜底）
  if (form.salaryMin != null && form.salaryMax != null && form.salaryMin > form.salaryMax) {
    message.error('薪资下限不能高于上限')
    return
  }

  submitting.value = true
  try {
    if (drawerMode.value === 'create') {
      const created = await jobsApi.create({ ...form })
      message.success(`已创建草稿「${created.title}」`)
    }
    else if (editingId.value != null) {
      await jobsApi.update(editingId.value, { ...form })
      message.success('已保存')
    }
    drawerVisible.value = false
    fetchList()
  }
  catch (e) {
    if (e instanceof BizError) message.error(e.message)
    else throw e
  }
  finally {
    submitting.value = false
  }
}

// ────────────────────────── helpers ──────────────────────────

function formatTime(iso: string | null) {
  if (!iso) return '—'
  const d = new Date(iso)
  const now = new Date()
  const diffH = (now.getTime() - d.getTime()) / 36e5
  if (diffH < 1) return `${Math.max(1, Math.floor(diffH * 60))} 分钟前`
  if (diffH < 24) return `${Math.floor(diffH)} 小时前`
  if (diffH < 24 * 30) return `${Math.floor(diffH / 24)} 天前`
  return d.toISOString().slice(0, 10)
}

// 监听 filter 变化（select / checkbox），keyword 用回车/点搜索按钮触发
watch(
  () => [filter.status, filter.workType, filter.level, filter.mine, filter.includeArchived],
  () => resetAndFetch(),
  { deep: true },
)

onMounted(() => {
  loadTags()
  fetchList()
})
</script>

<template>
  <main min-h-screen bg-app class="pt-[60px]">
    <!-- ──────────────── 顶部标题区 ──────────────── -->
    <section max-w="[1400px]" mx-auto p="t-10 b-6 x-6">
      <div flex="~ items-center justify-between wrap" gap-4>
        <div>
          <p
            inline-block
            p="y-[5px] x-[12px]"
            mb-3
            rounded-full
            bg-elevated
            border="~ subtle"
            text="xs secondary"
            font="medium mono"
          >
            M2 · 岗位管理
          </p>
          <h1 m-0 text="[36px] gray-900" font="display black" tracking="[-0.03em]" leading="[1.05]">
            岗位<span class="text-gradient">管理台</span>
          </h1>
          <p mt-2 text-secondary>
            共 <span text-primary font-semibold>{{ total }}</span> 条记录。{{ auth.isAdmin ? '管理员视角：可见所有岗位 + 软删权限。' : 'HR 视角：默认只看自己创建的岗位，支持全字段过滤。' }}
          </p>
        </div>

        <NButton type="primary" size="large" @click="openCreate">
          <template #icon>
            <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
              <path d="M12 5v14M5 12h14" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
            </svg>
          </template>
          新建岗位
        </NButton>
      </div>
    </section>

    <!-- ──────────────── 过滤条 ──────────────── -->
    <section max-w="[1400px]" mx-auto p="x-6">
      <div
        p-4
        rounded-xl
        bg-elevated
        border="~ subtle"
        shadow-sm
        grid
        gap-3
        grid-cols="[2fr_1fr_1fr_1fr_auto]"
        max-md="grid-cols-1"
      >
        <NInputGroup>
          <NInput
            v-model:value="filter.keyword"
            placeholder="搜索岗位标题 / 描述全文…"
            clearable
            @keydown.enter="resetAndFetch"
          >
            <template #prefix>
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                <circle cx="11" cy="11" r="7" stroke="currentColor" stroke-width="1.8" />
                <path d="M20 20l-3-3" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
              </svg>
            </template>
          </NInput>
          <NButton type="primary" @click="resetAndFetch">
            搜索
          </NButton>
        </NInputGroup>

        <NSelect
          v-model:value="filter.status"
          :options="STATUS_OPTIONS"
          multiple
          clearable
          placeholder="状态"
          max-tag-count="responsive"
        />
        <NSelect
          v-model:value="filter.workType"
          :options="WORK_TYPE_OPTIONS"
          multiple
          clearable
          placeholder="工作类型"
          max-tag-count="responsive"
        />
        <NSelect
          v-model:value="filter.level"
          :options="LEVEL_OPTIONS"
          multiple
          clearable
          placeholder="级别"
          max-tag-count="responsive"
        />

        <NSpace align="center" :wrap="false">
          <NCheckbox v-model:checked="filter.mine">
            仅看我创建
          </NCheckbox>
          <NCheckbox v-model:checked="filter.includeArchived">
            含归档
          </NCheckbox>
        </NSpace>
      </div>
    </section>

    <!-- ──────────────── 数据表格 ──────────────── -->
    <section max-w="[1400px]" mx-auto p="y-4 x-6">
      <div rounded-xl overflow-hidden bg-elevated border="~ subtle" shadow-sm>
        <NDataTable
          :columns="columns"
          :data="items"
          :loading="loading"
          :row-key="(row) => row.id"
          :bordered="false"
          :single-line="false"
          striped
          size="medium"
          :scroll-x="1300"
          :pagination="{
            page,
            pageSize,
            itemCount: total,
            pageSizes: [10, 20, 50],
            showSizePicker: true,
            prefix: ({ itemCount }) => `共 ${itemCount} 条`,
            onUpdatePage: (p) => { page = p; fetchList() },
            onUpdatePageSize: (s) => { pageSize = s; page = 1; fetchList() },
          }"
        />
      </div>
    </section>

    <!-- ──────────────── 创建 / 编辑 Drawer ──────────────── -->
    <NDrawer v-model:show="drawerVisible" :width="640" placement="right">
      <NDrawerContent
        :title="drawerMode === 'create' ? '新建岗位' : '编辑岗位'"
        closable
      >
        <NForm
          ref="formRef"
          :model="form"
          :rules="rules"
          label-placement="top"
          require-mark-placement="right-hanging"
        >
          <NFormItem label="岗位名称" path="title">
            <NInput
              v-model:value="form.title"
              placeholder="例如：高级前端工程师"
              maxlength="200"
              show-count
            />
          </NFormItem>

          <div grid grid-cols-2 gap-4>
            <NFormItem label="工作类型" path="workType">
              <NSelect v-model:value="form.workType" :options="WORK_TYPE_OPTIONS" />
            </NFormItem>
            <NFormItem label="级别" path="level">
              <NSelect v-model:value="form.level" :options="LEVEL_OPTIONS" />
            </NFormItem>
          </div>

          <div grid grid-cols-3 gap-4>
            <NFormItem label="工作地点" path="location">
              <NInput v-model:value="form.location" placeholder="北京 / 远程" />
            </NFormItem>
            <NFormItem label="招聘人数" path="headcount">
              <NInputNumber v-model:value="form.headcount" :min="1" :max="999" w-full />
            </NFormItem>
            <NFormItem label="部门 ID" path="departmentId">
              <NInputNumber v-model:value="form.departmentId" :min="1" placeholder="可选" w-full />
            </NFormItem>
          </div>

          <NFormItem label="薪资范围（元/月，留空 = 面议）">
            <div flex items-center gap-2 w-full>
              <NInputNumber
                v-model:value="form.salaryMin"
                :min="0"
                :step="1000"
                placeholder="下限"
                flex-1
              />
              <span text-tertiary>—</span>
              <NInputNumber
                v-model:value="form.salaryMax"
                :min="0"
                :step="1000"
                placeholder="上限"
                flex-1
              />
            </div>
          </NFormItem>

          <NFormItem label="标签" path="tagIds">
            <NSelect
              v-model:value="form.tagIds"
              :options="tagOptionsGrouped"
              multiple
              filterable
              clearable
              placeholder="选择技术栈 / 行业 / 福利 / 文化标签"
              max-tag-count="responsive"
            />
          </NFormItem>

          <NFormItem label="岗位描述（支持纯文本，全文检索目标）" path="description">
            <NInput
              v-model:value="form.description"
              type="textarea"
              :autosize="{ minRows: 6, maxRows: 16 }"
              placeholder="职责、要求、技术栈、薪酬福利…&#10;支持后端全文检索（ILIKE + tsvector）"
              maxlength="50000"
              show-count
            />
          </NFormItem>
        </NForm>

        <template #footer>
          <NSpace>
            <NButton @click="drawerVisible = false">
              取消
            </NButton>
            <NButton type="primary" :loading="submitting" @click="submitForm">
              {{ drawerMode === 'create' ? '保存为草稿' : '保存修改' }}
            </NButton>
          </NSpace>
        </template>
      </NDrawerContent>
    </NDrawer>
  </main>
</template>

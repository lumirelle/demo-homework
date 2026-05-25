---
name: ai-fullstack-dev
description: AI 辅助全栈开发工作流。用于从 0 到 1 搭建中等复杂度 Web 系统 MVP，覆盖选题分析、需求调研、技术设计、编码实现到部署交付的完整流程。当用户提到全栈开发、搭建系统、需求文档、MVP、从零开始建项目时触发。
metadata: v0.0.26.20260526
---

# AI 全栈开发工作流

## 阶段总览

```
Phase 1: 调研  →  Phase 2: 技术设计  →  Phase 3: 编码实现  →  Phase 4: 交付
```

---

## Phase 1：需求调研

### 1.1 需求调研

输入：候选系统（如白板/文档）

输出：基于选定系统，完成以下内容并输出 HTML 文档：

1. **概述**
   1. **项目背景**：项目背景即参考产品
   2. **目标与范围**：项目目标，迭代周期以及个周期交付范围
   3. **角色与权限**：列出所有用户角色及对应操作权限
2. **功能需求**
   1. 功能用例表。每个模块列出用例编号、名称、角色、描述，可以扩展涉及的概念定义
3. **技术设计**
   1. **状态机设计**：核心业务实体的状态流转图与约束规则
   2. **数据模型（ERD）**：列出所有核心表、字段、类型、主外键关系
   3. **API 设计**：RESTful 接口列表清单，含方法、路径、权限要求
   4. **技术架构选型**：前后端框架和库、数据库、缓存、文件存储、部署方案等
4. **其他**
   1. **非功能需求**：性能、安全、兼容性基线
   2. **MVP 页面清单**：前端路由列表，标注角色可见范围
   3. **开发里程碑**：按天拆分前后端并行任务

按需扩充。

输出路径：`docs/project-requirements.html`

---

## Phase 2：技术设计

输出：

| 名称 | 路径 | 说明 |
|---|---|---|
| 数据库 DDL | `docs/project-schema.sql` | PostgreSQL 建表语句 |
| 技术设计文档 | `docs/project-tech-design.html` | 后端/前端结构可视化 HTML |

### 2.1 数据库 Schema（`docs/project-schema.sql`）

用 SQL DDL 输出建表语句（PostgreSQL 语法）

包含：

- 枚举类型（`CREATE TYPE`）
- 所有表的字段、类型、NOT NULL、DEFAULT、CHECK 约束
- 主外键关系，ON DELETE 策略按业务选 CASCADE / RESTRICT / SET NULL
- B-tree 索引（高频查询字段）；文本搜索用 GIN 索引
- 每张表和关键字段的 `COMMENT`
- `updated_at` 自动更新触发器（统一用 `set_updated_at()` 函数）
- 常用聚合视图（如漏斗、月度概览）
- 种子数据（初始管理员账号、字典数据）

按需扩充。

### 2.2 技术设计文档（`docs/project-tech-design.html`）

1. **概述**
   1. 系统架构概览：前端 ↔ 后端 ↔ 数据库/缓存/文件 的分层架构图
2. **数据库**：
   1. Schema 说明：核心表用途、数据量级、关键约束速查表
   2. 枚举类型清单
   3. 索引策略说明
3. **后端**：
   1. 项目结构文件树（暗色背景，含目录注释）
   2. 各层（Controller / Service / Repository / Model / Config / Exception）职责卡片
   3. 编码规范（响应格式、错误码、状态机约束、安全规范）
   4. 环境变量清单（`.env.example` 内容）
4. **前端**：
   1. 项目结构文件树（含 views、components、stores、api、router、utils、types 目录注释）
   2. 各模块职责卡片
   3. 编码规范（组件风格、状态管理、加载处理、代码质量）
   4. 环境变量清单
5. **部署**
   1. Docker Compose 部署方案：服务表（postgres / redis / backend / frontend/nginx）
   2. 开发启动检查清单：后端 + 前端各自的启动前核查项

按需扩充。

### 2.3 后端分层参考

Spring Boot 推荐分层：

```
controller/   → 接口层，参数校验（@Valid）
service/      → 业务逻辑，事务管理，状态机校验
repository/   → 数据访问（MyBatis-Plus 或 JPA）
model/entity/ → 数据库实体
model/dto/    → 请求入参（含校验注解）
model/vo/     → 响应出参（脱敏）
config/       → JWT、Security、Redis、CORS、文件上传配置
middleware/   → JWT 过滤器（注入 SecurityContext）
exception/    → 全局异常处理（@RestControllerAdvice）
```

Gin 推荐分层：

```
handler/    → 路由处理
service/    → 业务逻辑
repo/       → 数据库访问（sqlx 或 GORM）
model/      → 结构体（entity / dto / vo）
middleware/ → JWT、CORS、日志
```

按需扩充。

### 2.4 前端结构参考

```
src/
  views/       → 页面组件（与路由 1:1，HR 页面放 views/hr/ 子目录）
  components/  → 通用组件（KanbanCard、StageTimeline、FunnelChart 等）
  stores/      → Pinia 状态（useAuthStore 持久化 Token）
  api/         → request.ts（Axios 实例+拦截器）+ 各模块请求函数
  router/      → 路由配置（meta.roles 声明权限）+ 全局路由守卫
  utils/       → token.ts / format.ts / stageMap.ts（枚举→标签/颜色）
  types/       → api.d.ts（与后端 VO 对齐）+ enums.ts
  styles/      → tokens.css（design tokens）+ global.css
```

按需扩充。

### 2.5 UI 设计基线（双轨：克制 + 张扬）

> 参考 awwwards 优秀作品。中等复杂度 Web 系统通常需要**两种语言并存**：
> - **张扬轨**（Stripe / Resend / Linear 营销页系）— 用于 Hero / Landing / 营销页：大渐变、巨型字号、aurora 漂移、噪点质感、强 accent 色、大胆微动画
> - **克制轨**（Linear app / Vercel Dashboard / Cron / Notion 系）— 用于应用内（列表、看板、表单、详情）：极致可读性、信息密度、克制配色、微动画
>
> **统一 tokens，分场景配方**：颜色不能 hardcode，全部走 CSS variables；张扬轨在克制 tokens 基础上**追加**(而非替换) accent / gradient / glow / noise token。

#### 2.5.1 共用 tokens 基线

**色彩**：

- **品牌主色**：单一品牌色（推荐**贴合项目语义**的颜色 — ATS 招聘项目选 `emerald #10b981` 寓意"好苗子、成长"；电商可选 amber；金融可选 navy）
- **中性色 9-11 阶灰度**（`gray-50` … `gray-950`），背景、边框、文字层级全靠它
- **语义色**：success / warning / danger / info 各一组（base + bg + border）
- **accent palette（张扬专用）**：围绕品牌叙事挑选 4-6 色构造 mesh 渐变。ATS 例：`mint / emerald / teal / cyan / lime / amber / forest`（萌芽→茁壮→沉淀→收获），避免一锅乱炖
- **暗色模式预留 token 切换位**

> ⚡ **色彩叙事原则**：accent palette 的颜色顺序应能映射到项目的核心业务流（如招聘漏斗 stage、订单状态、用户成长等级）。这样列表 / 看板 / 状态徽章用到对应阶段时，颜色复用且语义自洽，不需要二次设计。

**排版**：

- 中文：`PingFang SC` / `Microsoft YaHei` / `Noto Sans SC`；英文/数字：`Inter` / `JetBrains Mono`
- 克制字号 6 档：`12 / 13 / 14 / 16 / 20 / 24`；张扬巨字号 3 档：`clamp(48,8vw,80) / (64,11vw,128) / (80,14vw,160)`
- 标题字重 600/700；张扬 hero 800；正文 400；重要数字 500–600 + tabular-nums

**圆角 / 间距 / 阴影**：

- 8px 栅格；圆角 6 / 8 / 12 三档；张扬 CTA 用 `999px` full
- 阴影 3 档（`shadow-sm/md/lg`），张扬场景额外加 `glow-brand/magenta/violet` 大模糊光晕
- 卡片白底 + 1px 浅边框；hover 升 2-4px + `shadow-lg`

#### 2.5.2 张扬轨追加武器

```css
/* mesh gradient（背景 / 文字 fill） */
--grad-aurora: radial-gradient(...) + 3 个 blob;
--grad-sunrise: linear-gradient(135deg, magenta, violet, cyan);
--grad-fire:    linear-gradient(135deg, amber, magenta, violet);

/* 光晕（hero CTA / 焦点元素） */
--glow-brand / --glow-magenta / --glow-violet

/* 噪点 SVG overlay（叠在大色块上抗 banding，加质感） */
--noise-url: url("data:image/svg+xml;..." feTurbulence ...)

/* aurora 漂移动画 */
@keyframes aurora-drift { ... } /* 24s 缓慢有机感 */

/* 入场 reveal */
.reveal { opacity: 0; transform: translateY(16px); transition: ... }
.reveal.is-visible { ... }

/* cursor follow glow（鼠标跟随发光） */
.cursor-glow { background: radial-gradient(400px circle at var(--mx) var(--my), ...) }
```

实用 utility class：`text-gradient` / `text-gradient-fire` / `with-noise` / `aurora-layer` / `reveal`。

**强约束**：

- `prefers-reduced-motion: reduce` 必须关闭 aurora 与 reveal
- 张扬 hero 仅出现在 landing/marketing 页，**应用内主流程**（看板、列表、表单）保持克制
- 渐变文字必须配 `-webkit-background-clip + background-clip + color: transparent`，保证 Safari/Chrome 双兼容

#### 2.5.3 Naive UI 落地

- 用 `NConfigProvider` + `themeOverrides` 把 token 注入主题，组件级颜色全部走主题
- 自定义组件用 CSS variables（`var(--brand-500)` 等）跟随主题切换
- 张扬场景的元素**不要**强行套 Naive 组件，用原生 button + token CSS 更自由（如 Hero CTA、stat strip）

#### 2.5.5 样式工具：UnoCSS · Attributify 第一公民（强制）

**所有前端项目使用 UnoCSS 作为原子化 CSS 引擎**，且优先用 **attributify mode** 而不是 class 串。理由：
1. 模板里 attribute 自带分组语义（`bg="elevated"` / `border="~ subtle"` 一眼看出语义类型），可读性远超长 class 串
2. 同 prefix 自动合并 → 字符总量比 class 风格少 30-50%
3. 与 Vue/React 模板的 prop 写法同构，AI 生成更稳定

##### 接入步骤

```bash
bun add -D unocss @unocss/preset-uno @unocss/preset-attributify @unocss/preset-icons \
              @unocss/transformer-directives @unocss/transformer-variant-group
```

```ts
// vite.config.ts
import Unocss from 'unocss/vite'
plugins: [Unocss(), vue()]  // UnoCSS 必须在 vue 之前

// main.ts
import 'virtual:uno.css'
import './styles/global.css'  // tokens + 复杂动画
```

##### Token 桥接（核心决策：CSS custom properties 是单一真值来源）

`uno.config.ts` 中 `theme.colors / spacing / fontSize / boxShadow / transitionTimingFunction / transitionDuration` 全部用 `var(--xxx)` 引用 `tokens.css`，**禁止在 UnoCSS 里重复定义色值**。这样 Naive UI、原生 CSS、UnoCSS 三方共享一套真值。

```ts
theme: {
  colors: {
    brand: { 500: 'var(--brand-500)', ... },
    accent: { mint: 'var(--accent-mint)', emerald: 'var(--accent-emerald)', ... },
  },
  transitionTimingFunction: {
    out: 'var(--ease-out)',           // hover 微交互
    'page-in': 'var(--ease-page-in)', // 页面/模态转场
  },
  transitionDuration: {
    'page-in': 'var(--dur-page-in)',  // 与 2.5.4 速度感工程学绑定
  },
}
```

##### Attributify 落地规约（最容易踩坑的地方）

**核心选择树**（按这个优先级判断写哪种形式）：

```
1. valueless（display / position / 状态 keyword）？  → <div flex relative grid>
2. 单值 + 无括号？                                    → <div bg-app mt-8 rounded-full>
3. 单值 = CSS 变量？                                  → <div bg-(--brand-500) text-(--text-primary)>  ✨ 圆括号简写
4. 单值 + 带括号（arbitrary 字面值）？                 → <div max-w="[1200px]" gap="[10px]">  ⚠️ 必须 attributify
5. 单值 variant（hover/focus/group-hover/max-sm）？    → <div hover:bg-active group-hover:translate-x-1>
6. 多值（含 ~ 或空格分隔的多个 utility）？             → <div flex="~ items-center" p="y-3 x-4">
7. shortcut / 状态化 / 含 . is-visible？               → <div text-gradient reveal ms-card>
8. 与元素 / 组件属性冲突（边界情况，更优选择是通过语义化 shortcut 命名规避此情况）？  → <div class="disabled">
```

| 场景 | 写法 | 说明 |
|---|---|---|
| **无值原子（display/position 等 keyword）** | `<div flex relative grid inline-flex>` | 直接 valueless，UnoCSS scanner 会扫到。**禁止** `flex="~"` 这种冗余形式 |
| **单值无括号** | `<div bg-app mt-8 rounded-full text-lg font-bold>` | **当 class 用**，更紧凑（`bg="app"` 比 `bg-app` 多 4 字符却没好处） |
| **单值带括号（arbitrary 字面值）** | `<div max-w="[1200px]" tracking="[-0.05em]" gap="[10px]">` | **⚠️ 必须 attributify value 形式**，**禁止** `max-w-[1200px]` 写在 attribute name 上 —— HTML attribute name 不允许 `[` `]` 字符，框架 / 浏览器不允许；attributify value 字符串里方括号完全合法 |
| **单值 + CSS 变量** ✨ | `<div bg-(--brand-500) text-(--text-primary) shadow-(--shadow-lg)>` | UnoCSS **圆括号简写**：`prop-(--var)` ≡ `prop-[var(--var)]`，比方括号 + `var()` 短 7 字符。HTML attribute name **允许** `(` `)`（与 `[` `]` 不同）|
| **单值 variant** | `<div hover:bg-active group-hover:translate-x-1 max-sm:hidden focus:ring-2>` | **当 class 用**，单值时连字符 + 冒号比 `hover="bg-active"` 更短更直观 |
| **多值（同 prefix，含 prefix 本身）** | `flex="~ items-center justify-between wrap"` | `~` 表示 prefix 本身作为 class（`display:flex`）；**此处 `~` 不能省**——去掉就只剩 `align-items` `justify-content` `flex-wrap`，没有 `display:flex` |
| **多值（同 prefix，不含 prefix 本身）** | `border="t subtle"` ／ `bg="elevated hover:active"` | 不写 `~`，只组合子 class。**注意：prefix 必须不与 HTML 原生 / Vue 组件 prop 冲突**（见反模式 #9） |
| **多值简写连写** | `p="y-3 x-4"` → `py-3 px-4` ／ `m="t-6 x-auto"` → `mt-6 mx-auto` | 维度复合写在一个属性里 |
| **多值 variant** | `hover="text-primary after:right-0"` ／ `before="absolute inset-0 content-empty"` | variant 包多个 utility 才用 attributify；单值 variant 走 class with hyphen |
| **shortcut / 状态化** | `text-gradient ms-card status-done reveal` | shortcut 等命名尽量保持语义化命名，避免和元素 / 组件的属性冲突 |

> 💡 **`duration-*` 默认 unit**：UnoCSS 对 `duration-N`（纯数字）默认 `N` 毫秒——`duration-260` ≡ `duration-[260ms]`，前者更短，**优先用**。同理 `delay-*`。但 `w-` `h-` `p-` `m-` 等纯数字走的是 theme.spacing（`w-4` ≠ `w-[4px]`），不要混淆。

> 💡 **借助插件做权威校验**：UnoCSS 写法的合法性以工具实时报告为准，**不要凭记忆判断**：
> - **VSCode**：装 `antfu.unocss` 扩展，hover / 行内即可看到 utility 是否匹配 + 生成的 CSS
> - **CLI 校验**：装 `@unocss/eslint-plugin`，配 minimal `eslint.config.js` 跑 `eslint . --rule '@unocss/order: error' --rule '@unocss/blocklist: error'` 验证；也可直接看 vite dev server stdout 的 `[unocss] unmatched utility "..."` 警告
> - **凡是 vite 报 unmatched 的写法都是无效的，看看是不是用了不存在的规则**——立即修，不要 ship 残缺 class

##### ⚠️ 反模式

1. **单独 `xxx="~"` 冗余写法**（如 `<div flex="~" relative="~">`）—— `~` 只在"prefix 本身 + 子值"混合场景才必要；单独无值原子直接 `<div flex relative>` 即可。全项目统一 valueless 风格
2. **`max-w-[1200px]` 直接当 attribute name 用**（如 `<div max-w-[1200px]>`）—— HTML attribute name 不允许 `[` `]`，浏览器宽容但 vue-tsc / prettier 不可靠。**必须**改 `<div max-w="[1200px]">`。但写在 class 字符串里（`class="max-w-[1200px]"`）OK，因为是 string value
3. **单值还用 attributify value 模式**（如 `<div bg="app" mt="8">`）—— 比 `bg-app mt-8` 多打 4-6 字符却没好处。**单值无括号 → class with hyphen** 是统一规约
4. **可以用 attributify 是使用 class**—— 规范不统一，diff 难读，规约混乱
5. **shortcut / 复杂状态 class 拆成 atomic**（如把 `text-gradient` 拆成 5 个属性）—— 失去 shortcut 的语义聚合价值
6. **在 UnoCSS theme 里重新写一遍颜色值**（如 `brand: { 500: '#10b981' }`）—— 破坏"token 单一真值"，Naive UI 和 UnoCSS 会渐行渐远
7. **CSS 变量长链没逐级降级到最短形态** —— 三档优先级，从短到长**强制递进**：
   1. ✅ **theme 已注册 → 直接用 token name**：`bg-brand-500` / `text-primary` / `bg-app` / `border-subtle` / `shadow-lg` / `duration-base` / `ease-out`。一次配置，处处复用，最短最语义化
   2. ✅ **theme 未注册 → 圆括号简写**：`bg-(--my-custom-var)` / `text-(--accent-color)`。圆括号 HTML 合法，可直接当 attribute name
   3. ⚠️ **绝不使用方括号 + `var()` 长写**：`bg-[var(--brand-500)]` —— 比简写多 7 字符没收益，且 attributify name 含方括号会触发 prettier / vue-tsc 兼容问题
   - **检查脚本**：
     ```pwsh
     # 找仍在用 (--xxx) 但 token 已在 theme 注册的写法（应升级到 hyphen）
     rg '\b(bg|text|border|shadow|rounded|font|duration|ease)-\(--[\w-]+\)' src/
     # 找方括号 + var() 长写（应降级到圆括号）
     rg '\[var\(--[\w-]+\)\]' src/
     ```
   - **每加新 token 先入 theme**：tokens.css 加变量时同步在 `uno.config.ts` 的 `theme.colors / backgroundColor / textColor / borderColor / fontSize / boxShadow / transitionTimingFunction / transitionDuration` 注册，否则全项目只能 fallback 到圆括号写法，违背"单一真值"
8. **`text="lg primary"` / `name="..."` / `for="..."` / `title="..."` / `role="..."` 这些 attribute name 用作 attributify prefix**——这些是 **HTML 原生属性 / WAI-ARIA 属性 / Vue 组件 prop**，attributify 模式下属性还会保留在 DOM 上，会被浏览器或组件错误解析：
   - `text` —— SVG `<text>` 元素 / Naive UI `NButton text` (boolean prop) / NEllipsis 等都吃 `text` prop，传字符串触发警告甚至渲染异常
   - `name` —— form 元素的 form data 字段名；`<input name="lg primary">` 提交时真会发出去
   - `for` —— `<label for="...">` 关联 input id；DOM 上挂 `for="text-lg"` 会破坏 a11y
   - `title` —— 全局 tooltip 属性，浏览器会真的浮出 "lg primary" 文字
   - `role` —— ARIA role，screen reader 会按 role="lg primary" 解读，无障碍语义崩坏
   - `type` / `value` / `placeholder` / `id` —— 同理，所有 HTML 标准 attribute name 都不能借用
   - **规约**：所有跟 HTML / ARIA / 第三方组件 prop 重名的 attribute name **禁止**当 attributify prefix。**改用 valueless attributify**（`text-lg text-primary` 拆开写，每个完整 utility 名作为独立 attribute name），或者写进 `class="..."`
   - **批量自查脚本**：`rg 'text="' src/` / `rg 'name="(?!&quot;)'` —— PR 前跑一遍，0 命中再合
9. **用 `bg-[var(--grad-xxx)]` ／ `bg-(--grad-xxx)` ／ shortcut 拼出渐变**—— UnoCSS 把 `bg-[...]` 和 `bg-(--xxx)` 都默认推断为 `background-color`，**`background-color` 不接受 `linear-gradient(...)`，渐变会静默失效**（不报错，但页面上就是一片透明 / 默认色）
   - **必须用 `rules` 接管**，显式输出 `background-image`：
     ```ts
     rules: [
       // text-gradient · text-gradient-{spring|bloom|forest|brand|aurora}
       [/^text-gradient(?:-(spring|bloom|forest|brand|aurora))?$/, ([, name]) => ({
         'background-image': `var(--grad-${name || 'spring'})`,
         '-webkit-background-clip': 'text',
         'background-clip': 'text',
         'color': 'transparent',
         '-webkit-text-fill-color': 'transparent',
       })],
       // bg-grad-{spring|bloom|forest|brand|aurora}
       [/^bg-grad-(spring|bloom|forest|brand|aurora)$/, ([, name]) => ({
         'background-image': `var(--grad-${name})`,
       })],
     ]
     ```
   - **自测**：浏览器打开页面，如果 `text-gradient` 文字是 `transparent` 但没看到渐变（一片空白） → 100% 是这个坑
   - **DOM 检查法**：dev tools 看 `__uno.css` 是否生成的是 `background-color: var(--grad-xxx)`（错）还是 `background-image: var(--grad-xxx)`（对）
   - 使用 CSS 变量时同理，如：`bg-(--gradient)` 是不可用的

##### shims.d.ts 必备声明

```ts
declare module 'virtual:uno.css'
```

> 💡 vue-tsc 现在对 attributify 属性是宽容的（任意未知 attribute 接受 string，**包括 valueless attribute 不再报 boolean 错**），无需为 `bg` / `text` / `p` / `m` 等做 HTMLAttributes augmentation。如果你看到旧文章建议加 `~` 来"绕过 boolean 报错"，那是过时信息——忽略，继续使用 valueless 即可。

##### Shortcuts 分层规约（≥ 3 处复用就抽 shortcut）

**判断标准**：同一段 utility 组合在 ≥ 3 个组件出现，或单段 ≥ 40 字符 → 立即抽进 `uno.config.ts` 的 `shortcuts`，模板里只剩语义类名。

**命名前缀分组**（来自 M1 实战沉淀，扫一眼前缀就知道用途）：

| 前缀 | 用途 | 示例 |
|---|---|---|
| `layout-*` / `center-*` / `between-*` / `col-*` | 布局原子 | `center-flex`、`between-flex`、`col-flex`、`card-base` |
| `typo-*` / `heading-*` / `kicker` / `eyebrow` | 排版语义 | `heading-1`、`eyebrow`（uppercase + tracking）|
| `surface-*` | 容器（玻璃 / 卡片） | `surface-glass`、`surface-glass-dark`、`surface-elevated` |
| `btn-*` | 按钮变体（含 hover/active） | `btn-primary`、`btn-secondary`、`btn-cta` |
| `field-*` / `kbd-hint` / `error-banner` / `demo-*` | 表单原子 | `error-banner`、`error-icon`、`demo-card`、`kbd-hint` |
| `navbar-*` / `logo-*` / `avatar` / `user-trigger` / `version-pill` | 导航栏专属 | `navbar-glass`、`navbar-glow-line`、`logo-mark`、`logo-mark-lg` |
| `brand-*` / `hero-*` / `aurora-bg-*` / `orb-*` | 品牌视觉（认证页 / Hero） | `brand-pane`、`hero-display`、`hero-outline`、`hero-gradient` |
| `anim-*` / `animate-*` / `btn-shimmer` / `cta-glow` | 动画绑定 | `animate-shimmer`、`btn-shimmer`、`cta-glow`（搭配 `group` 用）|

##### Keyframes 集中沉淀策略

`@keyframes` 定义**只能写在 CSS** 里（UnoCSS 不支持定义，只能引用）。集中沉淀到 `styles/global.css`，shortcuts 通过 `animate-xxx` utility 引用：

```css
/* global.css —— 所有共享 keyframes 集中 */
@keyframes shimmer       { 0%{transform:translateX(-100%)} 50%,100%{transform:translateX(100%)} }
@keyframes gradient-flow { 0%,100%{background-position:0% 50%} 50%{background-position:100% 50%} }
@keyframes aurora-shift  { 0%,100%{transform:translate3d(0,0,0) scale(1)} 50%{transform:translate3d(-3%,2%,0) scale(1.05)} }
@keyframes orb-float-a   { 0%,100%{transform:translate3d(0,0,0)} 50%{transform:translate3d(40px,30px,0)} }
@keyframes card-bob      { 0%,100%{translate:0 0} 50%{translate:0 -6px} }
```

```ts
// uno.config.ts rules 里逐个注册 animate-* utility
rules: [
  ['animate-shimmer',       { animation: 'shimmer 2.5s ease-in-out infinite' }],
  ['animate-gradient-flow', { animation: 'gradient-flow 6s ease-in-out infinite' }],
  ['animate-aurora-shift',  { animation: 'aurora-shift 18s ease-in-out infinite' }],
  // ...
]
```

> ⚠️ **不要用 `theme.animation`**：实测 theme.animation 在不同时填 `keyframes` 字段时 UnoCSS **不生成 utility**（即使 keyframes 已在 global.css 定义）。统一走 rules 更直观可靠。

**reduced-motion 兜底用通配符匹配**，避免每加一个 keyframe 都要补声明：

```css
@media (prefers-reduced-motion: reduce) {
  [class*="animate-aurora"],
  [class*="animate-orb"],
  [class*="animate-gradient"],
  [class*="animate-card-bob"],
  [class*="animate-tag-float"],
  [class*="animate-shimmer"],
  [class*="animate-pulse"] { animation: none !important; }
}
```

##### text-stroke / 复杂多层渐变的自定义 rule 套路

UnoCSS 默认不带 `-webkit-text-stroke`（描边文字），加规则即可：

```ts
rules: [
  [/^text-stroke-(\d+)$/, ([, w]) => ({
    '-webkit-text-stroke-width': `${w}px`,
    'color': 'transparent',
  })],
  [/^text-stroke-(\[[^\]]+\]|white|black|brand)$/, ([, c]) => {
    const color = c.startsWith('[') ? c.slice(1, -1) : c === 'brand' ? 'var(--brand-500)' : c
    return { '-webkit-text-stroke-color': color }
  }],
]
```

用法：`<span class="text-stroke-2 text-stroke-[rgba(255,255,255,.85)]">`。

##### 「能否完全替代 scoped CSS？」诚实回答

**理论上 100% 可以，实战 92%**。剩下 8% 必须 / 推荐留 plain CSS：

| 场景 | 为什么留 CSS | 例子 |
|---|---|---|
| **`@keyframes` 本身** | UnoCSS 不能定义，只能引用 | `keyframes shimmer { ... }` |
| **Vue Transition 命名 class** | Vue 命名约定要求 plain class | `.fade-slide-enter-active` |
| **依赖 `::before` `::after` 伪元素** + 复杂结构 | utility 写多层伪元素链路啰嗦 | `.with-noise::after`（噪点 overlay）|
| **依赖 JS 注入 CSS var** | `--mx --my` 跟随鼠标场景 | `.cursor-glow` |
| **状态化 `[data-state='up']` 联动多个子元素** | 父级状态控制多个 selector 时 utility 难表达 | health card 状态色联动 |

#### 2.5.4 页面过渡 / 路由动画基线（强制）

**所有应用都必须**为路由切换提供过渡动画，避免页面"硬切"的廉价感。统一基线：

- **默认动效 = `fade-slide`**：280ms 入场（12px 上滑）+ 200ms 离场（6px 上飘）
- **节奏控制**：入场 ≤ 320ms、离场 ≤ 220ms（B 端工具不能让用户等），同时配合 `mode="out-in"` 避免新旧页同框抖动
- **滚动复位**：路由切换时 `scrollBehavior` 始终回到顶部（除非有 `meta.keepScroll`）
- **可达性**：`prefers-reduced-motion: reduce` 媒体查询下**完全禁用过渡**（不是减速，而是 0ms），与 reveal/aurora 同标准
- **个别页定制**：通过 `route.meta.transition` 字段覆盖默认（如登录页用 `fade` 不带位移，404/empty state 用 `fade-scale`）
- **嵌套路由**：HR / 候选人后台等带 layout 的场景，**只对内层 view 加过渡**，外层 sidebar/topnav 保持静止；用 `<RouterView v-slot="{ Component, route }">` 在内层包 `<Transition>`

##### 速度感工程学（避免「太快显跳」「太慢显粘」）

| 维度 | 反面教材 | 正确做法 |
|---|---|---|
| **时长** | 入场 180ms 显跳；入场 ≥ 400ms 显粘 | **页面入场 260-320ms 是甜区**；离场比入场短 60-80ms |
| **曲线** | hover 用的 `expo-out`（前段冲得猛）放到页面转场 | 入场用 `cubic-bezier(0.32, 0.72, 0, 1)`（iOS spring，**末段稳**）<br>离场用 `cubic-bezier(0.4, 0, 0.6, 1)`（gentle，**不抢戏**） |
| **节奏差** | opacity 和 transform 同时间结束 → 末段"半透明残影"拖尾 | **opacity 比 transform 略短**（180 vs 280），让位置先稳下来再淡入 |
| **位移幅度** | 入离场幅度一样大 | **入场幅度 > 离场幅度**（12px vs 6px），制造"前进感" |
| **属性范围** | `transition: all 200ms` | **显式列属性**，避免浏览器把 `color/border-radius/...` 全做插值 |
| **GPU** | `translateY()` / `scale()` | **`translate3d()` / `scale3d()`** 强制 GPU compositing，掉帧少 |

> **判断动画好不好的简单方法**：路由切换时眼睛能否"跟得上但又看得到"。跟不上 = 太快，等不及 = 太慢。300ms 上下做加减是黄金区间。

##### 推荐的 token 划分

```css
/* hover / focus 等微交互 */
--ease-out: cubic-bezier(0.16, 1, 0.3, 1);    /* expo-out，snappy */
--dur-fast: 120ms;
--dur-base: 180ms;

/* 页面 / 模态级转场专用（与微交互曲线区分）*/
--ease-page-in:  cubic-bezier(0.32, 0.72, 0, 1);
--ease-page-out: cubic-bezier(0.4, 0, 0.6, 1);
--dur-page-in:   280ms;
--dur-page-out:  200ms;
--dur-fade:      180ms;   /* opacity 通道专用 */
```

##### ⚠️ 反模式：曲线串轨（最常踩的坑）

**绝对不要把 `--ease-page-in`（decel）用在 hover 上**。decel 曲线前 30% 几乎没动静，对页面转场是"末段稳定感"，对 hover 就是"指头点上去半天没反应"，用户会**感到延迟**，即便实际时长更短。

| 场景 | 期望体感 | 必须用 | 禁止用 |
|---|---|---|---|
| **hover / focus / 点击反馈** | "指哪打哪"，前段必须立刻动 | `--ease-out`（expo-out，前段快） | `--ease-page-in`（decel，前段慢） |
| **页面切换 / 模态弹出** | 末段稳，不显冲击 | `--ease-page-in` | `--ease-out`（expo-out 用在大动作上前段冲得猛） |

> **自测**：把手放鼠标上，hover 卡片。如果第一感觉是"哎？怎么愣了一下才浮起来" → 你把 page-in 错用到 hover 上了。立即换回 `--ease-out`。

##### 最小落地模板（Vue 3 + Vue Router 4）

```vue
<!-- App.vue（或 layout 内层）-->
<RouterView v-slot="{ Component, route }">
  <Transition :name="(route.meta.transition as string) || 'fade-slide'" mode="out-in" appear>
    <component :is="Component" :key="route.fullPath" />
  </Transition>
</RouterView>
```

```css
/* global.css —— 默认 fade-slide */
.fade-slide-enter-active {
  transition:
    opacity   var(--dur-fade)    var(--ease-page-in),
    transform var(--dur-page-in) var(--ease-page-in);
  will-change: opacity, transform;
}
.fade-slide-leave-active {
  transition:
    opacity   160ms               var(--ease-page-out),
    transform var(--dur-page-out) var(--ease-page-out);
  will-change: opacity, transform;
}
.fade-slide-enter-from { opacity: 0; transform: translate3d(0, 12px, 0); }
.fade-slide-leave-to   { opacity: 0; transform: translate3d(0, -6px, 0); }

.fade-enter-active { transition: opacity var(--dur-page-in)  var(--ease-page-in); }
.fade-leave-active { transition: opacity var(--dur-page-out) var(--ease-page-out); }
.fade-enter-from, .fade-leave-to { opacity: 0; }

.fade-scale-enter-active {
  transition:
    opacity   220ms var(--ease-page-in),
    transform 320ms var(--ease-bounce);
  will-change: opacity, transform;
}
.fade-scale-leave-active {
  transition:
    opacity   160ms var(--ease-page-out),
    transform 200ms var(--ease-page-out);
}
.fade-scale-enter-from { opacity: 0; transform: scale3d(0.96, 0.96, 1); }
.fade-scale-leave-to   { opacity: 0; transform: scale3d(1.03, 1.03, 1); }

@media (prefers-reduced-motion: reduce) {
  .fade-slide-enter-active, .fade-slide-leave-active,
  .fade-enter-active, .fade-leave-active,
  .fade-scale-enter-active, .fade-scale-leave-active { transition: none !important; }
  .fade-slide-enter-from, .fade-slide-leave-to,
  .fade-scale-enter-from, .fade-scale-leave-to { transform: none !important; }
}
```

**强约束**：

- `key="route.fullPath"` 必须给（而非 `route.path`），否则 `/jobs/1 → /jobs/2` 同组件不会触发过渡
- `mode="out-in"`，**不要**用 `in-out`（会出现两份 DOM 同框抖动 + 闪烁滚动条）
- 不要在 Transition 里包含 `position: fixed/sticky` 的 header — 会跟着动；header 留在 Transition **外面**
- 离场动画 `transform` 方向应与入场**相反**（入场上滑 → 离场上飘），制造"前进感"
- **禁止** `transition: all`，必须显式列出参与动画的属性
- transform 始终用 `translate3d` / `scale3d`，触发 GPU compositing，scroll 抖动率明显下降

> 💡 **进阶**：带方向感的 history 过渡（前进右进、后退左出）可在 router `beforeEach` 比对历史栈记录方向，在 `meta._transitionDirection` 上挂值给 Transition 用。MVP 阶段不强求，M5 打磨阶段再升级。

---

## Phase 3：编码实现

进入编码前，**先输出两份文档**：

1. `docs/project-dev-plan.html` — 总体开发计划（一次性输出，不频繁改）
2. `docs/project-milestones.html` — **活文档**：里程碑实时进度 + 变更日志 + 风险台账 + 关键决策 + 给未来 agent 的续接说明

> ⚡ **`project-milestones.html` 是 Phase 3 的核心交接物**。每个里程碑完成（哪怕是部分完成）都必须更新本文档；
> 这是下一个 agent / 新加入的人接手时第一份要看的文档，能节省他们 80% 的"摸索时间"。
> 模板要点：**仪表盘 + 时间线 + 续接说明 + 每个里程碑的详情卡 + 风险登记台账 + ADR-lite 决策表 + 变更日志**。

### 关于 `project-dev-plan.html`

文档必须包含：

1. **总览**
   1. 目标与产出：列出 Phase 1/2 的输入文档清单 + Phase 3 末态交付物
   2. 总体策略：纵切而非横切、契约先行、小步快跑、状态机闭环 4 条原则
   3. 里程碑甘特图：M0–M5 共 6 个里程碑，按天/周可视化
2. **里程碑**
   1. 每个里程碑的详细规划卡片（4 张卡 = 后端 + 前端 + 联调 + 风险/注意事项）
3. **开发环境准备**（进入 M0 之前必做，参考本文 3.1 章节）
   1. 工具与版本清单：JDK / Maven / Node / 包管理器 / Docker / Git / OpenSSL
   2. 本地服务方案：Docker Compose vs 本机原生，含端口冲突预案
   3. 凭据与密钥：JWT RS256 密钥生成、BCrypt hash 生成、`.env` 填值
   4. 代码仓库与 Git 规范：仓库布局、`.gitignore`、分支策略、commit 规范
   5. IDE 与编辑器推荐插件
   6. 环境自检脚本（Bash + PowerShell 双版本）
   7. 常见问题预案：端口冲突 / 镜像源 / WSL2 / BCrypt $ 转义等
4. **实施细节**
   1. 完整任务清单表格：编号 `MX-XX`、任务、类型（BE/FE/MIX/OPS/DB）、依赖、预估工时、优先级
   2. 关键技术要点代码片段：JWT 流程、状态机声明、看板回滚、文件上传校验、全文搜索
   3. 联调节点表：每个里程碑末的必跑场景 + 关键检查项
5. **协作规范**
   1. AI 辅助 SOP：Prompt 模板、生成粒度、多方案取舍原则
   2. 代码自检清单：后端 + 前端，参考本文 3.4 章节
   3. DoD（Definition of Done）**：单任务完成标准，参考本文 3.5 章节
6. **风险与交付**
   1. 风险矩阵：高/中/低 3 档 + 应对策略
   2. 阶段交付物清单

按需扩充。

### 3.1 开发环境准备（M0 之前必做）

> ⚠ **超过一半的 MVP 项目卡在环境问题**：JDK 版本不匹配、端口被占、镜像拉不下、JWT 密钥未生成……进入 M0 之前花 1–2 小时把环境彻底打通，能节省后面 3–5 倍调试时间。本节自检 100% 通过才能开始编码。

**工具与最低版本**：

| 工具 | 最低版本 | 用途 | 检查命令 |
|------|---------|------|---------|
| JDK | 21 (LTS) | 后端运行/编译 | `java -version` |
| Maven | 3.9+ | 后端构建 | `mvn -v` |
| Node.js | 20 (LTS) | 前端工具链 | `node -v` |
| 包管理器 | bun 1.3+ / pnpm 9 / npm 10 | 前端依赖 | `bun -v` |
| 容器引擎 | Docker 24+ **或** Podman 4+ | 本地 pg/redis | 见下 |
| compose | Docker Compose v2 **或** docker-compose v1 **或** podman compose | 编排 | 见下 |
| Git | 2.40+ | 版本控制 | `git --version` |
| OpenSSL | 3.0+ | 生成 JWT 密钥 | `openssl version` |

**容器命令兼容矩阵**（compose 文件用 `version: "3.8"` + 不使用 v2 独有语法即可三家通吃）：

| 引擎 | 启动命令 | 备注 |
|------|---------|------|
| Docker Desktop | `docker compose -f xxx up -d` | 现代默认 |
| `docker-compose` v1（独立 binary） | `docker-compose -f xxx up -d` | 兼容旧仓 / Podman 上常装 |
| Podman + podman compose | `podman compose -f xxx up -d` | Podman 4.0+ 内置 |
| Podman + docker-compose | `DOCKER_HOST=unix://...podman.sock docker-compose ...` | 走 podman socket |

> **Windows + Podman 用户**：装 Podman Desktop 后，命令行里直接用 `podman` 看容器、`docker-compose` 起服务最稳；npm scripts 里**统一写 `docker-compose`**（v1 写法），无论底层是 Docker 还是 Podman 都能跑。

**本地服务方案**：

- **方案 A（MVP 推荐）**：compose 起 `postgres` + `redis`，schema.sql 挂到 `/docker-entrypoint-initdb.d/` 自动初始化
- **方案 B（长期开发）**：本机原生安装；启动更快但跨平台版本对齐困难
- 默认端口 5432 / 6379 / 8080 / 5173 被占时在 compose 改映射如 `15432:5432`

**凭据与密钥（不可省略）**：

```bash
openssl genrsa -out jwt-private.pem 2048
openssl rsa -in jwt-private.pem -pubout -out jwt-public.pem
htpasswd -bnBC 12 "" "YourPassword" | tr -d ':\n'
```

`.env`、`*.pem`、`*.b64`、`secrets/` 必须全部加入 `.gitignore`，**任何 commit / 截图 / 日志都不得包含真实密钥**。

**Git 规范**：

- 仓库布局：MVP 阶段用 monorepo（`ats-backend/` + `ats-frontend/` + `docker-compose.yml`）
- 分支：`main` 保护 + 每里程碑一条 `feature/m1-auth`
- commit 格式：`[模块] 动词 + 内容`，禁止 `WIP` / `update` / `fix bug`
- `.gitignore` 必含：`.env*` / `*.pem` / `*.b64` / `target/` / `node_modules/` / `dist/` / `logs/` / `uploads/` / `.idea/` / `.DS_Store`

**IDE 推荐**：

- 后端：IntelliJ IDEA / Cursor + Java Extension Pack + Spring Boot Tools + Lombok
- 前端：Cursor / VS Code + Vue (Official) + ESLint + Oxlint + EditorConfig
- DB：DBeaver / DataGrip / RedisInsight
- 禁用旧版 Vetur（与 Volar 冲突）

**环境自检**：提供 `scripts/check-env.sh`（Bash）和 `scripts/check-env.ps1`（PowerShell），覆盖：

1. JDK / Maven / Node / Docker / Git / OpenSSL 版本
2. 5432 / 6379 / 8080 / 5173 端口空闲
3. `docker compose up -d` 后 pg / redis 健康
4. `psql ... -c "\dt"` 能列出全部表
5. `redis-cli ping` 返回 PONG
6. JWT 密钥已生成并写入 `.env`

**常见问题预案**：

| 问题 | 解决 |
|------|------|
| 端口被占 | compose 改映射；或停掉本机服务 |
| Maven 慢 | `~/.m2/settings.xml` 配阿里云 mirror |
| npm/bun 慢 | `npm config set registry https://registry.npmmirror.com` 或 `~/.bunfig.toml` 配 `registry` |
| 容器拉镜像超时 | Docker Desktop → Engine 配国内 mirror；Podman 改 `~/.config/containers/registries.conf` 加 mirror |
| Windows Docker 启动失败 | 启用 WSL2 + Hyper-V；或改用 Podman Desktop |
| Podman 起 pg 端口绑不上 | 默认 rootless 不能 < 1024 端口；5432/6379 没问题，若需 80/443 用 rootful 或映射高端口 |
| BCrypt hash 含 `$` 被 shell 截断 | 单引号包裹或写到 application.yml |
| PowerShell 多行命令 | 用反引号 \` 续行，**不要**用反斜杠 \\ |

按需扩充。

### 3.2 参考里程碑划分

| 里程碑 | 名称        | 工期参考 | 关键产出 |
|--------|-------------|----------|----------|
| M0     | 项目基建    | 1 天     | 前后端骨架 + dev compose + /health 跑通 |
| M1     | 认证模块    | 2 天     | 注册/登录/Refresh + JWT 拦截器 + 路由守卫 |
| M2     | 核心 CRUD   | 1 天     | 主实体增删改查 + 列表/详情页 |
| M3 ⭐  | 项目亮点功能 | 2 天     | 以具体项目为准 |
| M4     | 辅助模块    | 2 天     | 文件上传、子实体 CRUD、数据看板 |
| M5     | 打磨交付    | 2 天     | UI 打磨 + 完整 docker-compose + README + 演示 |

按需扩充。

每个里程碑结束都必须**能跑起来、能演示一个完整场景**。Mn 未通过联调验收禁止进入 Mn+1。

### 3.3 AI 辅助 SOP

**契约先行**：每次让 AI 写接口前，必须把以下信息一起喂给它：
- 任务（接口路径 + 一句话目标）
- 输入约定（DTO 字段 + 校验规则）
- 输出约定（VO 字段 + ApiResponse 包装）
- 业务规则（编号列举，含权限、状态机、唯一约束）
- 参考代码风格（贴一段已有 Service 30 行）
- 数据库 DDL 相关表的 CREATE TABLE

**生成粒度**：
- ✅ 一次生成「Controller + Service + Mapper」三件套（同一业务）
- ✅ 一次生成「一个 Vue 页面 + 对应 api 函数」
- ❌ 避免一次生成整个模块（如全部认证）—— 难以审阅
- ❌ 避免攒到 30 个文件再统一调试 —— 累积错误难定位

**多方案抉择**：
- 选最接近已有代码风格的那一种，不要混用（已用 MyBatis-Plus 就不再引 JPA）
- 方案差异显著时让 AI 列 trade-off，自己定夺，**不要直接接受 "AI 推荐"**
- 与 `project-tech-design.html` 冲突时，**以设计文档为准**

### 3.4 代码自检清单（每次 AI 生成后必做）

**后端 7 项**：

1. 字段名/类型是否与 DDL 对齐？枚举序列化用 name 而非 ordinal
2. 接口是否加 `@PreAuthorize` 或在 SecurityConfig 配规则？
3. 多表写入是否 `@Transactional`？状态变更是否与审计日志同事务？
4. 参数校验注解（`@Valid` + DTO 的 `@NotNull/@Size/...`）是否齐全？
5. SQL 是否用 `#{}` 占位符或 Wrapper，**禁止字符串拼接**
6. 状态机相关代码是否调用了统一校验方法，未自定义 if 判断？
7. 日志里有无敏感字段（密码、token、手机号、身份证）？

**前端 7 项**：

1. 类型是否从 `types/api.d.ts` 引入而非现写？
2. 异步操作是否带 loading？错误是否 toast？
3. 表单提交前是否 `formRef.validate()`？
4. 路由是否在 `meta.roles` 声明角色？
5. 是否有 hardcode 颜色（应使用 Naive UI theme token）？
6. 接口失败时本地乐观更新是否有回滚？
7. `any` 是否已消除？枚举是否从 `enums.ts` 引用？

### 3.5 单任务完成判定（DoD）

1. 本地能跑通对应场景（含至少一条 happy path + 一条异常 path）
2. 接口返回结构符合 `{ code, msg, data }`，HTTP 状态码与 code 一致
3. `npm run lint` / `mvn verify` 无新增报错
4. 关键逻辑（状态机、文件上传校验等）至少 1 个单测覆盖
5. 提交前 `git diff` self-review，删除 console.log / 调试代码
6. commit message 遵循 `[模块] 动词 + 内容`（如 `[auth] add refresh endpoint`）

### 3.6 高风险点速查（务必单测覆盖）

- **状态机非法流转**：用 `Map<Stage, Set<Stage>>` 声明合法图 + 终态不在 key 中保护
- **Token refresh 死循环**：拦截器内 refresh 失败必须清状态跳 `/login`，并用队列防重入
- **看板并发拖拽**：后端基于 `from_stage` 校验当前状态，UI 失败时 snapshot 回滚
- **文件上传越权**：所有下载接口必须查 application 归属，**禁止** nginx 直接静态暴露 `/uploads/`
- **AI 字段名漂移**：契约先行 + 自检清单第 1 项双重防线

---

## Phase 4：交付

### 本地运行

提供 `docker-compose.yml`，一条命令启动所有服务：

```bash
# Docker
docker compose up -d
# 或 v1 / Podman 兼容写法
docker-compose up -d
# Podman 原生
podman compose up -d
```

包含服务：postgres、redis、backend、frontend（nginx）

### 演示准备

- 录制 2-3 分钟演示视频，按业务流程顺序操作
- 重点展示亮点交互（看板拖拽、进度追踪等）
- 准备一份简短的架构说明（可用本 docs/ 下的需求文档）

---

## 参考文档

| 类型 | 路径 | 性质 |
|---|---|---|
| 需求文档 | `docs/project-requirements.html` | 静态 · Phase 1 末完成 |
| 数据库 Schema | `docs/project-schema.sql` | 单一来源 · 改动需 dev:reset |
| 技术设计文档 | `docs/project-tech-design.html` | 静态 · Phase 2 末完成 |
| Phase 3 总体计划 | `docs/project-dev-plan.html` | 半静态 · 大改才动 |
| **里程碑活文档** | `docs/project-milestones.html` | **活文档 · 每个里程碑必更** |

> 接手项目第一份要看：**`docs/project-milestones.html` 的「续接说明」**章节。

---

## 2.6 JWT + 认证模块落地规约（M1 沉淀）

### 2.6.1 密钥管理策略

| 环境 | 方式 | 文件位置 | git |
|---|---|---|---|
| dev | 文件 mount | `infra/jwt/dev-private.pem` / `dev-public.pem` | ✅ 允许提交（非生产密钥）|
| prod | 环境变量 / 密钥管理系统 | 容器内 mount 路径 | ❌ 绝不提交 |

- `.gitignore` 策略：`*.pem` 全局忽略 + `!infra/jwt/dev-*.pem` 白名单豁免
- `ATS_JWT_KEY_DIR` 环境变量：dev 默认 `../infra/jwt`（相对于 ats-backend/），Docker 内通过卷覆盖

### 2.6.2 Token 双轨架构

```
Access Token  RS256 JWT  15min TTL  → Authorization: Bearer <token>
Refresh Token 随机串(32B) 30d TTL  → HttpOnly Cookie, SameSite=Lax
              SHA-256 后存 DB，原值只在内存/cookie 里
```

**Rotation 策略**：每次 refresh 吊销旧 token，生成新 token（防 token 复用攻击）

### 2.6.3 Spring Security 配置要点

```java
// 放行清单（permitAll）：
// /health, /auth/register, /auth/login, /auth/refresh, /auth/logout
// GET /jobs, GET /jobs/*

// 关键：/auth/logout 必须 permitAll
// 原因：refresh cookie 过期前 access token 可能已失效，不能要求 Bearer 才能登出
```

### 2.6.4 PostgreSQL Enum 处理

MyBatis-Plus 默认用 `setString()` 写 PG enum 列会报 `column "role" is of type user_role but expression is of type character varying`。

**解决**：
1. 自定义 `PgEnumTypeHandler extends BaseTypeHandler<String>`，在 `setNonNullParameter` 里改用 `ps.setObject(i, value, Types.OTHER)`
2. 实体字段加 `@TableField(typeHandler = PgEnumTypeHandler.class)`
3. `@TableName(value = "xxx", autoResultMap = true)` —— SELECT 时 TypeHandler 才生效
4. `application.yml` 加 `type-handlers-package: com.ats.config`

### 2.6.5 前端认证 Store 架构

```
useAuthStore (Pinia)
├── accessToken: string | null     (内存，不持久化)
├── user: MeVO | null
├── login()                        → 调 /auth/login，setTokens
├── logout()                       → 调 /auth/logout，clearTokens，跳 /login
├── silentRefresh()                → 调 /auth/refresh（浏览器自动带 cookie）
└── initialize()                   → 页面刷新时调用，静默恢复登录态
```

**循环依赖处理**：`stores/auth` → `api/request` → `stores/auth` 的循环，通过在 axios interceptor 内用 `await import('@/stores/auth')` 懒加载解决（Vite 模块缓存，无性能损耗）。

**401 自动 refresh 并发控制**：
```
第一个 401 请求 → 发起 silentRefresh，设 isRefreshing = true
后续并发 401   → 进入 pendingQueue 排队等新 token
refresh 完成   → drainQueue 分发新 token，原请求全部重试
```

### 2.6.6 注册流程决策

| 角色 | 注册方式 | 端点 |
|---|---|---|
| CANDIDATE | 自助注册 | `POST /auth/register`（role 硬编码为 CANDIDATE）|
| HR | Admin 创建 | `POST /admin/users`（ADMIN 角色鉴权）|
| ADMIN | DB seed / 直接 SQL | 不开放 API（防权限提升）|

> ⚠️ `POST /admin/users` 的 role 字段必须通过 `@Pattern(regexp = "HR|CANDIDATE")` 校验，禁止创建 ADMIN。

### 2.6.7 后端测试分层（MVP 阶段）

> ⚡ **核心原则**：MVP 阶段坚决**不引入 Testcontainers / H2**。让单测在 10s 内跑完、CI 无 Docker 依赖、新人 `mvn test` 就过。SQL 正确性靠 dev compose 联调 + 后续 e2e 兜底。

**三层分工**（按"启动成本"由低到高，能下沉就下沉）：

| 层 | 工具 | 适用场景 | 启动成本 |
|---|---|---|---|
| **L1 · 纯 JUnit** | JUnit 5 + `@TempDir` | 算法 / 工具类 / 纯函数（如 JwtService 的 sign/verify/hash）| 0ms |
| **L2 · Mockito 单测** | `@ExtendWith(MockitoExtension)` + `@Mock` / `@InjectMocks` | Service 业务分支（所有 error path 必须覆盖）| ~500ms |
| **L3 · Web 集成** | `@WebMvcTest` + `@MockitoBean` + `@Import(SecurityConfig, Filter, Handler)` | 401 / 403 / `@PreAuthorize` / CSRF / 路径放行 | ~2.5s |

**关键技巧**：

1. **L1 不依赖外部文件**：用 `TestRsaKeyPair` helper 现场生成 RSA keypair 写入 `@TempDir`，跑完即删，CI/离线都能跑（不依赖 `infra/jwt/`）
2. **L2 用 `@Nested` 按方法分组**：`Register / Login / Refresh / Logout / Me` 五组，每组独立 setup，IDE 树形展示一目了然
3. **L3 用 `@WebMvcTest` 而非 `@SpringBootTest`**：只装 controller + security 链路，启动快 5×；`@MockitoBean`（Spring 6.2+）替换 Service / Mapper bean，无需 DB
4. **JJWT 0.12 mock claims**：`Claims` 接口已无 setter，必须用 `new DefaultClaims(map)` + `put(Claims.SUBJECT, ...)`
5. **CSRF disable 回归测试**：写一个 `noCsrfCookieIssued()` 显式验证无 XSRF-TOKEN 下发，防止有人偷偷把 `csrf.disable()` 改回去

**Mockito + JDK 24/25 兼容性**（Spring Boot 3.4.0 默认 mockito 5.14 在 JDK 25 上失效）：

```xml
<!-- pom.xml -->
<properties>
  <mockito.version>5.17.0</mockito.version>     <!-- 覆盖 BOM 默认 5.14 -->
  <byte-buddy.version>1.17.6</byte-buddy.version>
</properties>

<plugin>
  <artifactId>maven-surefire-plugin</artifactId>
  <configuration>
    <argLine>
      -XX:+EnableDynamicAgentLoading
      -javaagent:${settings.localRepository}/net/bytebuddy/byte-buddy-agent/${byte-buddy.version}/byte-buddy-agent-${byte-buddy.version}.jar
      -Xshare:off
    </argLine>
  </configuration>
</plugin>
```

> ⚠️ **症状**：`Mockito cannot mock this class ... Could not modify all classes` —— 别去查代码，先看 JDK 版本 + Mockito 版本对应表。Mockito 5.17 内置 byte-buddy 1.17 才适配 JDK 24+ 新的 ClassFile API。

**MyBatis-Plus `argThat` 编译歧义**：

```java
// ❌ 编译失败：BaseMapper 同时声明 insert(T) 和 insert(Collection<T>)
verify(userMapper).insert(argThat(u -> "alice".equals(u.getEmail())));

// ✅ 用类型化 helper 消除 lambda 推断歧义
private static User argThatUser(ArgumentMatcher<User> m) { return argThat(m); }
verify(userMapper).insert(argThatUser(u -> "alice".equals(u.getEmail())));
```

**测试 application-test.yml 关键**：

```yaml
# 仅供 @SpringBootTest / @WebMvcTest 使用；@ConfigurationProperties 启动校验需要值
# 但 JwtService 在 web 测试里也是 @MockitoBean，不会真去读 keypair
ats:
  jwt:
    key-dir: build/test-jwt       # 假路径
    private-key-file: priv.pem
    public-key-file: pub.pem
    access-ttl-seconds: 900
    refresh-ttl-seconds: 86400
    issuer: ats.test
```

**M1 测试覆盖参考矩阵**（43 case / 10s）：

| 类 | Case 数 | 覆盖点 |
|---|---|---|
| `JwtServiceTest` | 8 | sign + verify happy / 篡改 / 过期 / 错 issuer / 垃圾输入 / refresh 唯一 / hash 确定 / TTL |
| `AuthServiceTest` | 17 | register × 2 / login × 4 / refresh × 6 / logout × 3 / me × 2 |
| `WebSecurityIntegrationTest` | 18 | 401 × 4 / 角色守卫 × 4 / Auth 路径 × 7 / CSRF 回归 × 3 |

**M2 状态机 / 业务服务测试矩阵**（71 case 新增，total 114 / 15s）：

| 类 | Case 数 | 覆盖点 |
|---|---|---|
| `JobStatusMachineTest` | 35 | 8 合法边 + 3 require 不抛 + 12 非法 + 5 自环禁止 + 6 边界 + 1 异常 message 上下文 |
| `JobServiceTest` | 17 | create × 4（含 salary 反向 + tagId 不存在 + 未登录）/ update × 5 / transition × 4 / softDelete × 2 / getDetail × 4 |
| `JobControllerSecurityTest` | 17 | 公开 × 5（list/detail/tags + 404/403 错误码映射）/ create × 5（401/403/200/200/400）/ transition × 4（409/403 错误码映射）/ delete × 3 |

**L1 状态机测试模式**（强烈推荐，新业务实体都套用）：

```java
@Nested @DisplayName("合法流转")
class Legal {
  @ParameterizedTest(name = "[{index}] {0} → {1}")
  @CsvSource({ "DRAFT,PUBLISHED", "PUBLISHED,CLOSED", ... })  // 列全所有合法边
  void canTransition_returnsTrue(JobStatus from, JobStatus to) {
    assertThat(JobStatusMachine.canTransition(from, to)).isTrue();
  }
}

@Nested @DisplayName("非法流转 · 含自环")
class Illegal {
  @ParameterizedTest @CsvSource({ "PUBLISHED,DRAFT", ... })   // 列出典型反例
  void canTransition_returnsFalse(JobStatus from, JobStatus to) { ... }

  @ParameterizedTest @EnumSource(JobStatus.class)              // 自环全枚举一遍
  void selfLoop_isIllegal(JobStatus s) {
    assertThat(JobStatusMachine.canTransition(s, s)).isFalse();
  }
}
```

> 💡 **35 case 看似多，跑完 &lt; 100ms**，覆盖度高、回归保护强、文档化效果好（CSV 即真理表）。

**L2 SecurityContext 注入模式**（Service 单测要读 `SecurityUtil.requireUserId()` 时必备）：

```java
@BeforeEach void setUp() { SecurityContextHolder.clearContext(); }
@AfterEach  void tearDown() { SecurityContextHolder.clearContext(); }

private static void setAuth(long userId, String role) {
  var auth = new UsernamePasswordAuthenticationToken(
      String.valueOf(userId), null,
      List.of(new SimpleGrantedAuthority("ROLE_" + role)));
  SecurityContextHolder.getContext().setAuthentication(auth);
}
```

> ⚠️ 必须 `@AfterEach` 清空，否则用例污染顺序敏感。

**L2 Mockito stub 冲突陷阱**（M2.5 踩到）：

```java
// ❌ 默认 stub 与具体 case 冲突：service 内部用 selectCount 校验 tagIds.size,
//    默认 99L 会让 happyPath（提供 2 个 tag）误抛 TAG_NOT_FOUND
@BeforeEach void setUp() {
  when(tagMapper.selectCount(any())).thenReturn(99L);  // ← 陷阱
}

// ✅ 关键校验类 stub 不设默认，按 case 显式 stub
@BeforeEach void setUp() {
  // 只 stub 与业务校验无关的辅助方法（dept/user batch 查空列表）
}

@Test void happyPath() {
  when(tagMapper.selectCount(any())).thenReturn(2L);  // 与 tagIds.size 对齐
  ...
}
```

> 💡 **判断标准**：被 service 用来"做校验比对"的 stub（count/exists）一定按 case 显式给；被 service 用来"拼数据"的 stub（batch select）可以默认空集合。

**L3 `@MapperScan` 隐式依赖陷阱**（M2.5 踩到，最大坑）：

```text
症状：@WebMvcTest 加载失败 → BeanCreationException:
  Property 'sqlSessionFactory' or 'sqlSessionTemplate' are required
```

`@WebMvcTest` **不启用 MyBatis 自动配置**，但 `@MapperScan`（通常在 main `@SpringBootApplication` 上）依然会扫描到所有 Mapper 接口并尝试创建 bean，导致缺 `sqlSessionFactory` 报错。修复必须**一次性 mock 项目所有 mapper**：

```java
@WebMvcTest(controllers = { JobController.class, TagController.class })
@Import({ SecurityConfig.class, JwtAuthenticationFilter.class, ... })
class JobControllerSecurityTest {
  @MockitoBean JwtService jwtService;
  @MockitoBean JobService jobService;   // ← 上层 service
  @MockitoBean TagService tagService;

  // ⚠️ 关键：项目所有 mapper 都要 mock，缺一个就 sqlSessionFactory required
  @MockitoBean JobMapper jobMapper;
  @MockitoBean TagMapper tagMapper;
  @MockitoBean JobTagMapper jobTagMapper;
  @MockitoBean UserMapper userMapper;
  @MockitoBean RefreshTokenMapper refreshTokenMapper;
  @MockitoBean PasswordEncoder passwordEncoder;
}
```

> ⚠️ **每加一个 Mapper（M3/M4），所有现有 `@WebMvcTest` 类都要补 `@MockitoBean`，否则反向坏掉**。M2 加 JobMapper/TagMapper/JobTagMapper 后，M1 的 `WebSecurityIntegrationTest` 立刻全红，必须同步补 mock。
> 💡 **替代方案**（暂未采用）：抽个 `@TestConfiguration` 基类一次声明所有 mapper mock，让各 `@WebMvcTest` 类 `@Import` 复用；MVP 阶段直接复制粘贴更直接。

**L3 错误码 → HTTP 映射验证**（M2.5 模式，业务码越多越值钱）：

```java
@Test void transitionIllegal_returns409() throws Exception {
  when(jobService.transition(anyLong(), any()))
      .thenThrow(new BizException(ErrorCode.ILLEGAL_TRANSITION, "..."));
  mvc.perform(post("/jobs/1/transitions").content("{\"to\":\"DRAFT\"}").contentType(JSON))
     .andExpect(status().isConflict())                                    // ← 验证 HTTP
     .andExpect(jsonPath("$.code").value(ErrorCode.ILLEGAL_TRANSITION.getCode())); // ← 验证业务码
}
```

> 💡 **GlobalExceptionHandler 修改 mapStatus 时，对应错误码必须有 L3 测试守门**，否则一旦把 409 改成 400 也不会报警。

---

## 2.7 状态机看板落地规约（M3 沉淀）

### 2.7.1 后端状态机模式（与 M2 JobStatusMachine 完全同构）

```java
public final class XxxStageMachine {
    private static final Map<Stage, Set<Stage>> ALLOWED;
    public static final Set<Stage> TERMINAL_STAGES;

    public static boolean canTransition(Stage from, Stage to) { ... }
    public static void requireTransition(Stage from, Stage to) {
        if (isTerminal(from)) throw new BizException(STAGE_TERMINATED, ...);
        if (!canTransition(from, to)) throw new BizException(ILLEGAL_TRANSITION,
            "非法流转：" + from + " → " + to + "，允许的下一步：" + nextStages(from));
    }
    public static Set<Stage> nextStages(Stage from) { ... }
    public static boolean isTerminal(Stage s) { ... }
}
```

**关键规则**：

1. **静态 EnumMap + EnumSet** 构建 ALLOWED 图，O(1) 查询，0 GC 压力。
2. **错误消息附带 from→to + 允许列表**，前端可直接 toast 不需要再翻文档。
3. **终态保护**：HIRED/REJECTED 这种"死亡线"用单独的 `TERMINAL_STAGES` 集合 + `APPLICATION_TERMINATED` 错误码区分（vs `ILLEGAL_TRANSITION`），便于前端给出"已是终态，无法变更"的友好提示。
4. **3 套测试全部要写**：合法边（含横切的 reject 边）+ 非法（跳级 / 回退 / 自环用 `@EnumSource`）+ 终态保护（用 `@EnumSource` 遍历所有目标，全部应抛 TERMINATED）。

### 2.7.2 看板拖拽：HTML5 原生 dnd vs 第三方 lib

**结论**：MVP 阶段强烈推荐 HTML5 原生 dnd（Vue 3 + 原生事件即可），**不引 vuedraggable / sortablejs**。

**为什么**：

| 维度 | HTML5 原生 | vuedraggable / sortablejs |
|---|---|---|
| 包体增量 | 0 | +200KB |
| Chromium 桌面端 | 稳如磐石 | 同样稳 |
| 触摸设备 | 需 polyfill | 自带 |
| 代码量 | ~80 行（4 事件 + 1 ref） | ~50 行（v-model + handler） |
| 视觉自定义 | 任意 CSS class | 受 helper class 约束 |

**最小落地骨架**：

```vue
<script setup>
const dragState = ref<{ id: number, fromStage: Stage } | null>(null)
const hoverStage = ref<Stage | null>(null)

function onCardDragStart(e, item) {
  if (isTerminal(item.stage)) { e.preventDefault(); return }
  dragState.value = { id: item.id, fromStage: item.stage }
  e.dataTransfer.effectAllowed = 'move'
}
function onColumnDragOver(e, target) {
  if (!dragState.value) return
  if (!canTransition(dragState.value.fromStage, target)) return  // ← 0 RT 预校验
  e.preventDefault()
  hoverStage.value = target
}
async function onColumnDrop(e, target) {
  e.preventDefault()
  const drag = dragState.value; dragState.value = null
  if (!drag || !canTransition(drag.fromStage, target)) return
  // 乐观更新：先搬卡片
  const moved = removeFromCol(drag.fromStage, drag.id)
  insertToCol(target, moved)
  try { await api.transition(drag.id, { toStage: target }) }
  catch (e) { rollback(); message.error(e.message) }  // ← 失败回滚
}
</script>
```

**视觉编排**（`.board-col`）：

```css
.board-col.is-allowed { border-color: var(--accent); box-shadow: 0 0 0 1px var(--accent); }
.board-col.is-dim     { opacity: 0.42; }
.board-col.is-hover   { background: color-mix(in oklab, var(--accent) 8%, var(--bg)); transform: translateY(-1px); }
```

> 💡 **draggable 属性**：终态卡片必须 `:draggable="!isTerminal(item.stage)"`，否则用户拖动看板已 HIRED 的卡片会触发 dragstart 但 dragover 总返回 false，体验割裂。

### 2.7.3 前端镜像状态机

后端 `ApplicationStageMachine.ALLOWED` 在前端 `api/applications.ts` 镜像一份：

```ts
export const STAGE_TRANSITIONS: Record<Stage, Stage[]> = { APPLIED: ['SCREENING_PASS', 'REJECTED'], ... }
export function canTransition(from, to) { return STAGE_TRANSITIONS[from]?.includes(to) ?? false }
```

**好处**：拖拽 dragover 时 0 RT 即时反馈合法性，避免每次问后端。**风险**：状态机迁移时前后端要同步改。**可接受性**：状态机一旦定型很少变；MVP 阶段 5-8 态以内，复制 1 份成本极低。

### 2.7.4 乐观更新 + 失败回滚

看板拖拽**必须**乐观更新，否则每次拖拽都要等 200-500ms 网络往返，体验断裂。

```ts
async function commitTransition(id, from, target, note) {
  // 1. 先在 UI 搬卡片
  const moved = colFrom.items.splice(idx, 1)[0]
  moved.stage = target
  colTo.items.unshift(moved)
  colFrom.count--; colTo.count++

  try {
    await api.transition(id, { toStage: target, note })
  } catch (e) {
    // 2. 失败回滚到原列原位
    colTo.items.shift()
    moved.stage = from
    colFrom.items.splice(idx, 0, moved)
    colFrom.count++; colTo.count--
    message.error(e.message)
  }
}
```

> ⚠️ **关键细节**：(a) 回滚时必须把卡片插回**原 idx**（不是 unshift），保持顺序稳定；(b) `count` 字段也要同步增减，否则列头计数会漂；(c) `moved.stage` 也要回退（因为 splice 出来的是引用，会泄漏到详情 Drawer）。

### 2.7.5 NSelect 哨兵值（NSelect option value 不能为 null）

Naive UI 的 `SelectOption['value']: string | number`，**无法直接传 null**（type error）。

**反模式**：

```ts
const options = [
  { label: '所有岗位', value: null },   // ← TS 报错
  ...
]
```

**正解**（用 sentinel 数字 + 内部转 undefined）：

```ts
const ALL_SENTINEL = -1
const selectedJobId = ref<number>(-1)
const effectiveJobId = computed(() => selectedJobId.value === ALL_SENTINEL ? undefined : selectedJobId.value)
const options = computed<SelectOption[]>(() => [
  { label: '所有岗位', value: ALL_SENTINEL },
  ...
])
```

### 2.7.6 oxlint `no-use-before-define` · setup script 顺序

Vue 3 setup script 是**顺序求值**的：

```vue
<script setup>
function onDrop() {
  pendingReject.value = ...  // ❌ oxlint: no-use-before-define
}
const pendingReject = ref(null)
</script>
```

**修复**：把所有被函数引用的 ref 声明前置到所有 function 之前，再写函数。或者 `oxlint-disable-next-line` 但 MVP 阶段还是规范一点好。

### 2.7.7 看板 schema：8 列固定顺序 + 计数为 0 也要返回空列

**反模式**：service 只返回 mapper 查到的非空列，前端被迫做"补齐缺失列"。

**正解**（service 端补齐）：

```java
private static final List<Stage> BOARD_ORDER = List.of(APPLIED, SCREENING_PASS, ..., REJECTED);

public BoardVO board(Long jobId, int itemsPerColumn) {
    Map<Stage, Long> counts = ...; // 从 mapper 拿
    List<BoardColumnVO> cols = new ArrayList<>();
    for (Stage st : BOARD_ORDER) {
        long count = counts.getOrDefault(st, 0L);
        List<Item> items = count == 0 ? List.of() : mapper.listItems(jobId, hrUserId, st, limit);
        cols.add(BoardColumnVO.builder().stage(st).count(count).items(items).build());
    }
    return BoardVO.builder().columns(cols).build();
}
```

> 💡 **这样前端可以直接 `v-for="col in board.columns"`**，不需要再 mergeWithDefaults，UI 代码极简。

### 2.7.8 monorepo 根脚本转发（避免 cd 来回切）

每加一个子项目，root `package.json` 加一行转发：

```json
{
  "scripts": {
    "fe:dev":       "cd ats-frontend && bun run dev",
    "fe:typecheck": "cd ats-frontend && bun run typecheck",
    "fe:lint":      "cd ats-frontend && bun run lint",
    "fe:check":     "cd ats-frontend && bun run typecheck && bun run lint",
    "be:dev":       "cd ats-backend && mvn spring-boot:run",
    "be:test":      "cd ats-backend && mvn -B test",
    "be:build":     "cd ats-backend && mvn -B package -DskipTests"
  }
}
```

> ⚠️ Windows 没有 `mvnw` shell wrapper（除非 Git Bash），要么生成 `mvnw.cmd`，要么直接用全局 `mvn`。MVP 阶段后者更简单。

### 2.7.9 `@MapperScan` 陷阱再次警告（M3 第二次踩）

**每加一个 Mapper，所有 `@WebMvcTest` 类都要补 `@MockitoBean`**。M3 加了 `ApplicationMapper` + `StageLogMapper`，必须立刻同步到 `WebSecurityIntegrationTest` + `JobControllerSecurityTest` + 新写的 `ApplicationControllerSecurityTest`，否则 M1/M2 测试反向变红。

**长期方案**（M4+ 考虑）：抽 `BaseWebMvcTest` 父类用 `@TestConfiguration` 一次性声明所有 mapper mock；但 MVP 阶段直接复制粘贴更直接。

### 2.7.10 双轨页面语言：HR 克制 + 候选人张扬（再次实践）

| 页面 | 角色 | 视觉语言 | 关键武器 |
|---|---|---|---|
| `views/hr/jobs.vue` | HR | 克制 | NDataTable 信息密度 |
| `views/hr/board.vue` | HR | 克制 + 微张扬 | 8 列 grid + 拖拽高亮 + 状态机色板 |
| `views/jobs.vue` | 候选人 | 张扬 + 克制 hero | aurora 装饰 / kicker eyebrow / 卡片进度条 |
| `views/me/applications.vue` | 候选人 | 张扬 | 进度条 + 时间线 + reject_reason 高亮区 |

> 💡 **看板用克制路线**：HR 高频操作的工作台必须信息密度 > 视觉炫技。状态机色板（每列 stage 一个 accent 色）是看板唯一的"张扬"点。

### 2.7.10.1 高频终态的「快路径浮动投放区」

**问题**：8 列流水线把 REJECTED 钉在最末尾，但「拒绝」是从任意阶段都可达的高频操作（每条非终态记录都至少有一条出边指向 REJECTED）。HR 在小屏 / 横向滚动到中段时，把卡片拖到最右侧极远 —— 实测 1280px 视口下要拖 800-1000px。

**解法**：拖拽期间在视口右下浮出**固定的「拖到此一键拒绝」投放区**，dragend 自动消失。它本质上是 REJECTED 列的**视觉别名**（不复制状态，复用同一套 dragover/drop handler，target='REJECTED'），所以：

- **0 状态新增**：`@dragover="onColumnDragOver($event, 'REJECTED')"` / `@drop="onColumnDrop($event, 'REJECTED')"` 直接复用列的 handler，REJECTED 列依然在原位（保留 8 态视觉一致性 + 看历史功能）；
- **0 业务分支**：drop 后照样走 `pendingReject` → reject Drawer → `commitTransition`，乐观更新 / 回滚链条不动；
- **入场动画 ≤ 220ms**：`opacity 0→1` + `translateY 8px→0`，避免突兀；hover 时 dashed → solid + 微 scale，给「确认要落到这」的视觉锚点；
- **小屏 < 640px**：左右 12px 贴底拉满（`right:12px; left:12px; bottom:12px;`），不会和列横滚条打架。

**关键判定**：

```ts
const canRejectFromDrag = computed(() =>
  dragState.value !== null && canTransition(dragState.value.fromStage, 'REJECTED'),
)
```

`v-show="canRejectFromDrag"` 双重保险：终态卡片本来 `:draggable="false"` 不会触发 dragstart，但状态机若以后调整（比如某些 stage 拒绝按钮要禁用），这里能自动跟随，不破。

> ⚠️ **z-index 谨慎选**：浮动区给 `1500`（高于看板，低于 NMessage / 全局 toast 4000+）。给到 9999 会盖过 message.success 的成功反馈，破体验。
>
> 💡 **同模式可复用场景**：M4 文件上传若需「拖文件到任意位置上传」，也是同一套 fixed 浮动接收区 + `dragover/drop` 全局监听。这是 **「高频终态/全局意图」 vs 「列状态机」** 的通用 UX 解耦手法。

### 2.7.11 PG `timestamptz` × 原生 SQL `Map<String,Object>` × 强转 OffsetDateTime

**踩坑**：M3 看板 / 详情走原生 SQL（join 查询拼接 user 信息）用 `List<Map<String,Object>>` 接住结果，里面的 `timestamptz` 字段直接 `(OffsetDateTime) row.get("applied_at")` —— 单测全绿（mock 给的就是 OffsetDateTime），上线 E2E 立刻 500：

```
java.lang.ClassCastException: class java.sql.Timestamp cannot be cast to class java.time.OffsetDateTime
    at ApplicationService.toStageLogVO(ApplicationService.java:336)
```

**根因**：
- MyBatis 在用 entity（带 `@TableField` 或 `typeHandler`）时会自动把 PG `timestamptz` 转成 `OffsetDateTime`；
- 但走 `Map<String, Object>` 这条"无类型"路径时，**MyBatis 直接走 JDBC 默认 typeHandler**，PG JDBC driver 在缺乏目标类型提示时返回 `java.sql.Timestamp`，强转必崩。

**为什么单测没拦住**：service 单测用 Mockito 注入了 `Map.of("applied_at", OffsetDateTime.now(), ...)`，路径覆盖到了，类型却"作弊"了 —— mock 数据和真实 JDBC 返回值类型不一致。

**修复**（最小侵入，不动 mapper）：在 service 里加一个统一的 helper 兼容所有时间类型，把所有 `(OffsetDateTime) row.get("xxx_at")` 都换成 `toOffsetDateTime(row.get("xxx_at"))`：

```java
private static OffsetDateTime toOffsetDateTime(Object v) {
    if (v == null) return null;
    if (v instanceof OffsetDateTime odt) return odt;       // 走 entity / mock 路径
    if (v instanceof Timestamp ts) {                        // 走 Map<String,Object> 真实路径
        return ts.toLocalDateTime().atZone(ZoneId.systemDefault()).toOffsetDateTime();
    }
    if (v instanceof LocalDateTime ldt) return ldt.atZone(ZoneId.systemDefault()).toOffsetDateTime();
    if (v instanceof java.util.Date d) return d.toInstant().atZone(ZoneId.systemDefault()).toOffsetDateTime();
    throw new IllegalStateException("不支持的时间类型: " + v.getClass());
}
```

> 💡 **后续防御**：M4+ 引入新表前评估 —— 如果有原生 SQL + Map 接收 + timestamptz 字段三件套，**默认走 helper**，永远不直接强转。
>
> 🔧 **可选硬核方案**：在 mapper XML 里给每个时间列显式声明 `<result column="applied_at" property="appliedAt" javaType="java.time.OffsetDateTime"/>`，但需要把 Map 改成 DTO，相比 helper 工作量大很多，MVP 阶段不划算。
>
> 📌 **测试启示**：service 单测里的 mock Map 应该至少有一份"真实类型"的契约测试（`Map.of("applied_at", new Timestamp(...))`），把这种 JDBC 默认类型路径覆盖进来，避免下次再踩。

## 2.8 文件上传通用规约（M4 沉淀）

### 2.8.1 三件套：UploadProperties + FileCategory + LocalFileStorage

**典型分层**（M4 ATS 实战）：

```
ats.upload.path         → UploadProperties (@ConfigurationProperties)
                        ↓
FileCategory enum       → 白名单（MIME + 扩展名 + 子目录）
   RESUME → resumes/, application/pdf, .pdf
                        ↓
FileStorage 接口        → 抽象（save / load / detectContentType）
   LocalFileStorage     → MVP 实现（生产换 S3/OSS/MinIO 不动调用方）
                        ↓
FileService             → 业务校验（双层 size：servlet hard + service soft）
                        ↓
FileController          → POST /files/upload + GET /files/**
```

**关键设计点**：

1. **UUID v4 文件名** + `yyyy-MM` 子目录：122 bit 熵不可枚举 + 月份分桶降低单目录文件数。
2. **FileCategory enum 白名单**：每个分类独立 MIME + 扩展名集合，`validate(contentType, ext)` 双校验，防止"PDF 接口被当图床"。
3. **路径穿越防御**：`ensureWithinRoot(resolved)`，解析后绝对路径必须 `startsWith(uploadRoot)`，否则拒绝。处理 `..` / 符号链接 / 绝对路径注入。
4. **双层 size 校验**：
   - `spring.servlet.multipart.max-file-size: 5MB` 硬拦截 → `MaxUploadSizeExceededException` → 413
   - `FileService` 用 `props.maxFileMb` 软校验 → 统一 `FILE_TOO_LARGE` 业务码 → 413
   - 双层冗余的好处：servlet 层早断（不消费完整 body），service 层给业务化错误信息

### 2.8.2 错误码 → HTTP 映射约定（M4 增补）

| 错误码 | HTTP | 备注 |
|---|---|---|
| `FILE_TYPE_NOT_ALLOWED` (30001) | **415 Unsupported Media Type** | 比 409 更 RESTful 标准 |
| `FILE_TOO_LARGE` (30002) | **413 Payload Too Large** | 来自 servlet 层或 service 层 |
| `FILE_NOT_FOUND` (30003) | **404 Not Found** | 含路径穿越拦截 |

> 💡 **下载鉴权简化原则**（MVP 阶段）：`@PreAuthorize("isAuthenticated()")` 即可。靠 UUID 不可枚举 + URL 仅在合法链路（application 当事人 / owner HR / ADMIN）暴露形成自然边界。生产再加"按 url 反查 application"。

### 2.8.3 GET /files/\*\* 多级路径捕获

**反模式**：`req.getServletPath()` 在 Spring 6 + Tomcat 嵌入式下可能返回空，导致 `null.startsWith()` NPE 500（M4 踩坑）。

**正模式**：

```java
@GetMapping("/**")
public ResponseEntity<Resource> download(HttpServletRequest req) {
    String uri = req.getRequestURI();           // 原始 URI 始终有值
    String contextPath = req.getContextPath();  // /api/v1
    if (contextPath != null && !contextPath.isEmpty() && uri.startsWith(contextPath)) {
        uri = uri.substring(contextPath.length());
    }
    // uri = /files/resumes/2026-05/xxx.pdf
    // ...
}
```

### 2.8.4 axios FormData 上传必须显式覆盖 Content-Type

**反模式**（默认 `application/json` 污染）：

```ts
// request.ts 默认 Content-Type: application/json
return post('/files/upload', formData)  // ❌ 后端拿不到 multipart boundary
```

**正模式**：

```ts
return post('/files/upload', formData, {
  headers: { 'Content-Type': 'multipart/form-data' },  // ← axios 自动加 boundary
})
```

### 2.8.5 自定义 file input vs NUpload

**判断标准**：

| 场景 | 推荐 |
|---|---|
| 需要进度条 / 多文件队列 / 拖拽 | NUpload |
| 单文件上传 + 自定义虚线 dropzone + 上传中态 + 移除按钮 | hidden `<input type="file">` + 自定义 div |

**MVP 倾向后者**：与看板"浮动拒绝区"等设计语言一致，CSS 完全可控，轻量。

```vue
<input ref="fileRef" type="file" :accept="..." class="hidden" @change="onChange">
<div v-if="!attached" class="uploader" @click="fileRef.click()">点击选择 ...</div>
<div v-else class="attached">{{ attached.name }} <button @click="remove">移除</button></div>
```

### 2.8.6 编辑窗口模式（24h + ADMIN bypass）

**问题**：UGC 系统都有"作者改错的窗口" vs "审计完整性"的张力。

**ATS M4 决策**：

```java
private static final long EDIT_WINDOW_HOURS = 24;

if (!isAdmin) {
    if (!isAuthor) throw INTERVIEW_EDIT_FORBIDDEN;
    if (isOutsideEditWindow(createdAt)) throw INTERVIEW_EDIT_EXPIRED;
}
```

**关键约定**：

1. **窗口长度按业务定**：面试评价 24h（次日还能改）；评论可短到 5 分钟；订单备注一般不允许改。
2. **ADMIN 必须能 bypass**：用于人工修复脏数据 + 申诉处理；这种"超级权限"不能省。
3. **同岗位 owner HR ≠ 作者**：哪怕你管这个岗位，别人面试的评价你也不能改 ——「谁面试谁负责」。这是 ATS 业务特定，其他场景按需调整。
4. **VO 返回 `editable` 字段**：service 在响应时根据 SecurityUtil + createdAt 算好返回，前端零额外往返决定按钮显隐。

> 💡 **测试启示**：编辑窗口边界用 `OffsetDateTime.now().minusHours(N)` 直接构造，覆盖 `0h / 23h / 24h / 100h` 四点确保不漏边界。

### 2.8.7 setup script 编辑铁律（第三次踩 no-use-before-define）

**已经第三次踩了**（M3 拒绝 modal、M4 面试 ref），形成铁律：

> **凡是写 `async function openDetail/openXxxForm` 时，所有它引用的 ref 必须在它之前声明。**

**实践模板**：

```vue
<script setup>
// 1. 全局 imports
// 2. 路由 / store
// 3. 所有顶层 ref / reactive / computed —— 一次性堆在前面
const drawerVisible = ref(false)
const detail = ref(null)
const interviews = ref([])           // ← 先声明
const interviewFormVisible = ref(false)

// 4. 所有 async / sync function —— 此时 setup 已执行到这里，所有 ref 都已 init
async function openDetail(id) {
  interviews.value = []              // ← 安全引用
  interviewFormVisible.value = false
}
</script>
```

**反模式**：

```vue
<script setup>
async function openDetail(id) {
  interviews.value = []  // ❌ TDZ + oxlint no-use-before-define
}
const interviews = ref([])
</script>
```

> ⚠️ Vue setup 的 `<script setup>` 是**顺序求值**的（不是 hoisting），所以 ref 必须早于使用它的 function。每次新加 ref 时**自查一遍**：是否被某个上面的 function 引用？是 → 提到 function 之前。

## 2.9 数据看板 + 部署交付规约（M5 沉淀）

### 2.9.1 SQL 切片复用：service 单一来源 + mapper 多视角

**痛点**：M5.1 数据看板的 funnel 与 M3 看板共用 `applications + jobs` 数据切片（jobId 选填、hrUserId 选填，ADMIN 看全部）。

**规约**：

- **mapper 是切片真值**：`ApplicationMapper.countByStage(jobId, hrUserId)` 同时服务 board 列计数 + funnel；新写 mapper 时**先想"这个切片其他模块要不要复用"**
- **service 调用方决定语义**：StatsService 把 ADMIN→`null` / HR→`userId` / CANDIDATE→直接 `BizException(FORBIDDEN)` 这套权限逻辑独立成 `effectiveHrUserId()` helper（与 ApplicationService.board / InterviewService 完全同构）
- **8 态固定顺序补 0**：mapper 只返回有数据的 stage 行，service 必须按 `STAGE_ORDER` 8 态固定输出，缺失补 0。前端约定：永远收 8 行，不需判空

```java
private static final List<ApplicationStage> FUNNEL_ORDER = List.of(
    APPLIED, SCREENING_PASS, PHONE_INTERVIEW, TECH_INTERVIEW,
    HR_INTERVIEW, OFFER, HIRED, REJECTED
);

Map<ApplicationStage, Long> counts = new HashMap<>();
for (Map<String, Object> row : rows) {
    counts.put(ApplicationStage.valueOf((String) row.get("stage")),
               ((Number) row.get("cnt")).longValue());
}
List<FunnelItemVO> items = FUNNEL_ORDER.stream()
    .map(s -> FunnelItemVO.builder().stage(s).count(counts.getOrDefault(s, 0L)).build())
    .toList();
```

### 2.9.2 业务时区在 service 算 since，不用 SQL `NOW()`

**痛点**：本月起点用 `WHERE applied_at >= date_trunc('month', NOW())` 看似简洁，实际：

1. **测试不可控**：单测时无法注入"假的本月起点"，必须依赖真实当前时间
2. **DB 时区漂移**：postgres 容器 TZ 与业务时区可能不同（特别多人多机部署时）

**规约**：service 内用 `LocalDate.now(BIZ_ZONE).withDayOfMonth(1).atStartOfDay(BIZ_ZONE).toOffsetDateTime()` 计算 `since`，作为参数传给 mapper。`BIZ_ZONE` 与 `application.yml` 的 `jackson.time-zone` 对齐（本项目 `Asia/Shanghai`）。

```java
static final ZoneId BIZ_ZONE = ZoneId.of("Asia/Shanghai");

static OffsetDateTime monthStart() {
    return LocalDate.now(BIZ_ZONE).withDayOfMonth(1)
            .atStartOfDay(BIZ_ZONE).toOffsetDateTime();
}
```

### 2.9.3 0 第三方依赖 SVG / CSS 漏斗图（vs ECharts）

**为什么不用 ECharts**：

- 包体 ~200KB+ 仅为画 1 个 8 态条形图
- 与项目"克制 + 张扬混搭"的定制 UI 调性不一致（ECharts 默认风格强烈）
- 数据简单（8 行 stage × count），CSS 完全够用

**纯 CSS 实现**：

```vue
<li v-for="item in funnel.items" :key="item.stage" class="funnel-row">
  <span class="row-label">{{ STAGE_LABEL[item.stage] }}</span>
  <div class="row-bar-wrap">
    <span class="row-bar" :style="{
      width: `${widthOf(item.count, funnel.max)}%`,
      background: STAGE_GRADIENT[item.stage],
    }" />
    <span class="row-count">{{ item.count }}</span>
  </div>
</li>
```

```ts
function widthOf(count: number, max: number) {
  if (max === 0) return 0
  // 最小可见宽度 4%，避免 count=0 完全消失
  return Math.max(count === 0 ? 0 : 4, (count / max) * 100)
}
```

**关键技巧**：

- `STAGE_GRADIENT` 把 stage → 渐变色硬编码（语义化：起点 brand 绿 / 面试段渐进青蓝 / OFFER 琥珀 / HIRED 金绿 / REJECTED 灰红）
- 后端返回 `max` 字段（同时算 `total`），前端不重新计算
- 最小宽度 4% 让 count=0 stage 也能看到一条灰色细线（透明度 0.45），用户能识别"这一态尚无候选人"
- `transition: width 0.6s` cubic-bezier 让数据加载完后条形从 0 → 目标宽度有动画感

### 2.9.4 多阶段 Dockerfile 模式

**后端 Dockerfile（builder + runtime 两段）**：

```dockerfile
FROM maven:3.9-eclipse-temurin-21-alpine AS builder
WORKDIR /build
COPY pom.xml .
RUN mvn -B -q -DskipTests dependency:go-offline   # ← 先抓依赖，pom 不变就 cache
COPY src ./src
RUN mvn -B -q -DskipTests package && cp target/*.jar /build/app.jar

FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN addgroup -S ats && adduser -S ats -G ats \
    && mkdir -p /app/uploads /app/jwt && chown -R ats:ats /app
USER ats                                          # ← 非 root 运行
COPY --from=builder /build/app.jar app.jar
ENV JAVA_TOOL_OPTIONS="-XX:MaxRAMPercentage=75 -Djava.security.egd=file:/dev/./urandom"
HEALTHCHECK CMD wget -qO- http://127.0.0.1:8080/api/v1/health > /dev/null || exit 1
ENTRYPOINT ["java", "-jar", "app.jar"]
```

**前端 Dockerfile（bun build → nginx serve）**：

```dockerfile
FROM oven/bun:1.3-alpine AS builder
WORKDIR /build
COPY package.json bun.lock* ./
RUN bun install --frozen-lockfile
COPY . .
ENV VITE_API_BASE_URL=/api/v1                      # ← 与 nginx 反代路径对齐
RUN bun run build

FROM nginx:1.27-alpine
WORKDIR /usr/share/nginx/html
RUN rm -rf ./*
COPY --from=builder /build/dist ./
COPY nginx.conf /etc/nginx/conf.d/default.conf
```

**关键点**：

- 先 `COPY pom.xml / package.json` + 跑依赖下载，再 `COPY src/` —— 这一步把 dependency 层独立 cache，源码变动不重新下依赖
- 后端用 jre-alpine（不是 jdk）省 ~150MB
- 非 root 用户 + 显式 `mkdir uploads jwt && chown` —— 容器逃逸受限 + volume 挂载点权限正确
- `JAVA_TOOL_OPTIONS` 而非 `JAVA_OPTS`：JVM 直接读，不需启动脚本转发
- HEALTHCHECK 直接打业务 endpoint，不要单独 actuator（少一个 endpoint = 少一个攻击面）

### 2.9.5 nginx 反代 SPA + API 双轨

```nginx
# 静态资源长缓存（vite 产物已 hash）
location ~* \.(?:css|js|woff2?|ttf|svg|png|jpe?g|webp|ico)$ {
    expires 30d;
    add_header Cache-Control "public, max-age=2592000, immutable";
    try_files $uri =404;
}

# SPA 路由：所有非 API 命中回退 index.html
location / {
    try_files $uri $uri/ /index.html;
    add_header Cache-Control "no-cache, must-revalidate";
}

# API 反代到 backend service
location /api/ {
    proxy_pass         http://backend:8080/api/;       # ← 注意末尾斜杠对齐
    proxy_set_header   Host              $host;
    proxy_set_header   X-Forwarded-Proto $scheme;
    proxy_read_timeout 30s;
    client_max_body_size 10m;                          # ← 给 multipart 留 buffer
}
```

**踩坑**：

- `proxy_pass http://backend:8080/api/` 必须保留末尾 `/`，否则 nginx 不替换前缀，`/api/v1/jobs` 会拼到 `/api/api/v1/jobs`
- `client_max_body_size` 要 ≥ 后端 `spring.servlet.multipart.max-file-size`，否则 nginx 先 413 拦截，错误码不可控
- 静态资源 `immutable` cache 必须配 vite 的 hash 文件名（默认就是）
- index.html 显式 `no-cache` —— 否则发版后用户浏览器拿到旧 index 引用旧 hash 的 chunk，404

### 2.9.6 一键发布脚本（cross-platform pwsh + bash）

**两套脚本同源同义**：

- `infra/scripts/release.ps1`（Windows · PowerShell 7+）
- `infra/scripts/release.sh`（Linux / macOS · bash）

**统一流程**（5 步）：

1. **校验 `.env.prod` 存在** → 不存在直接报错给出 `cp .env.prod.example .env.prod` 提示
2. **校验 prod JWT keypair** → 防止 dev key 误带到 prod；不存在给出 `openssl genrsa` 命令
3. **跑后端测试**（可 `--skip-tests` 跳过）
4. **构建 image**（可 `--skip-build` 跳过，复用已有）
5. **`up -d` + 健康轮询 60s**：循环 `curl /api/v1/health` 直到 `code: 0`，超时给 `bun run prod:logs` 引导

**关键点**：

- 脚本失败必须有可操作的修复提示（"找不到 X → 运行 cp Y" / "缺少 keypair → 运行 openssl Z"）
- 不要只 `up -d` 就退出 —— 健康轮询能在 1 分钟内告诉你"backend 启动失败 / DB 没就绪 / nginx 配错"，比 logs 翻屏快 10 倍
- pwsh 和 bash 各有 grep 习惯：pwsh 用 `Where-Object { $_ -match '^WEB_PORT=' }`，bash 用 `grep -E '^WEB_PORT=' | cut -d= -f2`，**输出格式必须一致**（同样的 ━ / ✓ / ✗ 符号），否则两套用户体验割裂

### 2.9.7 dev / prod env 隔离铁律

- **dev env**：`infra/.env`（被 git 忽略 / 例外是 `.env.example`）
- **prod env**：`infra/.env.prod`（被 git 忽略 / 例外是 `.env.prod.example`）
- compose 命令显式 `--env-file infra/.env.prod` 而非依赖默认查找，避免在测试环境跑混
- env 模板里所有 secret 字段写 `***GENERATE_STRONG_PASSWORD_AT_LEAST_32_CHARS***` 占位，发布脚本里跑一次"是否仍是占位"检测（暂未实现，未来加）

**JWT keypair 同样隔离**：

- `infra/jwt/dev-private.pem` / `dev-public.pem` —— 仓库内有，开发用
- `infra/jwt/prod-private.pem` / `prod-public.pem` —— 仓库不提交，生产部署前手动生成
- compose env 默认值 `${JWT_PRIVATE_KEY_FILE:-prod-private.pem}` —— prod 不需要在 .env.prod 里再覆盖一次

---

## 2.10 批量管理接口 + 运营增强规约（Admin 账号管理沉淀）

> 上下文：M5 完结后，运营反馈"admin 通过 SQL 直接 INSERT 创建 HR 太原始"——产品上需要带表单 / CSV 导入的运营页。
> 关键约束：(1) 部分失败不能整批回滚，否则 100 条里 5 条邮箱重复就要全员重做；(2) 必须能让运营快速 iterate 失败行；(3) 鉴权 / 权限提升攻击面要堵死。

### 2.10.1 批量接口"逐行独立提交"模式（vs 整批事务）

**反模式**：service 方法加 `@Transactional`，循环里某行抛 BizException → JPA / MyBatis-Plus 触发 rollback → 已成功插入的几十行全没了。

**正确模式**：

```java
// service 整体方法 NOT @Transactional —— 每个 mapper.insert 走默认短事务
public BatchCreateUsersVO batchCreate(BatchCreateUsersReq req) {
    List<BatchCreateItemVO> items = new ArrayList<>(req.getUsers().size());
    Set<String> seenInBatch = new HashSet<>();   // 同批次去重
    int ok = 0, fail = 0;

    for (int i = 0; i < req.getUsers().size(); i++) {
        var item = req.getUsers().get(i);
        String email = item.getEmail().toLowerCase();
        try {
            // 1) 同批次去重（DB UNIQUE 在 commit 后才生效，service 内层就要拦）
            if (!seenInBatch.add(email)) {
                throw new BizException(ErrorCode.EMAIL_ALREADY_EXISTS, "同批次重复：" + email);
            }
            // 2) DB 查重（已存在的旧账号）
            if (mapper.selectCount(byEmail(email)) > 0) {
                throw BizException.of(ErrorCode.EMAIL_ALREADY_EXISTS);
            }
            // 3) 插入
            User u = persist(...);
            items.add(BatchCreateItemVO.builder()
                .rowIndex(i).email(email).success(true).userId(u.getId()).build());
            ok++;
        }
        catch (BizException e) {
            items.add(BatchCreateItemVO.builder()
                .rowIndex(i).email(email).success(false)
                .errorCode(e.getErrorCode().getCode())
                .errorMsg(e.getMessage())
                .build());
            fail++;
        }
        catch (Exception e) {
            // 兜底：未知异常也不能让整批挂
            log.warn("[BATCH] row {} unexpected: {}", i, e.toString());
            items.add(BatchCreateItemVO.builder()
                .rowIndex(i).email(email).success(false)
                .errorCode(ErrorCode.INTERNAL_ERROR.getCode())
                .errorMsg("服务异常：" + e.getMessage())
                .build());
            fail++;
        }
    }
    return BatchCreateUsersVO.builder().successCount(ok).failureCount(fail).items(items).build();
}
```

**关键点**：

1. **integer rowIndex** 跟着请求列表索引走 —— 前端不需要 join，直接按 index 高亮"第几行失败"
2. **errorCode + errorMsg 双字段**：errorCode 给程序判断（前端可统一处理 EMAIL_ALREADY_EXISTS），errorMsg 给运营人员看
3. **HashSet 同批次去重**：DB UNIQUE 约束只在事务 commit 时校验，service 里循环 selectCount 也只能查到已 commit 的；同批次第二行写同邮箱必须显式拦
4. **DTO 限单批数量**：`@Size(max = 100)` 在 DTO 上挡住"贴 1 万行 CSV 把 service 跑死"的攻击 / 误操作；超出请前端分批
5. **响应包格式**：`{ successCount, failureCount, items[] }` —— counts 给运营立即数字反馈，items 给逐行明细，前端直接摆两个卡片

**适用场景**：批量导入 / 批量审核 / 批量状态机迁移 —— 凡是"业务上单行成败彼此独立"的批量操作都套这个模式。

### 2.10.2 防权限提升：DTO 校验层就拦下危险 role

**反模式**：service / controller 里 `if ("ADMIN".equals(req.getRole())) throw ...` —— 业务异常 500 风格、单测要 mock SecurityContext 太重。

**正确做法**：在 DTO 上贴 Bean Validation `@Pattern`：

```java
@NotBlank
@Pattern(regexp = "HR|CANDIDATE", message = "role 只能是 HR 或 CANDIDATE")
private String role;
```

`@Valid` 触发 → Spring 直接 `MethodArgumentNotValidException` → GlobalExceptionHandler 映射 400 / `ErrorCode.VALIDATION_FAILED` —— service 层根本拿不到非法值，单测断言 status 400 即可。

**批量场景级联校验**：

```java
public class BatchCreateUsersReq {
    @NotEmpty
    @Size(max = 100)
    @Valid                             // 关键：触发 List 元素的校验
    private List<CreateUserReq> users;
}
```

—— 单行 role=ADMIN 也走 400，跟单条创建行为一致。

### 2.10.3 运营页 UX 五件套（CSV 批量导入）

适用于"管理员把 Excel/CSV 数据塞进系统"的所有页面，复用度极高：

| 件 | 设计点 | 价值 |
|---|---|---|
| **(1) 大文本框 + 注释支持** | placeholder 给完整示例，解析时跳过 `#` 开头行和空行 | 运营从飞书表格直接复制粘贴，不用清洗 |
| **(2) 本地预校验**（解析按钮） | 按行解析 + Bean Validation 同步规则（邮箱格式 / 长度 / 枚举），失败行红底 + 错误提示，无效行**不发到后端** | 减少无效请求 + 让运营立即看到错在哪 |
| **(3) 提交按钮带 count**（"提交批量创建（{{validRows.length}} 条）"） | 文案带数字 | 防止"我以为有 50 行，结果只有 47 行" |
| **(4) 结果卡片：成功绿底 + 失败红底** | 失败行带 errorCode + errorMsg，rowIndex 标"row N" | 运营一眼定位问题 |
| **(5) "复制失败行"按钮** | 把失败行 + 错误注释（`# 同批次重复` 等）拷贝到剪贴板 | 关键！运营粘回输入框改完直接重提，闭环 |

**辅助件**：

- "**填充示例**"按钮自动塞 3 行模板（含强密码生成）—— 第一次进页面的人立刻就能 demo
- "**一键生成强密码**"工具：`abcdefghijklmnopqrstuvwxyz` + `ABCDEFGHIJKLMNOPQRSTUVWXYZ` + `23456789`（去掉 0/1 防混淆）+ `!@#$%^&*` 各保底 1 个字符 + 余数随机，最后 `sort(() => random)` 打乱

```ts
function genPassword(len = 12): string {
  const lowers = 'abcdefghijklmnopqrstuvwxyz'
  const uppers = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  const digits = '23456789'        // 去掉 0/1 防混淆
  const symbols = '!@#$%^&*'
  const all = lowers + uppers + digits + symbols
  const a = (s: string) => s[Math.floor(Math.random() * s.length)]
  const required = [a(lowers), a(uppers), a(digits), a(symbols)]
  const rest = Array.from({ length: len - required.length }, () => a(all))
  return [...required, ...rest].sort(() => Math.random() - 0.5).join('')
}
```

### 2.10.4 WebMvcTest 加 service 进 `@Import` 的反模式 → 正模式

**踩坑**：原 `AdminController.createUser` inline 写业务逻辑（直接 mapper.insert），WebMvcTest 用 `@MockitoBean UserMapper` 跑得通。抽 service 后 controller→service 注入失败，因为 `@WebMvcTest` 默认只扫描 controller。

**修复**：把 service 显式加进 `@Import`：

```java
@WebMvcTest(controllers = {AuthController.class, AdminController.class})
@Import({
    SecurityConfig.class,
    JwtAuthenticationFilter.class,
    JwtAuthEntryPoint.class,
    GlobalExceptionHandler.class,
    com.ats.auth.AdminUserService.class,    // ← 关键
})
```

这样 controller→service→mocked mapper 完整链路跑：`@MockitoBean UserMapper` 还是有效，`verify(userMapper).insert(...)` 断言不变，service 层错误码 / 同批次去重等业务路径全部覆盖。

**判定规则**：WebMvcTest 涉及"controller 直接依赖的 service 类"必须显式 `@Import`，但不涉及"service 间接依赖的 mapper"（mapper 走 `@MockitoBean`）。

### 2.10.5 oxlint `import/consistent-type-specifier-style` 反模式

**踩过 2 次**（jobs.vue + admin/users.vue）：

```ts
// ❌ inline 类型 specifier
import { adminApi, type CreateUserReq, type BatchCreateResult } from '@/api/admin'
```

→ oxlint 报 `consistent-type-specifier-style`。

```ts
// ✅ 顶层 type-only import
import type { BatchCreateItem, BatchCreateResult, CreateUserReq } from '@/api/admin'
import { adminApi } from '@/api/admin'
```

**规约**：vue / ts 文件里**禁止 inline `type` specifier**，类型 import 永远独立一行写在所有 value import 之前。

---

## 2.11 全站 UI 统一打磨规约（v0.0.25 · 4 轮交付经验）

> 触发场景："统一打磨所有页面 UI / 让其更有质感 / 没有不可达处"这种宽泛 polish 任务。

### 2.11.1 4 轮交付方法

宽泛 UI 打磨任务**不要一口气改 20 个文件**，而是按"全局 → 通用组件 → 危险确认 → 不可达处"分轮，每轮跑一次 fe:check：

| 轮次 | 内容 | 风险 |
| --- | --- | --- |
| **第 1 轮 · 全局基础** | global.css 加 `:focus-visible` 环 / `accent-color` / 可选 selection 色；NLoadingBar 接路由钩子 | 极低 · 全站受益、零侵入 |
| **第 2 轮 · 通用组件** | EmptyState / ErrorBlock / CopyButton / useCopy composable | 低 · 仅新增文件 |
| **第 3 轮 · 危险确认** | 删除 / 状态流转 / 批量提交 NPopconfirm 或 dialog.warning | 中 · 改动每个 mutation 入口 |
| **第 4 轮 · 不可达处** | 跨页深链 query 协议 / 一键复制 / 错误状态 retry / a11y aria-current | 中 · 跨多文件，但每处独立 |

**优势**：每轮 fe:check 通过后才进下轮，出错可以快速定位是哪一轮引入。

### 2.11.2 NLoadingBar 与 router 桥接（关键工程问题）

**问题**：`useLoadingBar()` 必须在 `NLoadingBarProvider` 子树的 setup 上下文调用，但 `router/index.ts` 是模块顶层 —— 直接 import 拿不到实例。

**解法**：模块级 ref 桥接 + InnerProviders 微组件。

```ts
// utils/loading-bar.ts
import type { LoadingBarApi } from 'naive-ui'
import { ref } from 'vue'
export const loadingBarRef = ref<LoadingBarApi | null>(null)
```

```vue
<!-- App.vue · 在 NLoadingBarProvider 子树内拿实例填到 ref -->
<script setup>
const InnerProviders = defineComponent({
  setup(_, { slots }) {
    const loadingBar = useLoadingBar()
    onMounted(() => { loadingBarRef.value = loadingBar })
    return () => slots.default?.()
  },
})
</script>
<NLoadingBarProvider>
  ...
  <InnerProviders>
    <RouterView ... />
  </InnerProviders>
</NLoadingBarProvider>
```

```ts
// router/index.ts
router.beforeEach(() => loadingBarRef.value?.start())
router.afterEach(() => loadingBarRef.value?.finish())
router.onError(() => loadingBarRef.value?.error())
```

**反模式**：用全局变量 `globalThis` / setup 外手动 `useLoadingBar()` 都会报"not in provider context"。

### 2.11.3 跨页深链协议（query vs hash）

**协议**：`?paramName=value` 通过 query 而非 hash 传递（hash 留给页面内锚点）。

| 跳转 | URL | 接收方处理 |
| --- | --- | --- |
| 候选人投递记录 → 岗位详情 | `/jobs?jobId=42` | jobs.vue mounted 后读取 query，自动 openDetail |
| HR 岗位市场 → 后台编辑 | `/hr/jobs?editJobId=42` | hr/jobs.vue mounted 后读取 query，自动 openEdit |
| HR 岗位管理 → 招聘看板 | `/hr/board?jobId=42` | board.vue mounted 后读取 query，自动选中 jobOption |
| Dashboard → Board 高亮列 | `/hr/board?stage=APPLIED` | board.vue 通过 computed focusStage 渲染 `.is-focus-target` |

**接收方时序**：必须在 `await fetchList()` / `await loadOptions()` 之后再读 query，否则数据未到时 openDetail 会拿不到内容。

```ts
onMounted(async () => {
  await loadOptions()  // 先确保 options 已加载
  await fetchList()    // 再确保列表已加载
  const id = route.query.jobId
  if (typeof id === 'string' && /^\d+$/.test(id)) {
    openDetail(Number(id))
  }
})
```

**白名单校验**：stage 这类枚举值必须 `valid.includes(s as Stage)`，否则 URL 注入非法值会渲染异常。

### 2.11.4 危险 vs 中间操作：差异化二次确认

**关键流转必须 NPopconfirm，中间过程直接执行**：

```vue
<!-- 看板 drawer footer · 关键流转包 NPopconfirm -->
<NPopconfirm
  v-if="next === 'OFFER' || next === 'HIRED' || next === 'REJECTED'"
  ...
>
  <template #trigger>
    <NButton size="small" :type="next === 'REJECTED' ? 'error' : 'primary'">
      → {{ STAGE_LABEL[next] }}
    </NButton>
  </template>
  即将把 {{ candidate }} 流转到 {{ STAGE_LABEL[next] }}。
  <span v-if="next === 'HIRED'">入职后该投递进入终态，不可再变更。</span>
</NPopconfirm>

<!-- 中间过程（SCREENING_PASS / *_INTERVIEW）直接推进，避免每次都打扰 -->
<NButton v-else size="small" @click="transition(next)">
  → {{ STAGE_LABEL[next] }}
</NButton>
```

**权衡**：每次都 confirm 会教育用户忽视，关键操作 confirm 才有价值。

### 2.11.5 全局 `:focus-visible` 覆盖范围

**反模式**：用通配 `*:focus-visible { outline: ... }` 会和 Naive UI 内置 focus 双环。

**正模式**：用 `:where()` 精确覆盖**裸**交互元素：

```css
:where(a, button, [role="button"], [tabindex]):focus-visible {
  outline: 2px solid var(--brand-500);
  outline-offset: 2px;
  border-radius: var(--radius-sm);
}
```

`:where()` 让选择器特异度为 0（不会覆盖 Naive UI 的 focus 样式），同时 `:focus-visible` 保证鼠标点击时不出现"刺眼蓝框"，只在键盘 Tab 时呈现。

### 2.11.6 移除永久 disabled 菜单项 / dead link

**反模式**：

```ts
{ label: '个人资料', key: 'me', disabled: true }
{ label: '快捷键', key: 'shortcut', disabled: true }
```

```html
<a class="text-brand">服务条款</a>  <!-- 没有 href -->
```

**问题**：disabled 占位看起来像坏链 / 故障，UX 上比"暂未提供"标注更糟。

**正模式**（择一）：
1. 真删掉；
2. 改成 `<span title="演示版本">服务条款</span>` 加可达 tooltip；
3. 替换成可用功能（如把"个人资料 disabled"换成"我的工作台 → /me/applications"）。

### 2.11.7 工具函数公用化时机

**信号**：当一个工具函数（如 `resumeDownloadUrl`）出现在第 2 个文件里时，立即提到 `utils/`，而不是 copy-paste。

**本次踩到**：原 `hr/board.vue` 私有的 `resumeDownloadUrl` + `isResumeFile`，me/applications.vue 也要回看简历，提取到 `utils/resume.ts` 单一真值，两个 view 都 import。

---

## 2.12 公开聚合接口 + 词条收敛规约（v0.0.26）

> **背景**：登录 / 注册页左半部分原本是<strong>静态硬编码示例数</strong>（"200+ 入驻企业 / 1.2k 活跃岗位 / 98% 回复及时"），看起来真实但毫无实际意义；同时"入驻企业"暗示这是 SaaS 多租户平台，与"公司内部私有招聘系统"的产品定位不符。

### 2.12.1 公开聚合接口设计 · 4 条铁律

未登录用户能看到的统计接口需要严格的"信息边界"设计，否则就是免费的情报泄露通道。

1. **只返回聚合数字，不返回任何个体记录**：禁止返回 list / id / name / email 任何能定位到候选人 / 岗位 / HR 个人的字段。`PublicStatsVO` 全 long 标量。

2. **不接受任何过滤参数**：`GET /stats/public` 不带 query / path 参数。一旦支持 `?jobId=` / `?hrId=` 就给了攻击者通过差分攻击推断个体存在性的接口（先查全量、再加过滤、对比变化得到目标信息）。

3. **稀疏数据要在<strong>前端</strong>而非后端模糊化**：后端返回真实数字，前端 `formatCount(n)` 把 `n < 5` 显示为"多人/多个"。原因：(1) 后端返回固定数值方便单测、缓存、CDN；(2) 前端格式化逻辑可随产品策略快速调整阈值；(3) 已登录用户在前端自己页面（dashboard）看自己切片是允许的精确数据，混在同一个 service 里会让测试断言变难。

4. **`permitAll` 路径必须显式配置 + 带 HTTP method 限定**：`SecurityConfig` 用 `.requestMatchers(HttpMethod.GET, "/stats/public")` 而非 `requestMatchers("/stats/public")`，避免未来加 POST/PUT 时被误放行。

```java
// SecurityConfig.java
.requestMatchers(HttpMethod.GET, "/stats/public").permitAll()

// StatsController.java
@GetMapping("/public")  // 不带 @PreAuthorize
public ApiResponse<PublicStatsVO> publicStats() {
    return ApiResponse.ok(statsService.publicStats());
}

// StatsService.java —— 复用 mapper，hrUserId/jobId 全传 null
public PublicStatsVO publicStats() {
    List<Map<String,Object>> rows = applicationMapper.countByStage(null, null);
    // ...聚合 5 个 stage group
}
```

### 2.12.2 公开统计字段选取原则

不要直接把"现成的 OverviewVO"暴露成公开版 —— "本月新增投递 20 / Offer 3 / 入职 1" 这种数字在小公司能直接被员工反推到具体岗位 / 候选人。

**安全字段清单**（按"无法定位个体"程度排序）：
- ✅ `publishedJobs` —— 当前在招岗位数（候选人页本来就能看见全量列表，不是新信息）
- ✅ `coveredDepartments` —— 至少有 1 个 PUBLISHED 岗位的 distinct 部门数
- ✅ 当前各 stage 候选人数（`screeningCount` / `interviewCount` / `offerCount`）—— 总数足够大时模糊
- ❌ "本月入职数" —— 小公司每月入职 1-3 人，能直接被同事反推
- ❌ "平均面试轮数" —— 暴露面试流程节奏
- ❌ "Offer 接受率" —— 暴露薪资竞争力

> **原则**：返回的数字应该是"候选人 + HR 同事在自己日常使用产品时<strong>本来就能感受到</strong>的水位"，而不是管理层视角的运营指标。

### 2.12.3 `formatCount` 三段式 helper

```typescript
// composables/use-format-count.ts
export function formatCount(n: number, fewLabel = '多人'): string {
  if (n < 5) return fewLabel             // 数据稀疏 → 模糊化
  if (n > 999) {
    const k = n / 1000
    const rounded = Math.floor(k * 10) / 10
    return rounded % 1 === 0 ? `${rounded.toFixed(0)}k+` : `${rounded.toFixed(1)}k+`
  }
  return String(n)                       // 5 ≤ n ≤ 999 真实展示
}
```

**关键点**：
- `fewLabel` 默认"多人"（候选人语义），部门 / 岗位场景传"多个"。
- 临界值用 `< 5` 而非 `<= 5`：5 个候选人在小团队也是有差异化感的，但 4 个就太稀疏。
- `> 999` 用 `Math.floor(k*10)/10` 而非四舍五入：避免 1199 显示成 1.2k 让用户以为已破 1200。

### 2.12.4 fetch 失败的降级策略：静默 → 占位

公开统计是<strong>装饰性</strong>信息，不能阻塞登录 / 注册主流程。

```typescript
const publicStats = ref<PublicStatsVO | null>(null)
onMounted(async () => {
  try {
    publicStats.value = await statsApi.publicStats()
  }
  catch (e) {
    console.warn('[login] publicStats fetch failed, falling back to placeholders', e)
    // 不 throw, 不 message.error —— 用户根本不需要知道"水位卡片"加载失败
  }
})
// 模板中：formatCount(s?.screeningCount ?? 0)  → 空值兜底走 "多人"
```

**对比反模式**：在 `onMounted` 里 `await` 后 throw / 弹 toast 把"装饰加载失败"升级成"用户感知错误"，登录页变成报错页。

### 2.12.5 词条与产品定位一致性检查

**触发信号**：用户提到"我们是 X 类型的系统"。立即扫一遍：
1. **页面文案**：是否有暗示其它产品形态的词（"入驻企业" / "多租户" / "为众多公司"）？
2. **图标 / 视觉**：是否有 SaaS 风格的元素（"Free Forever" / "All Plans" 等定价暗示）？
3. **文档背景**：技术设计 / 里程碑 / SKILL 是否一致使用同一定位？

**本次替换链**：
- `register.vue` "入驻企业 200+" → "覆盖部门 {coveredDepartments}"（产品定位 + 真实数据）
- `login.vue` "一套现代化招聘追踪系统" → "公司内部招聘追踪系统"（强调私有部署）
- 注册页第 3 个 stat block "回复及时 98%"（虚构指标）→ "全程追踪 7×24"（真实属性）

> **教训**：UI 上的所有数字 / 描述如果是<strong>假的</strong>就别放，宁可放真实但平淡的（"7×24 全程追踪"），也别放虚构但闪亮的（"98% 回复及时"）—— demo 阶段用户会发现，产品阶段会被合规打。


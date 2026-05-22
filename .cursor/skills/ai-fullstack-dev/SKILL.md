---
name: ai-fullstack-dev
description: AI 辅助全栈开发工作流。用于从 0 到 1 搭建中等复杂度 Web 系统 MVP，覆盖选题分析、需求调研、技术设计、编码实现到部署交付的完整流程。当用户提到全栈开发、搭建系统、需求文档、MVP、从零开始建项目时触发。
metadata: v0.0.16.20260522
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
1. 模板里 attribute 自带分组语义（`bg="elevated"` / `text="lg primary"` 一眼看出语义类型），可读性远超长 class 串
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
7. shortcut / 状态化 / 含 . is-visible？               → class="text-gradient reveal ms-card"
```

| 场景 | 写法 | 说明 |
|---|---|---|
| **无值原子（display/position 等 keyword）** | `<div flex relative grid inline-flex>` | 直接 valueless，UnoCSS scanner 会扫到。**禁止** `flex="~"` 这种冗余形式 |
| **单值无括号** | `<div bg-app mt-8 rounded-full text-lg font-bold>` | **当 class 用**，更紧凑（`bg="app"` 比 `bg-app` 多 4 字符却没好处） |
| **单值带括号（arbitrary 字面值）** | `<div max-w="[1200px]" tracking="[-0.05em]" gap="[10px]">` | **⚠️ 必须 attributify value 形式**，**禁止** `max-w-[1200px]` 写在 attribute name 上 —— HTML attribute name 不允许 `[` `]` 字符，浏览器虽宽容但 vue-tsc / prettier / 严格 parser 会出问题；attributify value 字符串里方括号完全合法 |
| **单值 = CSS 变量** ✨ | `<div bg-(--brand-500) text-(--text-primary) shadow-(--shadow-lg)>` | UnoCSS **圆括号简写**：`prop-(--var)` ≡ `prop-[var(--var)]`，比方括号 + `var()` 短 7 字符。HTML attribute name **允许** `(` `)`（与 `[` `]` 不同），所以可以直接当 attribute 写，无需 attributify value。**优先用此形式**替代 `bg-[var(--xxx)]`／`bg="[var(--xxx)]"` |
| **单值 variant** | `<div hover:bg-active group-hover:translate-x-1 max-sm:hidden focus:ring-2>` | **当 class 用**，单值时连字符 + 冒号比 `hover="bg-active"` 更短更直观 |
| **多值（同 prefix，含 prefix 本身）** | `flex="~ items-center justify-between wrap"` | `~` 表示 prefix 本身作为 class（`display:flex`）；**此处 `~` 不能省**——去掉就只剩 `align-items` `justify-content` `flex-wrap`，没有 `display:flex` |
| **多值（同 prefix，不含 prefix 本身）** | `border="t subtle"` ／ `text="xs secondary uppercase"` | 不写 `~`，只组合子 class |
| **多值简写连写** | `p="y-3 x-4"` → `py-3 px-4` ／ `m="t-6 x-auto"` → `mt-6 mx-auto` | 维度复合写在一个属性里 |
| **多值 variant** | `hover="text-primary after:right-0"` ／ `before="absolute inset-0 content-empty"` | variant 包多个 utility 才用 attributify；单值 variant 走 class with hyphen |
| **arbitrary 在 class 字符串里** | `class="max-w-[1200px] transition-[transform,box-shadow]"` | string value 内括号完全合法，复杂组合（含 variant + arbitrary）写 class 反而比拆 attribute 更清晰 |
| **自定义 class（shortcut / 状态化）** | `class="text-gradient ms-card status-done reveal"` | shortcut、有 `::before/::after` / 状态切换 / JS 加 .is-visible 的 class 仍用 `class=` |

> 💡 **核心心智模型**：HTML attribute name 在生成 selector 时 UnoCSS 走 `[attr~=value]` 路径，attribute value 字符串则走标准 class selector 路径。两者最终生成的 CSS 一致，但**只有 attribute name 不能含 `[` `]`**（HTML 规范限制 + 工具链兼容）。所以"括号必须用 attributify value"不是 UnoCSS 限制，是 HTML 限制。

> 💡 **`~` 的语义**：UnoCSS attributify 里 `~` 代表"把 attribute prefix 本身也作为一个 utility class 应用"。只在「prefix 自身需要 + 子值组合」的混合写法里才需要 `~`，**单独 `xxx="~"` 是冗余写法**（等价于 valueless `xxx`），全项目应统一为 valueless。

> 💡 **`duration-*` 默认 unit**：UnoCSS 对 `duration-N`（纯数字）默认 `N` 毫秒——`duration-260` ≡ `duration-[260ms]`，前者更短，**优先用**。同理 `delay-*`。但 `w-` `h-` `p-` `m-` 等纯数字走的是 theme.spacing（`w-4` ≠ `w-[4px]`），不要混淆。

> 💡 **CSS 变量圆括号简写** ✨：`prop-(--var-name)` ≡ `prop-[var(--var-name)]`，三档展开率（短 7 字符）：
>
> | 旧写法 | 新写法 | 等价 CSS |
> |---|---|---|
> | `bg-[var(--brand-500)]` | `bg-(--brand-500)` | `background-color: var(--brand-500)` |
> | `text="[var(--text-primary)]"` | `text-(--text-primary)` | `color: var(--text-primary)` |
> | `shadow-[var(--shadow-lg)]` | `shadow-(--shadow-lg)` | `box-shadow: var(--shadow-lg)` |
> | `border-[var(--border-default)]` | `border-(--border-default)` | `border-color: var(--border-default)` |
> | `animate-[var(--blink)]` | `animate-(--blink)` | `animation: var(--blink)` |
>
> 同样适用于 hover variant：`hover:bg-(--brand-700)`。**全项目优先用圆括号简写**，仅当不是 CSS 变量而是任意字面值（`max-w-[1200px]`、`tracking-[-0.05em]`、复杂渐变字符串等）时才用方括号。
>
> 🚧 **适用边界**（preset-uno v66 实测）：
> - ✅ `.vue` template 内、`class="..."` 字符串内、attributify attribute name 上（`<div bg-(--brand-500)>`）：**圆括号简写匹配成功**
> - ❌ `uno.config.ts` 内 `shortcuts` 字符串里：**会被解析器吞掉括号变成 `border---border`**（vite 报 `unmatched utility "border---border"`）。shortcut 字符串内仍写 `border-[var(--border)]`
> - ❌ 带透明度修饰符的复合写法 `bg-(--bg-app)/70` 暂未验证稳定，遇到这种保留方括号 `bg-[var(--bg-app)]/70` 更稳
>
> ⚠️ 圆括号简写**不会自动生成 gradient**——`bg-(--grad-spring)` 仍然展开为 `background-color`，渐变同样会静默失效，规避方式与方括号一致：用自定义 `rules` 接管（见下方反模式 #8）。

> 💡 **借助插件做权威校验**：UnoCSS 写法的合法性以工具实时报告为准，**不要凭记忆判断**：
> - **VSCode**：装 `antfu.unocss` 扩展，hover / 行内即可看到 utility 是否匹配 + 生成的 CSS
> - **CLI 校验**：装 `@unocss/eslint-plugin`，配 minimal `eslint.config.js` 跑 `eslint . --rule '@unocss/order: error' --rule '@unocss/blocklist: error'` 验证；也可直接看 vite dev server stdout 的 `[unocss] unmatched utility "..."` 警告
> - **凡是 vite 报 unmatched 的写法都是无效的**——立即修，不要 ship 残缺 class

##### ⚠️ 反模式

1. **单独 `xxx="~"` 冗余写法**（如 `<div flex="~" relative="~">`）—— `~` 只在"prefix 本身 + 子值"混合场景才必要；单独无值原子直接 `<div flex relative>` 即可。全项目统一 valueless 风格
2. **`max-w-[1200px]` 直接当 attribute name 用**（如 `<div max-w-[1200px]>`）—— HTML attribute name 不允许 `[` `]`，浏览器宽容但 vue-tsc / prettier 不可靠。**必须**改 `<div max-w="[1200px]">`。但写在 class 字符串里（`class="max-w-[1200px]"`）OK，因为是 string value
3. **单值还用 attributify**（如 `<div bg="app" mt="8">`）—— 比 `bg-app mt-8` 多打 4-6 字符却没好处。**单值无括号 → class with hyphen** 是统一规约
4. **同一原子同时出现在 class 和 attribute 上**—— diff 难读，规约混乱
5. **shortcut / 复杂状态 class 拆成 atomic**（如把 `text-gradient` 拆成 5 个属性）—— 失去 shortcut 的语义聚合价值
6. **在 UnoCSS theme 里重新写一遍颜色值**（如 `brand: { 500: '#10b981' }`）—— 破坏"token 单一真值"，Naive UI 和 UnoCSS 会渐行渐远
7. **CSS 变量还用方括号 + `var()` 长写**（如 `bg-[var(--brand-500)]` / `text="[var(--text-primary)]"` / `class="shadow-[var(--shadow-lg)]"`）—— UnoCSS 早已支持**圆括号简写** `bg-(--brand-500)`，等价但短 7 字符且可直接当 attribute name（圆括号在 HTML 中合法）。template / class 字符串内统一走简写；**shortcut 字符串内例外**（preset-uno 解析失败，保留方括号 + `var()`）
8. **用 `bg-[var(--grad-xxx)]` ／ `bg-(--grad-xxx)` ／ shortcut 拼出渐变**—— UnoCSS 把 `bg-[...]` 和 `bg-(--xxx)` 都默认推断为 `background-color`，**`background-color` 不接受 `linear-gradient(...)`，渐变会静默失效**（不报错，但页面上就是一片透明 / 默认色）
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

##### shims.d.ts 必备声明

```ts
declare module 'virtual:uno.css'
```

> 💡 vue-tsc 现在对 attributify 属性是宽容的（任意未知 attribute 接受 string，**包括 valueless attribute 不再报 boolean 错**），无需为 `bg` / `text` / `p` / `m` 等做 HTMLAttributes augmentation。如果你看到旧文章建议加 `~` 来"绕过 boolean 报错"，那是过时信息——直接 valueless 即可。

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

**实战收益**（M1 认证页迁移）：

| 文件 | scoped 样式行数（前 → 后） | 减少 |
|---|---|---|
| `AppNavbar.vue` | 175 → 0 | -100% |
| `LoginView.vue` | 270 → 55 | -80% |
| `RegisterView.vue` | 230 → 80 | -65% |

**总体「UnoCSS 化率」≈ 92%**，剩 8% 都是合理留存（见下条）。

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
| **复杂 calc + CSS var** | `translate-x-[calc(var(--i)*36px)]` 可写但极丑 | `transform: translateX(calc(var(--i) * 36px))` |
| **Vue Transition 命名 class** | Vue 命名约定要求 plain class | `.fade-slide-enter-active` |
| **依赖 `::before` `::after` 伪元素** + 复杂结构 | utility 写多层伪元素链路啰嗦 | `.with-noise::after`（噪点 overlay）|
| **依赖 JS 注入 CSS var** | `--mx --my` 跟随鼠标场景 | `.cursor-glow` |
| **状态化 `[data-state='up']` 联动多个子元素** | 父级状态控制多个 selector 时 utility 难表达 | health card 状态色联动 |

> 原则：**这一行写 utility 比写 CSS 更短更清晰 → 用 utility；反之 → 留 CSS**。不要为了"100% UnoCSS 化"硬塞复杂表达式，可读性永远第一。

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

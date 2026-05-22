---
name: ai-fullstack-dev
description: AI 辅助全栈开发工作流。用于从 0 到 1 搭建中等复杂度 Web 系统 MVP，覆盖选题分析、需求调研、技术设计、编码实现到部署交付的完整流程。当用户提到全栈开发、搭建系统、需求文档、MVP、从零开始建项目时触发。
metadata: v0.0.5.20260522
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

### 2.5 UI 设计基线（B 端 SaaS 风）

> 参考 awwwards 上 Linear / Vercel Dashboard / Cron / Notion 这类**克制现代**的设计，而非重视觉的展示型站点。B 端工具优先**信息密度、可读性、操作可预期**，再追求质感。

**色彩**（统一通过 design token 引用，禁止 hardcode 颜色）：

- 主色：单一品牌色（如 `#5b6bff` indigo / `#0a0a0a` near-black），高饱和度小面积点缀
- 语义色：success / warning / danger / info 各一组（base + bg + border）
- 中性色 9-11 阶灰度（`gray-50` … `gray-950`），背景、边框、文字层级全靠它
- 暗色模式预留 token 切换位（即便 MVP 只发亮色，token 命名也别绑死颜色）

**排版**：

- 中文：`PingFang SC` / `Microsoft YaHei` / `Noto Sans SC`；英文/数字：`Inter` / `SF Pro` / `JetBrains Mono`（代码与数字）
- 字号 6 档：`12 / 13 / 14 / 16 / 20 / 24`；行高 `1.5` 默认、`1.3` 标题
- 标题字重 600/700；正文 400；重要数字 500–600 + tabular-nums

**布局与质感**：

- 8px 栅格；圆角统一 6 / 8 / 12 三档
- 阴影只用 1–2 档（`shadow-sm` 用于卡片、`shadow-md` 用于浮层），不堆叠
- 表格 / 列表零或细 1px 分隔；hover 行用极浅背景（`gray-50`）而非边框跳动
- 卡片白底 + 1px 浅边框 > 厚阴影

**交互**：

- 微动画 `transition: all 150-200ms cubic-bezier(.4,0,.2,1)`，仅用于颜色/位移/透明度
- 看板拖拽、抽屉、Toast 等都给一个 200ms 内的入场动画，禁用大幅缩放/弹跳
- 空态、loading、错误都要有专属插画或图标 + 文案，不留白屏

**Naive UI 落地**：

- 用 `NConfigProvider` + `themeOverrides` 把上述 token 注入主题，组件级颜色全部走主题
- 自定义组件用 CSS variables（`var(--n-color)` 等）跟随主题切换

---

## Phase 3：编码实现

进入编码前，**先输出一份开发计划 HTML**：`docs/project-dev-plan.html`。

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

- 需求文档：`docs/project-requirements.html`
- 数据库 Schema：`docs/project-schema.sql`
- 技术设计文档：`docs/project-tech-design.html`
- Phase 3 开发计划：`docs/project-dev-plan.html`

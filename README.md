# ATS · 招聘管理系统

> 一个 10 天 AI 辅助开发的全栈 MVP — 跟踪候选人从投递到入职的完整漏斗。

## 技术栈

| 层 | 选型 |
|---|---|
| 前端 | Vue 3 · Vite · TypeScript · Naive UI · Pinia · vuedraggable · ECharts |
| 后端 | Spring Boot 3 · Java 21 · MyBatis-Plus · JJWT (RS256) · Spring Security |
| 数据 | PostgreSQL 16 · Redis 7 |
| 部署 | Docker Compose / Podman compose / docker-compose v1 |

## 仓库布局

```
demo-homework/
├── docs/                       # 所有设计文档（HTML + SQL）
│   ├── project-selection-analysis.html  Phase 0 选题
│   ├── project-requirements.html        Phase 1 需求
│   ├── project-schema.sql               Phase 2 数据库 DDL
│   ├── project-tech-design.html         Phase 2 技术设计
│   ├── project-dev-plan.html            Phase 3 总体编码计划
│   └── project-milestones.html          ★ 活文档·进度追踪·给未来 agent 看
├── infra/
│   ├── docker-compose.dev.yml  # 开发用：pg + redis
│   └── .env.example
├── scripts/
│   ├── check-env.ps1 / .sh     # 环境自检
│   └── new-jwt-keys.ps1        # 生成 RS256 密钥
├── ats-backend/                # Spring Boot 3（M0 创建）
├── ats-frontend/               # Vue 3 + Vite（M0 创建）
└── .cursor/skills/ai-fullstack-dev/SKILL.md
```

## 快速开始

### 0. 环境自检

```powershell
pnpm run check-env          # 或 bun run check-env
```

需要：JDK 21+ · Maven 3.9+ · Node 20+ · Bun 1.3+ · Docker **或** Podman · OpenSSL

### 1. 启动数据库 + 缓存

```powershell
cp infra/.env.example infra/.env       # 首次
bun run dev:up                          # 后台启动 pg + redis
bun run dev:logs                        # 看日志
bun run dev:reset                       # 清库重来（演示前用）
```

> Compose 文件用通用语法，`docker-compose` v1 / `docker compose` v2 / `podman compose` 都能跑。
> Podman 用户：把 npm script 里 `docker-compose` 改为 `podman compose` 也可。

### 2. 启动后端（M0 末有）

```powershell
pwsh -File scripts/new-jwt-keys.ps1     # 生成 RS256 密钥
cp ats-backend/.env.example ats-backend/.env
# 把脚本输出的 JWT_*_KEY_B64 粘进去
bun run be:dev
```

### 3. 启动前端（M0 末有）

```powershell
cp ats-frontend/.env.example ats-frontend/.env.local
bun run fe:dev          # 默认 http://localhost:5173
```

## 开发进度

按 `docs/project-dev-plan.html` 的 M0 → M5 推进。**实时进度、决策记录、风险台账、给未来 agent 的续接说明全部在活文档** `docs/project-milestones.html`：

```powershell
bun run docs:project-milestones    # 在 http://localhost:3004 打开活文档
```

里程碑速览：

- [x] **M0** 项目基建 · 骨架 + dev compose + /health 联调 _(2026-05-22)_
- [ ] **M1** 认证模块 · register/login/refresh/logout/me
- [ ] **M2** 岗位 CRUD · 状态机 + 全文搜索
- [ ] **M3** ⭐ 状态机看板 · 投递 + 看板拖拽 + 审计日志
- [ ] **M4** 辅助 · 简历上传 + 面试评价 + 数据看板
- [ ] **M5** 打磨交付 · UI + 生产 compose + README + 演示

## 演示账号

> M5 完成后填入。

## 设计参考

UI 风格参考 [awwwards](https://www.awwwards.com/) 上 SaaS Dashboard 一类项目（Linear / Vercel Dashboard / Cron / Notion 系），克制留白 + 精细字体 + 玻璃质感 + 微动画。详见 `.cursor/skills/ai-fullstack-dev/SKILL.md` 的「UI 设计基线」。

## License

Personal / homework project.

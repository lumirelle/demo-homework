-- ============================================================
--  ATS 招聘管理系统 — 数据库 Schema
--  数据库：PostgreSQL 16
--  版本：v1.1   日期：2026-05-22
--  变更：M2 引入 jobs 5 态状态机 + tags 标准化表 + 组合拳搜索索引
-- ============================================================

-- ────────────────────────────────────────────────────────────
--  扩展（必须在 superuser 下安装；Postgres 16 默认账号即 superuser）
-- ────────────────────────────────────────────────────────────

CREATE EXTENSION IF NOT EXISTS pg_trgm;     -- title ILIKE 加速（GIN trgm）

-- ────────────────────────────────────────────────────────────
--  枚举类型
-- ────────────────────────────────────────────────────────────

-- 用户角色
CREATE TYPE user_role AS ENUM (
    'ADMIN',      -- 超级管理员
    'HR',         -- HR / 招聘专员
    'CANDIDATE'   -- 候选人
);

-- 岗位状态（5 态状态机，合法流转见 JobStatusMachine.java）
--   DRAFT     ──publish──▶ PUBLISHED ──pause───▶ PAUSED
--   DRAFT     ──archive──▶ ARCHIVED  ──restore─▶ DRAFT
--   PUBLISHED ──close────▶ CLOSED    ──archive─▶ ARCHIVED
--   PAUSED    ──publish──▶ PUBLISHED （恢复招聘）
--   PAUSED    ──close────▶ CLOSED    （直接关闭）
CREATE TYPE job_status AS ENUM (
    'DRAFT',       -- 草稿，HR 编辑中，候选人不可见
    'PUBLISHED',   -- 招聘中，候选人可见可投递
    'PAUSED',      -- 暂停收件（HR 短期不想看新简历，候选人仍可见但提示暂停）
    'CLOSED',      -- 已关闭，候选人可见标记已关闭，不可投递
    'ARCHIVED'     -- 已归档，列表默认隐藏，可恢复为 DRAFT
);

-- 工作类型
CREATE TYPE job_work_type AS ENUM (
    'FULL_TIME',   -- 全职
    'PART_TIME',   -- 兼职
    'CONTRACT',    -- 合同制
    'INTERN',      -- 实习
    'REMOTE'       -- 远程
);

-- 岗位资历级别
CREATE TYPE job_level AS ENUM (
    'INTERN',      -- 实习
    'JUNIOR',      -- 初级 (P4/L3)
    'MID',         -- 中级 (P5/L4)
    'SENIOR',      -- 高级 (P6/L5)
    'LEAD',        -- 资深 / 团队 Lead
    'DIRECTOR'     -- 总监
);

-- 标签分类
CREATE TYPE tag_category AS ENUM (
    'TECH',        -- 技术栈：Java / Spring / TypeScript
    'SOFT',        -- 软实力：沟通 / 团队协作
    'CERT',        -- 证书：CISSP / AWS Certified
    'LANG',        -- 语言能力：英语流利 / 日语 N1
    'DOMAIN'       -- 业务领域：金融 / 电商 / 医疗
);

-- 候选人申请阶段
CREATE TYPE application_stage AS ENUM (
    'APPLIED',           -- 待筛选（刚投递）
    'SCREENING_PASS',    -- 简历通过
    'PHONE_INTERVIEW',   -- 电话面试
    'TECH_INTERVIEW',    -- 技术面试
    'HR_INTERVIEW',      -- HR 终面
    'OFFER',             -- 发放 Offer
    'HIRED',             -- 已入职（终态）
    'REJECTED'           -- 已拒绝（终态）
);

-- 面试结论
CREATE TYPE interview_conclusion AS ENUM (
    'PASS',    -- 通过
    'REJECT',  -- 拒绝
    'HOLD'     -- 待定
);

-- ────────────────────────────────────────────────────────────
--  通用触发器函数：自动更新 updated_at
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ────────────────────────────────────────────────────────────
--  1. users — 用户表
-- ────────────────────────────────────────────────────────────

CREATE TABLE users (
    id            BIGSERIAL       PRIMARY KEY,
    email         VARCHAR(255)    NOT NULL,
    password_hash VARCHAR(255)    NOT NULL,                  -- BCrypt hash，禁止明文
    full_name     VARCHAR(100)    NOT NULL,
    role          user_role       NOT NULL DEFAULT 'CANDIDATE',
    is_active     BOOLEAN         NOT NULL DEFAULT TRUE,     -- 软删除/禁用标志
    created_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ     NOT NULL DEFAULT NOW(),

    CONSTRAINT users_email_unique UNIQUE (email)
);

COMMENT ON TABLE  users                IS '系统用户：包含管理员、HR 和候选人三种角色';
COMMENT ON COLUMN users.id            IS '自增主键';
COMMENT ON COLUMN users.email         IS '登录邮箱，全局唯一';
COMMENT ON COLUMN users.password_hash IS 'BCrypt(cost=12) 加密后的密码';
COMMENT ON COLUMN users.role          IS '角色：ADMIN / HR / CANDIDATE';
COMMENT ON COLUMN users.is_active     IS 'FALSE 表示账号已禁用';

-- 索引
CREATE INDEX idx_users_email    ON users (email);
CREATE INDEX idx_users_role     ON users (role);

-- 自动更新 updated_at
CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ────────────────────────────────────────────────────────────
--  2. departments — 部门表
-- ────────────────────────────────────────────────────────────

CREATE TABLE departments (
    id         BIGSERIAL     PRIMARY KEY,
    name       VARCHAR(100)  NOT NULL,
    created_at TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT departments_name_unique UNIQUE (name)
);

COMMENT ON TABLE  departments      IS '部门信息，岗位关联到部门';
COMMENT ON COLUMN departments.name IS '部门名称，全局唯一';

-- ────────────────────────────────────────────────────────────
--  3. jobs — 岗位表（M2 增强：5 态状态机 + 结构化薪资 + 浏览量 + 软删）
-- ────────────────────────────────────────────────────────────

CREATE TABLE jobs (
    id              BIGSERIAL       PRIMARY KEY,
    department_id   BIGINT          REFERENCES departments(id) ON DELETE SET NULL,
    created_by      BIGINT          NOT NULL REFERENCES users(id) ON DELETE RESTRICT,

    title           VARCHAR(200)    NOT NULL,
    description     TEXT,                                       -- 岗位 JD，支持 Markdown
    location        VARCHAR(200),
    work_type       job_work_type   NOT NULL DEFAULT 'FULL_TIME',
    level           job_level       NOT NULL DEFAULT 'MID',

    salary_min      INTEGER         CHECK (salary_min >= 0),    -- 月薪下限（元），NULL 表示面议
    salary_max      INTEGER         CHECK (salary_max >= 0),    -- 月薪上限（元）
    headcount       SMALLINT        NOT NULL DEFAULT 1 CHECK (headcount > 0),

    status          job_status      NOT NULL DEFAULT 'DRAFT',
    view_count      INTEGER         NOT NULL DEFAULT 0 CHECK (view_count >= 0),
    published_at    TIMESTAMPTZ,                                -- 首次进入 PUBLISHED 的时间
    closed_at       TIMESTAMPTZ,                                -- 进入 CLOSED 的时间

    created_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,                                -- 软删，Admin 专用

    CONSTRAINT jobs_salary_range_chk
        CHECK (salary_min IS NULL OR salary_max IS NULL OR salary_min <= salary_max)
);

COMMENT ON TABLE  jobs               IS '招聘岗位，5 态状态机由 JobStatusMachine 控制';
COMMENT ON COLUMN jobs.department_id IS 'FK → departments，部门可被删除，置 NULL';
COMMENT ON COLUMN jobs.created_by    IS 'FK → users，创建人（HR），不可删除';
COMMENT ON COLUMN jobs.headcount     IS '招聘人数，至少为 1';
COMMENT ON COLUMN jobs.salary_min    IS '月薪下限（元/月），NULL 表示薪资面议';
COMMENT ON COLUMN jobs.salary_max    IS '月薪上限（元/月），≥ salary_min';
COMMENT ON COLUMN jobs.status        IS 'DRAFT/PUBLISHED/PAUSED/CLOSED/ARCHIVED，流转规则见 JobStatusMachine';
COMMENT ON COLUMN jobs.view_count    IS '岗位详情页浏览次数，候选人查看时 +1';
COMMENT ON COLUMN jobs.published_at  IS '首次发布时间，用于「最新岗位」排序';
COMMENT ON COLUMN jobs.deleted_at    IS '软删时间，Admin 物理删除入口在后台；候选人列表完全过滤';

-- 索引（带 WHERE deleted_at IS NULL 的 partial index 仅命中活跃岗位，体积更小）
CREATE INDEX idx_jobs_status        ON jobs (status)                              WHERE deleted_at IS NULL;
CREATE INDEX idx_jobs_department_id ON jobs (department_id)                       WHERE deleted_at IS NULL;
CREATE INDEX idx_jobs_created_by    ON jobs (created_by)                          WHERE deleted_at IS NULL;
CREATE INDEX idx_jobs_published_at  ON jobs (published_at DESC NULLS LAST)        WHERE deleted_at IS NULL;
CREATE INDEX idx_jobs_work_type     ON jobs (work_type)                           WHERE deleted_at IS NULL;
CREATE INDEX idx_jobs_level         ON jobs (level)                               WHERE deleted_at IS NULL;

-- 全文搜索组合拳：
--   (1) title 走 pg_trgm GIN，加速 ILIKE '%kw%' 模糊匹配（中文/英文都行）
--   (2) description 走 to_tsvector('english') GIN，英文岗位 JD 自动分词
CREATE INDEX idx_jobs_title_trgm    ON jobs USING GIN (title gin_trgm_ops)         WHERE deleted_at IS NULL;
CREATE INDEX idx_jobs_desc_fts      ON jobs USING GIN (to_tsvector('english', coalesce(description, ''))) WHERE deleted_at IS NULL;

CREATE TRIGGER trg_jobs_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ────────────────────────────────────────────────────────────
--  3a. tags — 技能/标签标准化表
-- ────────────────────────────────────────────────────────────

CREATE TABLE tags (
    id         BIGSERIAL     PRIMARY KEY,
    slug       VARCHAR(80)   NOT NULL,                       -- url-safe 标识，如 'spring-boot'
    name       VARCHAR(80)   NOT NULL,                       -- 显示名，如 'Spring Boot'
    category   tag_category  NOT NULL DEFAULT 'TECH',
    created_at TIMESTAMPTZ   NOT NULL DEFAULT NOW(),

    CONSTRAINT tags_slug_unique UNIQUE (slug)
);

COMMENT ON TABLE  tags          IS '技能/标签标准化表，HR 选已有标签，避免拼写发散';
COMMENT ON COLUMN tags.slug     IS 'url-safe 唯一标识，前端 query string 用';
COMMENT ON COLUMN tags.category IS 'TECH(技术) / SOFT(软实力) / CERT(证书) / LANG(语言) / DOMAIN(业务领域)';

CREATE INDEX idx_tags_category ON tags (category);

-- ────────────────────────────────────────────────────────────
--  3b. job_tags — 岗位 ↔ 标签 关联表
-- ────────────────────────────────────────────────────────────

CREATE TABLE job_tags (
    job_id     BIGINT       NOT NULL REFERENCES jobs(id) ON DELETE CASCADE,
    tag_id     BIGINT       NOT NULL REFERENCES tags(id) ON DELETE RESTRICT,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    PRIMARY KEY (job_id, tag_id)
);

COMMENT ON TABLE job_tags IS '岗位 ↔ 标签 多对多关联，查询时 JOIN tags 即可';

-- 反向查询索引（"有 Java 标签的岗位"用得到）
CREATE INDEX idx_job_tags_tag_id ON job_tags (tag_id);

-- ────────────────────────────────────────────────────────────
--  4. applications — 候选人申请表
-- ────────────────────────────────────────────────────────────

CREATE TABLE applications (
    id             BIGSERIAL         PRIMARY KEY,
    job_id         BIGINT            NOT NULL REFERENCES jobs(id) ON DELETE RESTRICT,
    candidate_id   BIGINT            NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    stage          application_stage NOT NULL DEFAULT 'APPLIED',
    resume_url     VARCHAR(500),                    -- 简历 PDF 存储路径或 URL
    years_exp      SMALLINT          CHECK (years_exp >= 0),
    phone          VARCHAR(30),
    reject_reason  TEXT,                            -- 拒绝原因，仅 REJECTED 阶段时填写
    applied_at     TIMESTAMPTZ       NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ       NOT NULL DEFAULT NOW(),

    -- 同一候选人不能对同一岗位重复投递
    CONSTRAINT applications_job_candidate_unique UNIQUE (job_id, candidate_id)
);

COMMENT ON TABLE  applications              IS '候选人对岗位的申请记录，核心业务实体';
COMMENT ON COLUMN applications.stage        IS '当前所处招聘阶段，状态机控制，不可回退';
COMMENT ON COLUMN applications.resume_url   IS '简历 PDF 的相对路径，如 /uploads/resumes/xxx.pdf';
COMMENT ON COLUMN applications.reject_reason IS '拒绝原因，HR 拒绝时必填';

-- 索引
CREATE INDEX idx_applications_job_id       ON applications (job_id);
CREATE INDEX idx_applications_candidate_id ON applications (candidate_id);
CREATE INDEX idx_applications_stage        ON applications (stage);
CREATE INDEX idx_applications_applied_at   ON applications (applied_at DESC);

CREATE TRIGGER trg_applications_updated_at
    BEFORE UPDATE ON applications
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ────────────────────────────────────────────────────────────
--  5. stage_logs — 阶段流转审计日志
-- ────────────────────────────────────────────────────────────

CREATE TABLE stage_logs (
    id             BIGSERIAL         PRIMARY KEY,
    application_id BIGINT            NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    operated_by    BIGINT            NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    from_stage     application_stage,              -- NULL 表示初始投递
    to_stage       application_stage NOT NULL,
    note           TEXT,                           -- 操作备注（可选）
    operated_at    TIMESTAMPTZ       NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  stage_logs               IS '候选人阶段流转的操作审计日志，只增不删';
COMMENT ON COLUMN stage_logs.from_stage    IS '流转前阶段，NULL 代表初始状态（投递时）';
COMMENT ON COLUMN stage_logs.to_stage      IS '流转后阶段';
COMMENT ON COLUMN stage_logs.operated_by   IS 'FK → users，执行流转操作的 HR/管理员';
COMMENT ON COLUMN stage_logs.note          IS '操作备注，拒绝时可记录简短原因';

-- 索引
CREATE INDEX idx_stage_logs_application_id ON stage_logs (application_id);
CREATE INDEX idx_stage_logs_operated_at    ON stage_logs (operated_at DESC);

-- ────────────────────────────────────────────────────────────
--  6. interview_records — 面试评价记录
-- ────────────────────────────────────────────────────────────

CREATE TABLE interview_records (
    id             BIGSERIAL            PRIMARY KEY,
    application_id BIGINT               NOT NULL REFERENCES applications(id) ON DELETE CASCADE,
    interviewer_id BIGINT               REFERENCES users(id) ON DELETE SET NULL,
    round          VARCHAR(100)         NOT NULL,  -- 面试轮次，如 "技术一面"、"HR 终面"
    rating         SMALLINT             CHECK (rating BETWEEN 1 AND 5),
    strengths      TEXT,                           -- 候选人优势
    weaknesses     TEXT,                           -- 候选人不足
    conclusion     interview_conclusion,           -- PASS / REJECT / HOLD
    notes          TEXT,                           -- 补充备注
    created_at     TIMESTAMPTZ          NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ          NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  interview_records               IS '面试轮次评价记录，支持多轮存储';
COMMENT ON COLUMN interview_records.round         IS '面试轮次描述，如「技术一面」「HR 终面」';
COMMENT ON COLUMN interview_records.rating        IS '综合评分 1–5 星';
COMMENT ON COLUMN interview_records.conclusion    IS '面试结论：PASS / REJECT / HOLD';
COMMENT ON COLUMN interview_records.interviewer_id IS 'FK → users，面试官（允许账号被删除后保留记录）';

-- 索引
CREATE INDEX idx_interview_records_application_id ON interview_records (application_id);
CREATE INDEX idx_interview_records_interviewer_id ON interview_records (interviewer_id);
CREATE INDEX idx_interview_records_created_at     ON interview_records (created_at DESC);

CREATE TRIGGER trg_interview_records_updated_at
    BEFORE UPDATE ON interview_records
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- ────────────────────────────────────────────────────────────
--  7. refresh_tokens — JWT Refresh Token 存储
--     （Redis 优先；此表作为持久化备份或无 Redis 降级方案）
-- ────────────────────────────────────────────────────────────

CREATE TABLE refresh_tokens (
    id         BIGSERIAL    PRIMARY KEY,
    user_id    BIGINT       NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,              -- SHA-256(token) 存储，避免泄露
    expires_at TIMESTAMPTZ  NOT NULL,
    revoked    BOOLEAN      NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ  NOT NULL DEFAULT NOW(),

    CONSTRAINT refresh_tokens_hash_unique UNIQUE (token_hash)
);

COMMENT ON TABLE  refresh_tokens            IS 'JWT RefreshToken 持久化，支持主动吊销';
COMMENT ON COLUMN refresh_tokens.token_hash IS 'SHA-256(rawToken)，避免数据库泄露后 token 被直接使用';
COMMENT ON COLUMN refresh_tokens.revoked    IS 'TRUE 表示已主动登出/吊销';

-- 索引
CREATE INDEX idx_refresh_tokens_user_id    ON refresh_tokens (user_id);
CREATE INDEX idx_refresh_tokens_expires_at ON refresh_tokens (expires_at);

-- ────────────────────────────────────────────────────────────
--  种子数据：初始化管理员账号 & 示例部门
--
--  ⚠️ Admin 账号：
--    email    = admin@ats.local
--    password = Admin@123         （首次登录后必须改！）
--    BCrypt   = $2b$12$8daJQt9...（cost=12，由 Bun.password.hash 生成，Spring 兼容 2a/2b）
--
--  生产环境部署前请重新生成 hash 并替换此行：
--    bun -e "console.log(await Bun.password.hash('YOUR_NEW_PWD', { algorithm: 'bcrypt', cost: 12 }))"
-- ────────────────────────────────────────────────────────────

INSERT INTO users (email, password_hash, full_name, role) VALUES
    ('admin@ats.local',
     '$2b$12$8daJQt9doR02lLfOVSmVWOW7e7DgA7pLAD39IgeqoTHdxmz0odHVm',
     'System Admin',
     'ADMIN');

INSERT INTO departments (name) VALUES
    ('技术研发'),
    ('产品设计'),
    ('市场营销'),
    ('人力资源'),
    ('财务法务');

-- ────────────────────────────────────────────────────────────
--  种子：标签库（前端选岗位标签时的下拉选项）
-- ────────────────────────────────────────────────────────────

INSERT INTO tags (slug, name, category) VALUES
    -- 技术栈
    ('java',         'Java',         'TECH'),
    ('spring-boot',  'Spring Boot',  'TECH'),
    ('typescript',   'TypeScript',   'TECH'),
    ('vue3',         'Vue 3',        'TECH'),
    ('react',        'React',        'TECH'),
    ('node',         'Node.js',      'TECH'),
    ('python',       'Python',       'TECH'),
    ('go',           'Go',           'TECH'),
    ('postgres',     'PostgreSQL',   'TECH'),
    ('redis',        'Redis',        'TECH'),
    ('docker',       'Docker',       'TECH'),
    ('kubernetes',   'Kubernetes',   'TECH'),
    ('aws',          'AWS',          'TECH'),
    -- 软实力
    ('teamwork',     '团队协作',     'SOFT'),
    ('communication','跨部门沟通',   'SOFT'),
    ('ownership',    'Ownership',    'SOFT'),
    -- 证书
    ('pmp',          'PMP',          'CERT'),
    ('aws-saa',      'AWS SAA',      'CERT'),
    -- 语言
    ('english',      '英语流利',     'LANG'),
    ('japanese-n1',  '日语 N1',      'LANG'),
    -- 业务领域
    ('fintech',      '金融科技',     'DOMAIN'),
    ('ecommerce',    '电商',         'DOMAIN'),
    ('saas-b2b',     'SaaS B2B',     'DOMAIN'),
    ('hr-tech',      'HR Tech',      'DOMAIN');

-- ────────────────────────────────────────────────────────────
--  种子：示例岗位（id = 1, 2, 3）
--    - 由 admin (users.id = 1) 创建，挂在「技术研发 / 产品设计」部门
--    - 1 个 PUBLISHED + 1 个 PAUSED + 1 个 DRAFT，方便演示不同状态
-- ────────────────────────────────────────────────────────────

INSERT INTO jobs (
    department_id, created_by, title, description, location,
    work_type, level, salary_min, salary_max, headcount,
    status, published_at
) VALUES
    (1, 1,
     '高级 Java 后端工程师',
     '## 岗位描述

负责 ATS 招聘平台核心服务的设计与开发，使用 Java 21 + Spring Boot 3.4 + PostgreSQL 16。

## 任职要求

- 5+ 年 Java 服务端开发经验
- 精通 Spring 生态（Boot / Security / Data）
- 熟悉 PostgreSQL 索引与调优、Redis 缓存设计
- 有 Docker / Kubernetes 部署经验加分

## 加分项

- 主导过 10+ 万 QPS 系统
- 开源贡献者优先',
     '上海·浦东', 'FULL_TIME', 'SENIOR', 30000, 50000, 2,
     'PUBLISHED', NOW() - INTERVAL '3 days'),

    (1, 1,
     'Vue 前端工程师（中级）',
     '## 岗位描述

参与 ATS 招聘平台前端建设，技术栈 Vue 3.5 + TypeScript + Naive UI + UnoCSS。

## 任职要求

- 3+ 年 Vue 项目经验
- 熟悉 TypeScript / Pinia / Vue Router
- 有组件库设计经验，理解原子化 CSS 思想
- 注重交互细节，懂动效曲线设计

## 工作模式

远程办公，每月线下 1 次集中协作日。',
     '远程办公', 'REMOTE', 'MID', 20000, 35000, 1,
     'PUBLISHED', NOW() - INTERVAL '1 day'),

    (2, 1,
     '产品经理（HR SaaS）',
     '## 岗位描述

负责 ATS 产品规划，深耕招聘场景，对接 HR 客户需求。（暂时暂停收件）

## 任职要求

- 5+ 年 B2B SaaS 产品经验
- 有 HR 行业背景优先
- 能写清晰的 PRD 与产品决策文档',
     '北京·朝阳', 'FULL_TIME', 'SENIOR', 25000, 45000, 1,
     'PAUSED', NOW() - INTERVAL '14 days');

-- 关联标签
INSERT INTO job_tags (job_id, tag_id)
SELECT 1, id FROM tags WHERE slug IN ('java', 'spring-boot', 'postgres', 'redis', 'docker', 'kubernetes', 'ownership');
INSERT INTO job_tags (job_id, tag_id)
SELECT 2, id FROM tags WHERE slug IN ('vue3', 'typescript', 'teamwork', 'communication');
INSERT INTO job_tags (job_id, tag_id)
SELECT 3, id FROM tags WHERE slug IN ('saas-b2b', 'hr-tech', 'communication', 'english');

-- ────────────────────────────────────────────────────────────
--  视图：招聘漏斗（各阶段申请数，用于数据看板）
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_pipeline_funnel AS
SELECT
    j.id          AS job_id,
    j.title       AS job_title,
    a.stage,
    COUNT(*)      AS cnt
FROM applications a
JOIN jobs j ON j.id = a.job_id
WHERE j.deleted_at IS NULL
GROUP BY j.id, j.title, a.stage
ORDER BY j.id, a.stage;

COMMENT ON VIEW v_pipeline_funnel IS '按岗位和阶段聚合的申请数量，供招聘漏斗图使用';

-- ────────────────────────────────────────────────────────────
--  视图：本月招聘概览（数据看板首页卡片）
-- ────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_monthly_overview AS
SELECT
    COUNT(*) FILTER (WHERE applied_at >= date_trunc('month', NOW()))  AS new_applications,
    COUNT(*) FILTER (WHERE stage = 'OFFER'
                      AND updated_at >= date_trunc('month', NOW()))   AS offers_sent,
    COUNT(*) FILTER (WHERE stage = 'HIRED'
                      AND updated_at >= date_trunc('month', NOW()))   AS hires
FROM applications;

COMMENT ON VIEW v_monthly_overview IS '本月新增申请数、Offer 数、入职数，供首页概览卡片使用';

-- ============================================================
--  ATS 招聘管理系统 — 数据库 Schema
--  数据库：PostgreSQL 16
--  版本：v1.0   日期：2026-05-21
-- ============================================================

-- ────────────────────────────────────────────────────────────
--  枚举类型
-- ────────────────────────────────────────────────────────────

-- 用户角色
CREATE TYPE user_role AS ENUM (
    'ADMIN',      -- 超级管理员
    'HR',         -- HR / 招聘专员
    'CANDIDATE'   -- 候选人
);

-- 岗位状态
CREATE TYPE job_status AS ENUM (
    'DRAFT',   -- 草稿，未发布
    'OPEN',    -- 开放，接受申请
    'CLOSED'   -- 已关闭，不再接受申请
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
--  3. jobs — 岗位表
-- ────────────────────────────────────────────────────────────

CREATE TABLE jobs (
    id            BIGSERIAL     PRIMARY KEY,
    department_id BIGINT        REFERENCES departments(id) ON DELETE SET NULL,
    created_by    BIGINT        NOT NULL REFERENCES users(id) ON DELETE RESTRICT,
    title         VARCHAR(200)  NOT NULL,
    location      VARCHAR(200),
    salary_range  VARCHAR(100),                  -- 如 "20k–30k"
    headcount     SMALLINT      NOT NULL DEFAULT 1 CHECK (headcount > 0),
    description   TEXT,                          -- 岗位 JD，支持富文本
    status        job_status    NOT NULL DEFAULT 'DRAFT',
    created_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ   NOT NULL DEFAULT NOW()
);

COMMENT ON TABLE  jobs               IS '招聘岗位，由 HR 创建和维护';
COMMENT ON COLUMN jobs.department_id IS 'FK → departments，部门可被删除，置 NULL';
COMMENT ON COLUMN jobs.created_by    IS 'FK → users，创建人（HR）';
COMMENT ON COLUMN jobs.headcount     IS '招聘人数，至少为 1';
COMMENT ON COLUMN jobs.status        IS 'DRAFT→OPEN→CLOSED，只能向前推进';

-- 索引
CREATE INDEX idx_jobs_status        ON jobs (status);
CREATE INDEX idx_jobs_department_id ON jobs (department_id);
CREATE INDEX idx_jobs_created_by    ON jobs (created_by);
CREATE INDEX idx_jobs_created_at    ON jobs (created_at DESC);

-- 全文检索索引（标题 + 地点）
CREATE INDEX idx_jobs_fts ON jobs USING GIN (
    to_tsvector('simple', coalesce(title, '') || ' ' || coalesce(location, ''))
);

CREATE TRIGGER trg_jobs_updated_at
    BEFORE UPDATE ON jobs
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

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

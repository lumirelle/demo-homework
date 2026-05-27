/**
 * Admin 用户管理 API · 仅 ADMIN 角色可调用。
 * 后端：com.ats.controller.AdminController
 */
import { post } from './request'
import type { MeVO } from './auth'

/** 单个创建用户的请求体 · role 只能是 HR 或 CANDIDATE */
export interface CreateUserReq {
  email: string
  password: string
  fullName: string
  role: 'HR' | 'CANDIDATE'
  /** HR 必填：绑定的子部门 id 列表（M6 多对多） */
  subDepartmentIds?: number[]
}

/** 批量创建结果中的单行结果 */
export interface BatchCreateItem {
  rowIndex: number
  email: string
  success: boolean
  userId?: number
  role?: 'HR' | 'CANDIDATE'
  errorCode?: number
  errorMsg?: string
}

/** 批量创建汇总结果 */
export interface BatchCreateResult {
  successCount: number
  failureCount: number
  items: BatchCreateItem[]
}

export const adminApi = {
  /** POST /admin/users · 单个创建 HR / CANDIDATE 账号 */
  createUser: (data: CreateUserReq) => post<MeVO>('/admin/users', data),

  /**
   * POST /admin/users/batch · 批量创建（最多 100 条 / 批）。
   * 单行失败不会回滚整批；前端按 items 逐行展示成功 / 失败结果。
   */
  batchCreate: (users: CreateUserReq[]) =>
    post<BatchCreateResult>('/admin/users/batch', { users }),
}

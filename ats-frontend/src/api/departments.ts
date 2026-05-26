import { get } from './request'

// ─────────────────────────── DTO ───────────────────────────

export interface DepartmentVO {
  id: number
  name: string
}

// ─────────────────────────── API ───────────────────────────

export const departmentsApi = {
  /** 全量部门字典（公开 GET 接口，前端筛选下拉用）。 */
  listAll: () => get<DepartmentVO[]>('/departments'),
}

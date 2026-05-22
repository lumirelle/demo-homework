/* oxlint-disable promise/prefer-await-to-callbacks, promise/no-promise-in-callback -- axios interceptors are callback-based by design */
import type { AxiosError, AxiosInstance, AxiosRequestConfig, AxiosResponse } from 'axios'
import axios from 'axios'

/** 后端统一响应结构 */
export interface ApiResponse<T = unknown> {
  code: number
  msg: string
  data: T | null
}

const baseURL = import.meta.env.VITE_API_BASE_URL || '/api/v1'

const request: AxiosInstance = axios.create({
  baseURL,
  timeout: 15000,
  headers: {
    'Content-Type': 'application/json',
  },
})

/* ── 请求拦截器：注入 token（M1 起激活） ───────────── */
request.interceptors.request.use(
  (config) => {
    // M1: 从 useAuthStore 取 accessToken 注入 Authorization
    return config
  },
  err => Promise.reject(err),
)

/* ── 响应拦截器：解包 { code, msg, data } ──────────── */
request.interceptors.response.use(
  (resp: AxiosResponse<ApiResponse>) => {
    const body = resp.data
    if (body && typeof body === 'object' && 'code' in body) {
      if (body.code === 0)
        return body.data as never
      return Promise.reject(new BizError(body.code, body.msg, body))
    }
    return resp.data as never
  },
  async (err: AxiosError<ApiResponse>) => {
    const status = err.response?.status
    const body = err.response?.data
    const code = body?.code ?? status ?? 0
    const msg = body?.msg ?? err.message ?? '网络错误'

    // M1: 若 status === 401 且未在 refresh 队列中 → 触发 refresh + 重试
    return Promise.reject(new BizError(code, msg, body))
  },
)

export class BizError extends Error {
  code: number
  body?: ApiResponse | undefined
  constructor(code: number, msg: string, body?: ApiResponse) {
    super(msg)
    this.code = code
    this.body = body
  }
}

/** 类型化助手：拿到的就是 data，已剥壳 */
export function get<T = unknown>(url: string, config?: AxiosRequestConfig) {
  return request.get<unknown, T>(url, config)
}
export function post<T = unknown, D = unknown>(url: string, data?: D, config?: AxiosRequestConfig) {
  return request.post<unknown, T>(url, data, config)
}
export function put<T = unknown, D = unknown>(url: string, data?: D, config?: AxiosRequestConfig) {
  return request.put<unknown, T>(url, data, config)
}
export function patch<T = unknown, D = unknown>(url: string, data?: D, config?: AxiosRequestConfig) {
  return request.patch<unknown, T>(url, data, config)
}
export function del<T = unknown>(url: string, config?: AxiosRequestConfig) {
  return request.delete<unknown, T>(url, config)
}

export default request

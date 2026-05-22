package com.ats.common.exception;

import lombok.Getter;

/**
 * 业务错误码 · 5 段编码
 * <p>
 * 10xxx — 鉴权/权限
 * 20xxx — 业务规则（状态机、重复投递等）
 * 30xxx — 资源相关（文件、上传等）
 * 40xxx — 参数校验/请求格式
 * 50xxx — 系统内部
 */
@Getter
public enum ErrorCode {

    OK(0, "ok"),

    UNAUTHORIZED(10001, "未登录或登录已过期"),
    FORBIDDEN(10002, "无权限执行此操作"),
    INVALID_TOKEN(10003, "无效或过期的 token"),

    BIZ_RULE_VIOLATED(20001, "业务规则校验失败"),
    ILLEGAL_TRANSITION(20002, "非法状态流转"),
    DUPLICATE_APPLICATION(20003, "已投递过此岗位，请勿重复操作"),
    REJECT_REASON_REQUIRED(20004, "拒绝时必须填写原因"),

    FILE_TYPE_NOT_ALLOWED(30001, "文件类型不被允许"),
    FILE_TOO_LARGE(30002, "文件超出大小限制"),
    FILE_NOT_FOUND(30003, "文件不存在或无权访问"),

    VALIDATION_FAILED(40001, "请求参数校验失败"),
    BAD_REQUEST(40002, "请求格式错误"),

    INTERNAL_ERROR(50000, "服务器内部错误");

    private final int code;
    private final String msg;

    ErrorCode(int code, String msg) {
        this.code = code;
        this.msg = msg;
    }
}

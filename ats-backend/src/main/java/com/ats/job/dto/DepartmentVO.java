package com.ats.job.dto;

import lombok.Builder;
import lombok.Data;

/**
 * 部门字典 VO（id → name）。
 * 用于前端筛选下拉、岗位详情显示等只读场景。
 */
@Data
@Builder
public class DepartmentVO {
    private Long id;
    private String name;
}

package com.ats.job;

import com.ats.job.dto.DepartmentVO;
import com.ats.repository.JobMapper;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

/**
 * 部门字典服务（只读）。
 * <p>
 * 实现复用 {@link JobMapper#selectAllDepartments()}，避免为只读字典新建独立 Mapper / Entity。
 * 数据源是 {@code departments} 表（M0 seed 已植入 5 条种子数据）。
 */
@Service
@RequiredArgsConstructor
public class DepartmentService {

    private final JobMapper jobMapper;

    /** 全量部门列表。前端筛选下拉用。 */
    public List<DepartmentVO> listAll() {
        return jobMapper.selectAllDepartments().stream()
                .map(DepartmentService::toVO)
                .toList();
    }

    private static DepartmentVO toVO(Map<String, Object> row) {
        return DepartmentVO.builder()
                .id(((Number) row.get("id")).longValue())
                .name((String) row.get("name"))
                .build();
    }
}

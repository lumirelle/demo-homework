package com.ats.job.dto;

import com.ats.entity.JobLevel;
import com.ats.entity.JobWorkType;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.PositiveOrZero;
import jakarta.validation.constraints.Size;
import lombok.Data;

import java.util.List;

/**
 * 岗位编辑请求。所有字段均 optional：null = 不修改该字段。
 * tagIds 例外：null = 不动；空数组 [] = 清空所有标签；非空数组 = 全量替换。
 */
@Data
public class JobUpdateReq {

    @Size(max = 200)
    private String title;

    @Size(max = 50_000)
    private String description;

    @Size(max = 200)
    private String location;

    private JobWorkType workType;

    private JobLevel level;

    @PositiveOrZero
    private Integer salaryMin;

    @PositiveOrZero
    private Integer salaryMax;

    @Min(1)
    private Short headcount;

    private Long departmentId;

    /** null=不动，[]=清空，非空=全量替换 */
    private List<Long> tagIds;
}

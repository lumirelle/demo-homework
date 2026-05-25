package com.ats.job.dto;

import com.ats.entity.JobLevel;
import com.ats.entity.JobStatus;
import com.ats.entity.JobWorkType;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.List;

/** 列表项 VO（瘦身版，不含 description）。 */
@Data
@Builder
@NoArgsConstructor
@AllArgsConstructor
public class JobListItemVO {

    private Long id;
    private String title;
    private String location;
    private JobWorkType workType;
    private JobLevel level;
    private Integer salaryMin;
    private Integer salaryMax;
    /** 展示用，如 "30k-50k" / "薪资面议" */
    private String salaryRange;
    private Short headcount;
    private JobStatus status;
    private Integer viewCount;
    private OffsetDateTime publishedAt;
    private OffsetDateTime updatedAt;

    private Long departmentId;
    private String departmentName;
    private Long createdBy;
    private String createdByName;

    /** 限制最多 5 个，避免列表过宽 */
    private List<TagVO> tags;
}

package com.ats.repository;

import com.ats.entity.Application;
import com.baomidou.mybatisplus.core.mapper.BaseMapper;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;
import org.apache.ibatis.annotations.Select;

import java.util.List;
import java.util.Map;

@Mapper
public interface ApplicationMapper extends BaseMapper<Application> {

    /**
     * 看板视图：按 stage 聚合该岗位（或当前 HR 名下全部岗位）的投递数。
     * 用 {@code GROUP BY stage} 一次查询返回 8 行（包含计数为 0 的阶段需在 service 里补齐）。
     *
     * @param jobId 单岗位看板用；为 null 则按 HR ownerId 名下所有岗位聚合
     * @param hrUserId HR 视角用：与 jobs.created_by 关联裁剪可见范围；Admin 视角传 null 不裁剪
     */
    @Select({
        "<script>",
        "SELECT a.stage AS stage, COUNT(*) AS cnt",
        "FROM applications a",
        "JOIN jobs j ON j.id = a.job_id",
        "WHERE j.deleted_at IS NULL",
        "<if test='jobId != null'> AND a.job_id = #{jobId} </if>",
        "<if test='hrUserId != null'> AND j.created_by = #{hrUserId} </if>",
        "GROUP BY a.stage",
        "</script>"
    })
    List<Map<String, Object>> countByStage(@Param("jobId") Long jobId,
                                           @Param("hrUserId") Long hrUserId);

    /**
     * 看板每列的投递明细（含候选人姓名 + 邮箱 + 投递时间 + 最近变更时间）。
     * 同时返回 job_id / job_title 供前端跨岗位看板分组。
     */
    @Select({
        "<script>",
        "SELECT a.id, a.job_id, j.title AS job_title, a.candidate_id,",
        "       u.full_name AS candidate_name, u.email AS candidate_email,",
        "       a.stage, a.applied_at, a.updated_at, a.years_exp",
        "FROM applications a",
        "JOIN jobs j  ON j.id = a.job_id",
        "JOIN users u ON u.id = a.candidate_id",
        "WHERE j.deleted_at IS NULL",
        "<if test='jobId != null'> AND a.job_id = #{jobId} </if>",
        "<if test='hrUserId != null'> AND j.created_by = #{hrUserId} </if>",
        "<if test='stage != null'> AND a.stage = #{stage}::application_stage </if>",
        "ORDER BY a.updated_at DESC",
        "<if test='limit != null'> LIMIT #{limit} </if>",
        "</script>"
    })
    List<Map<String, Object>> listBoardItems(@Param("jobId") Long jobId,
                                             @Param("hrUserId") Long hrUserId,
                                             @Param("stage") String stage,
                                             @Param("limit") Integer limit);

    /** 候选人「我的投递」：按 candidate_id 列出，带岗位标题与最近 stage。 */
    @Select({
        "SELECT a.id, a.job_id, j.title AS job_title, j.status AS job_status,",
        "       a.stage, a.applied_at, a.updated_at",
        "FROM applications a",
        "JOIN jobs j ON j.id = a.job_id",
        "WHERE a.candidate_id = #{candidateId}",
        "ORDER BY a.updated_at DESC"
    })
    List<Map<String, Object>> listByCandidate(@Param("candidateId") Long candidateId);

    /** 是否已投递过 (job_id, candidate_id) ；唯一约束在 DB 也兜底，但提前检查 UX 更友好。 */
    @Select("SELECT COUNT(1) FROM applications WHERE job_id = #{jobId} AND candidate_id = #{candidateId}")
    long countDuplicate(@Param("jobId") Long jobId, @Param("candidateId") Long candidateId);
}

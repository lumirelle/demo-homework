package com.ats.stats;

import com.ats.common.exception.BizException;
import com.ats.common.exception.ErrorCode;
import com.ats.common.security.SecurityUtil;
import com.ats.entity.ApplicationStage;
import com.ats.repository.ApplicationMapper;
import com.ats.repository.StatsMapper;
import com.ats.stats.dto.FunnelItemVO;
import com.ats.stats.dto.FunnelVO;
import com.ats.stats.dto.OverviewVO;
import com.ats.stats.dto.PublicStatsVO;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * 数据看板 service · M5.1。
 *
 * <h3>权限切片</h3>
 * 与 ApplicationService.board / InterviewService 完全同构：
 * <ul>
 *   <li>ADMIN：全局视角，hrUserId 传 {@code null}</li>
 *   <li>HR：自己视角，hrUserId = 当前用户 id</li>
 *   <li>CANDIDATE：404 不可达（controller 层 {@code @PreAuthorize} 拦截）</li>
 * </ul>
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class StatsService {

    private final ApplicationMapper applicationMapper;
    private final StatsMapper statsMapper;

    /** 业务时区与 application.yml 的 jackson.time-zone 对齐 */
    private static final ZoneId BIZ_ZONE = ZoneId.of("Asia/Shanghai");

    /** 漏斗 stage 固定顺序（与看板列同序），缺失 stage 也要补 0 */
    private static final List<ApplicationStage> FUNNEL_ORDER = List.of(
            ApplicationStage.APPLIED,
            ApplicationStage.SCREENING_PASS,
            ApplicationStage.PHONE_INTERVIEW,
            ApplicationStage.TECH_INTERVIEW,
            ApplicationStage.HR_INTERVIEW,
            ApplicationStage.OFFER,
            ApplicationStage.HIRED,
            ApplicationStage.REJECTED
    );

    public FunnelVO funnel(Long jobId) {
        Long hrUserId = effectiveHrUserId();
        // 复用 ApplicationMapper.countByStage：jobId/hrUserId 双过滤已支持
        List<Map<String, Object>> rows = applicationMapper.countByStage(jobId, hrUserId);

        Map<ApplicationStage, Long> counts = new HashMap<>();
        for (Map<String, Object> row : rows) {
            String stageStr = (String) row.get("stage");
            if (stageStr == null) continue;
            Object cntObj = row.get("cnt");
            long cnt = cntObj instanceof Number n ? n.longValue() : 0L;
            counts.put(ApplicationStage.valueOf(stageStr), cnt);
        }

        List<FunnelItemVO> items = new ArrayList<>(FUNNEL_ORDER.size());
        long total = 0;
        long max = 0;
        for (ApplicationStage st : FUNNEL_ORDER) {
            long c = counts.getOrDefault(st, 0L);
            items.add(FunnelItemVO.builder().stage(st).count(c).build());
            total += c;
            max = Math.max(max, c);
        }

        return FunnelVO.builder()
                .items(items)
                .total(total)
                .max(max)
                .build();
    }

    /**
     * 公开聚合统计（permitAll 接口） —— 不调 effectiveHrUserId，直接传 null 看全平台快照。
     * <p>
     * 复用 {@link ApplicationMapper#countByStage(Long, Long)} 拿全量 stage 分布，
     * 在 service 内做 5 stage group 聚合，避免新增 mapper 方法。
     */
    public PublicStatsVO publicStats() {
        // 全平台（hrUserId = null, jobId = null）的 stage 分布
        List<Map<String, Object>> rows = applicationMapper.countByStage(null, null);
        long screening = 0;
        long interview = 0;
        long offer = 0;
        for (Map<String, Object> row : rows) {
            String stageStr = (String) row.get("stage");
            if (stageStr == null) continue;
            long cnt = row.get("cnt") instanceof Number n ? n.longValue() : 0L;
            ApplicationStage stage = ApplicationStage.valueOf(stageStr);
            switch (stage) {
                case APPLIED, SCREENING_PASS -> screening += cnt;
                case PHONE_INTERVIEW, TECH_INTERVIEW, HR_INTERVIEW -> interview += cnt;
                case OFFER -> offer += cnt;
                default -> {
                    // HIRED / REJECTED 不计入 "进行中" 水位
                }
            }
        }

        return PublicStatsVO.builder()
                .screeningCount(screening)
                .interviewCount(interview)
                .offerCount(offer)
                .publishedJobs(statsMapper.countActiveJobs(null))
                .coveredDepartments(statsMapper.countCoveredDepartments())
                .build();
    }

    public OverviewVO overview() {
        Long hrUserId = effectiveHrUserId();
        OffsetDateTime since = monthStart();

        long newApps = statsMapper.countNewApplications(since, hrUserId);
        long offers = statsMapper.countTransitionsToStage(since, ApplicationStage.OFFER.name(), hrUserId);
        long hires = statsMapper.countTransitionsToStage(since, ApplicationStage.HIRED.name(), hrUserId);
        long activeJobs = statsMapper.countActiveJobs(hrUserId);

        return OverviewVO.builder()
                .newApplicationsThisMonth(newApps)
                .offersThisMonth(offers)
                .hiresThisMonth(hires)
                .activeJobs(activeJobs)
                .build();
    }

    /**
     * 当前用户切片 ID：
     * - ADMIN 返回 null（看全部）
     * - HR 返回自己的 userId
     * - 其他角色应被 controller 拦截不到此处；保险起见抛 FORBIDDEN
     */
    Long effectiveHrUserId() {
        if (SecurityUtil.isAdmin()) return null;
        if (SecurityUtil.isHr()) return SecurityUtil.requireUserId();
        throw BizException.of(ErrorCode.FORBIDDEN);
    }

    /**
     * 业务月份起点（本月 1 号 00:00 ZoneId=Asia/Shanghai 对应的 OffsetDateTime）。
     * 用 service 内部计算而非 SQL 内 NOW() 是为了：(1) 测试可控；(2) 避免 DB 时区漂移。
     */
    static OffsetDateTime monthStart() {
        LocalDate firstOfMonth = LocalDate.now(BIZ_ZONE).withDayOfMonth(1);
        return firstOfMonth.atStartOfDay(BIZ_ZONE).toOffsetDateTime();
    }

    // 非业务方法：让单测能直接验证 stage 顺序
    static List<ApplicationStage> funnelOrderForTest() {
        return FUNNEL_ORDER.stream().sorted(Comparator.naturalOrder()).toList();
    }
}

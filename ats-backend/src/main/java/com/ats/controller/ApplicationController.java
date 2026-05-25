package com.ats.controller;

import com.ats.application.ApplicationService;
import com.ats.application.dto.ApplicationCreateReq;
import com.ats.application.dto.ApplicationDetailVO;
import com.ats.application.dto.ApplicationListItemVO;
import com.ats.application.dto.BoardVO;
import com.ats.application.dto.StageTransitionReq;
import com.ats.common.response.ApiResponse;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

import java.util.List;

/**
 * 投递（applications）+ 看板（board）+ 阶段流转（transitions）。
 * <p>
 * 权限矩阵：
 * <pre>
 *   POST /applications              CANDIDATE         投递
 *   GET  /applications/me           CANDIDATE         我的投递列表
 *   GET  /applications/board        HR / ADMIN        看板（jobId 可选）
 *   GET  /applications/{id}         OWNER / HR / ADMIN 详情（service 内裁剪 phone 等敏感字段）
 *   POST /applications/{id}/transitions  HR / ADMIN   推进阶段
 * </pre>
 */
@RestController
@RequestMapping("/applications")
@RequiredArgsConstructor
public class ApplicationController {

    private final ApplicationService applicationService;

    @PostMapping
    @PreAuthorize("hasRole('CANDIDATE')")
    public ApiResponse<ApplicationDetailVO> apply(@Valid @RequestBody ApplicationCreateReq req) {
        return ApiResponse.ok(applicationService.apply(req));
    }

    @GetMapping("/me")
    @PreAuthorize("hasRole('CANDIDATE')")
    public ApiResponse<List<ApplicationListItemVO>> listMine() {
        return ApiResponse.ok(applicationService.listMine());
    }

    @GetMapping("/board")
    @PreAuthorize("hasAnyRole('HR', 'ADMIN')")
    public ApiResponse<BoardVO> board(@RequestParam(required = false) Long jobId,
                                      @RequestParam(required = false, defaultValue = "50") Integer itemsPerColumn) {
        return ApiResponse.ok(applicationService.board(jobId, itemsPerColumn));
    }

    @GetMapping("/{id}")
    public ApiResponse<ApplicationDetailVO> detail(@PathVariable Long id) {
        // service 内做精细鉴权（owner / job-owner-hr / admin）
        return ApiResponse.ok(applicationService.getDetail(id));
    }

    @PostMapping("/{id}/transitions")
    @PreAuthorize("hasAnyRole('HR', 'ADMIN')")
    public ApiResponse<ApplicationDetailVO> transition(@PathVariable Long id,
                                                       @Valid @RequestBody StageTransitionReq req) {
        return ApiResponse.ok(applicationService.transition(id, req.getToStage(), req.getNote()));
    }
}

package com.ats.controller;

import com.ats.auth.dto.CreateUserReq;
import com.ats.auth.dto.MeVO;
import com.ats.common.exception.BizException;
import com.ats.common.exception.ErrorCode;
import com.ats.common.response.ApiResponse;
import com.ats.entity.User;
import com.ats.repository.UserMapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/admin")
@RequiredArgsConstructor
public class AdminController {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    /**
     * Admin 创建 HR / CANDIDATE 账号（带初始密码，首次登录后可自行修改）。
     * 仅 ADMIN 角色可调用；ADMIN 账号本身只能通过 DB seed 或直接 SQL 生成，
     * 不允许通过 API 创建（防止权限提升攻击）。
     */
    @PostMapping("/users")
    @PreAuthorize("hasRole('ADMIN')")
    public ApiResponse<MeVO> createUser(@Valid @RequestBody CreateUserReq req) {
        long count = userMapper.selectCount(
                new LambdaQueryWrapper<User>().eq(User::getEmail, req.getEmail().toLowerCase()));
        if (count > 0) throw BizException.of(ErrorCode.EMAIL_ALREADY_EXISTS);

        User user = new User();
        user.setEmail(req.getEmail().toLowerCase());
        user.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        user.setFullName(req.getFullName());
        user.setRole(req.getRole().toUpperCase());
        user.setIsActive(true);
        userMapper.insert(user);

        return ApiResponse.ok(MeVO.builder()
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .role(user.getRole())
                .build());
    }
}

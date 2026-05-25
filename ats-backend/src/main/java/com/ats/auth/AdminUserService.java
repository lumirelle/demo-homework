package com.ats.auth;

import com.ats.auth.dto.BatchCreateItemVO;
import com.ats.auth.dto.BatchCreateUsersReq;
import com.ats.auth.dto.BatchCreateUsersVO;
import com.ats.auth.dto.CreateUserReq;
import com.ats.auth.dto.MeVO;
import com.ats.common.exception.BizException;
import com.ats.common.exception.ErrorCode;
import com.ats.entity.User;
import com.ats.repository.UserMapper;
import com.baomidou.mybatisplus.core.conditions.query.LambdaQueryWrapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;

/**
 * Admin 用户管理服务：单个 / 批量创建 HR / CANDIDATE 账号。
 *
 * 设计要点：
 * - 单个创建：事务内执行，重复邮箱抛 {@link BizException}；
 * - 批量创建：每行独立 try / catch，单行失败不影响其余行 ——
 *   这样运营侧"导入 50 条 HR、其中 3 条邮箱已存在"时不会整批回滚，
 *   前端可逐行展示成功 / 失败状态；
 * - 批量请求内部还需查重 email 重复（如同批 2 行写同一邮箱），
 *   先匹配先成功、后续记为 EMAIL_ALREADY_EXISTS；
 * - ADMIN 账号始终拒绝创建（防权限提升）—— Bean Validation 在 DTO 层
 *   已用 {@code @Pattern(regexp = "HR|CANDIDATE")} 拦下，service 层不再额外判断。
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AdminUserService {

    private final UserMapper userMapper;
    private final PasswordEncoder passwordEncoder;

    /** 创建单个 HR / CANDIDATE 账号。 */
    @Transactional
    public MeVO createUser(CreateUserReq req) {
        String email = req.getEmail().toLowerCase();

        long count = userMapper.selectCount(
                new LambdaQueryWrapper<User>().eq(User::getEmail, email));
        if (count > 0) throw BizException.of(ErrorCode.EMAIL_ALREADY_EXISTS);

        User user = persist(email, req.getPassword(), req.getFullName(), req.getRole());

        log.info("[ADMIN] create user id={} email={} role={}", user.getId(), user.getEmail(), user.getRole());
        return MeVO.builder()
                .id(user.getId())
                .email(user.getEmail())
                .fullName(user.getFullName())
                .role(user.getRole())
                .build();
    }

    /**
     * 批量创建。逐行独立提交，单行失败不影响其余行 ——
     * 因此整体方法不加 {@code @Transactional}（每个 mapper.insert 走默认短事务）。
     */
    public BatchCreateUsersVO batchCreate(BatchCreateUsersReq req) {
        List<CreateUserReq> users = req.getUsers();
        List<BatchCreateItemVO> items = new ArrayList<>(users.size());
        Set<String> seenInBatch = new HashSet<>();
        int success = 0;
        int failure = 0;

        for (int i = 0; i < users.size(); i++) {
            CreateUserReq item = users.get(i);
            String email = item.getEmail() == null ? "" : item.getEmail().toLowerCase();

            try {
                if (!seenInBatch.add(email)) {
                    throw new BizException(ErrorCode.EMAIL_ALREADY_EXISTS, "同批次内重复邮箱：" + email);
                }

                long count = userMapper.selectCount(
                        new LambdaQueryWrapper<User>().eq(User::getEmail, email));
                if (count > 0) throw BizException.of(ErrorCode.EMAIL_ALREADY_EXISTS);

                User user = persist(email, item.getPassword(), item.getFullName(), item.getRole());

                items.add(BatchCreateItemVO.builder()
                        .rowIndex(i)
                        .email(email)
                        .success(true)
                        .userId(user.getId())
                        .role(user.getRole())
                        .build());
                success++;
            }
            catch (BizException e) {
                items.add(BatchCreateItemVO.builder()
                        .rowIndex(i)
                        .email(email)
                        .success(false)
                        .errorCode(e.getErrorCode().getCode())
                        .errorMsg(e.getMessage())
                        .build());
                failure++;
            }
            catch (Exception e) {
                log.warn("[ADMIN] batch create row {} unexpected error: {}", i, e.toString());
                items.add(BatchCreateItemVO.builder()
                        .rowIndex(i)
                        .email(email)
                        .success(false)
                        .errorCode(ErrorCode.INTERNAL_ERROR.getCode())
                        .errorMsg("服务异常：" + e.getMessage())
                        .build());
                failure++;
            }
        }

        log.info("[ADMIN] batch create done · total={} success={} failure={}",
                users.size(), success, failure);

        return BatchCreateUsersVO.builder()
                .successCount(success)
                .failureCount(failure)
                .items(items)
                .build();
    }

    private User persist(String email, String password, String fullName, String role) {
        User user = new User();
        user.setEmail(email);
        user.setPasswordHash(passwordEncoder.encode(password));
        user.setFullName(fullName);
        user.setRole(role.toUpperCase());
        user.setIsActive(true);
        userMapper.insert(user);
        return user;
    }
}

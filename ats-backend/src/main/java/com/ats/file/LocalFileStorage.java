package com.ats.file;

import com.ats.common.exception.BizException;
import com.ats.common.exception.ErrorCode;
import lombok.extern.slf4j.Slf4j;
import org.springframework.core.io.Resource;
import org.springframework.core.io.UrlResource;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardCopyOption;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.UUID;

/**
 * 本地文件系统实现。
 *
 * <h3>路径布局</h3>
 * <pre>
 *   {uploadRoot}/
 *     resumes/
 *       2026-05/
 *         {uuid}.pdf
 * </pre>
 *
 * <h3>安全</h3>
 * <ul>
 *   <li><strong>UUID v4 文件名</strong>：122 bit 熵不可枚举，原始文件名不进路径（防中文 / 特殊字符 / 路径穿越）</li>
 *   <li><strong>load() 强制规整</strong>：解析后的绝对路径必须以 {@code uploadRoot} 开头，否则拒绝</li>
 *   <li><strong>不依赖原始文件名</strong>：扩展名只取最后一段（不含 path separator），且与 category 白名单交叉校验</li>
 * </ul>
 */
@Slf4j
@Component
public class LocalFileStorage implements FileStorage {

    private static final DateTimeFormatter MONTH_FMT = DateTimeFormatter.ofPattern("yyyy-MM");

    private final Path uploadRoot;

    public LocalFileStorage(UploadProperties props) {
        this.uploadRoot = Paths.get(props.getPath()).toAbsolutePath().normalize();
        try {
            Files.createDirectories(uploadRoot);
            log.info("[FILE] uploadRoot ready: {}", uploadRoot);
        }
        catch (IOException ex) {
            // 启动期失败直接抛 RuntimeException 阻止应用起来
            throw new IllegalStateException("无法创建上传根目录: " + uploadRoot, ex);
        }
    }

    @Override
    public String save(FileCategory category, MultipartFile file) {
        if (file == null || file.isEmpty()) {
            throw new BizException(ErrorCode.BAD_REQUEST, "文件为空");
        }
        String original = file.getOriginalFilename();
        String ext = extractExtension(original);
        category.validate(file.getContentType(), ext);

        String month = LocalDate.now().format(MONTH_FMT);
        String fileName = UUID.randomUUID() + ext;
        Path dir = uploadRoot.resolve(category.getSubDir()).resolve(month).normalize();
        Path target = dir.resolve(fileName).normalize();

        ensureWithinRoot(target);

        try {
            Files.createDirectories(dir);
            try (InputStream in = file.getInputStream()) {
                Files.copy(in, target, StandardCopyOption.REPLACE_EXISTING);
            }
        }
        catch (IOException ex) {
            log.error("[FILE] write failed: {}", target, ex);
            throw new BizException(ErrorCode.INTERNAL_ERROR, "文件写入失败");
        }

        // 返回对外 URL：/uploads/resumes/2026-05/<uuid>.pdf（前端拿这个串进 application.resumeUrl）
        String url = "/uploads/" + category.getSubDir() + "/" + month + "/" + fileName;
        log.info("[FILE] saved {} bytes ({}) to {}", file.getSize(), file.getContentType(), url);
        return url;
    }

    @Override
    public Resource load(String relativePath) {
        Path resolved = uploadRoot.resolve(relativePath).normalize();
        ensureWithinRoot(resolved);
        if (!Files.exists(resolved) || !Files.isRegularFile(resolved)) {
            throw new BizException(ErrorCode.FILE_NOT_FOUND, "文件不存在或已被删除");
        }
        try {
            Resource res = new UrlResource(resolved.toUri());
            if (!res.isReadable()) {
                throw new BizException(ErrorCode.FILE_NOT_FOUND, "文件不可读");
            }
            return res;
        }
        catch (MalformedURLException ex) {
            throw new BizException(ErrorCode.FILE_NOT_FOUND, "文件路径异常");
        }
    }

    @Override
    public String detectContentType(String relativePath) {
        Path resolved = uploadRoot.resolve(relativePath).normalize();
        ensureWithinRoot(resolved);
        try {
            String type = Files.probeContentType(resolved);
            return type != null ? type : "application/octet-stream";
        }
        catch (IOException ex) {
            return "application/octet-stream";
        }
    }

    /**
     * 路径穿越防御：解析后的绝对路径必须仍在 uploadRoot 之内。
     * 处理 ".." / 符号链接 / 绝对路径注入等场景。
     */
    private void ensureWithinRoot(Path resolved) {
        if (!resolved.startsWith(uploadRoot)) {
            log.warn("[FILE] path traversal blocked: {} not under {}", resolved, uploadRoot);
            throw new BizException(ErrorCode.FILE_NOT_FOUND, "非法路径");
        }
    }

    /**
     * 取最后一个 {@code .} 后的扩展名，全部小写。空 / 无扩展返回空串。
     * 不直接相信 MultipartFile.getOriginalFilename() 的中间路径段，做基本剥离。
     */
    static String extractExtension(String original) {
        if (original == null || original.isBlank()) return "";
        // 剥掉路径段（防止 "../etc/passwd.pdf" 类输入）
        String name = original.replace('\\', '/');
        int slash = name.lastIndexOf('/');
        if (slash >= 0) name = name.substring(slash + 1);
        int dot = name.lastIndexOf('.');
        if (dot < 0 || dot == name.length() - 1) return "";
        return name.substring(dot).toLowerCase();
    }
}

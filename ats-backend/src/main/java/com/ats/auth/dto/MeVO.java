package com.ats.auth.dto;

import lombok.Builder;
import lombok.Data;

@Data
@Builder
public class MeVO {
    private Long id;
    private String email;
    private String fullName;
    private String role;
}

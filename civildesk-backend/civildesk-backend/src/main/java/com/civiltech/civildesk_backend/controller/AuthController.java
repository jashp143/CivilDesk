package com.civiltech.civildesk_backend.controller;

import com.civiltech.civildesk_backend.dto.*;
import com.civiltech.civildesk_backend.exception.BadRequestException;
import com.civiltech.civildesk_backend.model.RefreshToken;
import com.civiltech.civildesk_backend.model.User;
import com.civiltech.civildesk_backend.repository.RefreshTokenRepository;
import com.civiltech.civildesk_backend.repository.UserRepository;
import com.civiltech.civildesk_backend.security.JwtTokenProvider;
import com.civiltech.civildesk_backend.service.EmailService;
import com.civiltech.civildesk_backend.service.OtpService;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
@CrossOrigin(origins = "*")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtTokenProvider tokenProvider;

    @Autowired
    private OtpService otpService;

    @Autowired
    private EmailService emailService;

    @Autowired
    private RefreshTokenRepository refreshTokenRepository;

    @PostMapping("/login")
    public ResponseEntity<ApiResponse<AuthResponse>> login(@Valid @RequestBody LoginRequest loginRequest, HttpServletRequest request) {
        try {
            User user = userRepository.findByEmail(loginRequest.getEmail())
                    .orElseThrow(() -> new BadRequestException("Invalid email or password"));

            // Check if email is verified (only for ADMIN and HR_MANAGER roles, employees don't need verification)
            if (!user.getEmailVerified() && (user.getRole() == User.Role.ADMIN || user.getRole() == User.Role.HR_MANAGER)) {
                throw new BadRequestException("Please verify your email before logging in");
            }

            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            loginRequest.getEmail(),
                            loginRequest.getPassword()
                    )
            );

            SecurityContextHolder.getContext().setAuthentication(authentication);

            String token = generateToken(user);
            String refreshToken = null;
            
            // Generate refresh token if rememberMe is true
            if (Boolean.TRUE.equals(loginRequest.getRememberMe())) {
                refreshToken = createAndSaveRefreshToken(user, request);
            }
            
            AuthResponse authResponse = createAuthResponse(token, refreshToken, user);

            return ResponseEntity.ok(ApiResponse.success("Login successful", authResponse));
        } catch (BadRequestException e) {
            throw e;
        } catch (Exception e) {
            throw new BadRequestException("Invalid email or password");
        }
    }

    @PostMapping("/login/admin")
    public ResponseEntity<ApiResponse<AuthResponse>> adminLogin(@Valid @RequestBody LoginRequest loginRequest, HttpServletRequest request) {
        try {
            User user = userRepository.findByEmail(loginRequest.getEmail())
                    .orElseThrow(() -> new BadRequestException("Invalid email or password"));

            // Only allow ADMIN and HR_MANAGER roles
            if (user.getRole() != User.Role.ADMIN && user.getRole() != User.Role.HR_MANAGER) {
                throw new BadRequestException("Access denied. This login is for administrators and HR managers only. Please use the Employee app.");
            }

            // Check if email is verified
            if (!user.getEmailVerified()) {
                throw new BadRequestException("Please verify your email before logging in");
            }

            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            loginRequest.getEmail(),
                            loginRequest.getPassword()
                    )
            );

            SecurityContextHolder.getContext().setAuthentication(authentication);

            String token = generateToken(user);
            String refreshToken = null;
            
            // Generate refresh token if rememberMe is true
            if (Boolean.TRUE.equals(loginRequest.getRememberMe())) {
                refreshToken = createAndSaveRefreshToken(user, request);
            }
            
            AuthResponse authResponse = createAuthResponse(token, refreshToken, user);

            return ResponseEntity.ok(ApiResponse.success("Login successful", authResponse));
        } catch (BadRequestException e) {
            throw e;
        } catch (Exception e) {
            throw new BadRequestException("Invalid email or password");
        }
    }

    @PostMapping("/login/employee")
    public ResponseEntity<ApiResponse<AuthResponse>> employeeLogin(@Valid @RequestBody LoginRequest loginRequest, HttpServletRequest request) {
        try {
            User user = userRepository.findByEmail(loginRequest.getEmail())
                    .orElseThrow(() -> new BadRequestException("Invalid email or password"));

            // Only allow EMPLOYEE role
            if (user.getRole() != User.Role.EMPLOYEE) {
                throw new BadRequestException("Access denied. This login is for employees only. Please use the Admin app.");
            }

            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(
                            loginRequest.getEmail(),
                            loginRequest.getPassword()
                    )
            );

            SecurityContextHolder.getContext().setAuthentication(authentication);

            String token = generateToken(user);
            String refreshToken = null;
            
            // Generate refresh token if rememberMe is true
            if (Boolean.TRUE.equals(loginRequest.getRememberMe())) {
                refreshToken = createAndSaveRefreshToken(user, request);
            }
            
            AuthResponse authResponse = createAuthResponse(token, refreshToken, user);

            return ResponseEntity.ok(ApiResponse.success("Login successful", authResponse));
        } catch (BadRequestException e) {
            throw e;
        } catch (Exception e) {
            throw new BadRequestException("Invalid email or password");
        }
    }

    @PostMapping("/signup")
    public ResponseEntity<ApiResponse<String>> signup(@Valid @RequestBody SignupRequest signupRequest) {
        // Validate password match
        if (!signupRequest.getPassword().equals(signupRequest.getConfirmPassword())) {
            throw new BadRequestException("Passwords do not match");
        }

        // Check if email already exists
        if (userRepository.existsByEmail(signupRequest.getEmail())) {
            throw new BadRequestException("Email already exists");
        }

        // Create user with email not verified
        User user = new User();
        user.setEmail(signupRequest.getEmail());
        user.setPassword(passwordEncoder.encode(signupRequest.getPassword()));
        user.setFirstName(signupRequest.getFirstName());
        user.setLastName(signupRequest.getLastName());
        user.setRole(User.Role.ADMIN); // Super admin signup
        user.setIsActive(true);
        user.setEmailVerified(false);

        // Generate and set OTP
        String otp = otpService.generateOtp();
        user.setOtp(otp);
        user.setOtpExpiry(otpService.calculateOtpExpiry());

        User savedUser = userRepository.save(user);

        // Send OTP email
        emailService.sendOtpEmail(savedUser.getEmail(), savedUser.getFirstName(), otp);

        return ResponseEntity.ok(ApiResponse.success("Signup successful. Please verify your email with the OTP sent to your email address.", null));
    }

    @PostMapping("/send-otp")
    public ResponseEntity<ApiResponse<String>> sendOtp(@Valid @RequestBody SendOtpRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadRequestException("User not found with this email"));

        if (user.getEmailVerified()) {
            throw new BadRequestException("Email is already verified");
        }

        // Generate new OTP
        String otp = otpService.generateOtp();
        user.setOtp(otp);
        user.setOtpExpiry(otpService.calculateOtpExpiry());
        userRepository.save(user);

        // Send OTP email
        emailService.sendOtpEmail(user.getEmail(), user.getFirstName(), otp);

        return ResponseEntity.ok(ApiResponse.success("OTP sent successfully to your email", null));
    }

    @PostMapping("/verify-otp")
    public ResponseEntity<ApiResponse<AuthResponse>> verifyOtp(@Valid @RequestBody OtpVerificationRequest request) {
        User user = userRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new BadRequestException("User not found with this email"));

        if (user.getEmailVerified()) {
            throw new BadRequestException("Email is already verified");
        }

        // Verify OTP
        if (!otpService.isOtpValid(user.getOtp(), request.getOtp(), user.getOtpExpiry())) {
            if (otpService.isOtpExpired(user.getOtpExpiry())) {
                throw new BadRequestException("OTP has expired. Please request a new one.");
            }
            throw new BadRequestException("Invalid OTP");
        }

        // Mark email as verified and clear OTP
        user.setEmailVerified(true);
        user.setOtp(null);
        user.setOtpExpiry(null);
        userRepository.save(user);

        // Generate token and return auth response
        String token = generateToken(user);
        AuthResponse authResponse = createAuthResponse(token, null, user);

        return ResponseEntity.ok(ApiResponse.success("Email verified successfully", authResponse));
    }

    @PostMapping("/register")
    public ResponseEntity<ApiResponse<AuthResponse>> register(@Valid @RequestBody RegisterRequest registerRequest) {
        if (userRepository.existsByEmail(registerRequest.getEmail())) {
            throw new BadRequestException("Email already exists");
        }

        User user = new User();
        user.setEmail(registerRequest.getEmail());
        user.setPassword(passwordEncoder.encode(registerRequest.getPassword()));
        user.setFirstName(registerRequest.getFirstName());
        user.setLastName(registerRequest.getLastName());
        user.setRole(registerRequest.getRole() != null ? registerRequest.getRole() : User.Role.EMPLOYEE);
        user.setIsActive(true);
        user.setEmailVerified(true); // Admin-created users are pre-verified

        User savedUser = userRepository.save(user);

        String token = generateToken(savedUser);
        AuthResponse authResponse = createAuthResponse(token, null, savedUser);

        return ResponseEntity.ok(ApiResponse.success("Registration successful", authResponse));
    }

    @PostMapping("/logout")
    public ResponseEntity<ApiResponse<String>> logout(@RequestBody(required = false) RefreshTokenRequest refreshTokenRequest) {
        // Revoke refresh token if provided
        if (refreshTokenRequest != null && refreshTokenRequest.getRefreshToken() != null) {
            refreshTokenRepository.findByToken(refreshTokenRequest.getRefreshToken())
                    .ifPresent(token -> {
                        token.setIsRevoked(true);
                        refreshTokenRepository.save(token);
                    });
        }
        
        SecurityContextHolder.clearContext();
        return ResponseEntity.ok(ApiResponse.success("Logout successful", null));
    }

    @PostMapping("/refresh")
    public ResponseEntity<ApiResponse<AuthResponse>> refreshToken(@Valid @RequestBody RefreshTokenRequest refreshTokenRequest) {
        try {
            RefreshToken refreshToken = refreshTokenRepository.findByTokenAndIsRevokedFalse(refreshTokenRequest.getRefreshToken())
                    .orElseThrow(() -> new BadRequestException("Invalid refresh token"));

            if (!refreshToken.isValid()) {
                throw new BadRequestException("Refresh token has expired");
            }

            User user = refreshToken.getUser();
            
            if (!user.getIsActive()) {
                throw new BadRequestException("User account is inactive");
            }

            // Generate new access token
            String newToken = generateToken(user);
            
            // Optionally generate new refresh token (rotate refresh token)
            String newRefreshToken = null;
            if (refreshToken.getExpiryDate().isBefore(LocalDateTime.now().plusDays(3))) {
                // If refresh token expires in less than 3 days, issue a new one
                refreshTokenRepository.delete(refreshToken);
                newRefreshToken = createAndSaveRefreshToken(user, null);
            }

            AuthResponse authResponse = createAuthResponse(newToken, newRefreshToken != null ? newRefreshToken : refreshTokenRequest.getRefreshToken(), user);

            return ResponseEntity.ok(ApiResponse.success("Token refreshed successfully", authResponse));
        } catch (BadRequestException e) {
            throw e;
        } catch (Exception e) {
            throw new BadRequestException("Invalid refresh token");
        }
    }

    private String generateToken(User user) {
        Map<String, Object> claims = new HashMap<>();
        claims.put("id", user.getId());
        claims.put("email", user.getEmail());
        claims.put("role", user.getRole().name());
        claims.put("firstName", user.getFirstName());
        claims.put("lastName", user.getLastName());
        
        return tokenProvider.generateTokenWithClaims(user.getEmail(), claims);
    }

    private String createAndSaveRefreshToken(User user, HttpServletRequest request) {
        String refreshTokenValue = tokenProvider.generateRefreshToken(user.getEmail());
        
        RefreshToken refreshToken = new RefreshToken();
        refreshToken.setUser(user);
        refreshToken.setToken(refreshTokenValue);
        refreshToken.setExpiryDate(LocalDateTime.now().plusDays(7)); // 7 days expiry
        refreshToken.setIsRevoked(false);
        
        // Store device info if available
        if (request != null) {
            String deviceInfo = request.getHeader("User-Agent");
            if (deviceInfo != null && deviceInfo.length() > 500) {
                deviceInfo = deviceInfo.substring(0, 500);
            }
            refreshToken.setDeviceInfo(deviceInfo);
        }
        
        refreshTokenRepository.save(refreshToken);
        return refreshTokenValue;
    }

    private AuthResponse createAuthResponse(String token, String refreshToken, User user) {
        AuthResponse.UserInfo userInfo = new AuthResponse.UserInfo(
                user.getId(),
                user.getEmail(),
                user.getFirstName(),
                user.getLastName(),
                user.getRole(),
                user.getIsActive()
        );

        AuthResponse authResponse = new AuthResponse();
        authResponse.setToken(token);
        authResponse.setRefreshToken(refreshToken);
        authResponse.setTokenType("Bearer");
        authResponse.setUser(userInfo);

        return authResponse;
    }
}


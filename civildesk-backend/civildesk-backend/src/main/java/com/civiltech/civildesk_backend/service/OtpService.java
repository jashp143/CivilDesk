package com.civiltech.civildesk_backend.service;

import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.time.temporal.ChronoUnit;

@Service
public class OtpService {

    private static final int OTP_LENGTH = 6;
    private static final int OTP_VALIDITY_MINUTES = 10;
    private static final SecureRandom random = new SecureRandom();

    /**
     * Generate a 6-digit OTP
     */
    public String generateOtp() {
        // Generate OTP with specified length (6 digits: 100000 to 999999)
        int min = (int) Math.pow(10, OTP_LENGTH - 1);
        int max = (int) Math.pow(10, OTP_LENGTH) - 1;
        int otp = min + random.nextInt(max - min + 1);
        return String.valueOf(otp);
    }

    /**
     * Calculate OTP expiry time (10 minutes from now)
     */
    public LocalDateTime calculateOtpExpiry() {
        return LocalDateTime.now().plus(OTP_VALIDITY_MINUTES, ChronoUnit.MINUTES);
    }

    /**
     * Verify if OTP is valid and not expired
     */
    public boolean isOtpValid(String storedOtp, String providedOtp, LocalDateTime otpExpiry) {
        if (storedOtp == null || providedOtp == null || otpExpiry == null) {
            return false;
        }
        
        if (!storedOtp.equals(providedOtp)) {
            return false;
        }
        
        return LocalDateTime.now().isBefore(otpExpiry);
    }

    /**
     * Check if OTP is expired
     */
    public boolean isOtpExpired(LocalDateTime otpExpiry) {
        if (otpExpiry == null) {
            return true;
        }
        return LocalDateTime.now().isAfter(otpExpiry);
    }
}


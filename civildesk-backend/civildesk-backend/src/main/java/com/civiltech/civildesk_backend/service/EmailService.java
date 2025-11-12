package com.civiltech.civildesk_backend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.SimpleMailMessage;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.stereotype.Service;

@Service
public class EmailService {

    private static final Logger logger = LoggerFactory.getLogger(EmailService.class);

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Value("${spring.mail.from:noreply@civildesk.com}")
    private String fromEmail;

    @Value("${app.email.enabled:true}")
    private boolean emailEnabled;

    /**
     * Send OTP email to user
     */
    public void sendOtpEmail(String toEmail, String firstName, String otp) {
        if (!emailEnabled || mailSender == null) {
            logger.warn("Email sending is disabled or not configured. OTP for {}: {}", toEmail, otp);
            return;
        }

        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject("Email Verification - Civildesk");
            message.setText(buildOtpEmailBody(firstName, otp));

            mailSender.send(message);
            logger.info("OTP email sent successfully to: {}", toEmail);
        } catch (Exception e) {
            logger.error("Failed to send OTP email to: {}", toEmail, e);
            throw new RuntimeException("Failed to send email. Please try again later.", e);
        }
    }

    /**
     * Send employee registration email with generated password
     */
    public void sendEmployeeRegistrationEmail(String toEmail, String firstName, String password) {
        if (!emailEnabled || mailSender == null) {
            logger.warn("Email sending is disabled or not configured. Password for {}: {}", toEmail, password);
            return;
        }

        try {
            SimpleMailMessage message = new SimpleMailMessage();
            message.setFrom(fromEmail);
            message.setTo(toEmail);
            message.setSubject("Welcome to Civildesk - Your Account Credentials");
            message.setText(buildEmployeeRegistrationEmailBody(firstName, toEmail, password));

            mailSender.send(message);
            logger.info("Employee registration email sent successfully to: {}", toEmail);
        } catch (Exception e) {
            logger.error("Failed to send employee registration email to: {}", toEmail, e);
            // Don't throw exception - allow registration to complete even if email fails
        }
    }

    private String buildOtpEmailBody(String firstName, String otp) {
        return String.format(
            "Hello %s,\n\n" +
            "Thank you for registering with Civildesk!\n\n" +
            "Your email verification code is: %s\n\n" +
            "This code will expire in 10 minutes.\n\n" +
            "If you didn't request this code, please ignore this email.\n\n" +
            "Best regards,\n" +
            "Civildesk Team",
            firstName, otp
        );
    }

    private String buildEmployeeRegistrationEmailBody(String firstName, String email, String password) {
        return String.format(
            "Hello %s,\n\n" +
            "Welcome to Civildesk! Your account has been created.\n\n" +
            "Your login credentials:\n" +
            "Email: %s\n" +
            "Password: %s\n\n" +
            "Please log in to your employee app and change your password after first login.\n\n" +
            "Best regards,\n" +
            "Civildesk Team",
            firstName, email, password
        );
    }
}


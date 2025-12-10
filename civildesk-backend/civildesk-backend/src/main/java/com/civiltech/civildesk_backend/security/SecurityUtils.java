package com.civiltech.civildesk_backend.security;

import com.civiltech.civildesk_backend.model.User;
import com.civiltech.civildesk_backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.stereotype.Component;

/**
 * Utility class for security-related operations
 */
@Component
public class SecurityUtils {

    private static UserRepository userRepository;

    @Autowired
    public void setUserRepository(UserRepository userRepository) {
        SecurityUtils.userRepository = userRepository;
    }

    /**
     * Get the currently authenticated user's username (email)
     */
    public static String getCurrentUsername() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null && authentication.getPrincipal() instanceof UserDetails) {
            UserDetails userDetails = (UserDetails) authentication.getPrincipal();
            return userDetails.getUsername();
        }
        return null;
    }

    /**
     * Get the currently authenticated user's ID
     */
    public static Long getCurrentUserId() {
        String email = getCurrentUsername();
        if (email != null && userRepository != null) {
            return userRepository.findByEmail(email)
                    .map(User::getId)
                    .orElse(null);
        }
        return null;
    }

    /**
     * Get the currently authenticated user entity
     */
    public static User getCurrentUser() {
        String email = getCurrentUsername();
        if (email != null && userRepository != null) {
            return userRepository.findByEmail(email).orElse(null);
        }
        return null;
    }

    /**
     * Get the currently authenticated user's authorities
     */
    public static boolean hasRole(String role) {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        if (authentication != null) {
            return authentication.getAuthorities().stream()
                    .anyMatch(authority -> authority.getAuthority().equals("ROLE_" + role));
        }
        return false;
    }

    /**
     * Check if current user is authenticated
     */
    public static boolean isAuthenticated() {
        Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
        return authentication != null && authentication.isAuthenticated()
                && !authentication.getName().equals("anonymousUser");
    }
}


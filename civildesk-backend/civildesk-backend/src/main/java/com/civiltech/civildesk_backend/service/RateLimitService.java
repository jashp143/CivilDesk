package com.civiltech.civildesk_backend.service;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.core.ValueOperations;
import org.springframework.stereotype.Service;

import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.TimeUnit;

/**
 * Rate limiting service for forgot password requests
 * Uses Redis if available, otherwise falls back to in-memory cache
 */
@Service
public class RateLimitService {

    private static final Logger logger = LoggerFactory.getLogger(RateLimitService.class);
    
    // Rate limit configuration
    private static final int MAX_ATTEMPTS = 3; // Maximum attempts per time window
    private static final int TIME_WINDOW_MINUTES = 15; // Time window in minutes
    private static final String RATE_LIMIT_KEY_PREFIX = "rate_limit:forgot_password:";

    @Autowired(required = false)
    private RedisTemplate<String, Object> redisTemplate;

    // In-memory fallback for rate limiting
    private final ConcurrentHashMap<String, RateLimitEntry> inMemoryCache = new ConcurrentHashMap<>();

    /**
     * Check if the request is rate limited
     * @param identifier Unique identifier (e.g., email or IP address)
     * @return true if rate limited, false otherwise
     */
    public boolean isRateLimited(String identifier) {
        String key = RATE_LIMIT_KEY_PREFIX + identifier;
        
        if (redisTemplate != null) {
            // Use Redis for distributed rate limiting
            return isRateLimitedRedis(key);
        } else {
            // Fallback to in-memory cache
            return isRateLimitedInMemory(key);
        }
    }

    private boolean isRateLimitedRedis(String key) {
        try {
            ValueOperations<String, Object> ops = redisTemplate.opsForValue();
            Object attemptsObj = ops.get(key);
            
            if (attemptsObj == null) {
                // First attempt - set counter
                ops.set(key, 1, TIME_WINDOW_MINUTES, TimeUnit.MINUTES);
                return false;
            }
            
            int attempts = Integer.parseInt(attemptsObj.toString());
            if (attempts >= MAX_ATTEMPTS) {
                // Check remaining TTL
                Long ttl = redisTemplate.getExpire(key, TimeUnit.SECONDS);
                logger.warn("Rate limit exceeded for key: {}. TTL: {} seconds", key, ttl);
                return true;
            }
            
            // Increment counter
            ops.increment(key);
            return false;
        } catch (Exception e) {
            logger.error("Error checking rate limit in Redis: {}", e.getMessage());
            // On error, fallback to in-memory
            return isRateLimitedInMemory(key);
        }
    }

    private boolean isRateLimitedInMemory(String key) {
        RateLimitEntry entry = inMemoryCache.get(key);
        long now = System.currentTimeMillis();
        
        if (entry == null || (now - entry.timestamp) > TimeUnit.MINUTES.toMillis(TIME_WINDOW_MINUTES)) {
            // First attempt or time window expired - create new entry
            inMemoryCache.put(key, new RateLimitEntry(1, now));
            return false;
        }
        
        if (entry.attempts >= MAX_ATTEMPTS) {
            long remainingSeconds = TimeUnit.MINUTES.toSeconds(TIME_WINDOW_MINUTES) - 
                                   TimeUnit.MILLISECONDS.toSeconds(now - entry.timestamp);
            logger.warn("Rate limit exceeded for key: {}. Remaining time: {} seconds", key, remainingSeconds);
            return true;
        }
        
        // Increment attempts
        entry.attempts++;
        return false;
    }

    /**
     * Reset rate limit for an identifier (useful for testing or manual reset)
     * @param identifier Unique identifier
     */
    public void resetRateLimit(String identifier) {
        String key = RATE_LIMIT_KEY_PREFIX + identifier;
        if (redisTemplate != null) {
            try {
                redisTemplate.delete(key);
                logger.info("Rate limit reset for key: {}", key);
            } catch (Exception e) {
                logger.error("Error resetting rate limit: {}", e.getMessage());
            }
        }
        inMemoryCache.remove(key);
    }

    /**
     * Internal class for in-memory rate limit entries
     */
    private static class RateLimitEntry {
        int attempts;
        long timestamp;

        RateLimitEntry(int attempts, long timestamp) {
            this.attempts = attempts;
            this.timestamp = timestamp;
        }
    }
}


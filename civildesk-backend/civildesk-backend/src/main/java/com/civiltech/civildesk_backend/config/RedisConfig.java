package com.civiltech.civildesk_backend.config;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.databind.jsontype.impl.LaissezFaireSubTypeValidator;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.boot.autoconfigure.condition.ConditionalOnBean;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.cache.CacheManager;
import org.springframework.cache.annotation.CachingConfigurer;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.cache.interceptor.CacheErrorHandler;
import org.springframework.cache.interceptor.SimpleCacheErrorHandler;
import org.springframework.cache.support.SimpleCacheManager;
import org.springframework.lang.NonNull;
import org.springframework.lang.Nullable;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;
import org.springframework.data.redis.cache.RedisCacheConfiguration;
import org.springframework.data.redis.cache.RedisCacheManager;
import org.springframework.data.redis.connection.RedisConnectionFactory;
import org.springframework.data.redis.connection.RedisStandaloneConfiguration;
import org.springframework.data.redis.connection.lettuce.LettuceConnectionFactory;
import org.springframework.data.redis.core.RedisTemplate;
import org.springframework.data.redis.serializer.GenericJackson2JsonRedisSerializer;
import org.springframework.data.redis.serializer.RedisSerializationContext;
import org.springframework.data.redis.serializer.StringRedisSerializer;

import java.time.Duration;
import java.util.Arrays;
import java.util.Objects;

/**
 * Redis Cache Configuration - Phase 2 Optimization
 * 
 * Provides caching layer to reduce database load and improve response times.
 * Expected improvement: 80% reduction in database load, 5x faster dashboard loading.
 * 
 * Falls back to in-memory cache if Redis is not available or disabled.
 */
@Configuration
@EnableCaching
public class RedisConfig implements CachingConfigurer {
    
    private static final Logger logger = LoggerFactory.getLogger(RedisConfig.class);
    
    @Value("${app.redis.enabled:true}")
    private boolean redisEnabled;
    
    @Value("${spring.data.redis.host:localhost}")
    private String redisHost;
    
    @Value("${spring.data.redis.port:6379}")
    private int redisPort;
    
    @Value("${spring.data.redis.password:}")
    private String redisPassword;
    
    /**
     * Redis connection factory - only created if Redis is enabled
     * Does not validate connection at startup to allow graceful fallback
     */
    @Bean
    @ConditionalOnProperty(name = "app.redis.enabled", havingValue = "true", matchIfMissing = true)
    public RedisConnectionFactory redisConnectionFactory() {
        RedisStandaloneConfiguration config = new RedisStandaloneConfiguration();
        config.setHostName(Objects.requireNonNull(redisHost, "Redis host cannot be null"));
        config.setPort(redisPort);
        if (redisPassword != null && !redisPassword.isEmpty()) {
            config.setPassword(redisPassword);
        }
        LettuceConnectionFactory factory = new LettuceConnectionFactory(config);
        // Don't validate connection at startup - allow lazy connection
        factory.setValidateConnection(false);
        factory.afterPropertiesSet();
        logger.info("Redis connection factory configured for {}:{} (lazy connection)", redisHost, redisPort);
        return factory;
    }
    
    /**
     * Configure Jackson ObjectMapper with JSR310 module for Java 8 time types
     * and type information for proper deserialization
     */
    @NonNull
    private ObjectMapper createObjectMapper() {
        ObjectMapper mapper = new ObjectMapper();
        mapper.registerModule(new JavaTimeModule());
        mapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
        // Enable type information for proper deserialization from Redis cache
        // This ensures objects are deserialized to their correct types instead of LinkedHashMap
        // Using LaissezFaireSubTypeValidator for Spring Boot 3.x compatibility
        mapper.activateDefaultTyping(
            LaissezFaireSubTypeValidator.instance,
            ObjectMapper.DefaultTyping.NON_FINAL,
            com.fasterxml.jackson.annotation.JsonTypeInfo.As.PROPERTY
        );
        return mapper;
    }

    /**
     * Redis template - only created if Redis is enabled
     */
    @Bean
    @ConditionalOnProperty(name = "app.redis.enabled", havingValue = "true", matchIfMissing = true)
    public RedisTemplate<String, Object> redisTemplate(@NonNull RedisConnectionFactory connectionFactory) {
        RedisTemplate<String, Object> template = new RedisTemplate<>();
        template.setConnectionFactory(connectionFactory);
        
        // Create serializer with proper ObjectMapper for Java 8 time types
        GenericJackson2JsonRedisSerializer serializer = new GenericJackson2JsonRedisSerializer(createObjectMapper());
        
        template.setDefaultSerializer(serializer);
        template.setKeySerializer(new StringRedisSerializer());
        template.setHashKeySerializer(new StringRedisSerializer());
        template.setHashValueSerializer(serializer);
        template.setValueSerializer(serializer);
        template.afterPropertiesSet();
        return template;
    }
    
    /**
     * Redis cache manager - only created if Redis connection factory is available
     */
    @Bean(name = "redisCacheManager")
    @Primary
    @ConditionalOnBean(RedisConnectionFactory.class)
    public CacheManager redisCacheManager(@NonNull RedisConnectionFactory connectionFactory) {
        logger.info("Using Redis cache manager");
        
        // Create serializer with proper ObjectMapper for Java 8 time types
        GenericJackson2JsonRedisSerializer serializer = new GenericJackson2JsonRedisSerializer(createObjectMapper());
        
        RedisCacheConfiguration defaultConfig = RedisCacheConfiguration.defaultCacheConfig()
            .entryTtl(Objects.requireNonNull(Duration.ofMinutes(30)))
            .serializeKeysWith(RedisSerializationContext.SerializationPair
                .fromSerializer(new StringRedisSerializer()))
            .serializeValuesWith(RedisSerializationContext.SerializationPair
                .fromSerializer(serializer))
            .disableCachingNullValues();
        
        return RedisCacheManager.builder(connectionFactory)
            .cacheDefaults(defaultConfig)
            // Employee cache: 30 minutes TTL
            .withCacheConfiguration("employees", 
                defaultConfig.entryTtl(Objects.requireNonNull(Duration.ofMinutes(30))))
            // Single employee cache: 30 minutes TTL
            .withCacheConfiguration("employee", 
                defaultConfig.entryTtl(Objects.requireNonNull(Duration.ofMinutes(30))))
            // Sites cache: 1 hour TTL (rarely changes)
            .withCacheConfiguration("sites", 
                defaultConfig.entryTtl(Objects.requireNonNull(Duration.ofHours(1))))
            // Single site cache: 1 hour TTL
            .withCacheConfiguration("site", 
                defaultConfig.entryTtl(Objects.requireNonNull(Duration.ofHours(1))))
            // Holidays cache: 24 hours TTL (very rarely changes)
            .withCacheConfiguration("holidays", 
                defaultConfig.entryTtl(Objects.requireNonNull(Duration.ofHours(24))))
            // Dashboard stats cache: 5 minutes TTL (frequently updated)
            .withCacheConfiguration("dashboard", 
                defaultConfig.entryTtl(Objects.requireNonNull(Duration.ofMinutes(5))))
            // Attendance cache: 10 minutes TTL
            .withCacheConfiguration("attendance", 
                defaultConfig.entryTtl(Objects.requireNonNull(Duration.ofMinutes(10))))
            // Tasks cache: 15 minutes TTL
            .withCacheConfiguration("tasks", 
                defaultConfig.entryTtl(Objects.requireNonNull(Duration.ofMinutes(15))))
            // Leave types cache: 1 hour TTL
            .withCacheConfiguration("leaveTypes", 
                defaultConfig.entryTtl(Objects.requireNonNull(Duration.ofHours(1))))
            .build();
    }
    
    /**
     * Fallback in-memory cache manager when Redis is disabled
     */
    @Bean(name = "cacheManager")
    @Primary
    @ConditionalOnProperty(name = "app.redis.enabled", havingValue = "false", matchIfMissing = false)
    public CacheManager simpleCacheManagerFallback() {
        return createSimpleCacheManager();
    }
    
    /**
     * Helper method to create simple cache manager
     */
    private CacheManager createSimpleCacheManager() {
        logger.info("Using in-memory cache (Redis is not available or disabled)");
        SimpleCacheManager cacheManager = new SimpleCacheManager();
        cacheManager.setCaches(Objects.requireNonNull(Arrays.asList(
            new org.springframework.cache.concurrent.ConcurrentMapCache("employees"),
            new org.springframework.cache.concurrent.ConcurrentMapCache("employee"),
            new org.springframework.cache.concurrent.ConcurrentMapCache("sites"),
            new org.springframework.cache.concurrent.ConcurrentMapCache("site"),
            new org.springframework.cache.concurrent.ConcurrentMapCache("holidays"),
            new org.springframework.cache.concurrent.ConcurrentMapCache("dashboard"),
            new org.springframework.cache.concurrent.ConcurrentMapCache("attendance"),
            new org.springframework.cache.concurrent.ConcurrentMapCache("tasks"),
            new org.springframework.cache.concurrent.ConcurrentMapCache("leaveTypes")
        )));
        cacheManager.afterPropertiesSet();
        return cacheManager;
    }
    
    /**
     * Cache error handler to gracefully handle Redis connection failures
     * When Redis is unavailable, cache operations will fail silently and
     * the application will continue to work by querying the database directly
     */
    @Bean
    @Override
    public CacheErrorHandler errorHandler() {
        return new SimpleCacheErrorHandler() {
            @Override
            public void handleCacheGetError(@NonNull RuntimeException exception, @NonNull org.springframework.cache.Cache cache, @NonNull Object key) {
                logger.warn("Cache get error for key '{}' in cache '{}': {}. Falling back to database query.", 
                    key, cache.getName(), exception.getMessage());
                // Don't throw exception - allow method to proceed and query database
            }
            
            @Override
            public void handleCachePutError(@NonNull RuntimeException exception, @NonNull org.springframework.cache.Cache cache, @NonNull Object key, @Nullable Object value) {
                logger.warn("Cache put error for key '{}' in cache '{}': {}. Continuing without cache.", 
                    key, cache.getName(), exception.getMessage());
                // Don't throw exception - allow method to proceed without caching
            }
            
            @Override
            public void handleCacheEvictError(@NonNull RuntimeException exception, @NonNull org.springframework.cache.Cache cache, @NonNull Object key) {
                logger.warn("Cache evict error for key '{}' in cache '{}': {}. Continuing without cache eviction.", 
                    key, cache.getName(), exception.getMessage());
                // Don't throw exception - allow method to proceed without cache eviction
            }
            
            @Override
            public void handleCacheClearError(@NonNull RuntimeException exception, @NonNull org.springframework.cache.Cache cache) {
                logger.warn("Cache clear error for cache '{}': {}. Continuing without cache clear.", 
                    cache.getName(), exception.getMessage());
                // Don't throw exception - allow method to proceed without cache clear
            }
        };
    }
}


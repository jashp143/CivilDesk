package com.civiltech.civildesk_backend.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

/**
 * This class is kept for backward compatibility but .env loading
 * is now done in CivildeskBackendApplication.main() before Spring Boot starts.
 * This ensures environment variables are available when application.properties is read.
 */
@Component
public class DotEnvConfig {

    private static final Logger logger = LoggerFactory.getLogger(DotEnvConfig.class);

    // Environment variables are now loaded in main() method before Spring Boot starts
    // This ensures they're available when DataSource is initialized
    public DotEnvConfig() {
        logger.info("DotEnvConfig initialized - .env file should already be loaded in main() method");
    }
}


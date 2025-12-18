package com.civiltech.civildesk_backend;

import io.github.cdimascio.dotenv.Dotenv;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.autoconfigure.data.redis.RedisRepositoriesAutoConfiguration;
import org.springframework.data.jpa.repository.config.EnableJpaRepositories;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication(exclude = {RedisRepositoriesAutoConfiguration.class})
@EnableJpaRepositories(basePackages = "com.civiltech.civildesk_backend.repository")
@EnableScheduling
public class CivildeskBackendApplication {

	private static final Logger logger = LoggerFactory.getLogger(CivildeskBackendApplication.class);

	public static void main(String[] args) {
		// Load .env file BEFORE Spring Boot starts
		// This ensures environment variables are available when application.properties is read
		try {
			Dotenv dotenv = Dotenv.configure()
					.directory("./") // Look for .env in project root (civildesk-backend/civildesk-backend/)
					.ignoreIfMissing()
					.load();
			
			// Load environment variables into system properties
			int loadedCount = 0;
			for (var entry : dotenv.entries()) {
				String key = entry.getKey();
				String value = entry.getValue();
				if (System.getProperty(key) == null) {
					System.setProperty(key, value);
					loadedCount++;
				}
			}
			logger.info("Loaded {} environment variables from .env file", loadedCount);
		} catch (Exception e) {
			logger.warn("Could not load .env file: {}. Using default values from application.properties or system environment variables", e.getMessage());
		}
		
		SpringApplication.run(CivildeskBackendApplication.class, args);
	}

}

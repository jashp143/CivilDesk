package com.civiltech.civildesk_backend;

import io.github.cdimascio.dotenv.Dotenv;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class CivildeskBackendApplication {

	public static void main(String[] args) {
		// Load .env file BEFORE Spring Boot starts
		// This ensures environment variables are available when application.properties is read
		try {
			Dotenv dotenv = Dotenv.configure()
					.directory("./") // Look for .env in project root (civildesk-backend/civildesk-backend/)
					.ignoreIfMissing()
					.load();
			
			// Load environment variables into system properties
			dotenv.entries().forEach(entry -> {
				String key = entry.getKey();
				String value = entry.getValue();
				if (System.getProperty(key) == null) {
					System.setProperty(key, value);
					System.out.println("Loaded environment variable: " + key + " from .env file");
				}
			});
			System.out.println("Environment variables loaded from .env file successfully");
		} catch (Exception e) {
			System.out.println("Warning: Could not load .env file: " + e.getMessage());
			System.out.println("Using default values from application.properties or system environment variables");
		}
		
		SpringApplication.run(CivildeskBackendApplication.class, args);
	}

}

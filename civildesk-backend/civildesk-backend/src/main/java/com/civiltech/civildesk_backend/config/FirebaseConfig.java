package com.civiltech.civildesk_backend.config;

import com.google.auth.oauth2.GoogleCredentials;
import com.google.firebase.FirebaseApp;
import com.google.firebase.FirebaseOptions;
import com.google.firebase.messaging.FirebaseMessaging;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.io.ByteArrayInputStream;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;

@Configuration
public class FirebaseConfig {

    private static final Logger logger = LoggerFactory.getLogger(FirebaseConfig.class);

    @Value("${firebase.credentials.json:}")
    private String firebaseCredentialsJson;

    @Value("${firebase.credentials.file:firebase-service-account.json}")
    private String firebaseCredentialsFile;

    @Bean
    public FirebaseMessaging firebaseMessaging() {
        try {
            // Check if Firebase is already initialized
            if (FirebaseApp.getApps().isEmpty()) {
                FirebaseOptions.Builder optionsBuilder = FirebaseOptions.builder();

                // Option 1: Use JSON from environment variable
                if (firebaseCredentialsJson != null && !firebaseCredentialsJson.trim().isEmpty()) {
                    logger.info("Initializing Firebase with credentials from environment variable");
                    InputStream credentialsStream = new ByteArrayInputStream(firebaseCredentialsJson.getBytes());
                    GoogleCredentials credentials = GoogleCredentials.fromStream(credentialsStream);
                    optionsBuilder.setCredentials(credentials);
                } 
                // Option 2: Use JSON file from resources
                else {
                    try {
                        logger.info("Attempting to load Firebase credentials from file: {}", firebaseCredentialsFile);
                        InputStream credentialsStream = getClass().getClassLoader()
                                .getResourceAsStream(firebaseCredentialsFile);
                        
                        if (credentialsStream == null) {
                            // Try absolute path
                            credentialsStream = new FileInputStream(firebaseCredentialsFile);
                        }
                        
                        GoogleCredentials credentials = GoogleCredentials.fromStream(credentialsStream);
                        optionsBuilder.setCredentials(credentials);
                        logger.info("Firebase credentials loaded successfully from file");
                    } catch (IOException e) {
                        logger.warn("Firebase credentials file not found: {}. Push notifications will be disabled.", firebaseCredentialsFile);
                        return null;
                    }
                }

                FirebaseApp.initializeApp(optionsBuilder.build());
                logger.info("Firebase initialized successfully");
            } else {
                logger.info("Firebase already initialized");
            }

            return FirebaseMessaging.getInstance();
        } catch (Exception e) {
            logger.error("Failed to initialize Firebase. Push notifications will be disabled.", e);
            return null;
        }
    }
}


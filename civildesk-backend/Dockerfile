# =========================
# Build stage
# =========================
FROM maven:3.9-eclipse-temurin-17 AS build

WORKDIR /app

# Copy Maven files
COPY civildesk-backend/civildesk-backend/pom.xml .
COPY civildesk-backend/civildesk-backend/mvnw .
COPY civildesk-backend/civildesk-backend/.mvn .mvn

# Download dependencies
RUN mvn dependency:go-offline -B

# Copy source code
COPY civildesk-backend/civildesk-backend/src ./src

# Build application
RUN mvn clean package -DskipTests


# =========================
# Runtime stage
# =========================
FROM eclipse-temurin:17-jre-jammy

WORKDIR /app

# Update packages and install wget for healthcheck
RUN apt-get update && \
    apt-get install -y --no-install-recommends wget && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Create non-root user
RUN groupadd -r spring && useradd -r -g spring spring
USER spring:spring

# Copy JAR
COPY --from=build /app/target/civildesk-backend-*.jar app.jar

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8080/api/health || exit 1

ENTRYPOINT ["java", "-jar", "app.jar"]

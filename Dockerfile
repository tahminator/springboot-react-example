# ==== Frontend Build Stage ====
FROM node:20 AS frontend-build

WORKDIR /frontend

# Copy frontend source code
COPY frontend/package.json frontend/pnpm-lock.yaml ./

# Install dependencies
RUN corepack enable pnpm && pnpm i --frozen-lockfile

# Copy the rest of the frontend files
COPY frontend/ ./

# Build the frontend
RUN npm run build

# ==== Backend Build Stage ====
FROM eclipse-temurin:21-jdk-jammy AS backend-build

WORKDIR /app

# Copy Maven Wrapper and pom.xml
COPY mvnw pom.xml ./
COPY .mvn/ .mvn/

# Download dependencies
RUN ./mvnw dependency:go-offline -B

# Copy the backend source code
COPY src ./src

# Copy frontend build output to backend static resources
COPY --from=frontend-build /frontend/dist/ src/main/resources/static/

# Package the application
RUN ./mvnw clean package -DskipTests


# ==== Runtime Stage ====
FROM eclipse-temurin:21-jre-jammy

WORKDIR /app

# Copy the built JAR file
COPY --from=backend-build /app/target/*.jar app.jar

# Expose backend port
EXPOSE 8080

# Start the application
ENTRYPOINT ["java", "-jar", "app.jar"]

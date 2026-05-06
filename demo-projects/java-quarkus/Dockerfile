# ── Multi-stage Dockerfile for Quarkus ────────────────────────
# Supports both JVM and native builds via build args.
#
# JVM build:    docker build -t quarkus-demo .
# Native build: docker build -t quarkus-demo --build-arg BUILD_TYPE=native .
# ──────────────────────────────────────────────────────────────

ARG BUILD_TYPE=jvm

# ════════════════════════════════════════════════════════════
# Stage 1a: JVM build
# ════════════════════════════════════════════════════════════
FROM maven:3.9-eclipse-temurin-21 AS jvm-build
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -DskipTests -B

# ════════════════════════════════════════════════════════════
# Stage 1b: Native build (GraalVM)
# ════════════════════════════════════════════════════════════
FROM ghcr.io/graalvm/native-image-community:21 AS native-build
RUN microdnf install -y maven && microdnf clean all
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline -B
COPY src ./src
RUN mvn package -Pnative -DskipTests -B

# ════════════════════════════════════════════════════════════
# Stage 2a: JVM runtime
# ════════════════════════════════════════════════════════════
FROM eclipse-temurin:21-jre-alpine AS jvm-runtime
RUN addgroup -S app && adduser -S app -G app
WORKDIR /app
COPY --from=jvm-build /app/target/quarkus-app/ ./
USER app
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://localhost:8080/q/health/ready || exit 1
ENTRYPOINT ["java", "-jar", "quarkus-run.jar"]

# ════════════════════════════════════════════════════════════
# Stage 2b: Native runtime (distroless)
# ════════════════════════════════════════════════════════════
FROM registry.access.redhat.com/ubi9/ubi-minimal:9.4 AS native-runtime
RUN microdnf install -y shadow-utils && microdnf clean all
RUN groupadd -r app && useradd -r -g app app
WORKDIR /app
COPY --from=native-build /app/target/*-runner ./application
USER app
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=3s CMD curl -sf http://localhost:8080/q/health/ready || exit 1
ENTRYPOINT ["./application"]

# ════════════════════════════════════════════════════════════
# Final: Select based on BUILD_TYPE arg
# ════════════════════════════════════════════════════════════
FROM ${BUILD_TYPE}-runtime AS final

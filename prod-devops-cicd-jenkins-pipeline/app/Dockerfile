# ─── Stage 1: Build ───────────────────────────────────────────────────────────
FROM amazoncorretto:17-al2023 AS builder

WORKDIR /build
COPY pom.xml .
# Download dependencies first (layer cache)
RUN mvn -f pom.xml dependency:go-offline -q 2>/dev/null || true

COPY src ./src
RUN mvn -f pom.xml package -DskipTests -q

# ─── Stage 2: Runtime ─────────────────────────────────────────────────────────
FROM amazoncorretto:17-al2023-headless

# Non-root user
RUN addgroup -g 1001 appgroup 2>/dev/null || groupadd -g 1001 appgroup && \
    adduser  -u 1001 -G appgroup -s /sbin/nologin -D appuser 2>/dev/null || \
    useradd  -u 1001 -g appgroup -s /sbin/nologin -M appuser

WORKDIR /app
COPY --from=builder /build/target/hello-service-1.0.0.jar app.jar

USER appuser
EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8080/actuator/health || exit 1

ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=75.0", "-jar", "app.jar"]

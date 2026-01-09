FROM maven:3.9-eclipse-temurin-21-alpine AS build

WORKDIR /app

COPY pom.xml .

RUN mvn dependency:go-offline -B

COPY src/main src/main

RUN mvn package -B -Dmaven.test.skip=true

FROM eclipse-temurin:21-jre-alpine AS runtime

RUN addgroup -S -g 1001 appgroup && \
    adduser -S -u 1001 -g appgroup appuser
USER appuser

WORKDIR /app

EXPOSE 8080

COPY --from=build /app/target/*.jar app.jar

ENTRYPOINT ["java", "-XX:+UseContainerSupport", "-XX:MaxRAMPercentage=80.0", "-jar", "app.jar"]

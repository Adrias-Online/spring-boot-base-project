FROM azul/zulu-openjdk-alpine:17
ARG JAR_FILE=target/*.jar
ARG APP_YML=properties/local/application.yml
COPY ${JAR_FILE} app.jar
COPY ${APP_YML} application.yml
ENTRYPOINT ["java","-jar","-Xdebug", "-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005", "/app.jar", "--spring.config.location=file:/application.yml"] 
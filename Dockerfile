FROM maven:3-alpine

COPY src/ pipeline/src/

WORKDIR pipeline/src/

EXPOSE 5005

ENTRYPOINT [ "java", "-jar", "/pipeline/src/companyNews.war"]
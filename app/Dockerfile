FROM tomcat:8.0-alpine

LABEL maintainer="karri.aditya@outlook.com"

ADD src/companyNews.war /usr/local/tomcat/webapps/

COPY src/static/ /usr/local/tomcat/webapps/

CMD ["catalina.sh", "run"]
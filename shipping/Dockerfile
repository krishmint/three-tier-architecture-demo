#
# Build
#
FROM ubuntu:22.04 AS build

RUN apt-get update && apt-get -y install maven openjdk-11-jdk

WORKDIR /opt/shipping
COPY pom.xml /opt/shipping/
COPY src /opt/shipping/src/

RUN mvn dependency:resolve 
##It downloads all necessary dependencies from Maven repositories, ensuring that your project has everything it needs to compile and run correctly.

RUN mvn package
# packages your project into a JAR file.

#
# Run
#
FROM openjdk:8-jdk

EXPOSE 8080

WORKDIR /opt/shipping

ENV CART_ENDPOINT=cart:8080
ENV DB_HOST=mysql

COPY --from=build /opt/shipping/target/shipping-1.0.jar shipping.jar

CMD [ "java", "-Xmn256m", "-Xmx768m", "-jar", "shipping.jar" ]


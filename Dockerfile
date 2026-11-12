# Steg 1: bygg JAR-filen med Maven
FROM maven:3.9-eclipse-temurin-21 AS build
WORKDIR /src

# pom.xml kopieres først, så avhengighetene får et eget lag som gjenbrukes når
# bare kildekoden endres. Gjelder lokalt: i GitHub Actions bygges alt på nytt hver gang.
COPY pom.xml .
RUN mvn -q -B -DskipTests dependency:go-offline

COPY src ./src
RUN mvn -q -B -DskipTests package

# Steg 2: kjøringsimage med bare JRE og den ferdige JAR-filen, uten Maven og kildekode
FROM eclipse-temurin:21-jre
COPY --from=build /src/target/*.jar /app.jar

# Appen lytter på 8080 inni containeren. Port 9999 settes ved kjøring med -p 9999:8080
EXPOSE 8080
ENTRYPOINT ["java","-jar","/app.jar"]

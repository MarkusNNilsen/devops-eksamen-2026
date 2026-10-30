# Besvarelse – PGR301 Eksamen 2026

## Oppgave 1 – Container og CI

### 1A – Containerisering

`Dockerfile` ligger i repo-roten og bruker multi-stage build:

- **Build-stage:** `maven:3.9-eclipse-temurin-21` bygger JAR-filen.
- **Runtime-stage:** `eclipse-temurin:21-jre` inneholder bare JRE og den ferdige JAR-filen.

#### Bygg imaget

```bash
docker build -t wishifai .
```

#### Kjør containeren (lytter på localhost:9999)

Appen lytter på port 8080 inni containeren, og `-p 9999:8080` gjør den tilgjengelig på `localhost:9999`.

**Alternativ A: AWS-nøkler fra `aws configure`**

```bash
docker run -p 9999:8080 -v ~/.aws:/root/.aws:ro wishifai
```

**Alternativ B: AWS-nøkler som miljøvariabler **

```bash
docker run -p 9999:8080 \
  -e AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY \
  -e AWS_REGION=eu-west-1 \
  wishifai
```

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

## Oppgave 1B – GitHub Actions og ECR

**Workflow:** `.github/workflows/deploy.yml`
**Grønn kjøring:** https://github.com/MarkusNNilsen/devops-eksamen-2026/actions/runs/41107439479

### Hva workflowen gjør
Ved push til `main` bygger workflowen Docker-imaget og publiserer det til
ECR-repoet `wishifai-mnn-wishifai` i eu-west-1. Den kjører kun på push til `main`.

### Secrets
AWS-nøklene ligger i GitHub Secrets (`AWS_ACCESS_KEY_ID` og
`AWS_SECRET_ACCESS_KEY`) og leses via `${{ secrets.* }}`. De ligger ikke i koden.

### Tagging-strategi
Hvert image får to tags:
- **Commit-SHA** (`github.sha`)
- **`latest`**

### Begrunnelse
- **Commit-SHA** er unik per commit og sporbar til nøyaktig hvilken kode som
  kjører. Den endres aldri, så den gir trygge rollbacks.
- **`latest`** peker alltid på siste build, så det er enkelt å hente ut nyeste
  image uten å kjenne SHA. Jeg startet med kun SHA, men la til `latest` fordi
  det er praktisk. Den brukes ikke til deploy.
- **Hvorfor ikke bare `latest`:** tags i ECR er mutable, så `latest` flytter seg
  ved hver push. Da vet jeg ikke hvilken commit som kjører i produksjon, jeg kan
  ikke rulle tilbake til en bestemt versjon, og ECS ser ingen endring når taggen
  er lik som sist.

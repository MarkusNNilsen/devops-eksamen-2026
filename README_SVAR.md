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

## Oppgave 2 – ECS Express og IaC

### 2A – Infrastruktur

Terraform-koden ligger i [`infra/`](infra/). Den oppretter:

- en ECS Express-tjeneste (`wishifai-18`) med offentlig endepunkt
- en S3-bucket for bildene (`wishifai-images-18`)
- en task role (`wishifai-task-role-18`) med tillatelser til S3 (`PutObject` på kun denne bucketen), Rekognition (`DetectLabels`) og Bedrock (`InvokeModel`)

Execution role og infrastructure role er de eksisterende rollene fra oppgaven. `S3_BUCKET` settes på tjenesten fra Terraform-ressursen, så bucket-navnet bare står ett sted.

**Offentlig URL:** https://wi-18457fa54bc74920bead38f9c980a621.ecs.eu-west-1.on.aws

Roten (`/`) har ingen side og gir 404. Test med:

```bash
curl https://wi-18457fa54bc74920bead38f9c980a621.ecs.eu-west-1.on.aws/api/health
curl -F "image=@samples/sample_image.png" https://wi-18457fa54bc74920bead38f9c980a621.ecs.eu-west-1.on.aws/api/analyze
```

### 2B – Remote state

State lagres i den delte bucketen `pgr301-terraform-state` med nøkkelen:

```
wishifai/18/terraform.tfstate
```

Nøkkelen inneholder kandidatnummeret, så state ikke overskrives av andre kandidater. Backend-konfigurasjonen ligger i [`infra/backend.tf`](infra/backend.tf).

### 2C – GitHub Actions-job for Terraform

**Workflow:** [`.github/workflows/deploy.yml`](.github/workflows/deploy.yml)
**Grønn kjøring:** https://github.com/MarkusNNilsen/devops-eksamen-2026/actions/runs/41138404062

Workflowen har to jobber i samme fil:

1. `build-push` bygger Docker-imaget og pusher det til ECR. Jobben sender adressen til imaget (med commit-SHA som tag) videre som job-output.
2. `terraform` har `needs: build-push`, så den starter først når build-jobben er ferdig og grønn. Den kjører `terraform fmt -check`, `terraform init` og `terraform apply` mot `infra/`, og gir imaget fra build-jobben til Terraform som `image`-variabel. AWS-nøklene hentes fra GitHub Secrets, på samme måte som i 1B.

Pipelinen feiler hvis Terraform-koden ikke er riktig formatert, siden `terraform fmt -check` avslutter med en feilkode når en fil trenger formatering.

#### Hvorfor Terraform kjører etter container-build

- Imaget med riktig tag må finnes i ECR før ECS prøver å hente det. Kjører Terraform først eller parallelt, kan tjenesten peke på et image som ikke finnes ennå, og deployen feiler.
- Adressen til imaget er et resultat av build-jobben (SHA-taggen), så Terraform kan ikke få den uten å vente.
- Med `needs:` stopper pipelinen hvis build feiler, så en ødelagt versjon aldri blir deployet.
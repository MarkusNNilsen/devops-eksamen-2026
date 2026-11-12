resource "aws_s3_bucket" "images" {
  bucket = "wishifai-images-${var.candidate}"
}

resource "aws_iam_role" "task" {
  name = "wishifai-task-role-${var.candidate}"
  # Sier hvem som får bruke rollen: ECS-tasken (selve containeren).
  # Hva rollen får gjøre, står i policyen under.
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Action    = "sts:AssumeRole"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "task" {
  name = "wishifai-task-policy-${var.candidate}"
  role = aws_iam_role.task.id
  # Rekognition og CloudWatch (PutMetricData) støtter ikke ressursbegrensning,
  # og for Bedrock er det tungvint fordi modellen kjøres på tvers av regioner.
  # Derfor bruker disse * som ressurs. Se README, oppgave 2A.
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = "s3:PutObject"
        Resource = "${aws_s3_bucket.images.arn}/*"
      },
      {
        Effect   = "Allow"
        Action   = "rekognition:DetectLabels"
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "bedrock:InvokeModel"
        Resource = "*"
      },

      {
        Effect   = "Allow"
        Action   = "cloudwatch:PutMetricData"
        Resource = "*"
      }
    ]
  })

}
resource "aws_ecs_express_gateway_service" "app" {
  service_name = "wishifai-${var.candidate}"

  # Execution role og infrastructure role er eksisterende roller gitt i oppgaven.
  # Task role er vår egen, og er den appen bruker når den kaller AWS.
  execution_role_arn      = "arn:aws:iam::244530008913:role/ecsTaskExecutionRole"
  infrastructure_role_arn = "arn:aws:iam::244530008913:role/service-role/ecsInfrastructureRoleForExpressServices"
  task_role_arn           = aws_iam_role.task.arn

  # Lastbalanseren bruker denne stien for å sjekke at appen lever
  health_check_path = "/api/health"

  primary_container {
    image = var.image

    # Porten appen lytter på inni containeren
    container_port = 8080

    # Bucket-navnet kommer fra Terraform-ressursen, så det står bare ett sted
    environment {
      name  = "S3_BUCKET"
      value = aws_s3_bucket.images.bucket
    }

    environment {
      name  = "METRICS_NAMESPACE"
      value = "wishifai-${var.candidate}"
    }
  }

  depends_on = [aws_iam_role_policy.task]
}
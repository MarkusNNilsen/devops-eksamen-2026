resource "aws_s3_bucket" "images" {
  bucket = "wishifai-images-${var.candidate}"
}

resource "aws_iam_role" "task" {
  name = "wishifai-task-role-${var.candidate}"

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
      }
    ]
  })

}
resource "aws_ecs_express_gateway_service" "app" {
  service_name            = "wishifai-${var.candidate}"
  execution_role_arn      = "arn:aws:iam::244530008913:role/ecsTaskExecutionRole"
  infrastructure_role_arn = "arn:aws:iam::244530008913:role/service-role/ecsInfrastructureRoleForExpressServices"
  task_role_arn           = aws_iam_role.task.arn
  health_check_path       = "/api/health"

  primary_container {
    image          = var.image
    container_port = 8080

    environment {
      name  = "S3_BUCKET"
      value = aws_s3_bucket.images.bucket
    }
  }

  depends_on = [aws_iam_role_policy.task]
}
locals {
  metrics_namespace = "wishifai-${var.candidate}"
}

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "wishifai-${var.candidate}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Business: gaveforslag generert"
          region = var.aws_region
          stat   = "Sum"
          period = 60
          metrics = [
            [local.metrics_namespace, "wishifai.suggestions.generated.count"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          title  = "Kostnad: Bedrock-tokens"
          region = var.aws_region
          stat   = "Sum"
          period = 60
          metrics = [
            [local.metrics_namespace, "bedrock.tokens.input.count"],
            [local.metrics_namespace, "bedrock.tokens.output.count"]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Svartid: Bedrock og Rekognition (ms)"
          region = var.aws_region
          stat   = "Average"
          period = 60
          metrics = [
            [local.metrics_namespace, "bedrock.duration.avg"],
            [local.metrics_namespace, "bedrock.duration.max", { stat = "Maximum" }],
            [local.metrics_namespace, "rekognition.duration.avg"],
            [local.metrics_namespace, "rekognition.duration.max", { stat = "Maximum" }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6
        properties = {
          title  = "Infrastruktur: ECS CPU og minne (%)"
          region = var.aws_region
          stat   = "Average"
          period = 60
          metrics = [
            ["AWS/ECS", "CPUUtilization", "ClusterName", "default", "ServiceName", aws_ecs_express_gateway_service.app.service_name],
            ["AWS/ECS", "MemoryUtilization", "ClusterName", "default", "ServiceName", aws_ecs_express_gateway_service.app.service_name]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Applikasjon: JVM heap-minne brukt"
          region = var.aws_region
          period = 60
          metrics = [
            [{
              expression = "SEARCH('{\"${local.metrics_namespace}\",area,id} MetricName=\"jvm.memory.used.value\" area=\"heap\"', 'Average', 60)"
              id         = "e1"
            }]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6
        properties = {
          title  = "Applikasjon: HTTP-latens /api/analyze"
          region = var.aws_region
          period = 60
          metrics = [
            [{
              expression = "SEARCH('{\"${local.metrics_namespace}\",exception,method,error,uri,outcome,status} MetricName=\"http.server.requests.avg\" uri=\"/api/analyze\"', 'Average', 60)"
              id         = "e2"
            }]
          ]
        }
      }
    ]
  })
}
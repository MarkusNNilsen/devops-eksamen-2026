resource "aws_cloudwatch_metric_alarm" "bedrock_slow" {
  alarm_name          = "wishifai-${var.candidate}-bedrock-slow"
  alarm_description   = "Gjennomsnittlig Bedrock-svartid er over 20 sekunder"
  namespace           = local.metrics_namespace
  metric_name         = "bedrock.duration.avg"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 20000
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}
/* 
  Tersklene er satt ut fra målinger under testtrafikk (en client, like bilder) og bør
  justeres når det finnes produksjonsdata. Begrunnelse: se README_SVAR.md, oppgave 3B.
*/
resource "aws_cloudwatch_metric_alarm" "bedrock_slow" {
  alarm_name          = "wishifai-${var.candidate}-bedrock-slow"
  alarm_description   = "Gjennomsnittlig Bedrock-svartid er over 20 sekunder"
  namespace           = local.metrics_namespace
  metric_name         = "bedrock.duration.avg"
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 1
  threshold           = 20000 //ms response time over 5 min
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}
/*
  Denne alarmen er satt for å fange opp uvanlig høyt tokenforbruk, som kan indikere spam eller at modellen gir uvanlig lange svar.
  Kan også bare være en naturlig spike i trafikk, men det er bedre å fange opp og vurdere enn å overse.
 */
resource "aws_cloudwatch_metric_alarm" "token_spike" {
  alarm_name          = "wishifai-${var.candidate}-token-spike"
  alarm_description   = "Uvanlig høyt tokenforbruk i Bedrock (mulig spam eller uvanlig lange svar fra modellen)"
  namespace           = local.metrics_namespace
  metric_name         = "bedrock.tokens.output.count"
  statistic           = "Sum"
  period              = 300
  evaluation_periods  = 1
  threshold           = 30000 //output tokens over 5 min
  comparison_operator = "GreaterThanThreshold"
  treat_missing_data  = "notBreaching"
}
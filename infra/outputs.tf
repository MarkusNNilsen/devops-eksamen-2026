output "service_url" {
  value = aws_ecs_express_gateway_service.app.ingress_paths[0].endpoint
}
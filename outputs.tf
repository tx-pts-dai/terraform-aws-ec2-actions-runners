output "webhook_endpoint" {
  description = "API gateway endpoint that handles GitHub App webhook events"
  value       = module.multi_runner.webhook.endpoint
}

output "ssm_parameters" {
  description = "Names and ARNs of the ssm parameters created by the multi_runner module"
  value       = module.multi_runner.ssm_parameters
}

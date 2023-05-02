output "webhook_endpoint" {
  description = "API gateway endpoint that handles GitHub App webhook events"
  value       = module.multi_runner.webhook.endpoint
}

output "webhook_secret" {
  description = "Webhook secret used to validate requests from Github. Use this as 'webhook secret' in the Github app."
  value       = random_id.webhook_secret.hex
  sensitive   = true
}

output "ssm_parameters" {
  description = "Names and ARNs of the ssm parameters created by the multi_runner module"
  value       = module.multi_runner.ssm_parameters
}

output "runner_iam_roles" {
  description = "Map of the IAM Roles used by the created runners"
  value       = { for k, v in module.multi_runner.runners : k => v.role_runner.arn }
}

output "runner_labels" {
  description = "Map of the runner labels you can use in your jobs to select the runners"
  value       = { for k, v in local.runners : k => v.matcherConfig.labelMatchers[0] }
}

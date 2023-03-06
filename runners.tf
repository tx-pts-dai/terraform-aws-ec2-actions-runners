resource "random_id" "webhook_secret" {
  byte_length = 20
}

module "multi_runner" {
  source  = "philips-labs/github-runner/aws//modules/multi-runner"
  version = "2.2.0"

  multi_runner_config = local.runners

  aws_region = var.aws_region
  vpc_id     = data.aws_vpc.selected.id
  subnet_ids = tolist(data.aws_subnets.subnets.ids)

  prefix = var.environment

  tags = {
    Environment = var.environment
  }

  github_app = {
    key_base64     = var.github_app_key_base64
    id             = var.github_app_multirunner_id
    webhook_secret = random_id.webhook_secret.hex
  }

  webhook_lambda_zip                = "${path.module}/lambdas/webhook.zip"
  runner_binaries_syncer_lambda_zip = "${path.module}/lambdas/runner-binaries-syncer.zip"
  runners_lambda_zip                = "${path.module}/lambdas/runners.zip"

  logging_retention_in_days = var.log_retention_in_days
}

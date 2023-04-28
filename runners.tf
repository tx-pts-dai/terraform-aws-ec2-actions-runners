resource "random_id" "webhook_secret" {
  byte_length = 20
}

module "multi_runner" {
  source  = "philips-labs/github-runner/aws//modules/multi-runner"
  version = "2.2.0"

  multi_runner_config = local.runners

  aws_region = var.aws_region
  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  prefix                = var.prefix
  role_path             = "/"
  instance_profile_path = "/"

  tags = {
    Environment = var.environment
  }

  github_app = {
    key_base64     = var.github_app_key_base64
    id             = var.github_app_multirunner_id
    webhook_secret = random_id.webhook_secret.hex
  }

  # Functions paths are hardcoded since we distribute the lambdas directly from this module
  # avoiding an extra step in the pipeline
  # 
  # webhook_lambda_zip lambda function to handle GitHub App webhook events 
  # https://github.com/philips-labs/terraform-aws-github-runner/tree/main/modules/webhook
  webhook_lambda_zip = "${path.module}/lambdas/webhook.zip"
  # runner_binaries_syncer_lambda_zip lambda that will sync GitHub action binary to a S3 bucket
  # https://github.com/philips-labs/terraform-aws-github-runner/tree/main/modules/runner-binaries-syncer
  runner_binaries_syncer_lambda_zip = "${path.module}/lambdas/runner-binaries-syncer.zip"
  # runners_lambda_zip Two set of lambdas that manage the life cycle of the runners on AWS 
  # One function will handle scaling up, the other scaling down.
  # https://github.com/philips-labs/terraform-aws-github-runner/tree/main/modules/runners
  runners_lambda_zip = "${path.module}/lambdas/runners.zip"

  logging_retention_in_days = var.log_retention_in_days
}

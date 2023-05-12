locals {
  org_runners = true
  runners_ami_filters = {
    "arm64" = ["amzn2-ami-kernel-5.*-hvm-*-arm64-gp2"]
    "x64"   = ["amzn2-ami-kernel-5.*-hvm-*-x86_64-gp2"]
  }

  runner_base_config = {
    instance_allocation_strategy            = var.instance_allocation_strategy
    enable_runner_detailed_monitoring       = true
    enable_ssm_on_runners                   = true
    enable_organization_runners             = local.org_runners
    delay_webhook_event                     = 0
    scale_up_reserved_concurrent_executions = -1 # don't put restrictions on concurrency for scaling up to scale fast.
    runner_group_name                       = var.runner_group_name
    runner_iam_role_managed_policy_arns     = var.runner_iam_role_policy_arns

    redrive_policy_build_queue = {
      enabled         = true
      maxReceiveCount = 50 # 50 retries every 30 seconds => 25 minutes
    }

    runner_run_as         = "runners"
    runner_log_files      = var.runner_log_files
    userdata_template     = "${path.module}/templates/user_data.sh"
    userdata_pre_install  = var.userdata_pre_install
    userdata_post_install = var.userdata_post_install
    ami_owners            = ["137112412989"] # amazon

    block_device_mappings = [
      {
        device_name           = "/dev/xvda"
        delete_on_termination = true
        volume_type           = "gp3"
        volume_size           = var.volume_size
        iops                  = null
        encrypted             = false
        kms_key_id            = null
        snapshot_id           = null
        throughput            = null
      }
    ]

  }

  runners = { for name, runner in var.runners : "${runner.os}-${name}" => {
    enable_fifo_build_queue = !local.org_runners # suggested only for repo-level runners
    runner_config = merge(local.runner_base_config, {
      instance_target_capacity_type   = runner.use_spot_instances ? "spot" : "on-demand"
      create_service_linked_role_spot = runner.use_spot_instances
      enable_ephemeral_runners        = runner.ephemeral
      enable_job_queued_check         = runner.ephemeral ? true : null
      runner_os                       = runner.os
      runner_architecture             = runner.architecture
      instance_types                  = runner.instance_types
      runner_extra_labels             = join(",", runner.labels)
      runners_maximum_count           = runner.maximum_count
      idle_config                     = runner.ephemeral ? [] : runner.idle_config
      pool_runner_owner               = runner.ephemeral ? var.github_org : null
      pool_config = runner.ephemeral ? [for config in runner.idle_config : {
        size                = config.idleCount
        schedule_expression = "cron(${config.poolCron})" # every minute from 8:00-18:59, Monday through Friday, it keeps var.idle_count runners online
      }] : []
      # if runners are ephemeral, scale-down function it's not needed because runners should get destroyed by itself after the run.
      # therefore we set it to once every 1h
      scale_down_schedule_expression = runner.ephemeral ? "cron(0 * * * ? *)" : null
    })
    matcherConfig = {
      labelMatchers = [concat(["self-hosted", runner.os, runner.architecture], runner.labels)]
      exactMatch    = true # TODO: test with false
    }
    ami_filter = {
      name = local.runners_ami_filters[runner.architecture]
    }
  } }
}

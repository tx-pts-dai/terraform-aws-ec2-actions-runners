locals {
  org_runners = true
  runner_base_config = {      # Base configuration shared between arm and amd runners
    fifo = !local.org_runners # suggested only for repo-level runners

    runner_config = {
      instance_target_capacity_type           = var.instance_target_capacity_type
      instance_allocation_strategy            = var.instance_allocation_strategy
      create_service_linked_role_spot         = var.instance_target_capacity_type == "spot"
      enable_runner_detailed_monitoring       = true
      enable_ssm_on_runners                   = true
      enable_organization_runners             = local.org_runners
      enable_ephemeral_runners                = var.enable_ephemeral_runners
      enable_job_queued_check                 = var.enable_ephemeral_runners ? true : null
      delay_webhook_event                     = 0
      scale_up_reserved_concurrent_executions = -1 # don't put restrictions on concurrency
      runner_group_name                       = var.runner_group_name
      runner_iam_role_managed_policy_arns     = var.runner_iam_role_policy_arns
      runner_os                               = "linux"
      runner_extra_labels                     = join(",", var.runner_labels)
      runners_maximum_count                   = var.runners_maximum_count
      idle_config                             = var.enable_ephemeral_runners ? [merge(var.idle_config[0], { idleCount = var.idle_count })] : []
      pool_runner_owner                       = var.github_org
      pool_config = var.enable_ephemeral_runners ? [{
        size                = var.idle_count
        schedule_expression = "cron(* 8-18 * * ? 1-5)" # Check that the at least var.idle_count runner is scheduled (once every min)
      }] : []

      runner_run_as         = "runners"
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

      runner_log_files = var.runner_log_files
    }
  }

  amd_runner = var.deploy_amd ? {
    "linux-x64" = merge(local.runner_base_config, { # merge of architecture dependant configuration
      runner_config = merge(local.runner_base_config.runner_config, {
        runner_architecture = "x64"
        instance_types      = var.amd_instance_types
      })
      matcherConfig = {
        labelMatchers = [concat(["self-hosted", "linux", "x64"], var.runner_labels)]
        exactMatch    = true
      }
      ami_filter = {
        name = ["amzn2-ami-kernel-5.*-hvm-*-x86_64-gp2"]
      }
    })
  } : {}

  arm_runner = var.deploy_arm ? {
    "linux-arm64" = merge(local.runner_base_config, { # merge of architecture dependant configuration
      runner_config = merge(local.runner_base_config.runner_config, {
        runner_architecture = "arm64"
        instance_types      = var.arm_instance_types
      })
      matcherConfig = {
        labelMatchers = [concat(["self-hosted", "linux", "arm64"], var.runner_labels)]
        exactMatch    = true
      }
      ami_filter = {
        name = ["amzn2-ami-kernel-5.*-hvm-*-arm64-gp2"]
      }
    })
  } : {}

  runners = merge(local.amd_runner, local.arm_runner)
}

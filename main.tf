locals {
  runner_run_as = "runners"

  runner_base_config = { # Base configuration shared between arm and amd runners
    fifo                = true
    delay_webhook_event = 0

    runner_config = {
      create_service_linked_role_spot     = true
      instance_allocation_strategy        = var.instance_allocation_strategy
      instance_target_capacity_type       = var.instance_target_capacity_type
      runners_maximum_count               = var.runners_maximum_count
      enable_organization_runners         = true
      enable_ephemeral_runners            = var.enable_ephemeral_runners
      runner_group_name                   = var.runner_group_name
      runner_iam_role_managed_policy_arns = var.runner_iam_role_policy_arns
      runner_os                           = "linux"
      runner_extra_labels                 = join(",", var.runner_labels)
      enable_ssm_on_runners               = true
      idle_config                         = var.idle_config
      runner_run_as                       = local.runner_run_as
      userdata_template                   = "${path.module}/templates/user_data.sh"
      userdata_pre_install                = var.userdata_pre_install
      userdata_post_install               = var.userdata_post_install
      ami_owners                          = ["137112412989"] # amazon

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

locals {
  org_runners = true
  runners_ami = {
    amazonlinux2 = {
      owners = ["137112412989"] # amazon
      filters = {
        "arm64" = ["amzn2-ami-kernel-5.*-hvm-*-arm64-gp2"]
        "x64"   = ["amzn2-ami-kernel-5.*-hvm-*-x86_64-gp2"]
      }
    }
    al2023 = {
      owners = ["137112412989"] # amazon
      filters = {
        "arm64" = ["al2023-ami-*-kernel-6.*-arm64"]
        "x64"   = ["al2023-ami-*-kernel-6.*-x86_64"]
      }
    }
    ubuntu = {
      owners = ["099720109477"] # canonical
      filters = {
        "arm64" = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-arm64-server-*"]
        "x64"   = ["ubuntu/images/hvm-ssd-gp3/ubuntu-noble-24.04-amd64-server-*"]
      }
    }
  }

  userdata_pre_install = var.dockerhub_credentials != null ? format(
    "%v\n%v\n%v",
    "DOCKERHUB_USERNAME=${var.dockerhub_credentials.username}",
    "DOCKERHUB_PASSWORD=${var.dockerhub_credentials.password}",
    var.userdata_pre_install
  ) : var.userdata_pre_install

  runner_base_config = {
    instance_allocation_strategy            = var.instance_allocation_strategy
    enable_ssm_on_runners                   = true
    enable_organization_runners             = local.org_runners
    delay_webhook_event                     = 0
    scale_up_reserved_concurrent_executions = -1 # don't put restrictions on concurrency for scaling up to scale fast.
    runner_group_name                       = var.runner_group_name
    runner_iam_role_managed_policy_arns     = var.runner_iam_role_policy_arns

    runner_run_as         = "runners"
    runner_log_files      = var.runner_log_files
    userdata_pre_install  = local.userdata_pre_install
    userdata_post_install = var.userdata_post_install
  }

  labels = { for runner_name, runner in var.runners : runner_name => concat(runner.labels, runner.use_spot_instances ? ["spot"] : ["on-demand"]) }

  # variable is `multi_runner_config` in https://github.com/philips-labs/terraform-aws-github-runner/blob/main/modules/multi-runner/variables.tf
  runners = { for runner_name, runner in var.runners : "${runner.os}-${runner_name}" => {
    fifo = !local.org_runners # suggested only for repo-level runners
    # SQS queue to retry failed scale-up attempts
    redrive_policy_build_queue = {
      enabled         = true
      maxReceiveCount = 50 # 50 retries every 30 seconds => 25 minutes
    }

    runner_config = merge(local.runner_base_config, {
      create_service_linked_role_spot = runner.use_spot_instances
      instance_target_capacity_type   = runner.use_spot_instances ? "spot" : "on-demand"
      instance_types                  = runner.instance_types
      enable_ephemeral_runners        = runner.ephemeral
      enable_job_queued_check         = runner.ephemeral ? true : null
      runner_os                       = runner.os
      runner_architecture             = runner.architecture
      ami_owners                      = local.runners_ami[runner.base_ami].owners
      ami_filter = {
        state = ["available"]
        name  = local.runners_ami[runner.base_ami].filters[runner.architecture]
      }
      block_device_mappings = [
        {
          device_name           = (runner.base_ami != "ubuntu") ? "/dev/xvda" : "/dev/sda1"
          delete_on_termination = true
          volume_type           = runner.disk.volume_type
          volume_size           = var.volume_size
          encrypted             = false
          iops                  = null
          kms_key_id            = null
          snapshot_id           = null
          throughput            = runner.disk.throughput_mbps
        }
      ]
      userdata_template     = "${path.module}/templates/user_data-${runner.base_ami}.sh"
      runner_extra_labels   = local.labels[runner_name]
      runners_maximum_count = runner.maximum_count
      idle_config           = runner.idle_config
      pool_runner_owner     = runner.ephemeral ? var.github_org : null
      pool_config = runner.ephemeral ? [for config in runner.idle_config : {
        size                = config.idleCount
        schedule_expression = "cron(${config.poolCron})"
      }] : []
      # if runners are ephemeral, scale-down function it's not needed because runners should get destroyed by itself after the run.
      # therefore we set it to once every 30 min
      scale_down_schedule_expression = runner.ephemeral ? "cron(*/30 * * * ? *)" : null
      # Many workflows are divided across multiple jobs, each triggering a new runner immediately after the previous one finishes.
      # Set a minimum delay of 15 minutes to prevent runners from provisioning too frequently.
      minimum_running_time_in_minutes = 15
    })

    matcherConfig = {
      labelMatchers = [concat(["self-hosted", runner.os, runner.architecture], local.labels[runner_name])]
      exactMatch    = true
    }
  } }
}

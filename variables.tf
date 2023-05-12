variable "unique_prefix" {
  description = "The unique prefix used for naming AWS resources."
  type        = string
}

variable "environment" {
  description = "The environment this resource will be deployed in."
  type        = string
}

variable "github_app_multirunner_id" {
  description = "id of the github app "
  type        = string
}

variable "github_app_key_base64" {
  description = "Github app private key. Ensure this value is the entire base64-encoded `.pem` file (e.g. the output of `base64 app.private-key.pem`), not its content."
  type        = string
}

variable "github_org" {
  description = "Name of the Github organization, owning the runners. Required only if specified with ephemeral runners"
  type        = string
  default     = null
}

variable "instance_allocation_strategy" {
  description = "allocation strategy for spot instances"
  type        = string
  default     = "price-capacity-optimized"
}

variable "runner_iam_role_policy_arns" {
  description = "Attach AWS or customer-managed IAM policies (by ARN) to the runner IAM role"
  type        = list(string)
  default     = []
}

variable "runner_group_name" {
  description = "github actions runner group to attach the agents to"
  type        = string
  default     = "Infrastructure-Repository-Deployment"
}

variable "aws_region" {
  description = "aws zone where to host the github actions runners"
  type        = string
  default     = "eu-central-1"
}

variable "volume_size" {
  description = "EBS volume size mounted to runner instance"
  type        = number
  default     = 40
}

variable "runner_log_files" {
  description = "Replaces the original module default cloudwatch log config. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html for details."
  type = list(object(
    {
      log_group_name   = string
      prefix_log_group = bool
      file_path        = string
      log_stream_name  = string
    }
  ))
  default = [
    {
      "log_group_name" : "syslog",
      "prefix_log_group" : true,
      "file_path" : "/var/log/syslog",
      "log_stream_name" : "{instance_id}"
    },
    {
      "log_group_name" : "user_data",
      "prefix_log_group" : true,
      "file_path" : "/var/log/user-data.log",
      "log_stream_name" : "{instance_id}/user_data"
    },
    {
      "log_group_name" : "runner",
      "prefix_log_group" : true,
      "file_path" : "/home/runners/actions-runner/_diag/Runner_**.log",
      "log_stream_name" : "{instance_id}/runner"
    }
  ]
}

variable "log_retention_in_days" {
  description = "Specifies the number of days you want to retain log events for the lambda log group. Possible values are: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653."
  type        = number
  default     = 7
}

variable "runners" {
  type = map(object({
    architecture   = string # x64 / arm64
    labels         = list(string)
    instance_types = list(string)
    idle_config = optional(list(object({
      cron      = optional(string, "* 8-18 ? * 1-5")     # AWS eventbridge cron schedule
      poolCron  = optional(string, "* 8-18 ? * Mon-Fri") # cron schedule parsed by CronParser (for pool)
      timeZone  = optional(string, "Europe/Zurich")
      idleCount = optional(number, 1)
      })), [{
      cron      = "* 8-18 ? * 1-5"
      poolCron  = "* 8-18 ? * Mon-Fri *"
      timeZone  = "Europe/Zurich"
      idleCount = 1
    }])
    maximum_count      = optional(number, 15)
    ephemeral          = optional(bool, false)
    use_spot_instances = optional(bool, false)
    os                 = optional(string, "linux") # linux / windows
  }))
  default = {
    "runner-1" = {
      architecture   = "x64"
      labels         = ["multi-runner"]
      instance_types = ["c6a.xlarge", "c6i.xlarge"]
    }
  }
  description = <<EOT
    runners = {
      architecture: Must be either "x64" or "arm64"
      labels: List of extra labels to attach to the runner. "self-hosted", os and architecture labels are attached by default. Make sure this field is unique among the runners you host.
      idle_config: List of objects specifying the schedule for keeping runners idle/warm
      maximum_count: Number of maximum concurrent runners that can be spawned
      ephemeral: Boolean for selecting the type of runner
      use_spot_instances: Boolean for using spot EC2 instances instead of on-demand
      os: linux or windows. Operating system
    }
  EOT
}


variable "userdata_pre_install" {
  description = "Script to be ran before the GitHub Actions runner is installed on the EC2 instances"
  type        = string
  default     = ""
}

variable "userdata_post_install" {
  description = "Script to be ran after the GitHub Actions runner is installed on the EC2 instances"
  type        = string
  default     = ""
}

variable "vpc_id" {
  description = "The vpc id where to deploy the runners"
  type        = string
}

variable "subnet_ids" {
  description = "The set of subnets where to deploy the runners"
  type        = list(string)
}

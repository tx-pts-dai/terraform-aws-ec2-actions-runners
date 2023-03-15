variable "environment" {
  description = "The environment this resource will be deployed in."
  type        = string
}

variable "github_app_multirunner_id" {
  description = "id of the github app "
  type        = string
}

variable "github_app_key_base64" {
  description = "Github app key. Ensure the key is the base64-encoded `.pem` file (the output of `base64 app.private-key.pem`, not the content of `private-key.pem`)."
  type        = string
}

variable "arm_instance_types" {
  description = "on demand spot arm64 instances"
  type        = list(string)
  # c6g.xlarge = 8 GB - 4 CPU 
  # t4g.xlarge = 16 GB - 4 CPU burstable
  default = ["c6g.xlarge", "t4g.xlarge"]
}

variable "amd_instance_types" {
  description = "on demand spot amd/intel instances"
  type        = list(string)

  # c6i.xlarge = 8 GB - 4 CPU
  # c6a.xlarge = 8 GB - 4 CPU
  # t3a.xlarge = 16 GB - 4 CPU burstable
  # t3.xlarge = 16 GB - 4 CPU burstable
  default = ["c6i.xlarge", "c6a.xlarge"]
}

variable "instance_allocation_strategy" {
  description = "allocation strategy for spot instances"
  type        = string
  default     = "price-capacity-optimized"
}

variable "runner_iam_role_managed_policy_arns" {
  description = "Attach AWS or customer-managed IAM policies (by ARN) to the runner IAM role"
  type        = list(string)
  default     = []
}

variable "runner_group_name" {
  description = "github actions runner group to attach the agents to"
  type        = string
  default     = "Infrastructure-Repository-Deployment"
}


variable "runners_maximum_count" {
  description = "max numbers of runners to keep per architecture"
  type        = number
  default     = 5
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

variable "idle_config" {
  description = "List of time period that can be defined as cron expression to keep a minimum amount of runners active instead of scaling down to 0. By defining this list you can ensure that in time periods that match the cron expression within 5 seconds a runner is kept idle."
  type = list(object({
    cron      = optional(string, "* * 8-19 * * 1-5") # cron schedule
    timeZone  = optional(string, "Europe/Zurich")
    idleCount = optional(number, 1)
  }))
  default = [
    {
      cron      = "* * 8-19 * * 1-5"
      timeZone  = "Europe/Zurich"
      idleCount = 1
    }
  ]
}

variable "log_retention_in_days" {
  description = "Specifies the number of days you want to retain log events for the lambda log group. Possible values are: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653."
  type        = number
  default     = 7
}

variable "deploy_amd" {
  description = "determine if the amd runners will be deployed (if both var.deploy_amd and var.deploy_arm are false the module will deploy the amd runners anyway)"
  type        = bool
  default     = true
}
variable "deploy_arm" {
  description = "determine if the arm runners will be deployed"
  type        = bool
  default     = false
}

variable "runners_labels" {
  description = "List of string of labels to assign to the runners. The runner architecture, os and 'self-hosted' will be automatically added by the module (x64 or arm64)"
  default     = ["multi-runner"]
  type        = list(string)
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

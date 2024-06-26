# Github Multi-Runner deployment on ec2 instances

This Module is a wrapper of the original [Philips Labs Multi-Runner module](https://github.com/philips-labs/terraform-aws-github-runner/tree/main/modules/multi-runner). All credits for the original implementation goes to [philips-labs](https://github.com/philips-labs), the module in this repo has been created according to the [MIT license](https://github.com/philips-labs/terraform-aws-github-runner/blob/main/LICENSE.md).

The goal of this wrapper is to solve one simple problem: the deployment of a basic Github Runner setup. We aimed at hiding as much configuration as possible behind defaults, giving the user a minimal set of required variables for a fast, opinionated deployment of the original multi-runner module.

Ephemeral and persistent runner configurations are both possible as well as `x64` and `arm64`. They are configurable with their respective parameters `runner.ephemeral` and `runner.architecture`.

By default, a single set of persistent, x64 runners with a minimum size of 1 is created.

## Usage

Example deployment with the required variables:

This snippet will deploy two set of runners:

  1. x64 with labels `["self-hosted", "linux", "x64", "team-red", "spot"]`
  2. arm64 with labels `["self-hosted", "linux", "arm64", "team-blue", "on-demand"]`

each have a default maximum count of 15 runners and 1 idle/warm runner each during office hours (8am-7pm Zurich time)

```hcl
module "example_multi_runner" {
  source                    = "github.com/tx-pts-dai/terraform-aws-ec2-actions-runners?ref=vX.X.X"
  unique_prefix             = "build-runners"
  github_app_multirunner_id = "123456"
  github_app_key_base64     = "myprivatekey"
  vpc_id                    = "vpc-01234567"
  subnet_ids                = ["subnet-0123456", "subnet-1234567"]
  runners = {
    team-red-x64 = {
      architecture       = "x64"
      instance_types     = ["c6i.large"]
      labels             = ["team-red"]
      use_spot_instances = true
    }
    team-blue-arm64 = {
      architecture       = "arm64"
      instance_types     = ["c7g.large"]
      labels             = ["team-blue"]
      ephemeral          = true
    }
  }
}
```

You can select the runners in a github workflow with:

```yaml
runs-on: ["self-hosted", "linux", "x64", "team-red", "spot"]
# or for arm64 arch
runs-on: ["self-hosted", "linux", "arm64", "team-blue", "on-demand"]
```

Keep in mind that a subset of labels can be used too, for example you can use `["self-hosted", "linux"]` to select either one or the other set indifferently.

The labels used by the runners are set as a Terraform output `runner_labels`. Our module adds the following labels additionally to the one you specify with `runner.labels`:

1. Architecture -> either `x64` or `arm64`
2. OS -> either `linux` or `windows`
3. Capacity type -> either `on-demand` or `spot`
4. Self-hosted -> `self-hosted`

IMPORTANT: When destroying the resources created by this module, there could be some EC2 instances as leftovers. Since they are launched dynamically via Lambda function, Terraform doesn't have any knowledge about them, therefore you should terminate/refresh them manually.

### Github Application (required)

Please follow the instruction on the original repo [Setup Github Application](https://github.com/philips-labs/terraform-aws-github-runner#setup-github-app-part-1)

The `webhook_endpoint` can be obtained as output from the module via `terraform output module.MY_MODULE_NAME.webhook_endpoint`.

The `webhook_secret` can be obtained in two ways:

1. As output from the module via `terraform output module.MY_MODULE_NAME.webhook_endpoint_secret`. This requires a valid terraform initialization.
2. From SSM: `aws ssm get-parameter --name /github-action-runners/MY_RUNNERS_UNIQUE_PREFIX/app/github_app_webhook_secret --with-decryption --output json`, note that this is an ecrypted parameter, therefore you need the flag `--with-decryption`. This requires a valid access to aws.

The Github App private key is also stored encrypted in ssm, if needed it can be retrieved with the following command:
`aws ssm get-parameter --name /github-action-runners/MY_RUNNERS_UNIQUE_PREFIX/app/github_app_key_base64 --with-decryption`

## Contributing

This repo has a pre-commit configuration and a workflow that verify that all checks pass on each PR.

### Pre-Commit

Installation: [install pre-commit](https://pre-commit.com/) and execute `pre-commit install`. This will generate pre-commit hooks according to the config in `.pre-commit-config.yaml`

Before submitting a PR be sure to have used the pre-commit hooks or run: `pre-commit run -a`

The `pre-commit` command will run:

- Terraform fmt
- Terraform validate
- Terraform docs
- Terraform validate with tflint
- check for merge conflicts
- fix end of files

as described in the `.pre-commit-config.yaml` file

### Update upstream

In order to update the upstream module version we need to:

1. Update versions in [`runners.tf`](./runners.tf) and [`lambdas/runners_lambdas.tf`](./lambdas/runners_lambdas.tf).
1. Change directory into `lambdas` and run `terraform init` and `terraform apply`. This will download the latest .zip files needed for the different lambdas.
1. Commit all the changed files.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.0 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_multi_runner"></a> [multi\_runner](#module\_multi\_runner) | philips-labs/github-runner/aws//modules/multi-runner | 5.10.4 |

## Resources

| Name | Type |
|------|------|
| [random_id.webhook_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | aws zone where to host the github actions runners | `string` | `"eu-central-1"` | no |
| <a name="input_dockerhub_credentials"></a> [dockerhub\_credentials](#input\_dockerhub\_credentials) | DockerHub username and password so that the runner is will automatically be logged in to DockerHub and have increased rate limits | <pre>object({<br>    username = string<br>    password = string<br>  })</pre> | `null` | no |
| <a name="input_github_app_key_base64"></a> [github\_app\_key\_base64](#input\_github\_app\_key\_base64) | Github app private key. Ensure this value is the entire base64-encoded `.pem` file (e.g. the output of `base64 app.private-key.pem`), not its content. | `string` | n/a | yes |
| <a name="input_github_app_multirunner_id"></a> [github\_app\_multirunner\_id](#input\_github\_app\_multirunner\_id) | id of the github app | `string` | n/a | yes |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | Name of the Github organization, owning the runners. Required only if specified with ephemeral runners | `string` | `null` | no |
| <a name="input_instance_allocation_strategy"></a> [instance\_allocation\_strategy](#input\_instance\_allocation\_strategy) | allocation strategy for spot instances | `string` | `"price-capacity-optimized"` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Specifies the number of days you want to retain log events for the lambda log group. Possible values are: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653. | `number` | `7` | no |
| <a name="input_runner_group_name"></a> [runner\_group\_name](#input\_runner\_group\_name) | github actions runner group to attach the agents to | `string` | `"Infrastructure-Repository-Deployment"` | no |
| <a name="input_runner_iam_role_policy_arns"></a> [runner\_iam\_role\_policy\_arns](#input\_runner\_iam\_role\_policy\_arns) | Attach AWS or customer-managed IAM policies (by ARN) to the runner IAM role | `list(string)` | `[]` | no |
| <a name="input_runner_log_files"></a> [runner\_log\_files](#input\_runner\_log\_files) | Replaces the original module default cloudwatch log config. See <https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html> for details. | <pre>list(object(<br>    {<br>      log_group_name   = string<br>      prefix_log_group = bool<br>      file_path        = string<br>      log_stream_name  = string<br>    }<br>  ))</pre> | <pre>[<br>  {<br>    "file_path": "/var/log/syslog",<br>    "log_group_name": "syslog",<br>    "log_stream_name": "{instance_id}",<br>    "prefix_log_group": true<br>  },<br>  {<br>    "file_path": "/var/log/user-data.log",<br>    "log_group_name": "user_data",<br>    "log_stream_name": "{instance_id}/user_data",<br>    "prefix_log_group": true<br>  },<br>  {<br>    "file_path": "/home/runners/actions-runner/_diag/Runner_**.log",<br>    "log_group_name": "runner",<br>    "log_stream_name": "{instance_id}/runner",<br>    "prefix_log_group": true<br>  }<br>]</pre> | no |
| <a name="input_runners"></a> [runners](#input\_runners) | runners = {<br>      architecture: Must be either "x64" or "arm64"<br>      labels: List of extra labels to attach to the runner. "self-hosted", os and architecture labels are attached by default. Make sure this field is unique among the runners you host.<br>      idle\_config: List of objects specifying the schedule for keeping runners idle/warm<br>      maximum\_count: Number of maximum concurrent runners that can be spawned<br>      ephemeral: Boolean for selecting the type of runner<br>      use\_spot\_instances: Boolean for using spot EC2 instances instead of on-demand<br>      os: linux or windows. Operating system<br>    } | <pre>map(object({<br>    architecture   = string # x64 / arm64<br>    labels         = list(string)<br>    instance_types = list(string)<br>    idle_config = optional(list(object({<br>      cron      = optional(string, "** 8-18 ? *1-5")     # cron schedule parsed by CronParser (used to keep idle runners up)<br>      poolCron  = optional(string, "* 6-16 ? *Mon-Fri*") # AWS eventbridge cron schedule (used to keep runners pool up)<br>      timeZone  = optional(string, "Europe/Zurich")        # Applied to 'cron' only, not 'poolCron'.<br>      idleCount = optional(number, 1)<br>      })), [{<br>      cron      = "* * 8-18 ? * 1-5" # Important to specify also the seconds or this won't work<br>      poolCron  = "* 6-16 ? * Mon-Fri *"<br>      timeZone  = "Europe/Zurich"<br>      idleCount = 1<br>    }])<br>    maximum_count      = optional(number, 15)<br>    ephemeral          = optional(bool, false)<br>    use_spot_instances = optional(bool, false)<br>    os                 = optional(string, "linux")        # linux / windows<br>    base_ami           = optional(string, "amazonlinux2") # amazonlinux2 / ubuntu<br>    disk = optional(object({<br>      throughput_mbps = optional(number) # between 125 and 750<br>      volume_type     = optional(string, "gp3")<br>    }), {})<br>  }))</pre> | <pre>{<br>  "runner-1": {<br>    "architecture": "x64",<br>    "instance_types": [<br>      "c7a.xlarge",<br>      "c7i.xlarge",<br>      "c6a.xlarge",<br>      "c6i.xlarge"<br>    ],<br>    "labels": [<br>      "multi-runner"<br>    ]<br>  }<br>}</pre> | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The set of subnets where to deploy the runners | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Map of tags to apply to all resources deployed from the module | `map(string)` | `{}` | no |
| <a name="input_unique_prefix"></a> [unique\_prefix](#input\_unique\_prefix) | The unique prefix used for naming AWS resources. | `string` | n/a | yes |
| <a name="input_userdata_post_install"></a> [userdata\_post\_install](#input\_userdata\_post\_install) | Script to be ran after the GitHub Actions runner is installed on the EC2 instances | `string` | `""` | no |
| <a name="input_userdata_pre_install"></a> [userdata\_pre\_install](#input\_userdata\_pre\_install) | Script to be ran before the GitHub Actions runner is installed on the EC2 instances | `string` | `""` | no |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | EBS volume size mounted to runner instance | `number` | `40` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | The vpc id where to deploy the runners | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_runner_iam_roles"></a> [runner\_iam\_roles](#output\_runner\_iam\_roles) | Map of the IAM Roles used by the created runners |
| <a name="output_runner_labels"></a> [runner\_labels](#output\_runner\_labels) | Map of the runner labels you can use in your jobs to select the runners |
| <a name="output_ssm_parameters"></a> [ssm\_parameters](#output\_ssm\_parameters) | Names and ARNs of the ssm parameters created by the multi\_runner module |
| <a name="output_webhook_endpoint"></a> [webhook\_endpoint](#output\_webhook\_endpoint) | API gateway endpoint that handles GitHub App webhook events |
| <a name="output_webhook_secret"></a> [webhook\_secret](#output\_webhook\_secret) | Webhook secret used to validate requests from Github. Use this as 'webhook secret' in the Github app. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Alfredo Gottardo](https://github.com/AlfGot), [David Beauvererd](https://github.com/Davidoutz), [Davide Cammarata](https://github.com/DCamma), [Demetrio Carrara](https://github.com/sgametrio) and [Roland Bapst](https://github.com/rbapst-tamedia)

## License

Apache 2 Licensed. See [LICENSE](https://github.com/tx-pts-dai/terraform-aws-ec2-actions-runners/blob/main/LICENSE) for full details.

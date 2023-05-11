# Github Multi-Runner deployment on ec2 instances

This Module is a wrapper of the original [Philips Labs Multi-Runner module](https://github.com/philips-labs/terraform-aws-github-runner/tree/main/modules/multi-runner). All credits for the original implementation goes to [philips-labs](https://github.com/philips-labs), the module in this repo has been created according to the [MIT license](https://github.com/philips-labs/terraform-aws-github-runner/blob/main/LICENSE.md).

The goal of this wrapper is to simplify the deployment of a simple and specific use case: a basic multi-runner deployment with two set of runners, one based on amd architecture and one based on arm architecture. We aimed at hiding as much configuration as possible behind defaults, giving the user a minimal set of required variables for a fast opinionated deployment of the original multi-runner module.

## Usage

Example deployment with the required variables:

This snippet will deploy two set of runners:

  1. Amd set (instances types ["c6i.xlarge", "c6a.xlarge"])
  2. Arm set (instances types ["c6g.xlarge", "t4g.xlarge"])

each have a max count of 5 runners and an idle configuration to have 3 idle runners each during office hours (Zurich time zone)

```hcl
module "example_multi_runner" {
  source                    = "github.com/tx-pts-dai/terraform-aws-ec2-actions-runners?ref=vX.X.X"
  unique_prefix             = "build-runners"
  github_app_multirunner_id = "..."
  github_app_key_base64     = "..."
  vpc_id                    = "..."
  subnet_ids                = "..."
}
```

You can select the runners in a github workflow with:

```yaml
# x64 runner
runs-on: ["self-hosted", "linux", "x64", "multi-runner"]
# arm64 runner
runs-on: ["self-hosted", "linux", "arm64", "multi-runner"]
```

The labels used by the runners are set as a Terraform output `runner_labels`

IMPORTANT: When destroying the resources created by this module, there could be some EC2 instances as leftovers. Since they are launched dynamically via Lambda function, Terraform doesn't have any knowledge about them.

### Github Application (required)

Please follow the instruction on the original repo [Setup Github Application](https://github.com/philips-labs/terraform-aws-github-runner#setup-github-app-part-1)

The `webhook_endpoint` and `webhook_secret` can be obtained as output from the module via `terraform output module.MY_MODULE_NAME.webhook_endpoint` (or `..._secret`)

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
1. Commit all of these changes.

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
| <a name="module_multi_runner"></a> [multi\_runner](#module\_multi\_runner) | philips-labs/github-runner/aws//modules/multi-runner | 3.2.0 |

## Resources

| Name | Type |
|------|------|
| [random_id.webhook_secret](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_amd_instance_types"></a> [amd\_instance\_types](#input\_amd\_instance\_types) | on demand spot amd/intel instances | `list(string)` | <pre>[<br>  "c6i.xlarge",<br>  "c6a.xlarge"<br>]</pre> | no |
| <a name="input_arm_instance_types"></a> [arm\_instance\_types](#input\_arm\_instance\_types) | on demand spot arm64 instances | `list(string)` | <pre>[<br>  "c6g.xlarge",<br>  "t4g.xlarge"<br>]</pre> | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | aws zone where to host the github actions runners | `string` | `"eu-central-1"` | no |
| <a name="input_deploy_amd"></a> [deploy\_amd](#input\_deploy\_amd) | determine if the amd runners will be deployed (if both var.deploy\_amd and var.deploy\_arm are false the module will deploy the amd runners anyway) | `bool` | `true` | no |
| <a name="input_deploy_arm"></a> [deploy\_arm](#input\_deploy\_arm) | determine if the arm runners will be deployed | `bool` | `false` | no |
| <a name="input_enable_ephemeral_runners"></a> [enable\_ephemeral\_runners](#input\_enable\_ephemeral\_runners) | Flag to enable 'ephemeral' runners rather than persistent. | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment this resource will be deployed in. | `string` | n/a | yes |
| <a name="input_github_app_key_base64"></a> [github\_app\_key\_base64](#input\_github\_app\_key\_base64) | Github app key. Ensure the key is the base64-encoded `.pem` file (the output of `base64 app.private-key.pem`, not the content of `private-key.pem`). | `string` | n/a | yes |
| <a name="input_github_app_multirunner_id"></a> [github\_app\_multirunner\_id](#input\_github\_app\_multirunner\_id) | id of the github app | `string` | n/a | yes |
| <a name="input_github_org"></a> [github\_org](#input\_github\_org) | Name of the Github organization, owning the runners. Required only if specified with ephemeral runners | `string` | `null` | no |
| <a name="input_idle_config"></a> [idle\_config](#input\_idle\_config) | List of time period that can be defined as cron expression to keep a minimum amount of runners active instead of scaling down to 0. By defining this list you can ensure that in time periods that match the cron expression within 5 seconds a runner is kept idle. | <pre>list(object({<br>    cron      = optional(string, "* 8-18 ? * 1-5") # cron schedule<br>    timeZone  = optional(string, "Europe/Zurich")<br>    idleCount = optional(number, 1)<br>  }))</pre> | <pre>[<br>  {<br>    "cron": "* 8-18 ? * 1-5",<br>    "idleCount": 1,<br>    "timeZone": "Europe/Zurich"<br>  }<br>]</pre> | no |
| <a name="input_instance_allocation_strategy"></a> [instance\_allocation\_strategy](#input\_instance\_allocation\_strategy) | allocation strategy for spot instances | `string` | `"price-capacity-optimized"` | no |
| <a name="input_instance_target_capacity_type"></a> [instance\_target\_capacity\_type](#input\_instance\_target\_capacity\_type) | Default lifecyle used runner instances, can be either `spot` or `on-demand`. | `string` | `"spot"` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Specifies the number of days you want to retain log events for the lambda log group. Possible values are: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653. | `number` | `7` | no |
| <a name="input_runner_group_name"></a> [runner\_group\_name](#input\_runner\_group\_name) | github actions runner group to attach the agents to | `string` | `"Infrastructure-Repository-Deployment"` | no |
| <a name="input_runner_iam_role_policy_arns"></a> [runner\_iam\_role\_policy\_arns](#input\_runner\_iam\_role\_policy\_arns) | Attach AWS or customer-managed IAM policies (by ARN) to the runner IAM role | `list(string)` | `[]` | no |
| <a name="input_runner_labels"></a> [runner\_labels](#input\_runner\_labels) | List of string of labels to assign to the runners. The runner architecture, os and 'self-hosted' will be automatically added by the module (x64 or arm64) | `list(string)` | <pre>[<br>  "multi-runner"<br>]</pre> | no |
| <a name="input_runner_log_files"></a> [runner\_log\_files](#input\_runner\_log\_files) | Replaces the original module default cloudwatch log config. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html for details. | <pre>list(object(<br>    {<br>      log_group_name   = string<br>      prefix_log_group = bool<br>      file_path        = string<br>      log_stream_name  = string<br>    }<br>  ))</pre> | <pre>[<br>  {<br>    "file_path": "/var/log/syslog",<br>    "log_group_name": "syslog",<br>    "log_stream_name": "{instance_id}",<br>    "prefix_log_group": true<br>  },<br>  {<br>    "file_path": "/var/log/user-data.log",<br>    "log_group_name": "user_data",<br>    "log_stream_name": "{instance_id}/user_data",<br>    "prefix_log_group": true<br>  },<br>  {<br>    "file_path": "/home/runners/actions-runner/_diag/Runner_**.log",<br>    "log_group_name": "runner",<br>    "log_stream_name": "{instance_id}/runner",<br>    "prefix_log_group": true<br>  }<br>]</pre> | no |
| <a name="input_runners_maximum_count"></a> [runners\_maximum\_count](#input\_runners\_maximum\_count) | max numbers of runners to keep per architecture | `number` | `15` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | The set of subnets where to deploy the runners | `list(string)` | n/a | yes |
| <a name="input_unique_prefix"></a> [unique\_prefix](#input\_unique\_prefix) | The unique prefix used for naming resources. | `string` | n/a | yes |
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

# < This section can be removed >

Official doc for public modules [hashicorp](https://developer.hashicorp.com/terraform/registry/modules/publish)

Repo structure:

```
├── README.md
├── main.tf
├── variables.tf
├── outputs.tf
├── ...
├── modules/
│   ├── nestedA/
│   │   ├── README.md
│   │   ├── variables.tf
│   │   ├── main.tf
│   │   ├── outputs.tf
│   ├── nestedB/
│   ├── .../
├── examples/
│   ├── exampleA/
│   │   ├── main.tf
│   ├── exampleB/
│   ├── .../
```

# My Terraform Module

< module description >

## Usage

< describe the module minimal code required for a deployment >

```hcl
module "my_module_example" {
}
```

## Explanation and description of interesting use-cases

< create a h2 chapter for each section explaining special module concepts >

## Examples

< if the folder `examples/` exists, put here the link to the examples subfolders with their descriptions >

## Contributing

< issues and contribution guidelines for public modules >

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

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0 |
| <a name="requirement_random"></a> [random](#requirement\_random) | 3.4.3 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0 |
| <a name="provider_random"></a> [random](#provider\_random) | 3.4.3 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_multi_runner"></a> [multi\_runner](#module\_multi\_runner) | philips-labs/github-runner/aws//modules/multi-runner | 2.2.0 |

## Resources

| Name | Type |
|------|------|
| [random_id.webhook_secret](https://registry.terraform.io/providers/hashicorp/random/3.4.3/docs/resources/id) | resource |
| [aws_subnets.subnets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnets) | data source |
| [aws_vpc.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/vpc) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_amd_instance_types"></a> [amd\_instance\_types](#input\_amd\_instance\_types) | on demand spot amd/intel instances | `list(string)` | <pre>[<br>  "c6i.xlarge",<br>  "c6a.xlarge"<br>]</pre> | no |
| <a name="input_arm_instance_types"></a> [arm\_instance\_types](#input\_arm\_instance\_types) | on demand spot arm64 instances | `list(string)` | <pre>[<br>  "c6g.xlarge",<br>  "t4g.xlarge"<br>]</pre> | no |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | aws zone where to host the github actions runners | `string` | `"eu-central-1"` | no |
| <a name="input_deploy_amd"></a> [deploy\_amd](#input\_deploy\_amd) | determine if the amd runners will be deployed (if both var.deploy\_amd and var.deploy\_arm are false the module will deploy the amd runners anyway) | `bool` | `true` | no |
| <a name="input_deploy_arm"></a> [deploy\_arm](#input\_deploy\_arm) | determine if the arm runners will be deployed | `bool` | `false` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | The environment this resource will be deployed in. | `string` | n/a | yes |
| <a name="input_github_app_key_base64"></a> [github\_app\_key\_base64](#input\_github\_app\_key\_base64) | Github app key. Ensure the key is the base64-encoded `.pem` file (the output of `base64 app.private-key.pem`, not the content of `private-key.pem`). | `string` | n/a | yes |
| <a name="input_github_app_multirunner_id"></a> [github\_app\_multirunner\_id](#input\_github\_app\_multirunner\_id) | id of the github app | `string` | n/a | yes |
| <a name="input_idle_config"></a> [idle\_config](#input\_idle\_config) | List of time period that can be defined as cron expression to keep a minimum amount of runners active instead of scaling down to 0. By defining this list you can ensure that in time periods that match the cron expression within 5 seconds a runner is kept idle. | <pre>list(object({<br>    cron      = optional(string, "* * 8-19 * * *") # cron schedule<br>    timeZone  = optional(string, "Europe/Zurich")<br>    idleCount = number<br>  }))</pre> | <pre>[<br>  {<br>    "cron": "* * 8-19 * * *",<br>    "idleCount": 3,<br>    "timeZone": "Europe/Zurich"<br>  }<br>]</pre> | no |
| <a name="input_instance_allocation_strategy"></a> [instance\_allocation\_strategy](#input\_instance\_allocation\_strategy) | allocation strategy for spot instances | `string` | `"price-capacity-optimized"` | no |
| <a name="input_log_retention_in_days"></a> [log\_retention\_in\_days](#input\_log\_retention\_in\_days) | Specifies the number of days you want to retain log events for the lambda log group. Possible values are: 0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1827, and 3653. | `number` | `7` | no |
| <a name="input_runner_group_name"></a> [runner\_group\_name](#input\_runner\_group\_name) | github actions runner group to attach the agents to | `string` | `"Infrastructure-Repository-Deployment"` | no |
| <a name="input_runner_iam_role_managed_policy_arns"></a> [runner\_iam\_role\_managed\_policy\_arns](#input\_runner\_iam\_role\_managed\_policy\_arns) | Attach AWS or customer-managed IAM policies (by ARN) to the runner IAM role | `list(string)` | `[]` | no |
| <a name="input_runner_log_files"></a> [runner\_log\_files](#input\_runner\_log\_files) | Replaces the original module default cloudwatch log config. See https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html for details. | <pre>list(object(<br>    {<br>      log_group_name   = string<br>      prefix_log_group = bool<br>      file_path        = string<br>      log_stream_name  = string<br>    }<br>  ))</pre> | <pre>[<br>  {<br>    "file_path": "/var/log/syslog",<br>    "log_group_name": "syslog",<br>    "log_stream_name": "{instance_id}",<br>    "prefix_log_group": true<br>  },<br>  {<br>    "file_path": "/var/log/user-data.log",<br>    "log_group_name": "user_data",<br>    "log_stream_name": "{instance_id}/user_data",<br>    "prefix_log_group": true<br>  },<br>  {<br>    "file_path": "/home/runners/actions-runner/_diag/Runner_**.log",<br>    "log_group_name": "runner",<br>    "log_stream_name": "{instance_id}/runner",<br>    "prefix_log_group": true<br>  }<br>]</pre> | no |
| <a name="input_runners_maximum_count"></a> [runners\_maximum\_count](#input\_runners\_maximum\_count) | max numbers of runners to keep per architecture | `number` | `5` | no |
| <a name="input_volume_size"></a> [volume\_size](#input\_volume\_size) | EBS volume size mounted to runner instance | `number` | `40` | no |
| <a name="input_vpc_tag_name_value"></a> [vpc\_tag\_name\_value](#input\_vpc\_tag\_name\_value) | Value of the vpc tag:Name where the runners will be deployed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_ssm_parameters"></a> [ssm\_parameters](#output\_ssm\_parameters) | Names and ARNs of the ssm parameters created by the multi\_runner module |
| <a name="output_webhook_endpoint"></a> [webhook\_endpoint](#output\_webhook\_endpoint) | API gateway endpoint that handles GitHub App webhook events |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Alfredo Gottardo](https://github.com/AlfGot), [David Beauvererd](https://github.com/Davidoutz), [Davide Cammarata](https://github.com/DCamma), [Demetrio Carrara](https://github.com/sgametrio) and [Roland Bapst](https://github.com/rbapst-tamedia)

## License

Apache 2 Licensed. See [LICENSE](< link to license file >) for full details.

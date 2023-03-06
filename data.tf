data "aws_vpc" "selected" {
  filter {
    name   = "tag:Name"
    values = [var.vpc_tag_name_value]
  }
}

data "aws_subnets" "subnets" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.selected.id]
  }

  filter {
    name   = "tag:Name"
    values = [var.vpc_tag_name_value]
  }
}

locals {
    region_vars = read_terragrunt_config(find_in_parent_folders("region.hcl"))

    aws_region = local.region_vars.locals.aws_region
}

generate "provider" {
    path = "provider.tf"
    if_exists = "overwrite_terragrunt"
    contents = <<EOF
    provider "aws" {
        region = "${local.aws_region}"
    }
    EOF
}
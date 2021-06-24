/*
 * variables.tf
 * Common variables to use in various Terraform files (*.tf)
 */

# The AWS region to use for the dev environment's infrastructure
variable "region" {
  default = "us-east-1"
}


variable "dggr_region" {}

variable "dggr_aws_key" {}

variable "dggr_aws_secret" {}

variable "certificate_domain" {}

variable "dggr_zone_id" {}
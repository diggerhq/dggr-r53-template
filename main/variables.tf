/*
 * variables.tf
 * Common variables to use in various Terraform files (*.tf)
 */

# The AWS region to use for the dev environment's infrastructure
variable "region" {
  default = "us-east-1"
}

# main aws account where ACM cert is provisioned
variable "aws_key" {}

variable "aws_secret" {}

# digger aws account which contains the R53 Zone for digger.app
variable "dggr_aws_key" {}

variable "dggr_aws_secret" {}

variable "certificate_domain" {}

variable "dggr_zone_id" {}


terraform {
  required_version = ">= 0.12"

  # vars are not allowed in this block
  # see: https://github.com/hashicorp/terraform/issues/22088
  backend "s3" {}

  required_providers {
    archive = {
      version = "= 1.3.0"
      source  = "hashicorp/archive"
    }

    local = {
      version = "= 1.4.0"
      source  = "hashicorp/local"
    }

    template = {
      version = "= 2.1.2"
      source  = "hashicorp/template"
    }
  }
}

# The AWS Profile to use
# variable "aws_profile" {
# }

provider "aws" {
  version = "= 3.45.0"
  region  = var.region
  # profile = var.aws_profile
  access_key = var.aws_key
  secret_key = var.aws_secret  
}

provider "aws" {
  alias  = "dggr_r53"
  # doesn't matter because R53 is global
  region  = "us-east-1"
  access_key = var.dggr_aws_key
  secret_key = var.dggr_aws_secret      
}


resource "aws_acm_certificate" "cert" {
  domain_name       = var.certificate_domain
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "cert_validation" {
  provider = aws.dggr_r53
  for_each = {
    for dvo in aws_acm_certificate.cert.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = var.dggr_zone_id
}


output "acm_certificate_arn" {
  value = aws_acm_certificate.cert.arn
}


{% if region != "us-east-1" %}
  provider "aws" {
    alias = "virginia"
    version = "= 3.45.0"
    region  = "us-east-1"
    # profile = var.aws_profile
    access_key = var.aws_key
    secret_key = var.aws_secret
  }

  resource "aws_acm_certificate" "cert_virginia" {
    provider = aws.virginia
    domain_name       = var.certificate_domain
    validation_method = "DNS"

    lifecycle {
      create_before_destroy = true
    }
  }


  resource "aws_route53_record" "cert_virginia_validation" {
    provider = aws.dggr_r53
    for_each = {
      for dvo in aws_acm_certificate.cert_virginia.domain_validation_options : dvo.domain_name => {
        name   = dvo.resource_record_name
        record = dvo.resource_record_value
        type   = dvo.resource_record_type
      }
    }

    allow_overwrite = true
    name            = each.value.name
    records         = [each.value.record]
    ttl             = 60
    type            = each.value.type
    zone_id         = var.dggr_zone_id
  }

  output "acm_virginia_certificate_arn" {
    value = aws_acm_certificate.cert_virginia.arn
  }

{% else %}

  output "acm_virginia_certificate_arn" {
    value = aws_acm_certificate.cert.arn
  }

{% endif %}


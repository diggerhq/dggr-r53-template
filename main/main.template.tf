
terraform {
  required_version = ">= 0.12"

  # vars are not allowed in this block
  # see: https://github.com/hashicorp/terraform/issues/22088
  backend "s3" {}

}

provider "aws" {
  alias  = "dggr_r53"
  # doesn't matter because R53 is global
  region  = "us-east-1"
  access_key = var.dggr_aws_key
  secret_key = var.dggr_aws_secret      
}

{% for region in environment_config.regions %}

  provider "aws" {
    alias = "{{region}}"
    region  = "{{region}}"
    # profile = var.aws_profile
    access_key = var.aws_key
    secret_key = var.aws_secret  
  }

  resource "aws_acm_certificate" "cert_{{region}}" {
    provider = aws.{{region}}
    domain_name       = var.certificate_domain
    validation_method = "DNS"

    lifecycle {
      create_before_destroy = true
    }
  }


  output "acm_certificate_record_type_{{region}}" {
    value = tolist(aws_acm_certificate.cert_{{region}}.domain_validation_options)[0].resource_record_type
  }

  output "acm_certificate_record_name_{{region}}" {
    value = tolist(aws_acm_certificate.cert_{{region}}.domain_validation_options)[0].resource_record_name
  }

  output "acm_certificate_record_value_{{region}}" {
    value = tolist(aws_acm_certificate.cert_{{region}}.domain_validation_options)[0].resource_record_value
  }

  output "acm_certificate_arn_{{region}}" {
    value = aws_acm_certificate.cert_{{region}}.arn
  }

{% endfor %}


resource "aws_route53_record" "cert_validation" {
  provider = aws.dggr_r53
  for_each = {
    for dvo in aws_acm_certificate.cert_{{environment_config.regions[0]}}.domain_validation_options : dvo.domain_name => {
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


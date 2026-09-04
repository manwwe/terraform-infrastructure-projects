mock_provider "aws" {}

run "private_parent_zone" {
  command = plan

  variables {
    zone_name = "internal.example.com"
    vpc_associations = {
      development = {
        vpc_id     = "vpc-0123456789abcdef0"
        vpc_region = "us-east-1"
      }
      production = {
        vpc_id     = "vpc-0fedcba9876543210"
        vpc_region = "us-east-1"
      }
    }
  }

  assert {
    condition     = aws_route53_zone.this.name == "internal.example.com"
    error_message = "The configured private parent zone must be created."
  }

  assert {
    condition     = length(aws_route53_zone_association.this) == 1
    error_message = "Every VPC after the initial VPC must have an explicit association."
  }
}

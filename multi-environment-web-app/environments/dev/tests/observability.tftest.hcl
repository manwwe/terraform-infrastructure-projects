mock_provider "aws" {
  mock_data "aws_ssm_parameter" {
    defaults = {
      value = "ami-0123456789abcdef0"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition = "aws"
    }
  }

  mock_resource "aws_db_instance" {
    override_during = plan

    defaults = {
      arn      = "arn:aws:rds:us-east-1:123456789012:db:example-dev"
      address  = "example-dev.us-east-1.rds.amazonaws.com"
      endpoint = "example-dev.us-east-1.rds.amazonaws.com:5432"
      master_user_secret = [{
        secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:example-dev"
      }]
    }
  }

  mock_resource "aws_lb" {
    override_during = plan

    defaults = {
      arn        = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/example-dev/0123456789abcdef"
      arn_suffix = "app/example-dev/0123456789abcdef"
    }
  }

  mock_resource "aws_lb_target_group" {
    override_during = plan

    defaults = {
      arn        = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/example-dev/0123456789abcdef"
      arn_suffix = "targetgroup/example-dev/0123456789abcdef"
    }
  }

  mock_resource "aws_cloudwatch_log_group" {
    override_during = plan

    defaults = {
      arn = "arn:aws:logs:us-east-1:123456789012:log-group:/example-dev/application"
    }
  }
}

variables {
  owner              = "platform-team"
  aws_region         = "us-east-1"
  availability_zones = ["us-east-1a", "us-east-1b"]
}

run "uses_development_observability_settings" {
  command = plan

  assert {
    condition = module.observability.configuration == {
      log_retention_in_days          = 7
      minimum_healthy_instance_count = 1
      rds_free_storage_threshold     = 2147483648
    }
    error_message = "Development must use the approved observability settings."
  }

  assert {
    condition = local.observability_log_group_names == {
      application = "/multi-environment-web-app-dev/application"
      nginx       = "/multi-environment-web-app-dev/nginx"
      cloud_init  = "/multi-environment-web-app-dev/cloud-init"
    }
    error_message = "Development bootstrap must receive every environment log-group name."
  }

  assert {
    condition = strcontains(
      file("${path.module}/templates/compute_user_data.sh.tftpl"),
      "install -d -o snake -g snake /var/log/snake-app"
    )
    error_message = "Development bootstrap must create the application log directory before starting the service."
  }
}

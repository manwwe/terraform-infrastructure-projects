mock_provider "aws" {}

run "organization_structure" {
  command = apply

  variables {
    root_id = "r-example"

    accounts = {
      security = {
        name                = "Security"
        email               = "aws-security@example.com"
        organizational_unit = "security"
      }
      shared_services = {
        name                = "Shared Services"
        email               = "aws-shared@example.com"
        organizational_unit = "infrastructure"
      }
      development = {
        name                = "Development"
        email               = "aws-development@example.com"
        organizational_unit = "workloads"
      }
      production = {
        name                = "Production"
        email               = "aws-production@example.com"
        organizational_unit = "workloads"
      }
    }
  }

  override_resource {
    target = aws_organizations_organizational_unit.this["security"]

    values = {
      id = "ou-exam-11111111"
    }
  }

  override_resource {
    target = aws_organizations_organizational_unit.this["infrastructure"]

    values = {
      id = "ou-exam-22222222"
    }
  }

  override_resource {
    target = aws_organizations_organizational_unit.this["workloads"]

    values = {
      id = "ou-exam-33333333"
    }
  }

  assert {
    condition     = aws_organizations_organizational_unit.this["security"].name == "Security"
    error_message = "The Security organizational unit must exist."
  }

  assert {
    condition     = aws_organizations_organizational_unit.this["infrastructure"].name == "Infrastructure"
    error_message = "The Infrastructure organizational unit must exist."
  }

  assert {
    condition     = aws_organizations_organizational_unit.this["workloads"].name == "Workloads"
    error_message = "The Workloads organizational unit must exist."
  }

  assert {
    condition = (
      aws_organizations_account.member["security"].parent_id ==
      aws_organizations_organizational_unit.this["security"].id
    )
    error_message = "The Security account must belong to the Security OU."
  }

  assert {
    condition = (
      aws_organizations_account.member["shared_services"].parent_id ==
      aws_organizations_organizational_unit.this["infrastructure"].id
    )
    error_message = "The Shared Services account must belong to the Infrastructure OU."
  }

  assert {
    condition = (
      aws_organizations_account.member["development"].parent_id ==
      aws_organizations_organizational_unit.this["workloads"].id &&
      aws_organizations_account.member["production"].parent_id ==
      aws_organizations_organizational_unit.this["workloads"].id
    )
    error_message = "Development and Production must belong to the Workloads OU."
  }

  assert {
    condition = alltrue([
      for account in aws_organizations_account.member :
      account.close_on_deletion == false
    ])
    error_message = "Removing an account from Terraform must not close it."
  }
}

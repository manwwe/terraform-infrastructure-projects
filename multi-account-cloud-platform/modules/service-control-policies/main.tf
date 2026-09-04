locals {
  policy_documents = {
    protect_organization = file(
      "${path.module}/policies/protect-organization.json"
    )

    protect_audit = file(
      "${path.module}/policies/protect-audit.json"
    )

    protect_s3_public_access = file(
      "${path.module}/policies/protect-s3-public-access.json"
    )

    restrict_regions = templatefile(
      "${path.module}/policies/restrict-regions.json.tftpl",
      {
        allowed_regions = jsonencode(sort(tolist(var.allowed_regions)))
      }
    )
  }

  policy_attachments = merge([
    for policy_name, targets in var.policy_targets : {
      for target_id in targets :
      "${policy_name}:${target_id}" => {
        policy_name = policy_name
        target_id   = target_id
      }
    }
  ]...)
}

resource "aws_organizations_policy" "this" {
  for_each = local.policy_documents

  name        = replace(each.key, "_", "-")
  description = "Managed Terraform guardrail: ${replace(each.key, "_", " ")}"
  type        = "SERVICE_CONTROL_POLICY"
  content     = each.value

  tags = {
    ManagedBy = "Terraform"
  }
}

resource "aws_organizations_policy_attachment" "this" {
  for_each = local.policy_attachments

  policy_id = aws_organizations_policy.this[each.value.policy_name].id
  target_id = each.value.target_id
}

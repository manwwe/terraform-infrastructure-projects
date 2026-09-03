module "network" {
  source = "../../modules/network"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = true
  tags               = local.common_tags
}

module "security" {
  source = "../../modules/security"

  name_prefix = local.name_prefix
  vpc_id      = module.network.vpc_id
  tags        = local.common_tags
}

module "iam" {
  source = "../../modules/iam"

  name_prefix = local.name_prefix
  secret_arns = [module.rds.master_user_secret_arn]
  tags        = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  name_prefix                = local.name_prefix
  database_subnet_ids_by_az  = module.network.database_subnet_ids_by_az
  database_security_group_id = module.security.database_security_group_id

  database_name   = "appdb"
  master_username = "app_admin"
  engine_version  = "17"
  instance_class  = "db.t4g.micro"

  allocated_storage = 20
  storage_type      = "gp3"
  multi_az          = false

  backup_retention_period    = 1
  deletion_protection        = false
  skip_final_snapshot        = true
  auto_minor_version_upgrade = true

  enabled_cloudwatch_logs_exports  = ["postgresql"]
  cloudwatch_log_retention_in_days = 7
  tags                             = local.common_tags
}

module "compute" {
  source = "../../modules/compute"

  name_prefix                   = local.name_prefix
  application_subnet_ids        = module.network.application_subnet_ids
  application_security_group_id = module.security.application_security_group_id
  instance_profile_name         = module.iam.instance_profile_name

  instance_type    = "t3.micro"
  min_size         = 1
  desired_capacity = 1
  max_size         = 2

  user_data = templatefile(
    "${path.module}/templates/compute_user_data.sh.tftpl",
    {}
  )

  tags = local.common_tags

  depends_on = [
    module.network,
    module.security,
    module.iam,
  ]
}

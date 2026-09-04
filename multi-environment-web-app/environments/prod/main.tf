module "network" {
  source = "../../modules/network"

  name_prefix        = local.name_prefix
  vpc_cidr           = var.vpc_cidr
  availability_zones = var.availability_zones
  single_nat_gateway = false
  tags               = local.common_tags
}

module "security" {
  source = "../../modules/security"

  name_prefix                 = local.name_prefix
  vpc_id                      = module.network.vpc_id
  load_balancer_ingress_cidrs = var.load_balancer_ingress_cidrs
  enable_load_balancer_https  = false
  tags                        = local.common_tags
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
  instance_class  = "db.t4g.small"

  allocated_storage = 20
  storage_type      = "gp3"
  multi_az          = true

  backup_retention_period    = 30
  deletion_protection        = true
  skip_final_snapshot        = false
  final_snapshot_identifier  = "${local.name_prefix}-postgresql-final"
  auto_minor_version_upgrade = true

  enabled_cloudwatch_logs_exports  = ["postgresql", "upgrade"]
  cloudwatch_log_retention_in_days = 30
  tags                             = local.common_tags
}

module "load_balancer" {
  source = "../../modules/load-balancer"

  name_prefix       = local.name_prefix
  vpc_id            = module.network.vpc_id
  public_subnet_ids = module.network.public_subnet_ids
  security_group_id = module.security.load_balancer_security_group_id
  application_port  = 80
  tags              = local.common_tags
}

module "compute" {
  source = "../../modules/compute"

  name_prefix                   = local.name_prefix
  application_subnet_ids        = module.network.application_subnet_ids
  application_security_group_id = module.security.application_security_group_id
  instance_profile_name         = module.iam.instance_profile_name

  instance_type     = "t3.micro"
  min_size          = 2
  desired_capacity  = 2
  max_size          = 4
  target_group_arns = [module.load_balancer.target_group_arn]

  user_data = templatefile(
    "${path.module}/templates/compute_user_data.sh.tftpl",
    {
      aws_region          = var.aws_region
      database_secret_arn = module.rds.master_user_secret_arn
      database_host       = module.rds.address
      database_port       = module.rds.port
      database_name       = module.rds.database_name

      requirements_gzip_b64 = base64gzip(file("${path.module}/../../application/requirements.txt"))
      app_init_gzip_b64     = base64gzip(file("${path.module}/../../application/snake_app/__init__.py"))
      database_gzip_b64     = base64gzip(file("${path.module}/../../application/snake_app/database.py"))
      init_db_gzip_b64      = base64gzip(file("${path.module}/../../application/snake_app/init_db.py"))
      wsgi_gzip_b64         = base64gzip(file("${path.module}/../../application/snake_app/wsgi.py"))
      index_gzip_b64        = base64gzip(file("${path.module}/../../application/snake_app/templates/index.html"))
      styles_gzip_b64       = base64gzip(file("${path.module}/../../application/snake_app/static/styles.css"))
      game_gzip_b64         = base64gzip(file("${path.module}/../../application/snake_app/static/game.js"))
    }
  )

  tags = local.common_tags

  depends_on = [
    module.network,
    module.security,
    module.iam,
  ]
}

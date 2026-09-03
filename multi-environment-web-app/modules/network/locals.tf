locals {
  subnets = {
    for index, az in var.availability_zones : az => {
      index            = index
      public_cidr      = cidrsubnet(var.vpc_cidr, 8, index)
      application_cidr = cidrsubnet(var.vpc_cidr, 8, index + 2)
      database_cidr    = cidrsubnet(var.vpc_cidr, 8, index + 4)
    }
  }
  nat_gateway_subnets = var.single_nat_gateway ? {
    (var.availability_zones[0]) = local.subnets[var.availability_zones[0]]
  } : local.subnets
}

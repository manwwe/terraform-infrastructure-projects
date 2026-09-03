resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-vpc"
  })
}

resource "aws_subnet" "public" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.public_cidr
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-${each.value.index + 1}"
    Tier = "public"
  })
}

resource "aws_subnet" "application" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.application_cidr
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-application-${each.value.index + 1}"
    Tier = "application"
  })
}

resource "aws_subnet" "database" {
  for_each = local.subnets

  vpc_id                  = aws_vpc.this.id
  cidr_block              = each.value.database_cidr
  availability_zone       = each.key
  map_public_ip_on_launch = false

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database-${each.value.index + 1}"
    Tier = "database"
  })
}

resource "aws_internet_gateway" "this" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-igw"
  })
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-public-rt"
    Tier = "public"
  })
}

resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.this.id
}

resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_eip" "nat" {
  for_each = local.nat_gateway_subnets

  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-eip-${each.value.index + 1}"
  })
}

resource "aws_nat_gateway" "this" {
  for_each = local.nat_gateway_subnets

  allocation_id = aws_eip.nat[each.key].id
  subnet_id     = aws_subnet.public[each.key].id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-nat-${each.value.index + 1}"
  })

  depends_on = [aws_internet_gateway.this]
}

resource "aws_route_table" "application" {
  for_each = local.subnets

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-application-rt-${each.value.index + 1}"
    Tier = "application"
  })
}

resource "aws_route" "application_outbound" {
  for_each = local.subnets

  route_table_id         = aws_route_table.application[each.key].id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.this[
    var.single_nat_gateway ? var.availability_zones[0] : each.key
  ].id
}

resource "aws_route_table_association" "application" {
  for_each = aws_subnet.application

  subnet_id      = each.value.id
  route_table_id = aws_route_table.application[each.key].id
}

resource "aws_route_table" "database" {
  for_each = local.subnets

  vpc_id = aws_vpc.this.id

  tags = merge(var.tags, {
    Name = "${var.name_prefix}-database-rt-${each.value.index + 1}"
    Tier = "database"
  })
}

resource "aws_route_table_association" "database" {
  for_each = aws_subnet.database

  subnet_id      = each.value.id
  route_table_id = aws_route_table.database[each.key].id
}

locals { name = var.project_name }

resource "aws_vpc" "vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "${local.name}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${local.name}-igw" }
}

# public subnets (for ALB)
resource "aws_subnet" "public_a" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "${var.region}a"
  map_public_ip_on_launch = true
  tags                    = { Name = "${local.name}-public-a" }
}
resource "aws_subnet" "public_b" {
  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "${var.region}b"
  map_public_ip_on_launch = true
  tags                    = { Name = "${local.name}-public-b" }
}

# private subnets (for EC2/RDS later)
resource "aws_subnet" "private_a" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.10.0/24"
  availability_zone = "${var.region}a"
  tags              = { Name = "${local.name}-private-a" }
}
resource "aws_subnet" "private_b" {
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = "10.0.11.0/24"
  availability_zone = "${var.region}b"
  tags              = { Name = "${local.name}-private-b" }
}

# routing
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${local.name}-public-rt" }
}
resource "aws_route" "public_internet" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}
resource "aws_route_table_association" "public_a" {
  subnet_id      = aws_subnet.public_a.id
  route_table_id = aws_route_table.public.id
}
resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}

# NAT for private subnets
resource "aws_eip" "nat" { domain = "vpc" }
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public_a.id
  tags          = { Name = "${local.name}-nat" }
}
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.vpc.id
  tags   = { Name = "${local.name}-private-rt" }
}
resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}
resource "aws_route_table_association" "private_a" {
  subnet_id      = aws_subnet.private_a.id
  route_table_id = aws_route_table.private.id
}
resource "aws_route_table_association" "private_b" {
  subnet_id      = aws_subnet.private_b.id
  route_table_id = aws_route_table.private.id
}

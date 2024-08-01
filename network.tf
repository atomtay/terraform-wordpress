data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

## NOTE: api error Resource.AlreadyAssociated with expected vpc
## Commenting out for visibility and troubleshooting
# resource "aws_internet_gateway_attachment" "gw_attachment" {
#   internet_gateway_id = aws_internet_gateway.gw.id
#   vpc_id              = aws_vpc.main.id
# }

## Public subnets and route table associations
resource "aws_route_table" "public_routes" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  count                   = length(data.aws_availability_zones.available.names)
  cidr_block              = "10.0.${count.index}.0/24"
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
}

resource "aws_route_table_association" "public_association" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.public_routes.id
}

## Private subnets and route table associations
resource "aws_route_table" "private_routes" {
  vpc_id = aws_vpc.main.id
  count  = length(aws_subnet.private)
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw[count.index].id
  }
}

resource "aws_subnet" "private" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index + length(data.aws_availability_zones.available.names)}.0/24"
  availability_zone = data.aws_availability_zones.available.names[count.index]
}

resource "aws_route_table_association" "private_association" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private.*.id[count.index]
  route_table_id = aws_route_table.private_routes.*.id[count.index]
}

## EIPs
resource "aws_eip" "eips" {
  count  = length(aws_subnet.public)
  domain = "vpc"
}

resource "aws_nat_gateway" "nat_gw" {
  count         = length(aws_eip.eips)
  subnet_id     = aws_subnet.public.*.id[count.index]
  allocation_id = aws_eip.eips.*.id[count.index]
}

resource "aws_vpc" "web" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "Web Network"
  }
}

resource "aws_internet_gateway" "ig" {
  vpc_id = aws_vpc.web.id
  tags = {
    Name = "Web Network IGW"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.web.id
  count                   = 2
  cidr_block              = "10.0.${count.index + 11}.0/24"
  availability_zone       = element(var.aws_az, count.index)
  map_public_ip_on_launch = true
  tags = {
    Name = "Public subnet ${count.index + 1}"
  }
}

/* Routing table for public subnet */
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.web.id
  tags = {
    Name = "Public-route-table"
  }
}
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.ig.id
}

/* Route table associations */
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public_subnet)
  subnet_id      = element(aws_subnet.public_subnet.*.id, count.index)
  route_table_id = aws_route_table.public.id
}
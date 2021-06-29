data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name = "name"
    values = [
    "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name = "virtualization-type"
    values = [
    "hvm"]
  }

  owners = [
  "099720109477"]
  # Canonical
}

resource "aws_security_group" "allow_http" {
  name        = "allow_http"
  description = "Allow HTTP inbound traffic"
  vpc_id      = aws_vpc.web.id

  ingress {
    description = "HTTP from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [
    "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = [
    "0.0.0.0/0"]
    ipv6_cidr_blocks = [
    "::/0"]
  }

  tags = {
    Name = "allow_http"
  }
}

resource "aws_instance" "web" {
  count         = 2
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  user_data     = file("script.sh")
  vpc_security_group_ids = [
  aws_security_group.allow_http.id]
  availability_zone = element(var.aws_az, count.index)
  key_name          = "new"

  subnet_id                   = aws_subnet.public_subnet[count.index].id
  associate_public_ip_address = true
  tags = {
    Name = "web_${count.index}"
  }
}

resource "aws_lb" "lb" {
  name                             = "test-lb-tf"
  internal                         = false
  load_balancer_type               = "network"
  subnets                          = aws_subnet.public_subnet.*.id
  enable_cross_zone_load_balancing = true

  tags = {
    Name = "Web LB"
  }
}

resource "aws_lb_target_group" "lb_tg" {
  name     = "tf-example-lb-tg"
  port     = 80
  protocol = "TCP"
  vpc_id   = aws_vpc.web.id
  tags = {
    Name = "LB target group"
  }
}

resource "aws_lb_listener" "lb_listener" {
  load_balancer_arn = aws_lb.lb.arn
  port              = "80"
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_tg.arn
  }
  tags = {
    Name = "LB listener"
  }
}

resource "aws_lb_target_group_attachment" "tg_attach" {
  count            = length(aws_instance.web)
  target_group_arn = aws_lb_target_group.lb_tg.arn
  target_id        = aws_instance.web[count.index].id
  port             = 80
}
data "aws_availability_zones" "available" {
  state = "available"
}

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
  name = "allow_http"
  description = "Allow HTTP inbound traffic"

  ingress {
    description = "HTTP from VPC"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = [
      "0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
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
  count = 2
  ami = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  availability_zone = data.aws_availability_zones.available.names[count.index]
  user_data = file("script.sh")
  vpc_security_group_ids = [
    aws_security_group.allow_http.id]
  tags = {
    Name = "HelloWorld"
  }
}

resource "aws_elb" "bar" {
  name = "foobar-terraform-elb"
  availability_zones = data.aws_availability_zones.available.names

  listener {
    instance_port = 80
    instance_protocol = "http"
    lb_port = 80
    lb_protocol = "http"
  }


  health_check {
    healthy_threshold = 2
    unhealthy_threshold = 2
    timeout = 3
    target = "HTTP:80/"
    interval = 30
  }

  instances = aws_instance.web.*.id
  cross_zone_load_balancing = true
  idle_timeout = 400
  connection_draining = true
  connection_draining_timeout = 400

  tags = {
    Name = "foobar-terraform-elb"
  }
}

variable "region" {
  description = "Region in AWS"
  default     = "us-east-1"
}

variable "aws_az" {
  description = "Available zones of the us-east-1 region"
  default     = ["us-east-1a", "us-east-1b"]
}
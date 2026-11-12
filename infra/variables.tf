variable "aws_region" {
  type    = string
  default = "eu-west-1"
}

# Full adresse til imaget i ECR, satt av pipelinen med commit-SHA som tag
variable "image" {
  type = string
}

variable "candidate" {
  type    = string
  default = "18"
}



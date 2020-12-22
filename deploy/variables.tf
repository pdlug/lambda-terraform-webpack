variable "app_name" {
  type    = string
}

variable "aws_profile" {
  type = string
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "aws_allowed_account_ids" {
  type = list(string)
}

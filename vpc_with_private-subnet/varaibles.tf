variable "AWS_REGION" {
  default = "ap-south-1"
}
variable "vpc_identifier" {
  default = "a"
}
variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "azs" {
  default = ["ap-south-1a"]
}

variable "public_subnet" {
  default = "10.0.1.0/24"
}

variable "private_subnet" {
  default = "10.0.2.0/24"
}
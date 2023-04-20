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
variable "AWS_REGION" {
  default = "ap-south-1"

}

variable "vpc_config" {
  default = [
    {
      vpc_identifier  = "a"
      cidr            = "10.100.0.0/16"
      az              = "ap-south-1a"
      public_subnets  = ["10.100.0.0/24"]
      private_subnets = ["10.100.1.0/24"]
      create_igw      = true
    }
    ,
    {
      vpc_identifier  = "b"
      cidr            = "10.200.0.0/16"
      az              = "ap-south-1a"
      public_subnets  = ["10.200.1.0/24"]
      private_subnets = ["10.200.0.0/24"]
      create_igw      = false
    }
  ]
}
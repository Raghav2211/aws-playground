variable "AWS_REGION" {
  default = "ap-south-1"

}

variable "vpc_config" {
  default = [
    {
      vpc_identifier  = "consumer"
      cidr            = "10.100.0.0/16"
      azs             = ["ap-south-1a"]
      public_subnets  = ["10.100.0.0/24"]
      private_subnets = []
      create_igw      = true
      enable_nat_gateway = false
    }
    ,
    {
      vpc_identifier  = "provider"
      cidr            = "10.200.0.0/16"
      azs             = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
      public_subnets  = ["10.200.0.0/24"]
      private_subnets = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]
      create_igw      = true
      enable_nat_gateway = true
    }
  ]
}
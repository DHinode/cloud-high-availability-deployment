variable "vpc-cidr-block" {
  type = string
  default = "10.0.0.0/16"
  description = "CIDR Block for VPC"
}

variable "vpc-name" {
  type = string 
  default = "My VPC"
  description = "Name for VPC"
}

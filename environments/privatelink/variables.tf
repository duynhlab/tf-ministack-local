variable "provider_cidr" {
  type    = string
  default = "10.2.0.0/16"
}

variable "consumer_cidr" {
  type    = string
  default = "10.3.0.0/16"
}

variable "provider_subnets" {
  type    = list(string)
  default = ["10.2.1.0/24", "10.2.2.0/24"]
}

variable "consumer_subnets" {
  type    = list(string)
  default = ["10.3.1.0/24", "10.3.2.0/24"]
}

variable "service_port" {
  type    = number
  default = 80
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "vpc-connectivity-lab"
    Environment = "localstack"
  }
}

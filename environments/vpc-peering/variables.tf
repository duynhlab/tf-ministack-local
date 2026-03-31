variable "requester_cidr" {
  type    = string
  default = "10.0.0.0/16"
}

variable "accepter_cidr" {
  type    = string
  default = "10.1.0.0/16"
}

variable "requester_subnets" {
  type    = list(string)
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "accepter_subnets" {
  type    = list(string)
  default = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "tags" {
  type = map(string)
  default = {
    Project     = "vpc-connectivity-lab"
    Environment = "localstack"
  }
}

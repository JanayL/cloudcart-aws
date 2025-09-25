variable "region" {
  type    = string
  default = "us-east-1"
}

variable "project_name" {
  type    = string
  default = "cloudcart"
}

variable "docker_image" {
  type    = string
  default = "jalee12/cloudcart:latest"
}

variable "instance_type" {
  type    = string
  default = "t3.micro"
}

variable "desired_capacity" {
  type    = number
  default = 2
}

variable "min_size" {
  type    = number
  default = 2
}

variable "max_size" {
  type    = number
  default = 4
}

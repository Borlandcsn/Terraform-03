###cloud vars
#variable "token" {
#  type        = string
#  description = "OAuth-token; https://cloud.yandex.ru/docs/iam/concepts/authorization/oauth-token"
#}

variable "cloud_id" {
  type        = string
  default = "b1gsrv4unoa6l6eiso29"
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
}

variable "folder_id" {
  type        = string
  default = "b1gcp0f2sja64k5b3qka"
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/folder/get-id"
}

variable "default_zone" {
  type        = string
  default     = "ru-central1-a"
  description = "https://cloud.yandex.ru/docs/overview/concepts/geo-scope"
}
variable "default_cidr" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "https://cloud.yandex.ru/docs/vpc/operations/subnet-create"
}

variable "vpc_name" {
  type        = string
  default     = "develop"
  description = "VPC network&subnet name"
}
variable "vm_web_user" {
  type        = string
  default     = "ubuntu"
  description = "user"
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2004-lts" 
}
variable "path_ssh_key" {
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
  description = "Path to the SSH key file"
}
locals {
  metadata = {
    serial-port-enable = 1
    ssh-keys           = "${var.vm_web_user}:${file(var.path_ssh_key)}"
  }
}

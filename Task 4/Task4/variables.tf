variable "cloud_id" {
  description = "Yandex Cloud ID"
  type        = string
  sensitive   = true
}

variable "folder_id" {
  description = "Folder ID"
  type        = string
  sensitive   = true
}

variable "yc_token" {
  description = "Yandex Cloud OAuth token"
  type        = string
  sensitive   = true
}

variable "default_zone" {
  description = "Default zone"
  default     = "ru-central1-a"
  type        = string
}

variable "network_name" {
  default = "app-network"
  type    = string
}

variable "subnet_name" {
  default = "app-subnet"
  type    = string
}

variable "subnet_cidr" {
  default = "10.1.0.0/24"
  type    = string
}

variable "sg_name" {
  default = "app-sg"
  type    = string
}

variable "vm_name" {
  default = "app-vm"
  type    = string
}

variable "vm_cores" {
  default = 2
  type    = number
}

variable "vm_memory" {
  default = 4
  type    = number
}

variable "vm_core_fraction" {
  default = 20
  type    = number
}

variable "boot_disk_size" {
  default = 20
  type    = number
}

variable "data_disk_size" {
  default = 10
  type    = number
}

variable "environment" {
  default = "prod"
  type    = string
}

variable "iam_token" {
  description = "IAM token for cloud-init"
  type        = string
  sensitive   = true
}

variable "lb_name" {
  default = "app-nlb"
  type    = string
}
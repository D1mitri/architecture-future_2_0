terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "~> 0.146.0"
    }
  }
  required_version = ">= 1.3"
}

provider "yandex" {

  token = var.yc_token

  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  zone      = var.default_zone
}

resource "yandex_vpc_network" "app-network" {
  name        = var.network_name
  description = "Network for automated deployment"
  labels = {
    environment = var.environment
  }
}

resource "yandex_vpc_subnet" "app-subnet" {
  name           = var.subnet_name
  zone           = var.default_zone
  network_id     = yandex_vpc_network.app-network.id
  v4_cidr_blocks = [var.subnet_cidr]
}

resource "yandex_vpc_security_group" "app-sg" {
  name        = var.sg_name
  description = "Security group for app instances"
  network_id  = yandex_vpc_network.app-network.id

  ingress {
    protocol       = "TCP"
    description    = "SSH"
    port           = 22
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTP"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "HTTPS"
    port           = 443
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    description    = "All egress"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

data "yandex_compute_image" "ubuntu" {
  family = "ubuntu-2204-lts"
}

resource "yandex_compute_disk" "app-data-disk" {
  name = "app-data-disk"
  zone = var.default_zone
  type = "network-ssd"
  size = var.data_disk_size
  labels = {
    environment = var.environment
  }
}

resource "yandex_compute_instance" "app-vm" {
  name        = var.vm_name
  platform_id = "standard-v3"
  zone        = var.default_zone

  resources {
    cores         = var.vm_cores
    memory        = var.vm_memory
    core_fraction = var.vm_core_fraction
  }

  boot_disk {
    initialize_params {
      size     = var.boot_disk_size
      image_id = data.yandex_compute_image.ubuntu.id
      type     = "network-ssd"
    }
  }

  secondary_disk {
    disk_id     = yandex_compute_disk.app-data-disk.id
    auto_delete = true
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.app-subnet.id
    security_group_ids = [yandex_vpc_security_group.app-sg.id]
    nat                = true
  }

  scheduling_policy {
    preemptible = false
  }

  service_account_id = yandex_iam_service_account.sa.id

  metadata = {
    user-data = templatefile("${path.module}/user-data.yaml", {
      iam_token_env = var.iam_token
    })
  }

  allow_stopping_for_update = true
}

resource "yandex_iam_service_account" "sa" {
  folder_id   = var.folder_id
  name        = "app-sa"
  description = "Service account for app VM"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-service-account-user" {
  folder_id = var.folder_id
  role      = "iam.serviceAccounts.user"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-compute-admin" {
  folder_id = var.folder_id
  role      = "compute.admin"
  member    = "serviceAccount:${yandex_iam_service_account.sa.id}"
}

resource "yandex_lb_target_group" "app-tg" {
  name      = "${var.lb_name}-tg"
  folder_id = var.folder_id

  target {
    subnet_id = yandex_vpc_subnet.app-subnet.id
    address   = yandex_compute_instance.app-vm.network_interface[0].ip_address
  }
}

resource "yandex_lb_network_load_balancer" "app-nlb" {
  name = var.lb_name

  listener {
    name        = "http-listener"
    port        = 80
    target_port = 80
    protocol    = "tcp"

    external_address_spec {
      ip_version = "ipv4"
    }
  }

  attached_target_group {
    target_group_id = yandex_lb_target_group.app-tg.id

    healthcheck {
      name = "http"
      http_options {
        port = 80
        path = "/"
      }
    }
  }
}
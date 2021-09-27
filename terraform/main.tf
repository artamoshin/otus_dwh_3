terraform {
  required_providers {
    yandex = {
      source  = "yandex-cloud/yandex"
      version = "0.64.0"
    }
  }
}

provider "yandex" {
  token     = var.yandex_token
  cloud_id  = var.yandex_cloud_id
  folder_id = var.yandex_folder_id
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "airflow-vm" {
  name        = "airflow-vm"
  platform_id = "standard-v3" # Intel Ice Lake

  resources {
    cores         = 2
    core_fraction = 20
    memory        = 2
  }

  scheduling_policy {
    preemptible = true
  }

  boot_disk {
    initialize_params {
      image_id = "fd8lq8qasokpmv4qnvej" # yc-apache-airflow-2-0-v20210915 (v2.1.3)
      size     = 10
      type     = "network-hdd"
    }
  }

  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-airflow.id
    nat       = true
  }

  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
    user-data = templatefile("cloud-config.yml", {
      db_hostname = yandex_mdb_postgresql_cluster.analytics-db.host[0].fqdn,
      db_password = var.db_password
    })
  }
}

resource "yandex_mdb_postgresql_cluster" "analytics-db" {
  name        = "analytics-db"
  environment = "PRESTABLE"
  network_id  = yandex_vpc_network.network-airflow.id

  config {
    version = 13
    resources {
      resource_preset_id = "b1.nano"
      disk_type_id       = "network-hdd"
      disk_size          = 10
    }
  }

  database {
    name  = "analytics"
    owner = "airflow"
  }

  user {
    name     = "airflow"
    password = var.db_password
    permission {
      database_name = "analytics"
    }
  }

  host {
    zone      = "ru-central1-a"
    subnet_id = yandex_vpc_subnet.subnet-airflow.id
  }
}

resource "yandex_vpc_network" "network-airflow" {}

resource "yandex_vpc_subnet" "subnet-airflow" {
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-airflow.id
  v4_cidr_blocks = ["10.5.0.0/24"]
}


resource "local_file" "airflow-vm-ip-address" {
  content  = yandex_compute_instance.airflow-vm.network_interface.0.nat_ip_address
  filename = "airflow-vm-ip-address.txt"
}

output "airflow-vm-ip-address" {
  value = yandex_compute_instance.airflow-vm.network_interface[0].nat_ip_address
}

output "analytics-db-hostname" {
  value = yandex_mdb_postgresql_cluster.analytics-db.host[0].fqdn
}

terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
         }
  }
  required_version = ">=0.13"
}
provider "yandex" {
  token     = var.token
  cloud_id  = var.cloud_id
  folder_id = var.folder_id
  }




# Создаем VPC

resource "yandex_vpc_network" "net" {
name = "net"
}

# Подсеть
resource "yandex_vpc_subnet" "subnet-a" {
  name           = "subnet-a"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}

resource "yandex_vpc_subnet" "subnet-b" {
  name           = "subnet-b"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["192.168.20.0/24"]
}

resource "yandex_vpc_subnet" "subnet-d" {
  name           = "subnet-d"
  zone           = "ru-central1-d"
  network_id     = yandex_vpc_network.net.id
  v4_cidr_blocks = ["192.168.30.0/24"]
}



# Virtual machines
## Kubernetes master
resource "yandex_compute_instance" "master" {
  name = "master"
  hostname = "master"
  zone      = "ru-central1-a"
  platform_id = "standard-v1"
  resources {
    cores  = 4
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = "fd8di2mid9ojikcm93en"
      size = "30"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-a.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

## Kubernetes worker-1
resource "yandex_compute_instance" "worker-1" {
  name = "worker-1"
  hostname = "worker-1"
  zone      = "ru-central1-a"
  platform_id = "standard-v1"
  resources {
    cores  = 4
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = "fd8di2mid9ojikcm93en"
      size = "30"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-a.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

## Kubernetes worker-2
resource "yandex_compute_instance" "worker-2" {
  name = "worker-2"
  hostname = "worker-2"
  zone      = "ru-central1-b"
  platform_id = "standard-v1"
  resources {
    cores  = 4
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = "fd8di2mid9ojikcm93en"
      size = "30"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-b.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

## Kubernetes worker-3
resource "yandex_compute_instance" "worker-3" {
  name = "worker-3"
  hostname = "worker-3"
  zone      = "ru-central1-d"
  platform_id = "standard-v3"
  resources {
    cores  = 4
    memory = 4
  }
  boot_disk {
    initialize_params {
      image_id = "fd8di2mid9ojikcm93en"
      size = "30"
    }
  }
  network_interface {
    subnet_id = yandex_vpc_subnet.subnet-d.id
    nat       = true
  }
  metadata = {
    ssh-keys = "ubuntu:${file("~/.ssh/id_rsa.pub")}"
  }
}

# Ansible inventory for Kuberspray
resource "local_file" "inventory-kubespray" {
  content = <<EOF2
all:
  hosts:
    ${yandex_compute_instance.master.fqdn}:
      ansible_host: ${yandex_compute_instance.master.network_interface.0.ip_address}
      ip: ${yandex_compute_instance.master.network_interface.0.ip_address}
      access_ip: ${yandex_compute_instance.master.network_interface.0.ip_address}
    ${yandex_compute_instance.worker-1.fqdn}:
      ansible_host: ${yandex_compute_instance.worker-1.network_interface.0.ip_address}
      ip: ${yandex_compute_instance.worker-1.network_interface.0.ip_address}
      access_ip: ${yandex_compute_instance.worker-1.network_interface.0.ip_address}
    ${yandex_compute_instance.worker-2.fqdn}:
      ansible_host: ${yandex_compute_instance.worker-2.network_interface.0.ip_address}
      ip: ${yandex_compute_instance.worker-2.network_interface.0.ip_address}
      access_ip: ${yandex_compute_instance.worker-2.network_interface.0.ip_address}
    ${yandex_compute_instance.worker-3.fqdn}:
      ansible_host: ${yandex_compute_instance.worker-3.network_interface.0.ip_address}
      ip: ${yandex_compute_instance.worker-3.network_interface.0.ip_address}
      access_ip: ${yandex_compute_instance.worker-3.network_interface.0.ip_address}
  children:
    kube_control_plane:
      hosts:
        ${yandex_compute_instance.master.fqdn}:
    kube_node:
      hosts:
        ${yandex_compute_instance.worker-1.fqdn}:
        ${yandex_compute_instance.worker-2.fqdn}:
        ${yandex_compute_instance.worker-3.fqdn}:
    etcd:
      hosts:
        ${yandex_compute_instance.master.fqdn}:
    k8s_cluster:
      children:
        kube_control_plane:
        kube_node:
    calico_rr:
      hosts: {}
  EOF2
  filename = "../ansible/inventory-kubespray"
  depends_on = [yandex_compute_instance.master, yandex_compute_instance.worker-1, yandex_compute_instance.worker-2, yandex_compute_instance.worker-3]
}

# Ansible inventory for preparation
resource "local_file" "inventory-preparation" {
  content = <<EOF1
[kube-cloud]
${yandex_compute_instance.master.network_interface.0.nat_ip_address}
${yandex_compute_instance.worker-1.network_interface.0.nat_ip_address}
${yandex_compute_instance.worker-2.network_interface.0.nat_ip_address}
${yandex_compute_instance.worker-3.network_interface.0.nat_ip_address}
  EOF1
  filename = "../ansible/inventory-preparation"
  depends_on = [yandex_compute_instance.master, yandex_compute_instance.worker-1, yandex_compute_instance.worker-2, yandex_compute_instance.worker-3]
}


















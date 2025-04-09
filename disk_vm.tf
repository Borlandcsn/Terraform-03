variable "vm_settings_disk" {
  type = object({
    name = string
    size = number
    type = string
  })
  default = {
    name = "vm-disk"
    size = 1
    type = "network-hdd"
  }
}

variable "vm_settings_storage" {
  type = object({
    platform_id   = string,
    core_count    = number,
    core_fraction = number,
    memory_count  = number,
    hdd_type      = string,
    hdd_size      = number,
    preemptible   = bool
    name          = string
  })
  default = {
    core_count    = 2,
    core_fraction = 20,
    memory_count  = 2,
    hdd_size      = 10,
    hdd_type      = "network-hdd",
    platform_id   = "standard-v3",
    preemptible   = true,
    name          = "storage"
  }
}

resource "yandex_compute_disk" "v_disk" {
  count = 3

  name = "${var.vm_settings_disk.name}-${count.index + 1}"
  type = var.vm_settings_disk.type
  size = var.vm_settings_disk.size
  zone = var.default_zone
}

resource "yandex_compute_instance" "storage" {
  name        = var.vm_settings_storage.name
  hostname    = var.vm_settings_storage.name
  platform_id = var.vm_settings_storage.platform_id

  resources {
    core_fraction = var.vm_settings_storage.core_fraction
    cores         = var.vm_settings_storage.core_count
    memory        = var.vm_settings_storage.memory_count
  }

  scheduling_policy {
    preemptible = var.vm_settings_storage.preemptible
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      type     = var.vm_settings_storage.hdd_type
      size     = var.vm_settings_storage.hdd_size
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop.id
    security_group_ids = toset([yandex_vpc_security_group.example.id])
    nat = true
  }

  dynamic "secondary_disk" {
    for_each = toset(yandex_compute_disk.v_disk.*.id)
    content {
      disk_id = secondary_disk.key
    }
  }

  metadata = local.metadata
}

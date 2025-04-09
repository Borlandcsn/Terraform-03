variable "each_vm" {
  type = list(object({ vm_name = string, cpu = number, ram = number, disk_volume = number, disk_type = string, core_fraction = number, platform_id = string, preemptible = bool }))
  default = [{
    core_fraction = 20
    cpu           = 4
    disk_volume   = 15
    disk_type     = "network-hdd"
    platform_id   = "standard-v3"
    ram           = 4
    vm_name       = "main"
    preemptible   = true
  },
  {
    core_fraction = 20
    cpu           = 2
    disk_volume   = 10
    disk_type     = "network-hdd"
    platform_id   = "standard-v3"
    ram           = 2
    vm_name       = "replica"
    preemptible   = true
  }]
}

resource "yandex_compute_instance" "db" {
  for_each = {
    for index, vm in var.each_vm :
    vm.vm_name => vm
  }

  name        = each.value.vm_name
  hostname    = each.value.vm_name
  platform_id = each.value.platform_id

  resources {
    cores         = each.value.cpu
    memory        = each.value.ram
    core_fraction = each.value.core_fraction
  }

  boot_disk {
    initialize_params {
      image_id = data.yandex_compute_image.ubuntu.image_id
      type     = each.value.disk_type
      size     = each.value.disk_volume
    }
  }

  metadata = local.metadata

  scheduling_policy {
    preemptible = each.value.preemptible
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.develop.id
    nat                = true
    security_group_ids = toset([yandex_vpc_security_group.example.id])
  }

}

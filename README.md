Задание 1

1 Изучите проект.

2 Инициализируйте проект, выполните код. Чтобы проект смог инициализироваться пришлось поправить файл провайдера  и немного файл провайдера для безовасного хранения токена  инициализируем и запускаем проект.

![Screenshot_1](https://github.com/user-attachments/assets/f09d4094-8188-4e9c-81d1-746be6da633c)

![Pasted image 20250211221456](https://github.com/user-attachments/assets/65e06ee7-fa30-4d22-aa0c-43115bee96c9)

Задание 2

Создайте файл count-vm.tf. Опишите в нём создание двух одинаковых ВМ web-1 и web-2 (не web-0 и web-1) с минимальными параметрами, используя мета-аргумент count loop. Назначьте ВМ созданную в первом задании группу 

безопасности.(как это сделать узнайте в документации провайдера yandex/compute_instance ) Листинг файла count-vm.tf

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

Создайте файл for_each-vm.tf. Опишите в нём создание двух ВМ для баз данных с именами "main" и "replica" разных по cpu/ram/disk_volume , используя мета-аргумент for_each loop. Используйте для обеих ВМ одну общую 

переменную типа:

variable "each_vm" {

  type = list(object({  vm_name=string, cpu=number, ram=number, disk_volume=number }))
  
}

Листинг файла for_each-vm.tf

variable "web_settings" {

  type = object({
  
    platform_id   = string,
    
    core_count    = number,
    
    core_fraction = number,
    
    memory_count  = number,
    
    hdd_size      = number,
    
    hdd_type      = string,
    
    preemptible   = bool,
    
    nat           = bool
    
  })
  
  default = {
  
    core_count    = 2,
    
    core_fraction = 20,
    
    memory_count  = 2,
    
    hdd_size      = 10,
    
    hdd_type      = "network-hdd",
    
    platform_id   = "standard-v3",
    
    preemptible   = true,
    
    nat           = true
    
  }
  
}


resource "yandex_compute_instance" "web" {

  count = 2
  
  depends_on = [ yandex_compute_instance.db ]
  

  name        = "web-${count.index + 1}"
  
  hostname    = "web-${count.index + 1}"
  
  platform_id = var.web_settings.platform_id

  resources {
  
    core_fraction = var.web_settings.core_fraction
    
    cores         = var.web_settings.core_count
    
    memory        = var.web_settings.memory_count
    
  }
  
  scheduling_policy {
  
    preemptible = var.web_settings.preemptible
    
  }


  boot_disk {

  
    initialize_params {
    
      image_id = data.yandex_compute_image.ubuntu.image_id
      
      type     = var.web_settings.hdd_type
      
      size     = var.web_settings.hdd_size
      
    }
    
  }

  network_interface {
  
    subnet_id          = yandex_vpc_subnet.develop.id
    
    security_group_ids = toset([yandex_vpc_security_group.example.id]) #прикручиваем политику
    
    nat                = var.web_settings.nat
    
  }

  metadata = local.metadata
  
}

При желании внесите в переменную все возможные параметры.

1. ВМ из пункта 2.1 должны создаваться после создания ВМ из пункта 2.2.

2. Используйте функцию file в local-переменной для считывания ключа ~/.ssh/id_rsa.pub и его последующего использования в блоке metadata, взятому из ДЗ 2.


variable "cloud_id" {

  type        = string
  
  default = "b1gl1mia19itahjudhdr"
  
  description = "https://cloud.yandex.ru/docs/resource-manager/operations/cloud/get-id"
  
}


variable "folder_id" {

  type        = string
  
  default = "b1gb7eigrg8f1c85cu89"
  
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

![Screenshot_1](https://github.com/user-attachments/assets/3e689ec1-d259-496f-b4e0-a2db6087efa4)

![Screenshot_2](https://github.com/user-attachments/assets/f1fcf91b-57f0-48c2-adb9-4fca8d4d5502)

![Screenshot_3](https://github.com/user-attachments/assets/b1d5a450-2254-4a73-a4fe-109dbbe26abd)


![Screenshot_4](https://github.com/user-attachments/assets/0cbc6e7f-5d57-4df2-80db-0b10f98b3a76)

Задание 3

Создайте 3 одинаковых виртуальных диска размером 1 Гб с помощью ресурса yandex_compute_disk и мета-аргумента count в файле disk_vm.tf .

Создайте в том же файле одиночную(использовать count или for_each запрещено из-за задания №4) ВМ c именем "storage" . Используйте блок dynamic secondary_disk{..} и мета-аргумент for_each для подключения созданных вами 

дополнительных дисков. Листинг файла disk_vm.tf

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

![Screenshot_1](https://github.com/user-attachments/assets/49d94985-6d60-47d3-8447-d75646556b7b)

![Screenshot_5](https://github.com/user-attachments/assets/989180b0-c69f-4bbc-b253-61c25e10902c)

Задание 4

В файле ansible.tf создайте inventory-файл для ansible. Используйте функцию tepmplatefile и файл-шаблон для создания ansible inventory-файла из лекции. Готовый код возьмите из демонстрации к лекции demonstration2.
Передайте в него в качестве переменных группы виртуальных машин из задания 2.1, 2.2 и 3.2, т. е. 5 ВМ.

Инвентарь должен содержать 3 группы и быть динамическим, т. е. обработать как группу из 2-х ВМ, так и 999 ВМ.

Добавьте в инвентарь переменную fqdn.

[webservers]

web-1 ansible_host=<внешний ip-адрес> fqdn=<полное доменное имя виртуальной машины>

web-2 ansible_host=<внешний ip-адрес> fqdn=<полное доменное имя виртуальной машины>


[databases]

main ansible_host=<внешний ip-адрес> fqdn=<полное доменное имя виртуальной машины>

replica ansible_host<внешний ip-адрес> fqdn=<полное доменное имя виртуальной машины>


[storage]

storage ansible_host=<внешний ip-адрес> fqdn=<полное доменное имя виртуальной машины>


Пример fqdn: web1.ru-central1.internal(в случае указания переменной hostname(не путать с переменной name)); fhm8k1oojmm5lie8i22a.auto.internal(в случае отсутвия перменной hostname - автоматическая генерация имени, зона 

изменяется на auto). нужную вам переменную найдите в документации провайдера или terraform console.

resource "local_file" "hosts_templatefile"{

 
    content = templatefile("${path.module}/hosts.tftpl",
    
    { webservers = yandex_compute_instance.web
    
      databases = yandex_compute_instance.db
      
      storage = [yandex_compute_instance.storage]
      
    })

   filename = "${abspath(path.module)}/hosts.cfg"
   
}

4 Выполните код. Приложите скриншот получившегося файла. 

![Screenshot_23](https://github.com/user-attachments/assets/4b0e34a6-a6f9-4380-a879-900877c1a7b3)

![Screenshot_2](https://github.com/user-attachments/assets/fcbf6f66-7bac-4d4d-92b1-bfb50d3e98ee)

Для общего зачёта создайте в вашем GitHub-репозитории новую ветку terraform-03. Закоммитьте в эту ветку свой финальный код проекта, пришлите ссылку на коммит.

Удалите все созданные ресурсы.



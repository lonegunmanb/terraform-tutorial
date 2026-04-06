# 这段代码从网上复制而来，直接使用了 Yandex Cloud Provider
# 但缺少必要的 terraform 块和 required_providers 声明
#
# 请先运行 terraform init 观察会发生什么

provider "yandex" {
  token     = "test"
  cloud_id  = "test"
  folder_id = "test"
  zone      = "ru-central1-a"
}

resource "yandex_compute_instance" "web" {
  name        = "web-server"
  platform_id = "standard-v1"

  resources {
    cores  = 2
    memory = 2
  }

  boot_disk {
    initialize_params {
      image_id = "fd80mrhj8fl2oe87o4e1"
    }
  }

  network_interface {
    subnet_id = "e9b3sl5gol2i3a2elc7t"
  }
}

variable "vm_name" {
  type = string
  default = "ubuntu2204-base"
}

variable "generation" {
  type = string
  default = "2"
}

variable "cpus" {
  type = number
  default = 1
}

variable "memory" {
  type = number
  default = 1024
}

variable "boot_wait" {
  type = string
  default = "1s"
}

variable "shutdown_timeout" {
  type = string
  default = "50m"
}

variable "iso_name" {
  type = string
  default = "ubuntu-22.04.1-live-server-amd64.iso"
}

variable "iso_remote_url" {
  type = string
  default = ""
}

variable "iso_checksum" {
  type = string
  default = ""
}

variable "output_directory" {
  type = string
  default = ""
}

variable "crypted_password" {
  type = string
  default = "$6$rounds=4096$UJSYfXMplc$Z0N/YThWrolFTIREcCCRvVhOigf1YVaH76Io7INhGZwoK9eyBEjkqMS4p4CdSm.iK6SnhhKaQHpn.wJcHuAQt/"
}

variable "ssh_username" {
  type = string
  default = "ubuntu"
}

variable "ssh_password" {
  type = string
  default = "ubuntu"
  sensitive = true
}

variable "ssh_timeout" {
  type = string
  default = "20m"
}

variable "ssh_handshake_attempts" {
  type = number
  default = 20
}

variable "no_proxy" {
  type = string
  default = ""
}

variable "locale" {
  type = string
  default = "en_US.UTF-8"
}

variable "keyboard_layout" {
  type = string
  default = "en"
}

variable "keyboard_variant" {
  type = string
  default = "us"
}

locals {
  iso_checksum = "sha256:10f19c5b2b8d6db711582e0e27f5116296c34fe4b313ba45f9b201a5007056cb"
  iso_remote_url = "https://releases.ubuntu.com/22.04/${var.iso_name}"
  output_directory = "${path.root}/output/${var.vm_name}"
}

source "hyperv-iso" "vm" {
  vm_name = "${var.vm_name}"
  generation = "${var.generation}"
  enable_secure_boot = false
  guest_additions_mode = "enable"
  cpus = "${var.cpus}"
  memory = "${var.memory}"

  iso_checksum = "${local.iso_checksum}"
  iso_urls = [
    "${path.root}/iso/${var.iso_name}",
    "${local.iso_remote_url}"
  ]

  http_content = {
    "/user-data" = templatefile("./templates/ubuntu2204/user-data.pkrtpl.hcl", {
      username = var.ssh_username
      password = var.crypted_password
      hostname = var.vm_name
      locale = var.locale
      keyboard_layout = var.keyboard_layout
      keyboard_variant = var.keyboard_variant
    })
    "/meta-data" = ""
  }

  output_directory = "${local.output_directory}"

  boot_wait = "${var.boot_wait}"
  boot_command = [
    "<esc><esc><wait1>",
    "c<wait1>",
    "set gfxpayload=keep", "<enter><wait>",
    "linux /casper/vmlinuz<wait>",
    " autoinstall<wait>", " \"ds=nocloud-net<wait>", ";s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/\"<wait>",
    " ---", "<enter><wait>",
    "initrd /casper/initrd", "<enter><wait>",
    "boot", "<enter><wait>"
  ]

  communicator = "ssh"
  ssh_username = "${var.ssh_username}"
  ssh_password = "${var.ssh_password}"
  ssh_pty = true
  ssh_timeout = "${var.ssh_timeout}"
  ssh_handshake_attempts = "${var.ssh_handshake_attempts}"

  shutdown_timeout = "${var.shutdown_timeout}"
  shutdown_command = "echo ${var.ssh_username} | sudo -S -E shutdown -P now"
}

build {
  sources = ["source.hyperv-iso.vm"]

  provisioner "shell" {
    inline = [
      "ls /",
      "env",
    ]
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive"]
    scripts = ["${path.root}/scripts/ubuntu-2204/hotfix.sh"]
    execute_command = "sudo -S -E sh -c '{{ .Vars }} {{ .Path }}'"
  }

  provisioner "shell" {
    environment_vars = ["DEBIAN_FRONTEND=noninteractive", "SSH_USERNAME=${var.ssh_username}", "SSH_PASSWORD=${var.ssh_password}", "no_proxy=${var.no_proxy}"]
    execute_command = "sudo -S -E sh -c '{{ .Vars }} {{ .Path }}'"
    scripts = ["${path.root}/scripts/ubuntu-base/minimize.sh"]
  }

  provisioner "shell" {
    pause_before = "5s"
    environment_vars = [ "DEBIAN_FRONTEND=noninteractive" ]
    execute_command = "sudo -S -E sh -c '{{ .Vars }} {{ .Path }}'"
    script = "${path.root}/scripts/ubuntu-base/cleanup.sh" # cleanup should be in last
  }
}

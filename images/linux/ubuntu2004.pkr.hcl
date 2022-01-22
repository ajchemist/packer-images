variable "vm_name" {
  type = string
  default = "ubuntu2004-zeroboot"
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
  default = "2s"
}

variable "shutdown_timeout" {
  type = string
  default = "50m"
}

variable "iso_name" {
  type = string
  default = "ubuntu-20.04.3-live-server-amd64.iso"
}

variable "iso_remote_url" {
  type = string
  default = ""
}

variable "iso_checksum" {
  type = string
  default = ""
}

variable "http_directory" {
  type = string
  default = ""
}

variable "output_directory" {
  type = string
  default = ""
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

locals {
  iso_checksum = "sha256:f8e3086f3cea0fb3fefb29937ab5ed9d19e767079633960ccb50e76153effc98"
  iso_remote_url = "https://releases.ubuntu.com/20.04/${var.iso_name}"
  http_directory = "${path.root}/http"
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

  http_directory = "${local.http_directory}/hyperv"
  output_directory = "${local.output_directory}"

  boot_wait = "${var.boot_wait}"
  boot_command = [
    "<esc><esc><wait1>",
    "set gfxpayload=keep", "<enter><wait>",
    "linux /casper/vmlinuz quiet<wait>",
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
      "env"
    ]
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "SSH_USERNAME=${var.ssh_username}",
      "SSH_PASSWORD=${var.ssh_password}",
      "no_proxy=${var.no_proxy}"
    ]
    scripts = [
      "${path.root}/scripts/ubuntu-base/minimize.sh",
      "${path.root}/scripts/ubuntu-base/cleanup.sh" # cleanup should be in last
    ]
    execute_command = "sudo -S -E sh -c '{{ .Vars }} {{ .Path }}'"
  }
}

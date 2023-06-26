packer {
  required_plugins {
    docker = {
      version = ">= 1.0.0"
      source  = "github.com/hashicorp/docker"
    }
  }
}

variable distro {
  type = string
}

variable distro_version {
  type = string
}

variable distro_platform {
  type    = string
  default = "linux/amd64"
}

variable distro_kernel {
  type = string
}

variable output_dir {
  type    = string
  default = "."
}

variable artifacts_dir {
  type    = string
  default = "."
}

locals {
  distro_docker_image = "${var.distro}:${var.distro_version}"
}

# This Source will only be used to create a Filesystem from the Docker Container
source "docker" "filesystem-container" {
  image       = "${local.distro_docker_image}"
  pull        = false # save bandwidth and avoid multiple pulls to same image
  platform    = "${var.distro_platform}"
  export_path = "${var.output_dir}/${var.distro}.tar"
}

# This source will be use to create a Bootable Disk Image from the Generated Filesystem
source "docker" "partition-container" {
  image      = "debian:bullseye"
  pull       = false
  platform   = "${var.distro_platform}"
  discard    = true
  cap_add    = ["SYS_ADMIN"]
  privileged = true
  volumes = {
    "${path.cwd}" : "/os",
    "${var.output_dir}" : "/output",
    "${var.artifacts_dir}" : "/artifacts"
  }
}

build {
  # Install the Respective Kernel and rc
  name    = "gen-fs-tarball"
  sources = ["source.docker.filesystem-container"]
  provisioner "shell" {
    inline = [
      "apk update",
      "apk add ${var.distro_kernel}",
      "apk add openrc",
      "echo \"root:root\" | chpasswd"
    ]
  }
}

build {
  # generate a bootable disk image
  name    = "gen-boot-img"
  sources = ["source.docker.partition-container"]
  provisioner "shell" {
    environment_vars = [
      "DISTR=${var.distro}"
    ]
    scripts = [
      "./scripts/create-image.sh"
    ]
  }
}

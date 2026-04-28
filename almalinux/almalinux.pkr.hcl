packer {
  required_plugins {
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

source "vagrant" "almalinux" {
  communicator = "ssh"
  source_path  = "bento/almalinux-9"
  provider     = "virtualbox"
  add_force    = true
  output_dir   = "builds"
}

build {
  sources = ["source.vagrant.almalinux"]

  provisioner "shell" {
    execute_command = "sudo bash '{{.Path}}'"
    script          = "provision-base.sh"
  }
}

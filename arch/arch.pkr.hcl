packer {
  required_plugins {
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

source "vagrant" "arch" {
  communicator = "ssh"
  source_path  = "generic/arch"
  provider     = "virtualbox"
  add_force    = true
  output_dir   = "builds"
}

build {
  sources = ["source.vagrant.arch"]

  provisioner "shell" {
    execute_command = "sudo bash '{{.Path}}'"
    script          = "provision-base.sh"
  }
}

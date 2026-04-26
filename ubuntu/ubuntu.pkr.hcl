packer {
  required_plugins {
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

source "vagrant" "ubuntu" {
  communicator = "ssh"
  source_path  = "bento/ubuntu-24.04"
  provider     = "virtualbox"
  add_force    = true
  output_dir   = "builds"
}

build {
  sources = ["source.vagrant.ubuntu"]

  provisioner "shell" {
    execute_command = "sudo bash '{{.Path}}'"
    script          = "provision-base.sh"
  }
}

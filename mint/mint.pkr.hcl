packer {
  required_plugins {
    vagrant = {
      source  = "github.com/hashicorp/vagrant"
      version = "~> 1"
    }
  }
}

source "vagrant" "mint" {
  communicator = "ssh"
  source_path  = "CJJR/LinuxMint21"
  provider     = "virtualbox"
  add_force    = true
  output_dir   = "builds"
}

build {
  sources = ["source.vagrant.mint"]

  provisioner "shell" {
    execute_command = "sudo bash '{{.Path}}'"
    script          = "provision-base.sh"
  }
}

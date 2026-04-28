#!/usr/bin/env bash
# ============================================================
#  provision-base.sh — system packages (AlmaLinux 9 headless)
#  Run by Packer to pre-bake the base image.
#  Also run by Vagrant on a fresh upstream box (no Packer build).
# ============================================================
set -euo pipefail

log() { echo ""; echo "====> $*"; echo ""; }

log "Installing EPEL..."
dnf install -y -q epel-release

log "Installing DKMS and kernel headers..."
dnf install -y -q dkms kernel-devel kernel-headers elfutils-libelf-devel bzip2 perl

log "Rebuilding VirtualBox Guest Additions with DKMS..."
VBOX_VER=$(modinfo vboxguest 2>/dev/null | awk '/^version/{print $2}')
if [ -n "$VBOX_VER" ]; then
  curl -fsSL "https://download.virtualbox.org/virtualbox/${VBOX_VER}/VBoxGuestAdditions_${VBOX_VER}.iso" \
    -o /tmp/VBoxGA.iso
  mkdir -p /tmp/vbox
  mount -o loop /tmp/VBoxGA.iso /tmp/vbox
  sh /tmp/vbox/VBoxLinuxAdditions.run --nox11 2>&1 | tail -5 || true
  umount /tmp/vbox 2>/dev/null || true
  rm -rf /tmp/VBoxGA.iso /tmp/vbox
fi

log "Updating system (DKMS will rebuild vboxsf for the new kernel automatically)..."
dnf update -y -q

log "Installing base packages..."
dnf install -y -q \
  curl wget git unzip zip gnupg2 ca-certificates \
  tmux zsh \
  gcc gcc-c++ make pkgconf-pkg-config openssl-devel \
  python3 python3-pip \
  tree vim neovim jq

log "Installing gh CLI..."
curl -fsSL https://cli.github.com/packages/rpm/gh-cli.repo \
  -o /etc/yum.repos.d/gh-cli.repo
dnf install -y -q gh

log "Installing Docker..."
dnf install -y -q dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
dnf install -y -q docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

log "Installing Go..."
GO_VERSION="1.22.3"
curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
  | tar -C /usr/local -xz
echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh

log "Setting SELinux to permissive..."
setenforce 0 2>/dev/null || true
sed -i 's/^SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config

log "Disabling firewalld..."
systemctl disable --now firewalld 2>/dev/null || true

log "Base provisioning complete."

#!/usr/bin/env bash
# ============================================================
#  provision-base.sh — system packages
#  Run by Packer to pre-bake the base image.
#  Also run by Vagrant on a fresh upstream box (no Packer build).
#  No user-specific setup here — that lives in provision.sh.
# ============================================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

log() { echo ""; echo "====> $*"; echo ""; }

log "Updating system..."
apt-get update -qq
apt-get upgrade -y -qq
apt-get install -y -qq \
  curl wget git unzip gnupg ca-certificates \
  lsb-release apt-transport-https software-properties-common \
  tmux zsh fonts-powerline \
  build-essential pkg-config libssl-dev

log "Installing GNOME desktop (this takes a few minutes)..."
apt-get install -y -qq ubuntu-desktop-minimal

log "Installing gh CLI..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | gpg --dearmor -o /usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
  https://cli.github.com/packages stable main" \
  > /etc/apt/sources.list.d/github-cli.list
apt-get update -qq && apt-get install -y -qq gh

log "Installing Docker..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
  | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/etc/apt/keyrings/docker.gpg] \
  https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" \
  > /etc/apt/sources.list.d/docker.list
apt-get update -qq
apt-get install -y -qq docker-ce docker-ce-cli containerd.io \
  docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

log "Installing Google Chrome..."
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
  | gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] \
  https://dl.google.com/linux/chrome/deb/ stable main" \
  > /etc/apt/sources.list.d/google-chrome.list
apt-get update -qq && apt-get install -y -qq google-chrome-stable

log "Installing VS Code..."
curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
  | gpg --dearmor -o /usr/share/keyrings/microsoft.gpg
echo "deb [arch=$(dpkg --print-architecture) \
  signed-by=/usr/share/keyrings/microsoft.gpg] \
  https://packages.microsoft.com/repos/code stable main" \
  > /etc/apt/sources.list.d/vscode.list
apt-get update -qq && apt-get install -y -qq code

log "Installing Go..."
GO_VERSION="1.22.3"
curl -fsSL "https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz" \
  | tar -C /usr/local -xz
echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh

systemctl mask systemd-networkd-wait-online.service

log "Base provisioning complete."

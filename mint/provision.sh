#!/usr/bin/env bash
# ============================================================
#  provision.sh — user setup for Linux Mint 21 (runs on every fresh vagrant up)
#  Assumes system packages are already present — either pre-baked
#  by Packer or installed by the "system" provisioner beforehand.
# ============================================================
set -euo pipefail
export DEBIAN_FRONTEND=noninteractive
DEV_USER="${DEV_USER:-dev}"
DEV_HOME="/home/${DEV_USER}"
DEV_TZ="${DEV_TZ:-America/Bogota}"

log() { echo ""; echo "====> $*"; echo ""; }

log "Setting timezone to ${DEV_TZ}..."
timedatectl set-timezone "${DEV_TZ}"

log "Creating user ${DEV_USER}..."
useradd -m -s /usr/bin/zsh -G sudo,adm "${DEV_USER}"
echo "${DEV_USER}:${DEV_PASSWORD}" | chpasswd
usermod -aG vagrant,docker "${DEV_USER}" 2>/dev/null || true

log "Installing oh-my-zsh..."
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
  -o /tmp/install-omz.sh
su - "${DEV_USER}" -c "sh /tmp/install-omz.sh --unattended"
rm -f /tmp/install-omz.sh
chsh -s /usr/bin/zsh "${DEV_USER}"

log "Installing nvm + Node.js LTS..."
NVM_VERSION="v0.40.1"
su - "${DEV_USER}" -c "
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
  . ~/.nvm/nvm.sh
  nvm install --lts
  nvm alias default node
"

log "Installing Rust..."
su - "${DEV_USER}" -c \
  "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path"

# Auto-login via LightDM (Mint's default display manager)
mkdir -p /etc/lightdm/lightdm.conf.d
cat > /etc/lightdm/lightdm.conf.d/50-autologin.conf << EOF
[Seat:*]
autologin-user=${DEV_USER}
autologin-user-timeout=0
EOF
systemctl set-default graphical.target

log "User provisioning complete."

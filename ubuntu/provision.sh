#!/usr/bin/env bash
# ============================================================
#  provision.sh — user setup (runs on every fresh vagrant up)
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
sudo -u "${DEV_USER}" sh -c \
  "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
  -- --unattended
chsh -s /usr/bin/zsh "${DEV_USER}"

log "Installing nvm + Node.js LTS..."
NVM_VERSION="v0.40.1"
sudo -u "${DEV_USER}" bash -c "
  export HOME=${DEV_HOME}
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
  export NVM_DIR=\"${DEV_HOME}/.nvm\"
  source \"\${NVM_DIR}/nvm.sh\"
  nvm install --lts
  nvm alias default node
"

log "Installing Rust..."
sudo -u "${DEV_USER}" bash -c \
  "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path"

# Auto-login — no password prompt on boot
mkdir -p /etc/gdm3
cat > /etc/gdm3/custom.conf << EOF
[daemon]
AutomaticLoginEnable=true
AutomaticLogin=${DEV_USER}
EOF
systemctl set-default graphical.target

log "User provisioning complete."

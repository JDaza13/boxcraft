#!/usr/bin/env bash
# ============================================================
#  provision.sh — user setup (runs on every fresh vagrant up)
# ============================================================
set -euo pipefail
DEV_USER="${DEV_USER:-dev}"
DEV_HOME="/home/${DEV_USER}"
DEV_TZ="${DEV_TZ:-America/Bogota}"

log() { echo ""; echo "====> $*"; echo ""; }

log "Setting timezone to ${DEV_TZ}..."
timedatectl set-timezone "${DEV_TZ}"

log "Creating user ${DEV_USER}..."
useradd -m -s /bin/zsh -G wheel "${DEV_USER}"
echo "${DEV_USER}:${DEV_PASSWORD}" | chpasswd
usermod -aG vagrant,docker "${DEV_USER}" 2>/dev/null || true

log "Installing oh-my-zsh..."
curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh \
  -o /tmp/install-omz.sh
su - "${DEV_USER}" -c "sh /tmp/install-omz.sh --unattended"
rm -f /tmp/install-omz.sh
chsh -s /bin/zsh "${DEV_USER}"

log "Installing nvm + Node.js LTS..."
NVM_VERSION="v0.40.1"
su - "${DEV_USER}" -c "
  curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_VERSION}/install.sh | bash
  . ~/.nvm/nvm.sh
  nvm install --lts
  nvm alias default node
"
NODE_BIN=$(su - "${DEV_USER}" -c ". ~/.nvm/nvm.sh && which node")
ln -sf "$NODE_BIN"                      /usr/local/bin/node
ln -sf "$(dirname "$NODE_BIN")/npm"     /usr/local/bin/npm
ln -sf "$(dirname "$NODE_BIN")/npx"     /usr/local/bin/npx

log "Installing Rust..."
su - "${DEV_USER}" -c \
  "curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path"
ln -sf "/home/${DEV_USER}/.cargo/bin/cargo"  /usr/local/bin/cargo
ln -sf "/home/${DEV_USER}/.cargo/bin/rustc"  /usr/local/bin/rustc

log "Writing login message..."
cat > /etc/motd << EOF

  AlmaLinux dev box  --  logged in as: vagrant
  Your dev user is: ${DEV_USER}

  Switch with:  su - ${DEV_USER}
  Or SSH directly:  ssh -p 2222 ${DEV_USER}@localhost

EOF

log "User provisioning complete."

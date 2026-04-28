#!/usr/bin/env bash
# ============================================================
#  provision-base.sh — system packages for Arch Linux
#  Run by Packer to pre-bake the base image.
#  Also run by Vagrant on a fresh upstream box (no Packer build).
#  No user-specific setup here — that lives in provision.sh.
# ============================================================
set -euo pipefail

log()     { echo ""; echo "====> $*"; echo ""; }
cleancache() { pacman -Sc --noconfirm; }

log "Refreshing keyring..."
pacman -Sy --noconfirm archlinux-keyring
pacman-key --populate archlinux

log "Updating system..."
pacman -Su --noconfirm
cleancache

log "Installing base packages..."
pacman -S --noconfirm \
  curl wget git unzip zip gnupg ca-certificates \
  tmux zsh powerline-fonts \
  base-devel pkgconf openssl \
  python python-pip \
  tree
cleancache

log "Installing KDE Plasma desktop..."
pacman -S --noconfirm plasma sddm dolphin konsole qt6-tools
systemctl enable sddm
cleancache

log "Installing gh CLI..."
pacman -S --noconfirm github-cli

log "Installing Docker..."
pacman -S --noconfirm docker docker-compose docker-buildx
systemctl enable docker

log "Installing Go..."
pacman -S --noconfirm go
cleancache

log "Installing VirtualBox guest utilities..."
pacman -Rns --noconfirm virtualbox-guest-utils-nox 2>/dev/null || true
pacman -S --noconfirm virtualbox-guest-utils
systemctl enable vboxservice

log "Installing Chrome (AUR)..."
sudo -u vagrant bash -c "
  cd /tmp
  rm -rf google-chrome
  git clone https://aur.archlinux.org/google-chrome.git
  cd google-chrome
  makepkg -si --noconfirm
  cd /tmp
  rm -rf google-chrome
"

log "Installing VS Code (direct from Microsoft)..."
curl -fsSL "https://update.code.visualstudio.com/latest/linux-x64/stable" \
  -o /tmp/vscode.tar.gz
mkdir -p /opt/visual-studio-code
tar -C /opt/visual-studio-code --strip-components=1 -xzf /tmp/vscode.tar.gz
rm -f /tmp/vscode.tar.gz
ln -sf /opt/visual-studio-code/bin/code /usr/local/bin/code
cat > /usr/share/applications/code.desktop << 'EOF'
[Desktop Entry]
Name=Visual Studio Code
Comment=Code Editing. Redefined.
GenericName=Text Editor
Exec=/opt/visual-studio-code/bin/code %F
Icon=code
Type=Application
StartupNotify=false
StartupWMClass=Code
Categories=TextEditor;Development;IDE;
MimeType=text/plain;inode/directory;application/x-code-workspace;
Actions=new-empty-window;

[Desktop Action new-empty-window]
Name=New Empty Window
Exec=/opt/visual-studio-code/bin/code --new-window %F
Icon=code
EOF

systemctl mask systemd-networkd-wait-online.service

log "Base provisioning complete."

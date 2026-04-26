#!/usr/bin/env bash
# ============================================================
#  provision-tune.sh — dotfiles, shell config, GNOME prefs
#
#  Re-run any time without destroying the VM:
#    vagrant provision --provision-with tune
#
#  All sections are idempotent (safe to run repeatedly).
# ============================================================
set -euo pipefail
DEV_USER="${DEV_USER:-dev}"
DEV_HOME="/home/${DEV_USER}"

log() { echo ""; echo "====> $*"; echo ""; }

# ── .zshrc additions ──────────────────────────────────────────
# Uses a marker so re-runs replace the block instead of appending.
log "Writing .zshrc additions..."
ZSHRC="${DEV_HOME}/.zshrc"
touch "$ZSHRC"
sed -i '/^# ── VAGRANT ADDITIONS ──/,$ d' "$ZSHRC" 2>/dev/null || true
cat >> "$ZSHRC" << 'EOF'

# ── VAGRANT ADDITIONS ─────────────────────────────────────────

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ]           && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ]  && \. "$NVM_DIR/bash_completion"

# Go
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Rust
export PATH=$PATH:$HOME/.cargo/bin

# Convenience
alias ws="cd /workspace"
alias ll="ls -lah --color=auto"
alias gs="git status"
alias gp="git pull"
EOF

# ── .tmux.conf ────────────────────────────────────────────────
log "Writing .tmux.conf..."
cat > "${DEV_HOME}/.tmux.conf" << 'EOF'
set -g default-shell /usr/bin/zsh
set -g mouse on
set -g history-limit 20000
set -g base-index 1
set -g pane-base-index 1
set -g renumber-windows on
set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
unbind C-b
set -g prefix C-a
bind C-a send-prefix
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
bind r source-file ~/.tmux.conf \; display "Reloaded!"
EOF

# ── git globals ───────────────────────────────────────────────
log "Setting git globals..."
sudo -u "${DEV_USER}" git config --global init.defaultBranch main
sudo -u "${DEV_USER}" git config --global pull.rebase false
sudo -u "${DEV_USER}" git config --global core.editor "code --wait"

# ── Workspace launcher ────────────────────────────────────────
log "Creating /workspace launcher..."
mkdir -p "${DEV_HOME}/.local/share/applications"
cat > "${DEV_HOME}/.local/share/applications/workspace.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Workspace
Exec=nautilus /workspace
Icon=folder
Terminal=false
EOF

# ── GNOME dock favorites ──────────────────────────────────────
log "Pinning apps to GNOME dock..."
mkdir -p /etc/dconf/profile /etc/dconf/db/local.d
cat > /etc/dconf/profile/user << 'EOF'
user-db:user
system-db:local
EOF
cat > /etc/dconf/db/local.d/00-favorites << 'EOF'
[org/gnome/shell]
favorite-apps=['google-chrome.desktop', 'code.desktop', 'workspace.desktop', 'org.gnome.Terminal.desktop', 'org.gnome.Nautilus.desktop']
EOF
dconf update

# ── Screen resolution 1920x1080 ───────────────────────────────
log "Configuring screen resolution autostart..."
mkdir -p "${DEV_HOME}/.config/autostart"
cat > "${DEV_HOME}/.config/autostart/vboxclient.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=VirtualBox Guest Utilities
Exec=/usr/bin/VBoxClient-all
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

cat > "${DEV_HOME}/.config/autostart/set-resolution.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Set Resolution 1920x1080
Exec=bash -c 'xrandr --output Virtual-1 --mode 1920x1080 2>/dev/null || xrandr --output VGA-1 --mode 1920x1080 2>/dev/null || true'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# ── VS Code — skip GNOME Keyring prompt ───────────────────────
# Auto-login VMs never unlock the keyring, so VS Code prompts every launch.
# "basic" stores secrets in a plain file instead.
log "Configuring VS Code password store..."
mkdir -p "${DEV_HOME}/.vscode"
cat > "${DEV_HOME}/.vscode/argv.json" << 'EOF'
{
    "password-store": "basic"
}
EOF

chown -R "${DEV_USER}:${DEV_USER}" \
  "${DEV_HOME}/.zshrc" \
  "${DEV_HOME}/.tmux.conf" \
  "${DEV_HOME}/.config" \
  "${DEV_HOME}/.vscode" \
  "${DEV_HOME}/.local"

log "Tune provisioning complete."

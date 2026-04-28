#!/usr/bin/env bash
# ============================================================
#  provision-tune.sh — dotfiles, shell config, KDE Plasma prefs
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

# Go (installed via pacman to /usr/bin; only GOPATH/bin needs to be on PATH)
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
su - "${DEV_USER}" -c "
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global core.editor 'code --wait'
"

# ── Workspace launcher ────────────────────────────────────────
log "Creating /workspace launcher..."
mkdir -p "${DEV_HOME}/.local/share/applications"
cat > "${DEV_HOME}/.local/share/applications/workspace.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Workspace
Exec=dolphin /workspace
Icon=folder
Terminal=false
EOF

# ── KDE Plasma taskbar favorites ──────────────────────────────
# Static plasma config IDs vary per install, so we use a one-shot autostart
# that runs plasmashell's scripting API at login to find and configure the
# task manager widget by type rather than by hardcoded ID.
log "Setting up KDE taskbar autostart..."
cat > /usr/local/bin/boxcraft-kde-setup << 'SCRIPT'
#!/usr/bin/env bash
sleep 8
JS='
var launchers = "preferred://browser,applications:code.desktop,applications:workspace.desktop,applications:org.kde.konsole.desktop,applications:org.kde.dolphin.desktop";
var allPanels = panels();
for (var i = 0; i < allPanels.length; i++) {
    var widgets = allPanels[i].widgets();
    for (var j = 0; j < widgets.length; j++) {
        if (widgets[j].type === "org.kde.plasma.icontasks") {
            widgets[j].currentConfigGroup = ["General"];
            widgets[j].writeConfig("launchers", launchers);
            widgets[j].reloadConfig();
        }
    }
}
'
(qdbus6 org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$JS" || \
 qdbus  org.kde.plasmashell /PlasmaShell org.kde.PlasmaShell.evaluateScript "$JS") 2>/dev/null || true
rm -f "${HOME}/.config/autostart/boxcraft-kde-setup.desktop"
SCRIPT
chmod +x /usr/local/bin/boxcraft-kde-setup

mkdir -p "${DEV_HOME}/.config/autostart"
cat > "${DEV_HOME}/.config/autostart/boxcraft-kde-setup.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Boxcraft KDE Setup
Exec=/usr/local/bin/boxcraft-kde-setup
Hidden=false
Terminal=false
X-KDE-autostart-enabled=true
EOF

# ── Screen resolution ─────────────────────────────────────────
# vboxservice (enabled in provision-base.sh) starts the guest display driver.
# xrandr --auto picks the best available mode once the driver is up.
log "Configuring screen resolution autostart..."
cat > "${DEV_HOME}/.config/autostart/set-resolution.desktop" << 'EOF'
[Desktop Entry]
Type=Application
Name=Set Resolution
Exec=bash -c 'sleep 3 && xrandr --auto'
Hidden=false
NoDisplay=false
X-KDE-autostart-enabled=true
EOF

# ── VS Code — skip keyring prompt ────────────────────────────
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

#!/usr/bin/env bash
# ============================================================
#  provision-tune.sh — dotfiles and shell config
#
#  Re-run any time without destroying the VM:
#    vagrant provision --provision-with tune
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
set -g default-shell /bin/zsh
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

# ── .vimrc ────────────────────────────────────────────────────
log "Writing .vimrc..."
cat > "${DEV_HOME}/.vimrc" << 'EOF'
syntax on
set number
set tabstop=4
set shiftwidth=4
set expandtab
set autoindent
set hlsearch
set incsearch
set ruler
set wildmenu
EOF

# ── git globals ───────────────────────────────────────────────
log "Setting git globals..."
su - "${DEV_USER}" -c "
  git config --global init.defaultBranch main
  git config --global pull.rebase false
  git config --global core.editor vim
"

chown -R "${DEV_USER}:${DEV_USER}" \
  "${DEV_HOME}/.zshrc" \
  "${DEV_HOME}/.tmux.conf" \
  "${DEV_HOME}/.vimrc"

log "Tune provisioning complete."

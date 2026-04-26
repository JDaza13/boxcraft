# boxcraft

Reproducible dev workstation VMs built on VirtualBox + Vagrant + Packer.
Each profile is fully self-contained — pick one, `cd` into it, and `vagrant up`.

## Profiles

| Profile | Distro | Desktop | Box |
|---------|--------|---------|-----|
| [`ubuntu/`](ubuntu/) | Ubuntu 24.04 LTS | GNOME | `bento/ubuntu-24.04` |
| [`mint/`](mint/) | Linux Mint 21 | Cinnamon | `CJJR/LinuxMint21` |

All profiles ship the same dev stack: git, gh CLI, Docker, nvm/Node LTS,
Go, Rust, VS Code, tmux, zsh + oh-my-zsh.

## Quick start

```powershell
# Step 0 — allow scripts (required on a fresh Windows machine, once)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Step 1 — install VirtualBox, Vagrant, Packer, Git if missing
.\setup.ps1
# !! Restart your terminal after this so the new tools are on PATH !!

# Step 2 (optional but recommended) — pre-bake the base image (~20 min, once)
#   Skipping this means `vagrant up` takes ~15 min on every fresh destroy.
.\build.ps1 ubuntu

# Step 3 — set your workspace folder (skip if V:\SharedFolder already exists)
$env:WORKSPACE = "C:\Users\$env:USERNAME\projects"   # or any folder you like

# Step 4 — boot the VM
cd ubuntu
vagrant up           # ~2 min with baked image, ~15 min without
```

`build.ps1` is optional but recommended — it pre-installs all system packages
into a reusable box so `vagrant up` after a `vagrant destroy` takes ~2 min
instead of ~15 min.

## Prerequisites

On Windows, run the bootstrap script — it checks for and installs anything missing via `winget`:

```powershell
.\setup.ps1
```

Or install manually:

| Tool | Install |
|------|---------|
| VirtualBox | https://virtualbox.org/wiki/Downloads |
| Vagrant | https://developer.hashicorp.com/vagrant/downloads |
| Git (for Git Bash) | https://git-scm.com/downloads |

## Usage

```bash
cd ubuntu        # or: cd mint
vagrant up       # First boot — prompts for username/password, ~15 min
vagrant reload   # Reboot VM
vagrant ssh      # Terminal access (vagrant user)
vagrant halt     # Graceful shutdown
vagrant destroy -f                          # Wipe the VM entirely
vagrant provision --provision-with tune     # Re-apply dotfiles/config without rebuilding
```

First `vagrant up` prompts for a username (Enter to accept `dev`) and a password
(hidden input), then opens a VirtualBox window. The VM reboots once into the
desktop and auto-logs in as that user.

To skip the prompts on rebuild, set env vars instead:

```powershell
$env:DEV_USER = "yourname"
$env:DEV_PASSWORD = "yourpassword"
vagrant up
```

## What's installed

| Tool | Notes |
|------|-------|
| Google Chrome | Pinned to dock/panel |
| VS Code | Pinned to dock/panel — `code .` from terminal |
| git + gh CLI | `gh auth login` to authenticate |
| Docker + Compose | Dev user is in the `docker` group — use `docker compose` |
| Node.js LTS | Via nvm — `nvm ls` to see versions |
| Go 1.22 | `/usr/local/go/bin`, `$GOPATH=$HOME/go` |
| Rust | Via rustup — `rustup update` to upgrade |
| tmux | Prefix: `Ctrl-A`, mouse on, zsh default shell |
| zsh + oh-my-zsh | Default shell, nvm/go/rust paths wired in |

## Shared folder

`V:\SharedFolder` on the host is mounted at `/workspace` inside the VM.
Use the `ws` alias to jump there instantly.

> **Fresh machine:** `V:\SharedFolder` probably doesn't exist yet. Set `WORKSPACE`
> to any local folder before `vagrant up`, or the VM will fail to start:
> ```powershell
> $env:WORKSPACE = "C:\Users\yourname\projects"
> vagrant up
> ```

The folder is owned by the `vagrant` group with `775/664` permissions.
The dev user is in that group, so no sudo is needed to read or write files.

## Customising per machine

These env vars can be set before `vagrant up` to customise the VM without
editing any files:

| Variable | Default | What it sets |
|----------|---------|--------------|
| `DEV_USER` | `dev` | Username for the main account |
| `DEV_PASSWORD` | _(prompted)_ | Password for the main account |
| `DEV_TZ` | `America/Bogota` | Timezone (`timedatectl list-timezones`) |
| `WORKSPACE` | `V:\SharedFolder` | Host path mounted at `/workspace` |

```powershell
$env:DEV_TZ = "America/New_York"
vagrant up
```

## Where to tweak things

| What you want to change | File to edit |
|-------------------------|--------------|
| System packages, tools, Go/Node versions | `provision-base.sh` → rebuild with `build.ps1` |
| Username, timezone, auto-login, nvm/Rust | `provision.sh` → `vagrant destroy && vagrant up` |
| Shell aliases, tmux, git config, dock shortcuts | `provision-tune.sh` → `vagrant provision --provision-with tune` |
| RAM, CPUs, ports | `Vagrantfile` → `vagrant reload` |

## Packer workflow

`build.ps1` pre-bakes a Packer image so that `vagrant up` after a destroy is fast:

```powershell
.\build.ps1 ubuntu   # or: .\build.ps1 mint
```

It takes ~20 minutes once, then every subsequent `vagrant up` skips the heavy
installs and boots in ~2 minutes. Each profile detects the baked box
automatically via a sentinel file — no manual config needed.

To rebuild (e.g. after changing `provision-base.sh`):

```powershell
.\build.ps1 ubuntu   # rebuilds and re-registers the box
vagrant destroy -f
vagrant up
```

## Adding a new profile

1. Copy an existing profile directory: `cp -r ubuntu myprofile`
2. Update `Vagrantfile`: box name, `vb.name`, `vm.hostname`, `BOX`/`USE_BAKED` constants
3. Rename the Packer template: `ubuntu.pkr.hcl` → `myprofile.pkr.hcl`, update `source_path`
4. Adapt `provision-base.sh` for the distro's package manager and desktop environment
5. Adapt `provision.sh` for the distro's display manager (GDM, LightDM, etc.)
6. Adapt `provision-tune.sh` for any desktop-specific dconf keys
7. Run `.\build.ps1 myprofile` to bake the image
8. Add the profile to the table at the top of this file

## Rebuilding from scratch

```powershell
cd ubuntu   # or whichever profile
vagrant destroy -f
vagrant up  # fast if baked box exists, ~15 min otherwise
```

To also discard the Packer-baked box and start completely fresh:

```powershell
vagrant box remove boxcraft/ubuntu   # or boxcraft/mint
Remove-Item .vagrant\packer_built     # clears the sentinel
.\build.ps1 ubuntu                    # rebuild from upstream
```

## Troubleshooting

**`setup.ps1` or `build.ps1` cannot be loaded / scripts disabled** — PowerShell blocks scripts by default. See Step 0 in Quick Start, or run once with:
```powershell
powershell -ExecutionPolicy Bypass -File .\setup.ps1
```

**Black screen after boot** — wait 60 s, then `vagrant reload`.
Guest Additions sometimes need a second boot to activate the display driver.

**Guest Additions build fails** — run `vagrant vbguest --do install`
then `vagrant reload`.

**Docker permission denied** — log out and back in (or `newgrp docker`)
so the group membership takes effect.

**Wrong screen resolution** — the autostart script handles this on login.
If it doesn't apply, run manually: `xrandr --output Virtual-1 --mode 1920x1080`

**VS Code prompts for a key on every launch** — GNOME Keyring never unlocks on
auto-login VMs. The tune provisioner writes `~/.vscode/argv.json` with
`"password-store": "basic"` to bypass it. If you skipped provisioning, create
the file manually:

```bash
mkdir -p ~/.vscode
echo '{ "password-store": "basic" }' > ~/.vscode/argv.json
```

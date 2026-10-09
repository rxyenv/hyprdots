#!/usr/bin/env bash
set -euo pipefail

# ── zen0x bootstrap ────────────────────────────────────────────────────────────
# Full system setup: packages → dotfiles → stow → theme → shell
# Target: Arch / CachyOS

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/modules/stow.sh" ]]; then
    DOTFILES_DIR="${DOTFILES_DIR:-$SCRIPT_DIR}"
else
    DOTFILES_DIR="${DOTFILES_DIR:-$HOME/dotfiles}"
fi
export DOTFILES_DIR
DOTFILES_REPO="${DOTFILES_REPO:-https://github.com/rxyenv/hyprdots.git}"
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; CYAN='\033[0;36m'; NC='\033[0m'
info()    { printf "${CYAN}:: %s${NC}\n" "$*"; }
success() { printf "${GREEN}✓  %s${NC}\n" "$*"; }
warn()    { printf "${YELLOW}!  %s${NC}\n" "$*"; }
die()     { printf "${RED}✗  %s${NC}\n" "$*" >&2; exit 1; }
step()    { printf "\n${CYAN}━━ %s ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n" "$*"; }

# ── sanity checks ──────────────────────────────────────────────────────────────
[[ "$EUID" -eq 0 ]] && die "Don't run as root — needs sudo internally."
command -v pacman >/dev/null 2>&1 || die "pacman not found — Arch/CachyOS only."

# ── packages ───────────────────────────────────────────────────────────────────
PACMAN_PACKAGES=(
    noctalia
    # Core tools
    git git-lfs stow python micro bat neovim tmux yazi nodejs npm ripgrep fd unzip dosfstools libimobiledevice usbmuxd

    # Build tools for hyprpm / plugin builds
    base-devel gcc cmake cpio pkgconf

    # Shell
    btop zsh fzf zoxide starship eza fastfetch

    # Wayland / WM
    hyprland uwsm hypridle hyprlock brightnessctl

    # Launcher & terminal
    kitty
    udiskie openrgb

    # File manager
    nautilus

    # Clipboard
    wl-clipboard cliphist

    # Capture / OCR / media
    grim slurp satty hyprpicker hyprshot wf-recorder
    xdg-user-dirs jq tesseract tesseract-data-eng xdg-utils libnotify playerctl

    # Audio / brightness
    pipewire pipewire-alsa pipewire-pulse wireplumber easyeffects gnome-keyring wiremix bluetui impala iwd bluez bluez-utils

    # Virtualization
    qemu-full libvirt virt-manager dnsmasq edk2-ovmf swtpm vde2 openbsd-netcat

    # Portals
    xdg-desktop-portal-hyprland xdg-desktop-portal-gtk

    # Fonts
    ttf-nerd-fonts-symbols
    ttf-jetbrains-mono-nerd
    noto-fonts noto-fonts-emoji
)


AUR_PACKAGES=(
    brave-bin
)

step "Bootstrap prerequisites"
sudo pacman -Syu --needed --noconfirm base-devel git git-lfs

step "AUR helper"
if ! command -v yay >/dev/null 2>&1; then
    info "Installing yay..."
    tmp="$(mktemp -d)"
    trap 'rm -rf -- "$tmp"' EXIT
    git clone --depth=1 https://aur.archlinux.org/yay-bin.git "$tmp/yay-bin"
    (cd "$tmp/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp"
    trap - EXIT
    success "yay installed"
else
    success "yay already present"
fi

step "System packages (pacman)"
sudo pacman -Syu --needed --noconfirm "${PACMAN_PACKAGES[@]}"
success "pacman packages done"

step "AUR packages"
yay -S --needed --noconfirm "${AUR_PACKAGES[@]}"
success "AUR packages done"

# ── virtualization ────────────────────────────────────────────────────────────
step "Virtualization"
sudo systemctl enable --now libvirtd.service
success "libvirtd enabled"

for group in libvirt kvm; do
    if getent group "$group" >/dev/null 2>&1; then
        if id -nG "$USER" | grep -qw "$group"; then
            success "$USER already in $group"
        else
            sudo usermod -aG "$group" "$USER"
            success "Added $USER to $group"
        fi
    else
        warn "Group $group not found; skipping"
    fi
done

if command -v virsh >/dev/null 2>&1; then
    if sudo virsh net-info default >/dev/null 2>&1; then
        sudo virsh net-autostart default >/dev/null 2>&1 || warn "Could not autostart default libvirt network"
        sudo virsh net-start default >/dev/null 2>&1 || true
        success "Default libvirt network ready"
    else
        warn "Default libvirt network unavailable; check libvirt network templates"
    fi
fi

# ── dotfiles ───────────────────────────────────────────────────────────────────
step "Dotfiles"
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    success "Repo already at $DOTFILES_DIR"
else
    info "Cloning dotfiles → $DOTFILES_DIR"
    GIT_LFS_SKIP_SMUDGE=1 git clone "$DOTFILES_REPO" "$DOTFILES_DIR"
    success "Cloned"
fi

step "Wallpaper assets"
if [[ -d "$DOTFILES_DIR/.git" ]]; then
    git -C "$DOTFILES_DIR" lfs install --local
    git -C "$DOTFILES_DIR" lfs pull
fi

# ── git identity ───────────────────────────────────────────────────────────────
step "Git identity"
current_name="$(git config --global --get user.name 2>/dev/null || true)"
current_email="$(git config --global --get user.email 2>/dev/null || true)"

if [[ -n "$current_name" && -n "$current_email" ]]; then
    warn "Git already configured as $current_name <$current_email>"
    printf "Reconfigure? [y/N] "; read -r reconfigure
    [[ "${reconfigure,,}" != "y" ]] && configure_git=false || configure_git=true
else
    configure_git=true
fi

if [[ "${configure_git:-true}" == "true" ]]; then
    printf "GitHub username: "; read -r github_username
    printf "GitHub email: "    ; read -r github_email
    [[ -z "$github_username" ]] && die "Username cannot be empty."
    [[ -z "$github_email"    ]] && die "Email cannot be empty."
    git config --global user.name  "$github_username"
    git config --global user.email "$github_email"
    success "Git configured: $github_username <$github_email>"
fi

# ── stow ───────────────────────────────────────────────────────────────────────
step "Stow configs"
cd "$DOTFILES_DIR"
"$DOTFILES_DIR/modules/stow.sh"
success "Stow done"

# ── default shell ──────────────────────────────────────────────────────────────
step "Default shell"
ZSH_BIN="$(command -v zsh)"
if [[ "$SHELL" == "$ZSH_BIN" ]]; then
    success "zsh already default shell"
else
    info "Setting zsh as default shell..."
    grep -qxF "$ZSH_BIN" /etc/shells || echo "$ZSH_BIN" | sudo tee -a /etc/shells
    chsh -s "$ZSH_BIN"
    success "Default shell → zsh (takes effect next login)"
fi

# ── uwsm / session ─────────────────────────────────────────────────────────────
step "Hyprland session"
info "Select Hyprland (uwsm-managed) in your existing display manager."
info "Or from TTY: uwsm start hyprland.desktop"

# ── done ───────────────────────────────────────────────────────────────────────
printf "\n${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n"
printf "${GREEN}  Done. Log out and back in (or reboot) to start.${NC}\n"
printf "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}\n\n"

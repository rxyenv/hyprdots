# Hyprdots

Arch/CachyOS desktop configs for Hyprland, Noctalia, Kitty, Zsh and LazyVim.

## Install

Run `./install.sh` as your regular user from a checkout. It installs dependencies,
hydrates Git LFS wallpapers, deploys configs with backups, and configures Zsh.
Sudo authentication and interactive Git identity prompts are required.
Keep your existing display manager; select the UWSM-managed Hyprland session.
The installer also enables libvirt and adds virtualization groups.

To deploy configs alone, run `./modules/stow.sh`. Helpers go into `~/.local/bin`;
configs into `${XDG_CONFIG_HOME:-~/.config}`. Existing conflicts are backed up
under `~/.local/state/zen0x-stow-backups`. Failed deployment restores moved paths.
Each backup contains `manifest.nul` with alternating original and backup paths.
Noctalia-generated theme files are preserved; defaults are copied only if absent.
Restart the session after installation to pick up UWSM environment and idle locking.

## Finish dependencies on an existing setup

Run this in a terminal where you can authenticate sudo:

```sh
sudo pacman -S --needed git-lfs hypridle hyprlock brightnessctl bluetui impala easyeffects bat neovim tmux yazi udiskie openrgb gnome-keyring iwd xdg-user-dirs nodejs npm ripgrep fd unzip
# Run from this repository:
git lfs install --local
git lfs pull
./modules/stow.sh
```

Install Brave with `yay -S brave-bin` if no Brave variant is already installed.
Code and Vesktop shortcuts are optional and require those apps separately.
Wi-Fi helper uses active NetworkManager with nmtui, otherwise iwd with impala;
do not enable competing Wi-Fi managers. Bluetooth needs an active bluetooth service.

## Hardware customization

`hypr/modules/monitors.lua` includes a preferred-mode fallback and the existing
DP-1 1080p/300 Hz override. Adjust the override to match your display.
Set `HYPR_TOUCHPAD_NAME` in your UWSM environment to the exact name shown by
`hyprctl devices` if you want adaptive touchpad acceleration with flat mouse input.
Optional CS2 plugin requires an ABI-compatible build via `CSGO_VULKAN_FIX_PLUGIN`.
Overview shortcut falls back to the launcher when its plugin is unavailable.

Zsh validates inherited locale settings against installed locales. Invalid
`en_IN.utf8` overrides fall back to `C.UTF-8`; valid overrides remain intact.
For an already-open terminal, run `source ~/.zshenv` to clear locale warnings.

Screen recording shortcuts toggle recording; a second press stops and finalizes it.
Screenshots support region, window, fullscreen and smart (region) modes.
`optimizer.sh` changes runtime tunables only, reports failed writes, and does not
restore previous values. Balanced is a predefined profile, not an undo operation.

## Verify

```sh
python3 -B -m unittest discover -s tests -v
Hyprland --verify-config --config "$PWD/hypr/hyprland.lua"
```

Compression tooling validates structural preservation and writes atomically with
an exact byte backup. Semantic preservation still requires human review;
model-generated prose cannot be proven equivalent by these checks.

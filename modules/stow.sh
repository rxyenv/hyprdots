#!/usr/bin/env bash
# Deploy individual links with rollback; never traverse foreign directory links.
set -euo pipefail
DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
HOME_TARGET="${HOME_TARGET:-$HOME}"
CONFIG_ROOT_TARGET="${CONFIG_ROOT_TARGET:-${XDG_CONFIG_HOME:-$HOME/.config}}"
BIN_ROOT_TARGET="${BIN_ROOT_TARGET:-$HOME/.local}"
STOW_BACKUP_ROOT="${STOW_BACKUP_ROOT:-$HOME/.local/state/zen0x-stow-backups}"
mkdir -p "$STOW_BACKUP_ROOT"
STOW_BACKUP_DIR="$(mktemp -d "$STOW_BACKUP_ROOT/${STOW_TIMESTAMP:-$(date +%Y%m%d-%H%M%S)}.XXXXXX")"
declare -a moved_paths=() saved_paths=() installed_links=() created_dirs=()
committed=false
rollback() {
    local status=$? i
    if [[ "$committed" != true ]]; then
        for ((i=${#installed_links[@]}-1; i>=0; i--)); do
            unlink "${installed_links[i]}" || true
        done
        for ((i=${#created_dirs[@]}-1; i>=0; i--)); do
            rmdir -- "${created_dirs[i]}" || true
        done
        for ((i=${#moved_paths[@]}-1; i>=0; i--)); do
            mv -T -- "${saved_paths[i]}" "${moved_paths[i]}" || printf 'Restore manually: %s → %s\n' "${saved_paths[i]}" "${moved_paths[i]}" >&2
        done
    fi
    exit "$status"
}
trap rollback EXIT
backup() {
    local path="$1" saved="$STOW_BACKUP_DIR/${#moved_paths[@]}"
    mv -T -- "$path" "$saved"
    moved_paths+=("$path"); saved_paths+=("$saved")
    printf '%s\0%s\0' "$path" "$saved" >> "$STOW_BACKUP_DIR/manifest.nul"
}
ensure_dir() {
    local path="$1"
    [[ "$path" == / ]] && return 0
    ensure_dir "$(dirname "$path")"
    if [[ -L "$path" || ( -e "$path" && ! -d "$path" ) ]]; then backup "$path"; fi
    if [[ ! -d "$path" ]]; then
        mkdir -- "$path"
        created_dirs+=("$path")
    fi
}
deploy_package() {
    local package="$1" target="$2" source rel dest
    [[ -d "$DOTFILES_DIR/$package" ]] || return 0
    ensure_dir "$target"
    while IFS= read -r -d '' source; do
        rel="${source#"$DOTFILES_DIR/$package/"}"
        case "$rel" in README*|LICENSE*|.gitignore|.stow-local-ignore|stylua.toml) continue ;; esac
        dest="$target/$rel"
        ensure_dir "$(dirname "$dest")"
        case "$package/$rel" in
            hypr/noctalia.lua|kitty/themes/noctalia.conf)
                if [[ -e "$dest" ]]; then continue; fi
                if [[ -L "$dest" ]]; then backup "$dest"; fi
                cp -- "$source" "$dest"
                installed_links+=("$dest")
                continue ;;
        esac
        if [[ -L "$dest" && "$(readlink "$dest")" == "$source" ]]; then continue; fi
        if [[ -e "$dest" || -L "$dest" ]]; then backup "$dest"; fi
        ln -s -- "$source" "$dest"
        installed_links+=("$dest")
    done < <(find "$DOTFILES_DIR/$package" \( -type f -o -type l \) -print0)
}
# Explicit grouping keeps find's -print0 active for both regular files and links.
# Paths are absolute, so deployment works independently of the caller's cwd.
DOTFILES_DIR="$(realpath "$DOTFILES_DIR")"
HOME_TARGET="$(realpath -ms "$HOME_TARGET")"
CONFIG_ROOT_TARGET="$(realpath -ms "$CONFIG_ROOT_TARGET")"
BIN_ROOT_TARGET="$(realpath -ms "$BIN_ROOT_TARGET")"
deploy_package zsh "$HOME_TARGET"
deploy_package bin "$BIN_ROOT_TARGET"
for pkg in fastfetch hypr kitty nvim wireplumber xdg-desktop-portal uwsm; do
    deploy_package "$pkg" "$CONFIG_ROOT_TARGET/$pkg"
done
committed=true
printf 'Deployment complete. Backups: %s\n' "$STOW_BACKUP_DIR"

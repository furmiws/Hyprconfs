#!/usr/bin/env bash

# -------------------------------------------------------
#  dotfiles install script
#  Symlinks configs to their correct locations.
#  Backs up any existing files before overwriting.
# -------------------------------------------------------

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$HOME/.config"
BACKUP_DIR="$HOME/.config/dotfiles-backup-$(date +%Y%m%d_%H%M%S)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

print_header() {
    echo -e "\n${CYAN}${BOLD}"
    echo "  ██████╗  ██████╗ ████████╗███████╗██╗██╗     ███████╗███████╗"
    echo "  ██╔══██╗██╔═══██╗╚══██╔══╝██╔════╝██║██║     ██╔════╝██╔════╝"
    echo "  ██║  ██║██║   ██║   ██║   █████╗  ██║██║     █████╗  ███████╗"
    echo "  ██║  ██║██║   ██║   ██║   ██╔══╝  ██║██║     ██╔══╝  ╚════██║"
    echo "  ██████╔╝╚██████╔╝   ██║   ██║     ██║███████╗███████╗███████║"
    echo "  ╚═════╝  ╚═════╝    ╚═╝   ╚═╝     ╚═╝╚══════╝╚══════╝╚══════╝"
    echo -e "${RESET}"
    echo -e "  ${BOLD}Hyprland dotfiles installer${RESET}"
    echo -e "  ${BLUE}────────────────────────────────────────${RESET}\n"
}

log_info()    { echo -e "  ${BLUE}[INFO]${RESET}  $1"; }
log_ok()      { echo -e "  ${GREEN}[ OK ]${RESET}  $1"; }
log_warn()    { echo -e "  ${YELLOW}[WARN]${RESET}  $1"; }
log_error()   { echo -e "  ${RED}[ERR ]${RESET}  $1"; }
log_section() { echo -e "\n  ${BOLD}${CYAN}▸ $1${RESET}"; }

# -------------------------------------------------------
# Symlink a file/folder, backing up any existing target
# Usage: symlink <source_relative_to_dotfiles> <target>
# -------------------------------------------------------
symlink() {
    local src="$DOTFILES_DIR/$1"
    local dst="$2"

    # Check source exists
    if [[ ! -e "$src" ]]; then
        log_warn "Source not found, skipping: $src"
        return
    fi

    # If destination exists and is NOT already our symlink, back it up
    if [[ -e "$dst" || -L "$dst" ]]; then
        if [[ -L "$dst" && "$(readlink "$dst")" == "$src" ]]; then
            log_ok "Already linked: $dst"
            return
        fi
        mkdir -p "$BACKUP_DIR"
        mv "$dst" "$BACKUP_DIR/"
        log_warn "Backed up existing: $dst → $BACKUP_DIR/"
    fi

    mkdir -p "$(dirname "$dst")"
    ln -s "$src" "$dst"
    log_ok "Linked: $dst"
}

# -------------------------------------------------------
# Check for optional dependencies
# -------------------------------------------------------
check_deps() {
    log_section "Checking dependencies"
    local deps=(hyprland waybar rofi dunst)
    local missing=()

    for dep in "${deps[@]}"; do
        if command -v "$dep" &>/dev/null; then
            log_ok "$dep found"
        else
            log_warn "$dep not found — you may need to install it"
            missing+=("$dep")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        echo -e "\n  ${YELLOW}Missing packages: ${missing[*]}${RESET}"
        echo -e "  ${YELLOW}Install with: sudo pacman -S ${missing[*]}${RESET}\n"
    fi
}

# -------------------------------------------------------
# Install configs
# -------------------------------------------------------
install_configs() {
    log_section "Installing configs"

    # Hyprland
    symlink "hypr/hyprland.lua"             "$CONFIG_DIR/hypr/hyprland.lua"

    # Waybar
    symlink "waybar/config.jsonc"           "$CONFIG_DIR/waybar/config.jsonc"
    symlink "waybar/style.css"              "$CONFIG_DIR/waybar/style.css"

    # Rofi
    symlink "rofi/config.rasi"             "$CONFIG_DIR/rofi/config.rasi"
    symlink "rofi/bluetooth-menu.sh"       "$CONFIG_DIR/rofi/bluetooth-menu.sh"
    symlink "rofi/power-menu.sh"           "$CONFIG_DIR/rofi/power-menu.sh"
    symlink "rofi/wifi-menu.sh"            "$CONFIG_DIR/rofi/wifi-menu.sh"

    # Dunst
    symlink "dunst/dunstrc"                "$CONFIG_DIR/dunst/dunstrc"
}

# -------------------------------------------------------
# Make rofi scripts executable
# -------------------------------------------------------
fix_permissions() {
    log_section "Fixing permissions"
    local scripts=(
        "$CONFIG_DIR/rofi/bluetooth-menu.sh"
        "$CONFIG_DIR/rofi/power-menu.sh"
        "$CONFIG_DIR/rofi/wifi-menu.sh"
    )
    for s in "${scripts[@]}"; do
        if [[ -e "$s" ]]; then
            chmod +x "$s"
            log_ok "chmod +x $(basename "$s")"
        fi
    done
}

# -------------------------------------------------------
# Set wallpaper with swww
# -------------------------------------------------------
set_wallpaper() {
    log_section "Setting wallpaper"
    if command -v swww &>/dev/null; then
        swww-daemon &>/dev/null &
        sleep 1
        swww img "$DOTFILES_DIR/wallpapers/CoolestFuryr.png"
        log_ok "Wallpaper set!"
    else
        log_warn "swww not found — install it with: sudo pacman -S swww"
        log_warn "Then run: swww img $DOTFILES_DIR/wallpapers/denia.gif"
    fi
}


print_done() {
    echo -e "\n  ${GREEN}${BOLD}All done! ✓${RESET}"
    echo -e "  ${BLUE}────────────────────────────────────────${RESET}"
    echo -e "  Reload Hyprland with:  ${BOLD}hyprctl reload${RESET}"
    echo -e "  Restart Waybar with:   ${BOLD}killall waybar && waybar &${RESET}"
    echo -e "  Restart Dunst with:    ${BOLD}killall dunst && dunst &${RESET}"
    echo -e "  ${BLUE}────────────────────────────────────────${RESET}\n"
}

# -------------------------------------------------------
# Main
# -------------------------------------------------------
main() {
    print_header
    check_deps
    install_configs
    fix_permissions
    set_wallpaper
    print_done
}

main "$@"

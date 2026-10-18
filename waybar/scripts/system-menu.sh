#!/usr/bin/env bash

# -------------------------------------------------------
# system-menu.sh
# Rofi popup with:
#   - Battery info + power modes (laptop)
#   - Flash icon + power modes (PC)
#   - Visual toggles: blur, animations, transparency
# -------------------------------------------------------

HAS_BATTERY=false
BATTERY_PATH=""

for bat in /sys/class/power_supply/BAT*; do
    if [[ -e "$bat" ]]; then
        HAS_BATTERY=true
        BATTERY_PATH="$bat"
        break
    fi
done

# ── Power profile ────────────────────────────────────────
get_profile() {
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl get 2>/dev/null || echo "unknown"
    else
        echo "unknown"
    fi
}

set_profile() {
    if command -v powerprofilesctl &>/dev/null; then
        powerprofilesctl set "$1"
        notify-send "Power Profile" "Switched to: $1" -i battery -t 2000 2>/dev/null || true
    fi
}

# ── Hyprland option helpers ──────────────────────────────
get_hypr_int() {
    hyprctl getoption "$1" 2>/dev/null | awk '/^int:/{print $2}'
}

get_hypr_float() {
    hyprctl getoption "$1" 2>/dev/null | awk '/^float:/{print $2}'
}

# ── Read current states ──────────────────────────────────
current_profile=$(get_profile)
blur_on=$(get_hypr_int "decoration:blur:enabled")
anim_on=$(get_hypr_int "animations:enabled")
inactive_opacity=$(get_hypr_float "decoration:inactive_opacity")

# Default fallbacks
[[ -z "$blur_on" ]]         && blur_on=0
[[ -z "$anim_on" ]]         && anim_on=1
[[ -z "$inactive_opacity" ]] && inactive_opacity=1.0

# ── Build rofi menu ──────────────────────────────────────
MENU=""

if $HAS_BATTERY; then
    capacity=$(cat "$BATTERY_PATH/capacity" 2>/dev/null || echo "?")
    status=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo "Unknown")
    MENU+="󰁹  Battery: ${capacity}% (${status})\n"
    MENU+="──────────────────\n"
fi

# Power modes with active marker
[[ "$current_profile" == "power-saver"  ]] && ps_mark=" ✓" || ps_mark=""
[[ "$current_profile" == "balanced"     ]] && bal_mark=" ✓" || bal_mark=""
[[ "$current_profile" == "performance"  ]] && pf_mark=" ✓" || pf_mark=""

MENU+="  Powersave${ps_mark}\n"
MENU+="󰓅  Balanced${bal_mark}\n"
MENU+="󱐋  Performance${pf_mark}\n"
MENU+="──────────────────\n"

# Visual toggles
[[ "$blur_on" == "1" ]]        && blur_label="󰈈  Disable Blur"        || blur_label="󰈈  Enable Blur"
[[ "$anim_on" == "1" ]]        && anim_label="󱁖  Disable Animations"  || anim_label="󱁖  Enable Animations"

# Transparency: inactive_opacity < 1.0 means it's on
if awk "BEGIN {exit !($inactive_opacity < 1.0)}"; then
    opacity_label="󰘡  Enable Full Opacity"
else
    opacity_label="󰘡  Disable Transparency"
fi

MENU+="$blur_label\n"
MENU+="$anim_label\n"
MENU+="$opacity_label"

# ── Show rofi ────────────────────────────────────────────
chosen=$(echo -e "$MENU" | rofi -dmenu \
    -p "󱐋 System" \
    -no-custom \
    -theme-str '
        window   { width: 300px; }
        listview { lines: 10; }
    ')

[[ -z "$chosen" ]] && exit 0

# ── Handle selection ─────────────────────────────────────
case "$chosen" in
    *"Powersave"*)
        set_profile "power-saver" ;;
    *"Balanced"*)
        set_profile "balanced" ;;
    *"Performance"*)
        set_profile "performance" ;;
    *"Blur"*)
        if [[ "$blur_on" == "1" ]]; then
            hyprctl keyword decoration:blur:enabled false
        else
            hyprctl keyword decoration:blur:enabled true
        fi
        ;;
    *"Animations"*)
        if [[ "$anim_on" == "1" ]]; then
            hyprctl keyword animations:enabled false
        else
            hyprctl keyword animations:enabled true
        fi
        ;;
    *"Opacity"|*"Transparency"*)
        if awk "BEGIN {exit !($inactive_opacity < 1.0)}"; then
            hyprctl keyword decoration:active_opacity 1.0
            hyprctl keyword decoration:inactive_opacity 1.0
        else
            hyprctl keyword decoration:active_opacity 1.0
            hyprctl keyword decoration:inactive_opacity 0.90
        fi
        ;;
esac

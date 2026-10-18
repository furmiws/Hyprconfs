#!/usr/bin/env bash

# -------------------------------------------------------
# system-label.sh
# Outputs battery info for laptops, or ⚡ for PCs.
# Used by waybar custom/system-menu module.
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

if $HAS_BATTERY; then
    capacity=$(cat "$BATTERY_PATH/capacity" 2>/dev/null || echo "?")
    status=$(cat "$BATTERY_PATH/status" 2>/dev/null || echo "Unknown")

    if [[ "$status" == "Charging" ]]; then
        icon="󰂄"
    elif [[ "$capacity" -ge 90 ]]; then
        icon="󰁹"
    elif [[ "$capacity" -ge 70 ]]; then
        icon="󰂀"
    elif [[ "$capacity" -ge 50 ]]; then
        icon="󰁾"
    elif [[ "$capacity" -ge 30 ]]; then
        icon="󰁼"
    elif [[ "$capacity" -ge 10 ]]; then
        icon="󰁺"
    else
        icon="󰂃"
    fi

    echo "$icon  $capacity%"
else
    # PC — show flash icon
    echo "󱐋"
fi

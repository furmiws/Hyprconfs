#!/usr/bin/env bash

# Catppuccin Mocha Rofi Bluetooth Menu

ROFI_THEME='
window {
    width: 440px;
    height: 420px;
}
listview {
    lines: 7;
}
inputbar {
    enabled: true;
}
mode-switcher {
    enabled: false;
}
'

# Check power status
is_powered=$(bluetoothctl show | grep "Powered: yes")

if [ -z "$is_powered" ]; then
    chosen=$(echo -e "󰂯  Turn Bluetooth On" | rofi -dmenu -i -p "󰂲  Bluetooth Off" -theme-str "$ROFI_THEME")
    if [ "$chosen" = "󰂯  Turn Bluetooth On" ]; then
        rfkill unblock bluetooth
        bluetoothctl power on
        notify-send "Bluetooth" "Bluetooth enabled" -i bluetooth-active
    fi
    exit 0
fi

# Build options
menu_items="󰂲  Turn Bluetooth Off\n"
menu_items+="  Scan for Devices\n"
menu_items+="󰒲  Disconnect All\n"

# Add paired / known devices
devices=$(bluetoothctl devices | while read -r _ mac name; do
    info=$(bluetoothctl info "$mac")
    if echo "$info" | grep -q "Connected: yes"; then
        echo "󰂱  $name ($mac) [Connected]"
    else
        echo "󰂯  $name ($mac)"
    fi
done)

if [ -n "$devices" ]; then
    menu_items+="$devices\n"
fi

chosen=$(echo -e -n "$menu_items" | rofi -dmenu -i -p "󰂯  Bluetooth" -theme-str "$ROFI_THEME")

[ -z "$chosen" ] && exit 0

case "$chosen" in
    "󰂲  Turn Bluetooth Off")
        bluetoothctl power off
        notify-send "Bluetooth" "Bluetooth disabled" -i bluetooth-disabled
        exit 0
        ;;
    "  Scan for Devices")
        notify-send "Bluetooth" "Scanning for 5 seconds..." -i bluetooth -t 2000
        bluetoothctl --timeout 5 scan on
        exec "$0"
        ;;
    "󰒲  Disconnect All")
        bluetoothctl devices Connected | while read -r _ mac _; do
            bluetoothctl disconnect "$mac"
        done
        notify-send "Bluetooth" "Disconnected all devices" -i bluetooth
        exit 0
        ;;
esac

# Extract MAC address inside parenthesis
mac=$(echo "$chosen" | grep -o -E '([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}')

if [ -n "$mac" ]; then
    name=$(echo "$chosen" | sed -E 's/^[󰂱󰂯]  //; s/ \([0-9A-Fa-f:]+\).*//')
    info=$(bluetoothctl info "$mac")
    
    if echo "$info" | grep -q "Connected: yes"; then
        action=$(echo -e "󰌙  Disconnect\n󰆴  Unpair/Remove" | rofi -dmenu -i -p "$name" -theme-str '
        window { width: 340px; height: 160px; }
        listview { lines: 2; }
        mode-switcher { enabled: false; }
        ')
        case "$action" in
            "󰌙  Disconnect")
                bluetoothctl disconnect "$mac"
                notify-send "Bluetooth" "Disconnected from $name" -i bluetooth
                ;;
            "󰆴  Unpair/Remove")
                bluetoothctl remove "$mac"
                notify-send "Bluetooth" "Removed $name" -i bluetooth
                ;;
        esac
    else
        notify-send "Bluetooth" "Connecting to $name..." -i bluetooth
        if bluetoothctl connect "$mac"; then
            notify-send "Bluetooth" "Connected to $name!" -i bluetooth-active
        else
            notify-send -u critical "Bluetooth" "Failed to connect to $name" -i bluetooth
        fi
    fi
fi

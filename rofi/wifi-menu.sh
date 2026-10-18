#!/usr/bin/env bash

# Catppuccin Mocha Rofi Wi-Fi Menu

# Check Wi-Fi radio status
wifi_status=$(nmcli radio wifi)

ROFI_THEME='
window {
    width: 460px;
    height: 440px;
}
listview {
    lines: 8;
}
inputbar {
    enabled: true;
}
mode-switcher {
    enabled: false;
}
'

if [ "$wifi_status" = "disabled" ]; then
    chosen=$(echo -e "󰖩  Turn Wi-Fi On\n  Network Connections (GUI)" | rofi -dmenu -i -p "󰖪  Wi-Fi Disabled" -theme-str "$ROFI_THEME")
    case "$chosen" in
        "󰖩  Turn Wi-Fi On")
            nmcli radio wifi on
            notify-send "Wi-Fi" "Wi-Fi enabled" -i network-wireless
            ;;
        "  Network Connections (GUI)")
            nm-connection-editor &
            ;;
    esac
    exit 0
fi

# Get current connection info
active_ssid=$(nmcli -t -f active,ssid dev wifi | grep '^yes:' | cut -d: -f2)
active_speed=$(nmcli -t -f active,rate dev wifi | grep '^yes:' | cut -d: -f2 | head -n1)

# Options list
menu_items=""
if [ -n "$active_ssid" ]; then
    menu_items+="󰖩  Connected: $active_ssid [${active_speed:-N/A}]\n"
    menu_items+="󰌙  Disconnect from $active_ssid\n"
fi

menu_items+="󰖪  Turn Wi-Fi Off\n"
menu_items+="  Rescan Networks\n"
menu_items+="  Network Connections (GUI)\n"

# Scan networks and parse
raw_list=$(nmcli -t -f active,ssid,bars,security dev wifi list --rescan no)

# Format list of available networks, avoiding duplicate SSIDs
declare -A seen_ssids
while IFS=: read -r active ssid bars security; do
    [ -z "$ssid" ] && continue
    [ "$ssid" = "$active_ssid" ] && continue
    [ "${seen_ssids[$ssid]}" = "1" ] && continue
    seen_ssids["$ssid"]=1

    if [ -n "$security" ] && [ "$security" != "--" ]; then
        icon=""
    else
        icon=""
    fi
    menu_items+="$icon  $ssid ($bars)\n"
done <<< "$raw_list"

chosen=$(echo -e -n "$menu_items" | rofi -dmenu -i -p "󰖩  Wi-Fi" -theme-str "$ROFI_THEME")

[ -z "$chosen" ] && exit 0

case "$chosen" in
    "󰖪  Turn Wi-Fi Off")
        nmcli radio wifi off
        notify-send "Wi-Fi" "Wi-Fi disabled" -i network-wireless-offline
        exit 0
        ;;
    "  Rescan Networks")
        notify-send "Wi-Fi" "Scanning for networks..." -i network-wireless -t 1500
        nmcli dev wifi rescan
        exec "$0"
        ;;
    "  Network Connections (GUI)")
        nm-connection-editor &
        exit 0
        ;;
    "󰌙  Disconnect from "*)
        nmcli dev disconnect wlan0
        notify-send "Wi-Fi" "Disconnected from $active_ssid" -i network-wireless-disconnected
        exit 0
        ;;
    "󰖩  Connected: "*)
        # User clicked current connection
        exit 0
        ;;
esac

# Parse selected network SSID from the icon + format
# Format: "icon  SSID (bars)"
selected_ssid=$(echo "$chosen" | sed -E 's/^[]  //; s/ \([ ▂▄▆█_]+\)$//')

[ -z "$selected_ssid" ] && exit 0

# Check if connection is already known/saved
if nmcli connection show "$selected_ssid" >/dev/null 2>&1; then
    notify-send "Wi-Fi" "Connecting to $selected_ssid..." -i network-wireless
    if nmcli connection up "$selected_ssid"; then
        notify-send "Wi-Fi" "Connected to $selected_ssid!" -i network-wireless
    else
        notify-send -u critical "Wi-Fi" "Failed to connect to $selected_ssid" -i network-error
    fi
    exit 0
fi

# Check if network is password protected
sec_info=$(echo "$raw_list" | grep ":$selected_ssid:" | cut -d: -f4 | head -n1)

if [ -n "$sec_info" ] && [ "$sec_info" != "--" ]; then
    pass=$(rofi -dmenu -password -p "Password for $selected_ssid" -theme-str '
    window {
        width: 380px;
        height: 140px;
    }
    listview {
        lines: 0;
    }
    mode-switcher {
        enabled: false;
    }
    ')
    [ -z "$pass" ] && exit 0

    notify-send "Wi-Fi" "Connecting to $selected_ssid..." -i network-wireless
    if nmcli dev wifi connect "$selected_ssid" password "$pass"; then
        notify-send "Wi-Fi" "Connected to $selected_ssid!" -i network-wireless
    else
        notify-send -u critical "Wi-Fi" "Failed to connect to $selected_ssid" -i network-error
    fi
else
    notify-send "Wi-Fi" "Connecting to $selected_ssid..." -i network-wireless
    if nmcli dev wifi connect "$selected_ssid"; then
        notify-send "Wi-Fi" "Connected to $selected_ssid!" -i network-wireless
    else
        notify-send -u critical "Wi-Fi" "Failed to connect to $selected_ssid" -i network-error
    fi
fi

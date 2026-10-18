#!/usr/bin/env bash

# Options
shutdown='  Shutdown'
reboot='  Reboot'
lock='  Lock'
suspend='󰒲  Suspend'
logout='󰍃  Logout'

options="$lock\n$suspend\n$logout\n$reboot\n$shutdown"

chosen="$(echo -e "$options" | rofi -dmenu -i -p "Power" -theme-str '
window {
    width: 320px;
    height: 280px;
}
listview {
    lines: 5;
}
inputbar {
    enabled: true;
}
mode-switcher {
    enabled: false;
}
')"

case "$chosen" in
    "$shutdown")
        systemctl poweroff
        ;;
    "$reboot")
        systemctl reboot
        ;;
    "$lock")
        loginctl lock-session
        ;;
    "$suspend")
        systemctl suspend
        ;;
    "$logout")
        hyprctl dispatch exit
        ;;
esac

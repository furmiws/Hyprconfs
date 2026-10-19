# dotfiles 🌿

My personal configuration files for a **Hyprland** Wayland setup on Arch Linux (I haven't tried on others Linux distros yet).

## 🖥️ Setup

| Component | App |
|-----------|-----|
| Compositor | [Hyprland](https://hyprland.org/) |
| Status Bar | [Waybar](https://github.com/Alexays/Waybar) |
| Launcher | [Rofi](https://github.com/davatorium/rofi) |
| Notifications | [Dunst](https://dunst-project.org/) |
| Wallpaper | [swww](https://github.com/LGFae/swww) |
| OS | Arch Linux |

---

## ⚡ Quick Install

```bash
git clone https://github.com/furmiws/Hyprconfs.git ~/Hyprconfs
cd ~/Hyprconfs
chmod +x install.sh
./install.sh
```

The script will:
- ✅ Check that required apps are installed.
- 🔗 Symlink all configs to `~/.config/`
- 💾 Back up any existing configs before overwriting.
- 🖼️ Set the wallpaper automatically with swww.

---

## 📁 Structure

```
Hyprconfs/
├── install.sh          # Installer script
├── hypr/
│   └── hyprland.lua    # Hyprland config
├── waybar/
│   ├── config.jsonc    # Waybar layout
│   └── style.css       # Waybar styles
├── rofi/
│   ├── config.rasi         # Rofi theme
│   ├── bluetooth-menu.sh   # Bluetooth menu
│   ├── power-menu.sh       # Power menu
│   └── wifi-menu.sh        # Wifi menu
├── dunst/
│   └── dunstrc         # Dunst notification config
└── wallpapers/
    └── CoolestFuryr.png    # Wallpaper (via swww)
```

---

## 📦 Dependencies

Install everything on Arch:

```bash
sudo pacman -S hyprland waybar rofi dunst swww
```

---

## 🔄 After Installing

```bash
hyprctl reload           # Reload Hyprland config
killall waybar && waybar & # Restart Waybar
killall dunst && dunst &   # Restart Dunst
```

---

## 📸 Screenshots

![Desktop](screenshots/2026-10-18_14-20-15.png)




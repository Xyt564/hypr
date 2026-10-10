#!/usr/bin/env bash
set -Eeuo pipefail

# Hyprland setup for Debian 13 (Trixie)
# Desktop: GNOME
# Graphics: AMD / Intel
# Includes: animations, blur, Waybar, Wofi, Foot, Mako

if [[ $EUID -eq 0 ]]; then
    echo "Please run this script as your normal user, not root."
    exit 1
fi

if ! grep -qE 'VERSION_ID="13"|VERSION_CODENAME=trixie' /etc/os-release; then
    echo "Warning: This script was designed for Debian 13 (Trixie)."
    read -r -p "Continue anyway? [y/N] " answer
    [[ "$answer" =~ ^[Yy]$ ]] || exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "Install sudo first, or run the package installation commands as root."
    exit 1
fi

echo "==> Updating package lists..."
sudo apt-get update

echo "==> Installing Hyprland and desktop utilities..."

packages=(
    hyprland
    waybar
    wofi
    foot
    mako-notifier
    xwayland
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    pipewire
    wireplumber
    pipewire-pulse
    fonts-noto-color-emoji
    fonts-dejavu-core
    brightnessctl
    grim
    slurp
    wl-clipboard
    network-manager
)

# Prefer the Debian 13 backports build if one is available.
if ! apt-cache madison hyprland | grep -q 'trixie-backports'; then
    echo "==> Adding the Debian Trixie backports repository..."
    echo "deb http://deb.debian.org/debian trixie-backports main" |
        sudo tee /etc/apt/sources.list.d/trixie-backports.list >/dev/null
    sudo apt-get update
fi

if apt-cache madison hyprland | grep -q 'trixie-backports'; then
    if ! sudo apt-get install -y -t trixie-backports "${packages[@]}"; then
        echo "Backports installation failed; trying standard Debian packages..."
        sudo apt-get install -y "${packages[@]}"
    fi
else
    sudo apt-get install -y "${packages[@]}"
fi

echo "==> Creating configuration directories..."

mkdir -p \
    "$HOME/.config/hypr" \
    "$HOME/.config/waybar" \
    "$HOME/.config/wofi" \
    "$HOME/.config/mako"

# Preserve an existing Hyprland configuration.
if [[ -f "$HOME/.config/hypr/hyprland.conf" ]]; then
    cp "$HOME/.config/hypr/hyprland.conf" \
       "$HOME/.config/hypr/hyprland.conf.backup.$(date +%Y%m%d%H%M%S)"
fi

echo "==> Writing Hyprland configuration..."

cat > "$HOME/.config/hypr/hyprland.conf" <<'HYPR'
# Monitor: choose preferred resolution and scale automatically.
monitor = , preferred, auto, 1

# Environment
env = XCURSOR_SIZE,24
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland

# Keyboard
input {
    kb_layout = us
    follow_mouse = 1
    sensitivity = 0
    touchpad {
        natural_scroll = true
        tap-to-click = true
    }
}

# General appearance
general {
    gaps_in = 5
    gaps_out = 12
    border_size = 2

    col.active_border = rgba(89b4faff) rgba(cba6f7ff) 45deg
    col.inactive_border = rgba(45475a99)

    layout = dwindle
    resize_on_border = true
}

# Rounded corners and blur
decoration {
    rounding = 12

    active_opacity = 1.0
    inactive_opacity = 0.95

    shadow {
        enabled = true
        range = 15
        render_power = 3
        color = rgba(1a1a1add)
    }

    blur {
        enabled = true
        size = 8
        passes = 3
        vibrancy = 0.17
        new_optimizations = true
    }
}

# Smooth animations
animations {
    enabled = true

    bezier = easeOut, 0.16, 1, 0.3, 1
    bezier = easeInOut, 0.65, 0, 0.35, 1

    animation = windows, 1, 5, easeOut, popin 80%
    animation = windowsOut, 1, 4, easeInOut, popin 80%
    animation = border, 1, 8, easeOut
    animation = fade, 1, 5, easeOut
    animation = workspaces, 1, 5, easeOut, slide
}

# Dwindle tiling
dwindle {
    pseudotile = true
    preserve_split = true
}

# Master key
$mainMod = SUPER

# Applications
$terminal = foot
$fileManager = thunar
$menu = wofi --show drun

# Start desktop services
exec-once = waybar
exec-once = mako
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP

# Keyboard shortcuts
bind = $mainMod, Q, exec, $terminal
bind = $mainMod, R, exec, $menu
bind = $mainMod, E, exec, thunar
bind = $mainMod, C, killactive
bind = $mainMod, M, exit
bind = $mainMod, V, togglefloating
bind = $mainMod, F, fullscreen
bind = $mainMod, P, pseudo
bind = $mainMod, J, togglesplit

# Switch workspaces with Super + number
bind = $mainMod, 1, workspace, 1
bind = $mainMod, 2, workspace, 2
bind = $mainMod, 3, workspace, 3
bind = $mainMod, 4, workspace, 4
bind = $mainMod, 5, workspace, 5
bind = $mainMod, 6, workspace, 6
bind = $mainMod, 7, workspace, 7
bind = $mainMod, 8, workspace, 8
bind = $mainMod, 9, workspace, 9

# Move windows between workspaces
bind = $mainMod SHIFT, 1, movetoworkspace, 1
bind = $mainMod SHIFT, 2, movetoworkspace, 2
bind = $mainMod SHIFT, 3, movetoworkspace, 3
bind = $mainMod SHIFT, 4, movetoworkspace, 4
bind = $mainMod SHIFT, 5, movetoworkspace, 5

# Move focus with Super + arrow keys
bind = $mainMod, LEFT, movefocus, l
bind = $mainMod, RIGHT, movefocus, r
bind = $mainMod, UP, movefocus, u
bind = $mainMod, DOWN, movefocus, d

# Move windows with Super + Shift + arrows
bind = $mainMod SHIFT, LEFT, movewindow, l
bind = $mainMod SHIFT, RIGHT, movewindow, r
bind = $mainMod SHIFT, UP, movewindow, u
bind = $mainMod SHIFT, DOWN, movewindow, d

# Screenshots
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy
HYPR

echo "==> Writing Waybar configuration..."

cat > "$HOME/.config/waybar/config" <<'WAYBAR'
{
    "layer": "top",
    "position": "top",
    "height": 34,
    "spacing": 8,

    "modules-left": ["hyprland/workspaces", "hyprland/window"],
    "modules-center": ["clock"],
    "modules-right": [
        "network",
        "pulseaudio",
        "cpu",
        "memory",
        "battery",
        "tray"
    ],

    "hyprland/workspaces": {
        "format": "{name}",
        "on-click": "activate",
        "sort-by-number": true
    },

    "hyprland/window": {
        "max-length": 45,
        "separate-outputs": true
    },

    "clock": {
        "format": "  {:%a %d %b  %H:%M}  ",
        "tooltip-format": "{:%A, %d %B %Y}"
    },

    "network": {
        "format-wifi": " Wi-Fi {signalStrength}%",
        "format-ethernet": " Ethernet",
        "format-disconnected": " Offline",
        "tooltip": true
    },

    "pulseaudio": {
        "format": " Vol {volume}%",
        "format-muted": " Muted",
        "on-click": "pavucontrol"
    },

    "cpu": {
        "format": " CPU {usage}%"
    },

    "memory": {
        "format": " RAM {}%"
    },

    "battery": {
        "format": " Battery {capacity}%",
        "format-charging": " Charging {capacity}%"
    },

    "tray": {
        "spacing": 8
    }
}
WAYBAR

echo "==> Writing Waybar styling..."

cat > "$HOME/.config/waybar/style.css" <<'CSS'
* {
    font-family: "DejaVu Sans", sans-serif;
    font-size: 12px;
    min-height: 0;
}

window#waybar {
    background: rgba(24, 24, 37, 0.88);
    color: #cdd6f4;
    border-bottom: 2px solid #89b4fa;
}

#workspaces,
#window,
#clock,
#network,
#pulseaudio,
#cpu,
#memory,
#battery,
#tray {
    padding: 0 10px;
    margin: 4px 3px;
    border-radius: 8px;
}

#workspaces button {
    color: #cdd6f4;
    padding: 0 7px;
    border-radius: 6px;
}

#workspaces button.active {
    color: #11111b;
    background: #89b4fa;
}

#workspaces button:hover {
    background: #45475a;
    box-shadow: none;
}

#clock {
    color: #cba6f7;
    font-weight: bold;
}

#network,
#pulseaudio {
    color: #a6e3a1;
}
CSS

echo "==> Writing Wofi styling..."

cat > "$HOME/.config/wofi/style.css" <<'CSS'
window {
    background-color: #1e1e2e;
    border: 2px solid #89b4fa;
    border-radius: 12px;
}

#input {
    margin: 10px;
    padding: 8px;
    color: #cdd6f4;
    background-color: #313244;
    border: none;
    border-radius: 8px;
}

#inner-box {
    margin: 5px;
}

#entry {
    padding: 8px;
    color: #cdd6f4;
    border-radius: 8px;
}

#entry:selected {
    background-color: #45475a;
    color: #89b4fa;
}

#text {
    margin: 4px;
}
CSS

echo "==> Writing Mako notification styling..."

cat > "$HOME/.config/mako/config" <<'MAKO'
font=DejaVu Sans 10
background-color=#1e1e2e
text-color=#cdd6f4
border-color=#89b4fa
border-size=2
border-radius=10
padding=12
default-timeout=5000
ignore-timeout=0
width=350
height=120
margin=12
MAKO

echo "==> Installing optional utilities..."

# Thunar and pavucontrol are used by the configuration above.
sudo apt-get install -y thunar pavucontrol

echo
echo "=========================================="
echo " Hyprland installation and setup finished"
echo "=========================================="
echo
echo "Log out of GNOME, then select Hyprland"
echo "from the login screen's session menu."
echo
echo "Shortcuts:"
echo "  Super + Q       Open terminal"
echo "  Super + R       Application launcher"
echo "  Super + E       File manager"
echo "  Super + C       Close window"
echo "  Super + V       Toggle floating"
echo "  Super + F       Fullscreen"
echo "  Super + M       Exit Hyprland"
echo "  Print           Screenshot selection"
echo
echo "Your GNOME desktop has not been removed."
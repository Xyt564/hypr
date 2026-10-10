#!/usr/bin/env bash
set -Eeuo pipefail

# Hyprland setup for minimal Arch Linux
# Graphics: AMD / Intel
# Includes: animations, blur, Waybar, Wofi, Foot, Mako
# Login: greetd + tuigreet
# No GNOME or other full desktop environment

if [[ $EUID -eq 0 ]]; then
    echo "Please run this script as your normal user, not root."
    exit 1
fi

if [[ ! -f /etc/arch-release ]]; then
    echo "This script is intended for Arch Linux."
    exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
    echo "Install sudo and configure permissions for your user first."
    exit 1
fi

echo "==> Updating Arch Linux..."
sudo pacman -Syu

echo "==> Installing Hyprland and desktop utilities..."

packages=(
    hyprland
    hyprpolkitagent
    greetd
    greetd-tuigreet
    waybar
    wofi
    foot
    mako
    thunar
    gvfs
    tumbler
    pavucontrol
    xorg-xwayland
    xdg-desktop-portal
    xdg-desktop-portal-hyprland
    xdg-desktop-portal-gtk
    pipewire
    pipewire-audio
    pipewire-pulse
    wireplumber
    networkmanager
    network-manager-applet
    polkit
    grim
    slurp
    wl-clipboard
    brightnessctl
    qt5-wayland
    qt6-wayland
    noto-fonts
    noto-fonts-emoji
    ttf-dejavu
    ttf-liberation
    papirus-icon-theme
    adwaita-icon-theme
)

sudo pacman -S --needed "${packages[@]}"

echo "==> Creating configuration directories..."

mkdir -p \
    "$HOME/.config/hypr" \
    "$HOME/.config/waybar" \
    "$HOME/.config/wofi" \
    "$HOME/.config/mako"

# Back up existing configuration files.
backup_dir="$HOME/.config/hypr-setup-backup-$(date +%Y%m%d%H%M%S)"
backup_needed=false

for file in \
    "$HOME/.config/hypr/hyprland.conf" \
    "$HOME/.config/waybar/config" \
    "$HOME/.config/waybar/style.css" \
    "$HOME/.config/wofi/style.css" \
    "$HOME/.config/mako/config"; do
    if [[ -f "$file" ]]; then
        mkdir -p "$backup_dir"
        backup_needed=true
        cp -a "$file" "$backup_dir/"
    fi
done

if [[ "$backup_needed" == true ]]; then
    echo "Previous configurations backed up to $backup_dir"
fi

echo "==> Writing Hyprland configuration..."

cat > "$HOME/.config/hypr/hyprland.conf" <<'HYPR'
# Monitor
monitor = , preferred, auto, 1

# Environment
env = XCURSOR_SIZE,24
env = XDG_CURRENT_DESKTOP,Hyprland
env = XDG_SESSION_TYPE,wayland
env = XDG_SESSION_DESKTOP,Hyprland
env = QT_QPA_PLATFORM,wayland

# Keyboard and touchpad
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

# Rounded corners, shadows, blur
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

# Tiling
dwindle {
    pseudotile = true
    preserve_split = true
}

# Applications
$mainMod = SUPER
$terminal = foot
$fileManager = thunar
$menu = wofi --show drun

# Startup applications and services
exec-once = waybar
exec-once = mako
exec-once = nm-applet --indicator
exec-once = systemctl --user start hyprpolkitagent
exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE

# Keyboard shortcuts
bind = $mainMod, Q, exec, $terminal
bind = $mainMod, R, exec, $menu
bind = $mainMod, E, exec, $fileManager
bind = $mainMod, C, killactive
bind = $mainMod, M, exit
bind = $mainMod, V, togglefloating
bind = $mainMod, F, fullscreen
bind = $mainMod, P, pseudo
bind = $mainMod, J, togglesplit

# Workspaces
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

# Focus windows
bind = $mainMod, LEFT, movefocus, l
bind = $mainMod, RIGHT, movefocus, r
bind = $mainMod, UP, movefocus, u
bind = $mainMod, DOWN, movefocus, d

# Move windows
bind = $mainMod SHIFT, LEFT, movewindow, l
bind = $mainMod SHIFT, RIGHT, movewindow, r
bind = $mainMod SHIFT, UP, movewindow, u
bind = $mainMod SHIFT, DOWN, movewindow, d

# Screenshots
bind = , Print, exec, grim -g "$(slurp)" - | wl-copy

# Volume controls
bind = , XF86AudioRaiseVolume, exec, wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+
bind = , XF86AudioLowerVolume, exec, wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-
bind = , XF86AudioMute, exec, wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle

# Brightness controls
bind = , XF86MonBrightnessUp, exec, brightnessctl set +10%
bind = , XF86MonBrightnessDown, exec, brightnessctl set 10%-

# Session controls
bind = $mainMod SHIFT, Q, exit
HYPR

echo "==> Writing Waybar configuration..."

cat > "$HOME/.config/waybar/config" <<'WAYBAR'
{
    "layer": "top",
    "position": "top",
    "height": 34,
    "spacing": 8,

    "modules-left": [
        "hyprland/workspaces",
        "hyprland/window"
    ],

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

echo "==> Writing Mako configuration..."

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

echo "==> Configuring greetd login..."

sudo install -d -m 755 /etc/greetd

# Back up the previous greetd configuration if present.
if [[ -f /etc/greetd/config.toml ]]; then
    sudo cp -a /etc/greetd/config.toml \
        "/etc/greetd/config.toml.backup.$(date +%Y%m%d%H%M%S)"
fi

sudo tee /etc/greetd/config.toml >/dev/null <<'GREETD'
[terminal]
vt = 1

[default_session]
command = "tuigreet --time --remember --cmd start-hyprland"
user = "greeter"
GREETD

echo "==> Enabling essential services..."

# NetworkManager
sudo systemctl enable NetworkManager.service

# Start audio services automatically for the user session.
systemctl --user enable pipewire.service pipewire-pulse.service wireplumber.service || true

# Start the login manager at boot.
sudo systemctl enable greetd.service

echo
echo "=========================================="
echo " Hyprland installation finished"
echo "=========================================="
echo
echo "A reboot is recommended."
echo "The greetd login screen will launch at boot."
echo
echo "Login with your normal Arch Linux username."
echo
echo "Shortcuts:"
echo "  Super + Q       Terminal"
echo "  Super + R       Application launcher"
echo "  Super + E       File manager"
echo "  Super + C       Close window"
echo "  Super + V       Toggle floating"
echo "  Super + F       Fullscreen"
echo "  Super + M       Exit Hyprland"
echo "  Print           Screenshot selection"
echo "  Super + Shift + Q  Exit Hyprland"
echo
echo "Reboot with: sudo reboot"

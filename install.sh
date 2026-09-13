#!/usr/bin/env bash

set -euo pipefail

if [[ $EUID -eq 0 ]]; then
    echo "Do not run this installer as root."
    echo "Run it as your normal user. sudo will be requested when required."
    exit 1
fi

if [[ ! -r /etc/os-release ]]; then
    echo "Error: /etc/os-release could not be read."
    exit 1
fi

source /etc/os-release

if [[ ${ID:-} != "fedora" || ${VERSION_ID:-} != "44" ]]; then
    echo "Error: This installer currently supports Fedora 44 only."
    exit 1
fi

ARCH="$(uname -m)"

if [[ "$ARCH" != "x86_64" ]]; then
    echo "Error: This installer currently supports x86_64 systems only."
    exit 1
fi

INSTALL_USER="$(id -un)"

REPO_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
    pwd
)"

echo "Fedora 44 detected."
echo "Repository: $REPO_DIR"
echo "User: $INSTALL_USER"
echo "Home: $HOME"

echo
echo "==> Creating user directories..."

mkdir -p \
    "$HOME/Pictures/Screenshot" \
    "$HOME/.local/bin" \
    "$HOME/.local/share/applications"
echo

echo "==> Installing DNF COPR support..."
sudo dnf install -y dnf5-plugins

echo
echo "==> Enabling COPR repositories..."

mapfile -t COPRS < <(
    grep -Ev '^[[:space:]]*(#|$)' "$REPO_DIR/packages/copr.txt"
)

for copr in "${COPRS[@]}"; do
    echo "Enabling COPR: $copr"
    sudo dnf copr enable -y "$copr"
done

echo
echo "==> Installing DNF packages..."

mapfile -t DNF_PACKAGES < <(
    grep -Ev '^[[:space:]]*(#|$)' "$REPO_DIR/packages/dnf.txt"
)

sudo dnf install -y "${DNF_PACKAGES[@]}"

echo
echo "==> Configuring Flathub..."

flatpak remote-add --user --if-not-exists \
    flathub \
    https://dl.flathub.org/repo/flathub.flatpakrepo

echo
echo "==> Installing Flatpak applications..."

mapfile -t FLATPAK_APPS < <(
    grep -Ev '^[[:space:]]*(#|$)' "$REPO_DIR/packages/flatpak.txt"
)

for app in "${FLATPAK_APPS[@]}"; do
    if flatpak list --app --columns=application | grep -Fxq "$app"; then
        echo "Flatpak already installed: $app"
    else
        echo "Installing Flatpak: $app"
        flatpak install --user -y flathub "$app"
    fi
done

echo
echo "==> Installing Satty..."

SATTY_VERSION="$(
    grep '^version=' "$REPO_DIR/packages/satty.txt" | cut -d= -f2-
)"

SATTY_URL="$(
    grep '^url=' "$REPO_DIR/packages/satty.txt" | cut -d= -f2-
)"

SATTY_SHA256="$(
    grep '^sha256=' "$REPO_DIR/packages/satty.txt" | cut -d= -f2-
)"

if flatpak list --app --columns=application | grep -Fxq "org.satty.Satty"; then
    echo "Satty already installed."
else
    echo "Downloading Satty $SATTY_VERSION..."

    SATTY_TMP_DIR="$(mktemp -d)"
    SATTY_BUNDLE="$SATTY_TMP_DIR/satty.flatpak"

    curl -L --fail --silent --show-error \
        -o "$SATTY_BUNDLE" \
        "$SATTY_URL"

    echo "$SATTY_SHA256  $SATTY_BUNDLE" | sha256sum -c -

    flatpak install --user -y --bundle "$SATTY_BUNDLE"

    rm -rf "$SATTY_TMP_DIR"
fi

echo
echo "==> Installing StyLua..."

STYLUA_VERSION="$(
    grep '^version=' "$REPO_DIR/packages/stylua.txt" | cut -d= -f2-
)"

STYLUA_URL="$(
    grep '^url=' "$REPO_DIR/packages/stylua.txt" | cut -d= -f2-
)"

STYLUA_SHA256="$(
    grep '^sha256=' "$REPO_DIR/packages/stylua.txt" | cut -d= -f2-
)"

mkdir -p "$HOME/.local/bin"

if command -v stylua >/dev/null 2>&1 \
    && [[ "$(stylua --version)" == "stylua $STYLUA_VERSION" ]]; then
    echo "StyLua $STYLUA_VERSION already installed."
else
    echo "Downloading StyLua $STYLUA_VERSION..."

    STYLUA_TMP_DIR="$(mktemp -d)"
    STYLUA_ARCHIVE="$STYLUA_TMP_DIR/stylua.zip"

    curl -L --fail --silent --show-error \
        -o "$STYLUA_ARCHIVE" \
        "$STYLUA_URL"

    echo "$STYLUA_SHA256  $STYLUA_ARCHIVE" | sha256sum -c -

    unzip -q "$STYLUA_ARCHIVE" -d "$STYLUA_TMP_DIR"

    install -m 0755 \
        "$STYLUA_TMP_DIR/stylua" \
        "$HOME/.local/bin/stylua"

    rm -rf "$STYLUA_TMP_DIR"
fi

echo
echo "==> Installing wallpaper..."

WALLPAPER_URL="$(
    grep '^url=' "$REPO_DIR/assets/wallpaper.txt" | cut -d= -f2-
)"

WALLPAPER_SHA256="$(
    grep '^sha256=' "$REPO_DIR/assets/wallpaper.txt" | cut -d= -f2-
)"

WALLPAPER_DIR="$HOME/.local/share/fedora-hyprland/wallpapers"
WALLPAPER_PATH="$WALLPAPER_DIR/wallhaven-lydwyy.jpg"

mkdir -p "$WALLPAPER_DIR"

if [[ -f "$WALLPAPER_PATH" ]] \
    && echo "$WALLPAPER_SHA256  $WALLPAPER_PATH" | sha256sum -c --status; then
    echo "Wallpaper already installed."
else
    echo "Downloading wallpaper..."

    WALLPAPER_TMP="$(mktemp)"

    curl -L --fail --silent --show-error \
        -o "$WALLPAPER_TMP" \
        "$WALLPAPER_URL"

    echo "$WALLPAPER_SHA256  $WALLPAPER_TMP" | sha256sum -c -

    install -m 0644 \
        "$WALLPAPER_TMP" \
        "$WALLPAPER_PATH"

    rm -f "$WALLPAPER_TMP"
fi

echo
echo "==> Installing user configuration..."

mkdir -p "$HOME/.config"

for config_dir in "$REPO_DIR"/config/*; do
    config_name="$(basename "$config_dir")"

    echo "Installing config: $config_name"

    mkdir -p "$HOME/.config/$config_name"
    cp -a "$config_dir/." "$HOME/.config/$config_name/"
done

echo
echo "==> Installing desktop applications..."

APPLICATION_DIR="$HOME/.local/share/applications"

mkdir -p "$APPLICATION_DIR"

for desktop_file in "$REPO_DIR"/applications/*.desktop; do
    echo "Installing desktop entry: $(basename "$desktop_file")"

    install -m 0644 \
        "$desktop_file" \
        "$APPLICATION_DIR/$(basename "$desktop_file")"
done

echo
echo "==> Configuring user services..."

USER_SYSTEMD_DIR="$HOME/.config/systemd/user"

mkdir -p "$USER_SYSTEMD_DIR"

install -m 0644 \
    "$REPO_DIR/systemd/user/quickshell.service" \
    "$USER_SYSTEMD_DIR/quickshell.service"

systemctl --user daemon-reload

USER_SERVICES=(
    hypridle.service
    hyprpaper.service
    hyprpolkitagent.service
    mako.service
    quickshell.service
)

for service in "${USER_SERVICES[@]}"; do
    echo "Enabling user service: $service"
    systemctl --user enable "$service"
done

echo
echo "==> Configuring TTY1 autologin..."

TTY1_OVERRIDE_DIR="/etc/systemd/system/getty@tty1.service.d"
TTY1_TEMPLATE="$REPO_DIR/systemd/system/getty@tty1.service.d/override.conf.template"

TTY1_TMP="$(mktemp)"

sed "s/@USER@/$INSTALL_USER/g" \
    "$TTY1_TEMPLATE" \
    > "$TTY1_TMP"

sudo mkdir -p "$TTY1_OVERRIDE_DIR"

sudo install -m 0644 \
    "$TTY1_TMP" \
    "$TTY1_OVERRIDE_DIR/override.conf"

rm -f "$TTY1_TMP"

sudo systemctl daemon-reload
sudo systemctl enable getty@tty1.service

echo
echo "==> Configuring login shell..."

FISH_PATH="$(command -v fish)"
CURRENT_SHELL="$(
     getent passwd "$INSTALL_USER" | cut -d: -f7
)"

if ! grep -Fxq "$FISH_PATH" /etc/shells; then
    echo "Error: $FISH_PATH is not listed in /etc/shells."
    exit 1
fi

if [[ "$CURRENT_SHELL" == "$FISH_PATH" ]]; then
    echo "Fish is already the login shell."
else
    echo "Setting Fish as login shell..."
    sudo usermod --shell "$FISH_PATH" "$INSTALL_USER"
fi

echo
echo "==> Configuring Plymouth..."

PLYMOUTH_THEME="catppuccin-macchiato"
PLYMOUTH_SOURCE="$REPO_DIR/assets/plymouth/$PLYMOUTH_THEME"
PLYMOUTH_DEST="/usr/share/plymouth/themes/$PLYMOUTH_THEME"

PLYMOUTH_CHANGED=false

if [[ ! -d "$PLYMOUTH_DEST" ]] \
    || ! diff -qr "$PLYMOUTH_SOURCE" "$PLYMOUTH_DEST" >/dev/null 2>&1; then
    echo "Installing Plymouth theme..."

    sudo mkdir -p "$PLYMOUTH_DEST"
    sudo cp -a "$PLYMOUTH_SOURCE/." "$PLYMOUTH_DEST/"

    PLYMOUTH_CHANGED=true
fi

CURRENT_PLYMOUTH_THEME="$(plymouth-set-default-theme)"

if [[ "$CURRENT_PLYMOUTH_THEME" != "$PLYMOUTH_THEME" ]] \
    || [[ "$PLYMOUTH_CHANGED" == true ]]; then
    echo "Setting Plymouth theme: $PLYMOUTH_THEME"
    sudo plymouth-set-default-theme "$PLYMOUTH_THEME" --rebuild-initrd
else
    echo "Plymouth theme already configured."
fi

echo
echo "==> Configuring GRUB..."

if sudo grub2-editenv - list | grep -Fxq "menu_auto_hide=1"; then
    echo "GRUB menu auto-hide already enabled."
else
    echo "Enabling GRUB menu auto-hide..."
    sudo grub2-editenv - set menu_auto_hide=1
fi

echo
echo "==> Configuring btop CPU power monitoring..."

BTOP_PATH="$(command -v btop)"
BTOP_CAPS="cap_dac_read_search,cap_perfmon=ep"

CURRENT_BTOP_CAPS="$(
    getcap "$BTOP_PATH" | cut -d' ' -f2-
)"

if [[ "$CURRENT_BTOP_CAPS" == "$BTOP_CAPS" ]]; then
    echo "btop capabilities already configured."
else
    echo "Granting btop access to CPU power information..."
    sudo setcap 'cap_perfmon,cap_dac_read_search=ep' "$BTOP_PATH"
fi

echo
echo "==> Configuring default file manager..."

CURRENT_DIRECTORY_HANDLER="$(
    xdg-mime query default inode/directory || true
)"

if [[ "$CURRENT_DIRECTORY_HANDLER" == "yazi.desktop" ]]; then
    echo "Yazi is already the default directory handler."
else
    echo "Setting Yazi as the default directory handler..."
    xdg-mime default yazi.desktop inode/directory
fi

echo
echo "==> Configuring power profiles..."

if systemctl is-enabled --quiet power-profiles-daemon.service; then
    echo "power-profiles-daemon is already enabled."
else
    echo "Enabling power-profiles-daemon..."
    sudo systemctl enable power-profiles-daemon.service
fi

echo
echo "==> Configuring Bluetooth..."

if systemctl is-enabled --quiet bluetooth.service; then
    echo "Bluetooth service is already enabled."
else
    echo "Enabling Bluetooth service..."
    sudo systemctl enable bluetooth.service
fi

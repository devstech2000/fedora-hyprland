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

REPO_DIR="$(
    cd -- "$(dirname -- "${BASH_SOURCE[0]}")"
    pwd
)"

echo "Fedora 44 detected."
echo "Repository: $REPO_DIR"
echo "User: $USER"
echo "Home: $HOME"

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

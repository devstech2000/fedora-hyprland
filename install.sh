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

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

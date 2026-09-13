# Fedora Hyprland Setup

A reproducible Fedora 44 setup built around Hyprland, Quickshell and a small set of carefully selected tools.

This repository contains the configuration files and installer I use for my own desktop environment. The goal is not to provide a prebuilt distribution or a generic dotfiles framework, but a transparent Fedora setup that can be inspected, understood and adapted.

## Goals

- Keep the system small and understandable
- Prefer Fedora packages where possible
- Use external repositories only when required
- Keep configuration files directly readable and editable
- Avoid large preconfigured desktop frameworks
- Make a fresh Fedora installation reproducible
- Keep personal files, credentials and application data out of the repository

## Requirements

This installer currently targets:

- Fedora 44
- x86_64 systems
- A normal non-root user
- An internet connection
- A Fedora installation with `sudo` access

The installer intentionally refuses to run as root.

## Main Components

- **Window manager:** Hyprland
- **Desktop shell:** Quickshell
- **Terminal:** Kitty
- **Shell:** Fish
- **Application launcher:** Rofi
- **Notifications:** Mako
- **File manager:** Yazi
- **Editor:** Neovim
- **System monitor:** btop
- **Lock screen:** Hyprlock
- **Idle management:** Hypridle
- **Wallpaper:** Hyprpaper
- **Audio:** PipeWire + WirePlumber
- **Bluetooth:** BlueZ
- **Boot splash:** Plymouth with Catppuccin Macchiato
- **Browser:** Google Chrome via Flatpak
- **Music:** Spotify via Flatpak
- **Screenshot workflow:** Grim + Slurp + Satty

## Installation

> [!WARNING]
> This installer makes system-level changes and is intended for a fresh Fedora 44 installation. Review `install.sh` before running it.

Clone the repository:

```bash
git clone https://github.com/devstech2000/fedora-hyprland.git
cd fedora-hyprland
```

Run the installer as your normal user:

```bash
./install.sh
```

Do not run the installer with `sudo`. It requests elevated privileges only for the individual operations that require them.

After the installer finishes successfully, reboot the system:

```bash
systemctl reboot
```

On the next boot, the system logs into TTY1 automatically and starts Hyprland through Fish and UWSM.

### Existing configuration files

The installer may replace configuration files managed by this repository.

If an existing configuration differs from the version provided by the repository, it is backed up before being replaced. This makes rerunning the installer safer on an already configured system, but reviewing the installer before using it on an existing installation is still recommended.

## What the Installer Does

The installer performs the following steps:

- Verifies that the system is Fedora 44 on x86_64
- Installs required DNF packages
- Enables the required COPR repositories
- Configures Flathub
- Installs Google Chrome and Spotify through Flatpak
- Installs the pinned Satty Flatpak bundle after verifying its SHA-256 checksum
- Installs the pinned StyLua binary after verifying its SHA-256 checksum
- Downloads the configured wallpaper and verifies its SHA-256 checksum
- Installs the repository configuration files into `~/.config`
- Backs up differing existing user configuration before replacing it
- Installs custom desktop entries for Chrome and Yazi
- Enables the required user services
- Configures TTY1 autologin for the current user
- Sets Fish as the login shell
- Sets `multi-user.target` as the default systemd target
- Configures Plymouth with the Catppuccin Macchiato theme
- Enables GRUB menu auto-hide
- Configures the capabilities required for btop CPU power monitoring
- Sets Yazi as the default directory handler
- Enables `power-profiles-daemon`
- Enables Bluetooth
- Configures the system so Hyprland starts through UWSM after TTY1 login

The installer is designed to be rerunnable. Operations that are already configured are skipped where practical.

## Display Configuration

The Hyprland configuration contains dedicated rules for my LG UltraFine and Arzopa displays.

Unknown monitors and laptop displays fall back to:

- Preferred resolution
- Automatic positioning
- Automatic scaling

This allows the setup to start on other hardware without requiring the same monitor connector names.

If you want to customize the layout, edit:

```text
~/.config/hypr/hyprland.lua
```

## Package Sources

Most packages are installed from the Fedora repositories.

The setup additionally uses these COPR repositories:

- `lionheartp/Hyprland` for Hyprland
- `lihaohong/yazi` for Yazi

Google Chrome and Spotify are installed through Flathub.

Satty is installed from a pinned Flatpak bundle and StyLua from a pinned upstream release. Both downloads are verified using SHA-256 checksums before installation.

## Chrome Video Decode Workaround

The Chrome configuration currently disables accelerated video decoding using `--disable-features=AcceleratedVideoDecoder`.

This is a workaround for video rendering artifacts observed with hardware video decoding on the AMD Radeon 780M.

The workaround is applied both to the Hyprland browser keybind and the custom Chrome desktop entry.

It can be removed if the underlying video decoding issue is fixed in a future Chrome or Mesa release.

## Wallpaper

The wallpaper itself is not included in this repository.

Instead, `assets/wallpaper.txt` contains the download URL and SHA-256 checksum. The installer downloads and verifies the wallpaper during setup.

## Session Startup

This setup intentionally does not use a display manager.

The startup flow is:

```text
systemd multi-user.target
        ↓
TTY1 autologin
        ↓
Fish login shell
        ↓
UWSM
        ↓
Hyprland
```

The installer configures TTY1 autologin for the user who runs the installer and sets Fish as that user's login shell.

Hyprland is started through UWSM from the Fish login configuration when logging in on TTY1.

> [!IMPORTANT]
> TTY1 autologin removes the normal console login prompt. Disk encryption and physical access security are separate concerns and are not configured by this repository.

## Notes

- The setup is designed primarily around my own Fedora workstation but includes a generic monitor fallback for other displays.
- Existing differing user configuration is backed up before replacement.
- The installer can be rerun and skips already configured operations where practical.
- The repository intentionally does not contain personal application data, credentials or private files.
- Some components are installed from COPR or upstream releases where the Fedora repositories do not provide the required setup.
- The Chrome accelerated video decoding workaround is hardware-specific and may not be necessary on other systems.

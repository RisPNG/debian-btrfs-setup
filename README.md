# Debian 13 "Trixie" GNOME Post-Installation Setup

This guide provides a comprehensive set of steps to configure a fresh Debian 13 "Trixie" GNOME installation from the live ISO. It covers everything from the initial setup to system updates, application installations, and theming.

These are my personal dotfiles and preferences. You're responsible for what you do with your system.

## Sections

1.  [Initial Installation](#initial-installation)
2.  [System Preparation](#system-preparation)
3.  [Package Installation](#package-installation)
4.  [System Configuration](#system-configuration)
5.  [Finalization](#finalization)

## Initial Installation

First, you gotta boot from the `debian-live-13.0.0-amd64-gnome.iso`.

1.  Start the "Live system (amd64)".
2.  Skip the initial tour and connect to a network through `Settings`.
3.  Run the "Install Debian" application.
4.  Follow the Calamares installer prompts:
    *   Language: "American English" (Default)
    *   Location: "Asia", "Kuala Lumpur", with locale "en\_GB.UTF-8"
    *   Keyboard: "English (US)", "Default"
5.  For partitioning, choose "Manual Partitioning":
    *   Create a "New Partition Table" with the "GPT" scheme.
    *   Create a 1024 MiB `fat32` partition for `/boot/efi` and set the `boot` flag.
    *   Create a `btrfs` partition using the remaining space for the root directory (`/`).
6.  Proceed to set up your user account and complete the installation.
7.  Once you've booted into your new system, it's a good idea to install `timeshift` and create your first "Perfect installation" snapshot as a backup.

## System Preparation

### System Update

Let's get your system up-to-date.

```bash
sudo apt update && sudo apt modernize-sources -y && sudo apt update && sudo apt upgrade -y && sudo apt full-upgrade -y && sudo apt dist-upgrade -y
```

### Timeshift and GRUB Snapshots

This will allow you to have bootable snapshots in your GRUB menu. Super useful if an update breaks something.

```bash
sudo apt install timeshift git -y
cd ~/Documents
mkdir Git
cd Git
git clone https://github.com/Antynea/grub-btrfs.git
cd grub-btrfs
sudo make install
sudo systemctl start grub-btrfsd
sudo systemctl enable grub-btrfsd
```

### Debloat Default Applications

Trimming the fat. Feel free to customize this list to your liking.

```bash
sudo apt purge gnome-calculator gnome-contacts gnome-calendar gnome-terminal evolution fcitx5 gnome-font-viewer goldendict-ng loupe gnome-music malcontent shotwell thunderbird gnome-tour totem gnome-weather xiterm+thai kasumi -y && sudo apt update && sudo apt autoclean -y && sudo apt autopurge -y && sudo apt autoremove -y && sudo apt clean -y
```

### Add `contrib`, `non-free`, and `non-free-firmware` Repositories

You'll need these for drivers and other proprietary software.

```bash
sudo tee -a /etc/apt/sources.list.d/debian.sources <<EOF

Types: deb
URIs: http://deb.debian.org/debian/
Suites: trixie
Components: main contrib non-free non-free-firmware
Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg
EOF
sudo apt update
sudo apt install linux-headers-$(uname -r) -y
```

### NVIDIA Driver (Secure Boot Off)

If you're rockin' an NVIDIA card, this one's for you. Make a Timeshift snapshot before proceeding, just in case.

```bash
sudo apt install nvidia-kernel-dkms nvidia-driver firmware-misc-nonfree -y
```

Now, it's time for a reboot.

```bash
sudo reboot -h 0
```

## Package Installation

### Main Packages (Native)

Here's a list of essential applications and tools installed via `apt`.

```bash
sudo apt install git wget gnome-shell-extension-apps-menu gnome-boxes gnome-snapshot gnome-characters gnome-clocks gnome-console gnome-disk-utility baobab gnome-shell-extension-manager gnome-shell-extension-prefs fastfetch file-roller font-manager gnome-tweaks libreoffice gnome-logs seahorse remmina gnome-connections gnome-sound-recorder gnome-system-monitor gnome-text-editor qbittorrent wine evince epiphany-browser nomacs-l10n diodon yt-dlp mpv libmpv-dev aptitude mc ncdu ddccontrol gddccontrol ddccontrol-db i2c-tools curl ca-certificates qalculate-gtk gir1.2-gnomedesktop-3.0 -y
sudo modprobe i2c-dev
sudo gpasswd -a "$USER" i2c
```

### Flatpaks

Gotta have Flatpak for that extra software availability.

```bash
sudo apt install flatpak gnome-software-plugin-flatpak -y
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo
flatpak install flathub com.usebottles.bottles org.gnome.meld it.mijorus.gearlever io.github.flattool.Warehouse com.bitwarden.desktop org.pgadmin.pgadmin4 -y
```

### Development Tools and `mise`

Setting up the environment for development work.

```bash
sudo apt install autoconf build-essential curl flex fop gcc git icu-devtools inotify-tools libcurl4-openssl-dev libedit-dev libgl1-mesa-dev libglu1-mesa-dev libicu-dev libncurses-dev libpam0g-dev libpng-dev libreadline-dev libssh-dev libssl-dev libwxgtk-webview3.2-dev libwxgtk3.2-dev libxml2-dev libxml2-utils libxslt1-dev m4 make unixodbc-dev unzip uuid-dev xsltproc zlib1g-dev bison -y
wget -O ~/Downloads/libssl1_1.deb http://security.debian.org/debian-security/pool/updates/main/o/openssl/libssl1.1_1.1.1w-0+deb11u3_amd64.deb && sudo apt install ~/Downloads/libssl1_1.deb -y
wget -O ~/Downloads/wkhtmltopdf.deb https://github.com/wkhtmltopdf/packaging/releases/download/0.12.6.1-2/wkhtmltox_0.12.6.1-2.bullseye_amd64.deb && sudo apt install ~/Downloads/wkhtmltopdf.deb -y

curl https://mise.run | sh
echo "eval \"\$(/home/$USER/.local/bin/mise activate bash)\"" >> ~/.bashrc
source ~/.bashrc
git config --global credential.helper store
mise use --global python@3.10
mise use --global rust@latest
mise use --global go@latest
mise use --global java@latest
mise use --global node@latest
```

### Additional Software (`.deb` Packages and Others)

These are installed from various sources.

<details>
<summary>Click to expand application installation commands</summary>

**Fonts**
```bash
sudo apt install fonts-* --no-install-recommends --no-install-suggests -y
```

**Waydroid**
```bash
curl -s https://repo.waydro.id | sudo bash
sudo apt install waydroid -y
```

**ONLYOFFICE**
```bash
wget -O ~/Downloads/onlyoffice.deb https://github.com/ONLYOFFICE/DesktopEditors/releases/latest/download/onlyoffice-desktopeditors_amd64.deb && sudo apt install ~/Downloads/onlyoffice.deb -y
```

**LocalSend**
```bash
wget $(curl -s https://api.github.com/repos/localsend/localsend/releases/latest | jq -r '.assets[] | select(.name | endswith("x86-64.deb")) | .browser_download_url') -O ~/Downloads/localsend-latest.deb && sudo apt install ~/Downloads/localsend-latest.deb -y
```

**Prospect Mail (Outlook Client)**
```bash
wget $(curl -s https://api.github.com/repos/julian-alarcon/prospect-mail/releases/latest | jq -r '.assets[] | select(.name | endswith("amd64.deb")) | .browser_download_url') -O ~/Downloads/prospect-mail-latest.deb && sudo apt install ~/Downloads/prospect-mail-latest.deb -y
```

**Ente Auth**
```bash
wget $(curl -s https://api.github.com/repos/ente-io/ente/releases | jq -r '[.[] | select(.tag_name | contains("auth"))][0].assets[] | select(.name | endswith("x86_64.deb")) | .browser_download_url') -O ~/Downloads/ente-auth-latest.deb && sudo apt install ~/Downloads/ente-auth-latest.deb -y
```

**Teams for Linux**
```bash
wget $(curl -s https://api.github.com/repos/IsmaelMartinez/teams-for-linux/releases/latest | jq -r '.assets[] | select(.name | endswith("amd64.deb")) | .browser_download_url') -O ~/Downloads/teams-latest.deb && sudo apt install ~/Downloads/teams-latest.deb -y
sudo tee /usr/share/applications/teams-for-linux.desktop > /dev/null <<'EOF'
[Desktop Entry]
Name=Teams
Exec=/opt/teams-for-linux/teams-for-linux %U --isCustomBackgroundEnabled=true --customBGServiceBaseUrl=https://raw.githubusercontent.com/RisPNG/SIG-Resources/main
Terminal=false
Type=Application
Icon=teams-for-linux
StartupWMClass=teams-for-linux
Comment=Unofficial Microsoft Teams client for Linux using Electron. It uses the Web App and wraps it as a standalone application using Electron.
MimeType=x-scheme-handler/msteams;
Categories=Chat;Network;Office;
EOF
```

**Sunshine**
```bash
wget -qO ~/Downloads/libicu72_72.1-3+deb12u1_amd64.deb http://security.debian.org/debian-security/pool/updates/main/i/icu/libicu72_72.1-3+deb12u1_amd64.deb && sudo apt install ~/Downloads/libicu72_72.1-3+deb12u1_amd64.deb -y
wget -qO ~/Downloads/libminiupnpc17_2.2.4-1+b1_amd64.deb http://ftp.debian.org/debian/pool/main/m/miniupnpc/libminiupnpc17_2.2.4-1+b1_amd64.deb && sudo apt install ~/Downloads/libminiupnpc17_2.2.4-1+b1_amd64.deb -y
wget $(curl -s https://api.github.com/repos/LizardByte/Sunshine/releases/latest | jq -r '.assets[] | select(.name | contains("debian") and endswith("amd64.deb")) | .browser_download_url') -O ~/Downloads/sunshine-latest.deb && sudo apt install ~/Downloads/sunshine-latest.deb -y
sudo setcap cap_sys_admin+p $(readlink -f $(which sunshine))
```

**Visual Studio Code**
```bash
wget -O ~/Downloads/vscode.deb "https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64" && sudo apt install ~/Downloads/vscode.deb -y
```

**Lutris**
```bash
echo 'deb http://download.opensuse.org/repositories/home:/strycore/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/home:strycore.list
curl -fsSL https://download.opensuse.org/repositories/home:strycore/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_strycore.gpg > /dev/null
sudo apt update
sudo apt install lutris -y
```

**ZeroTier**
```bash
curl -s https://install.zerotier.com | sudo bash
sudo systemctl enable zerotier-one --now
```

**MPV Media Player + uosc Plugin**
```bash
sudo curl --output-dir /etc/apt/trusted.gpg.d -O https://apt.fruit.je/fruit.gpg
echo "deb http://apt.fruit.je/debian bookworm mpv" | sudo tee /etc/apt/sources.list.d/fruit.list
sudo apt update
sudo apt install mpv -y
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/tomasklaen/uosc/HEAD/installers/unix.sh)"
mkdir -p ~/.config/mpv && tee ~/.config/mpv/mpv.conf <<EOF
keep-open=always
idle=yes
force-window=yes
EOF
```

**qView**
```bash
echo 'deb http://download.opensuse.org/repositories/home:/tangerine:/deb12-xfce4.18/Debian_12/ /' | sudo tee /etc/apt/sources.list.d/home:tangerine:deb12-xfce4.18.list
curl -fsSL https://download.opensuse.org/repositories/home:tangerine:deb12-xfce4.18/Debian_12/Release.key | gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/home_tangerine_deb12-xfce4.18.gpg > /dev/null
sudo apt update
sudo apt install qview -y
```

**Cloudflare WARP**
```bash
curl -fsSL https://pkg.cloudflareclient.com/pubkey.gpg | sudo gpg --yes --dearmor --output /usr/share/keyrings/cloudflare-warp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/cloudflare-warp-archive-keyring.gpg] https://pkg.cloudflareclient.com/ bookworm main" | sudo tee /etc/apt/sources.list.d/cloudflare-client.list
sudo apt update && sudo apt install cloudflare-warp -y
```

**Notion Enhanced**
```bash
echo "deb [trusted=yes] https://apt.fury.io/notion-repackaged/ /" | sudo tee /etc/apt/sources.list.d/notion-repackaged.list
sudo apt update
sudo apt install notion-app-enhanced nodejs npm -y
sudo npm install -g asar
cd ~/Downloads
wget -qO- "https://gitlab.com/-/snippets/3615945/raw/main/patch-notion-enhanced.linux.sh" | sudo bash
```

</details>

### Other Recommended GUI Applications

These are best installed manually from their websites.
*   [Vivaldi](https://vivaldi.com/download/)
*   [Stacher](https://stacher.io/)
*   [Insync](https://www.insynchq.com/downloads/linux#debian)
*   [Keyguard](https://github.com/AChep/keyguard-app/releases/latest)
*   [Moonlight](https://github.com/moonlight-stream/moonlight-qt/releases/latest)
*   [Beeper](https://www.beeper.com/download)
*   [Harmonoid](https://harmonoid.com/downloads#)

## System Configuration

### Fluent Theme

Let's make things look pretty.

```bash
cd ~/Documents/Git
git clone https://github.com/vinceliuice/Fluent-icon-theme
cd Fluent-icon-theme
chmod +x install.sh && ./install.sh -a
mkdir -p ~/.icons/Fluent && cp -r cursors/dist/* ~/.icons/Fluent/
mkdir -p ~/.icons/Fluent-Dark && cp -r cursors/dist-dark/* ~/.icons/Fluent-Dark/
cd ..
git clone https://github.com/vinceliuice/Fluent-gtk-theme
cd Fluent-gtk-theme
chmod +x install.sh && ./install.sh && ./install.sh --tweaks round
```

### Load Default Settings

This is the final step for configuration. Do this last.

1.  Copy the extensions from `https://github.com/RisPNG/debian-install-scripts` to `~/.local/share/gnome-shell/extensions/`.
2.  Reboot your system.
3.  Enable all user extensions through the GNOME Extensions application.
4.  Load all settings by running:
    ```bash
    curl -s https://raw.githubusercontent.com/RisPNG/debian-install-scripts/refs/heads/main/all-settings.conf | dconf load /
    ```
5.  You might need to adjust Dash to Panel settings manually (e.g., invisible center box, taskbar stacked to the left).
6.  Reboot again.

## Finalization

### Final System Update

One last update to clean everything up.

```bash
sudo apt update && sudo apt modernize-sources -y && sudo apt update && sudo apt upgrade -y && sudo apt full-upgrade -y && sudo apt dist-upgrade -y && sudo apt update && sudo apt autoclean -y && sudo apt autopurge -y && sudo apt autoremove -y && sudo apt clean -y
```

You might encounter a Python package conflict due to the live installer using an older version. If so, force the overwrite with the correct package version from the error message. For example:

```bash
sudo dpkg -i --force-overwrite /var/cache/apt/archives/python3.13_3.13.5-5_amd64.deb
```

Then, rerun the update command above.

Reboot one last time, and you should be good to go

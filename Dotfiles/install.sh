#!/bin/bash
#
# FILE: install.sh
# AUTHOR: aiwasevil (DragonHeart Project)
# DESCRIPTION: Automated installation script for Arch Linux Bare Metal deployment.
#              Installs all necessary packages and links Dotfiles configurations.
#

# Henti skrip jika terdapat ralat
set -e

# --- -1. PERSEDIAAN SUDO ---
echo "Skrip ini memerlukan hak pentadbir untuk beberapa arahan."
echo "Sila masukkan kata laluan anda jika diminta untuk meneruskan."
# Minta kata laluan sudo di awal dan kekalkan sesi
sudo -v
# Kekalkan sesi sudo aktif
while true; do sudo -n true; sleep 60; kill -0 "$$" || exit; done 2>/dev/null &

# --- 0. DEKLARASI PEMBOLEH UBAH ---
# Dapatkan direktori semasa (ia sepatutnya ~/Dotfiles)
DOTFILES_DIR=$(pwd)
CONFIG_DIR="$HOME/.config"

# --- 0a. KEMAS KINI MIRRORLIST DENGAN REFLECTOR ---
echo "--- 0a. Mengemas kini mirrorlist dengan Reflector... ---"
sudo reflector --latest 5 --sort rate --save /etc/pacman.d/mirrorlist > /dev/null 2>&1
sudo pacman -Syy

# Senarai Aplikasi Teras Penuh (Disahkan melalui pacman -Qs)
CORE_PKGS=(
    # SHELL & TOOLS
    fish starship fastfetch lsd eza git sudo base-devel picom 
    
    # XFCE4 & UTILITIES (Groups handled separately)
    mousepad xfce4-screenshooter catfish # Editor Teks dan Carian
    p7zip unrar # Pengurusan Arkib
    thunar-archive-plugin thunar-media-tags-plugin # Plugin Thunar
    
    # AUDIO & MULTIMEDIA
    vlc yt-dlp pavucontrol parole               
    pipewire pipewire-alsa pipewire-pulse wireplumber # Audio System
    
    # RANGKAIAN & DISPLAY MANAGER
    sddm networkmanager network-manager-applet 
    
    # FONTS (penting untuk ikon lsd/exa)
    ttf-font-awesome ttf-fira-code ttf-nerd-fonts-symbols 
)

# Pakej Codec Tambahan (Penting untuk multimedia penuh)
CODEC_PKGS=(
    gst-plugins-base gst-plugins-good gst-plugins-bad gst-plugins-ugly
    libdvdcss libmpeg2 libx264 libvpx
)

# Pakej AUR (Dipasang menggunakan Paru)
AUR_PKGS=(
    sddm-sugar-candy-git candy-icons-git bibata-cursor-theme-bin 
)


# --- 1. PENGESANAN & PEMASANGAN PEMACU GRAFIK ---
echo "--- 1. Mengesan dan memasang pemacu grafik... ---"
if lspci | grep -i 'VGA.*VirtualBox'; then
    echo "Mesin maya VirtualBox dikesan."
    sudo pacman -S --noconfirm --needed virtualbox-guest-utils
    # Aktifkan perkhidmatan VirtualBox
    sudo systemctl enable vboxservice.service
elif lspci | grep -i 'VGA.*Intel'; then
    echo "Kad grafik Intel dikesan."
    yes "" | yes | sudo pacman -S --noconfirm xf86-video-intel
elif lspci | grep -i 'VGA.*AMD'; then
    echo "Kad grafik AMD dikesan."
    yes "" | yes | sudo pacman -S --noconfirm xf86-video-amdgpu
elif lspci | grep -i 'VGA.*NVIDIA'; then
    echo "Kad grafik NVIDIA dikesan."
    # Memasang pemacu sumber terbuka 'nouveau'
    yes "" | yes | sudo pacman -S --noconfirm xf86-video-nouveau
else
    echo "Tidak dapat mengesan kad grafik yang disokong secara automatik."
    echo "Sila pasang pemacu grafik yang betul secara manual."
fi


# --- 1b. KEMAS KUNI SISTEM DAN PASANG ALAT UTAMA (pacman) ---
echo "--- 1b. Mengemas kini sistem dan memasang alat asas (pacman) ---"

# Pasang kumpulan XFCE4 secara non-interaktif
echo "Memasang kumpulan XFCE4..."
sudo pacman -S --noconfirm --needed --ask 4 $(pacman -Sgq xfce4)
sudo pacman -S --noconfirm --needed --ask 4 $(pacman -Sgq xfce4-goodies)

# Pasang pakej teras yang lain
echo "Memasang pakej teras individu..."
sudo pacman -Syu --noconfirm --needed "${CORE_PKGS[@]}"

# --- 2. PASANG CODEC MULTIMEDIA ---
echo "--- 2. Memasang Codec Multimedia ---"
sudo pacman -S --noconfirm --needed "${CODEC_PKGS[@]}"

# --- 3. PERSIAAPAN PARU & PEMASANGAN AUR ---
echo "--- 3. Memastikan Paru berada di PATH dan mengemas kini AUR ---"

# Pasang base-devel dan git jika belum ada (diperlukan untuk makepkg)
sudo pacman -S --noconfirm --needed base-devel git

# Semak jika paru dipasang, jika tidak, pasang dari AUR
if ! command -v paru &> /dev/null; then
    echo "Paru tidak ditemui. Memasang Paru dari AUR..."
    ( # Jalankan dalam sub-shell untuk mengelakkan perubahan direktori kekal
        cd /tmp
        git clone https://aur.archlinux.org/paru.git
        cd paru
        yes | makepkg -si --noconfirm
    )
fi

# Kemas kini AUR dan pasang pakej
paru -Syu --noconfirm --needed --batchinstall || true

echo "--- 3b. Memasang pakej AUR (sddm-sugar-candy-git) ---"
paru -S --noconfirm --needed --batchinstall "${AUR_PKGS[@]}"

# --- 4. PENYEDIAAN FOLDER KONFIGURASI DAN SIMLINK ---
echo "--- 4. Menyediakan folder konfigurasi dan Simlink ---"

# Cipta folder .config
mkdir -p "$CONFIG_DIR"

# Buang symlink lama yang mungkin wujud
rm -rf "$CONFIG_DIR/fish" "$CONFIG_DIR/xfce4" "$CONFIG_DIR/fastfetch" "$CONFIG_DIR/picom"

# Cipta Simlink Baharu
ln -s "$DOTFILES_DIR/.config/fish" "$CONFIG_DIR/fish"
ln -s "$DOTFILES_DIR/.config/xfce4" "$CONFIG_DIR/xfce4"
ln -s "$DOTFILES_DIR/.config/fastfetch" "$CONFIG_DIR/fastfetch"
ln -s "$DOTFILES_DIR/.config/picom" "$CONFIG_DIR/picom"

# Symlink untuk fail dot-file terus di $HOME (jika ada)
# Contoh:
# ln -s "$DOTFILES_DIR/.bashrc" "$HOME/.bashrc" || true


# --- 4a. PENYEDIAAN DIREKTORI PENGGUNA ---
echo "--- 4a. Memastikan direktori pengguna standard wujud ---"
mkdir -p "$HOME/Documents"
mkdir -p "$HOME/Pictures"
mkdir -p "$HOME/Videos"
mkdir -p "$HOME/Music"

# --- 4b. PENYEDIAAN WALLPAPER ---
echo "--- 4b. Menyediakan Wallpaper Desktop ---"

# Laluan Penuh untuk Wallpaper Anda di SISTEM BARU
WALLPAPER_DEST="/home/$USER/Pictures/wallpapers/Dr460nized_Honeycomb.png"

# Lokasi fail wallpaper anda di dalam Dotfiles untuk penyalinan
WALLPAPER_SOURCE="$DOTFILES_DIR/Pictures/wallpapers/Dr460nized_Honeycomb.png"

# Cipta folder wallpapers di $HOME/Pictures
mkdir -p "$HOME/Pictures/wallpapers"

# Salin fail wallpaper
if [ -f "$WALLPAPER_SOURCE" ]; then
    cp "$WALLPAPER_SOURCE" "$WALLPAPER_DEST"
    echo "Wallpaper Dr460nized_Honeycomb.png berjaya disalin."
else
    echo "Ralat: Fail wallpaper tidak dijumpai di $WALLPAPER_SOURCE. Teruskan tanpa wallpaper."
fi

# Kemas kini konfigurasi Xfce4
echo "Mengemas kini tetapan Xfce Desktop..."
# Tukar path wallpaper:
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/last-image -s "$WALLPAPER_DEST" --type string --create -n || true
xfconf-query -c xfce4-desktop -p /backdrop/screen0/monitor0/workspace0/image-style -s 5 --type int --create -n # 5 = Zoom/Fill

# Tetapkan tema GTK dan tema pengurus tetingkap
echo "Menetapkan tema GTK dan pengurus tetingkap..."
xfconf-query -c xsettings -p /Net/ThemeName -s "Adwaita-Dark" --create -n || true
xfconf-query -c xfwm4 -p /general/theme -s "Adwaita-Dark" --create -n || true

# Tetapkan sesi Xfce lalai
echo "Menetapkan sesi Xfce lalai kepada Xfce Session..."
xfconf-query -c xfce4-session -p /general/SessionName -s "Xfce Session" --create -n || true

# Tetapkan tema ikon
echo "Menetapkan tema ikon..."
xfconf-query -c xsettings -p /Net/IconThemeName -s "candy-icons" --create -n || true




# Bersihkan cache Xfce4 dan mulakan semula panel untuk memastikan tema digunakan
echo "Membersihkan cache Xfce4 dan memulakan semula panel..."
rm -rf "$HOME/.cache/xfce4/session/"
xfce4-panel -r || true

# Tambah Picom ke autostart Xfce
echo "Menambah Picom ke autostart Xfce..."
mkdir -p "$HOME/.config/autostart"
echo -e "[Desktop Entry]\nType=Application\nExec=picom\nHidden=false\nNoDisplay=false\nX-GNOME-Autostart-enabled=true\nName=Picom\nComment=Compositor" | tee "$HOME/.config/autostart/picom.desktop" > /dev/null


# --- 5. TUKAR SHELL KE FISH ---
echo "--- 5. Menukar shell default ke Fish ---"
chsh -s /usr/bin/fish

# --- 6. PENGAKTIFAN PERKHIDMATAN ---
echo "--- 6. Mengaktifkan SDDM dan NetworkManager ---"
sudo systemctl enable sddm
sudo systemctl enable NetworkManager

# --- 7. TUKAR TEMA SDDM ---
echo "--- 7. Menetapkan tema SDDM ke Sugar Candy ---"
# Kaedah yang lebih kukuh: Cipta fail konfigurasi secara terus.
THEME_CONF_DIR="/etc/sddm.conf.d"
THEME_CONF_FILE="$THEME_CONF_DIR/theme.conf"
echo "Memastikan direktori $THEME_CONF_DIR wujud..."
sudo mkdir -p "$THEME_CONF_DIR"
echo "Menulis konfigurasi tema ke $THEME_CONF_FILE..."
echo -e "[Theme]\nCurrent=sugar-candy" | sudo tee "$THEME_CONF_FILE" > /dev/null

# Tetapkan sesi lalai SDDM kepada Xfce Session
echo "Menetapkan sesi lalai SDDM kepada Xfce Session..."
if grep -q "^Session=" "$THEME_CONF_FILE"; then
    sudo sed -i 's|^Session=.*|Session=xfce.desktop|' "$THEME_CONF_FILE"
else
    echo "Session=xfce.desktop" | sudo tee -a "$THEME_CONF_FILE" > /dev/null
fi

# Salin wallpaper ke direktori tema SDDM sugar-candy
echo "Menyalin wallpaper ke tema SDDM sugar-candy..."
sudo cp "$DOTFILES_DIR/grub/themes/dragonheart/garuda_bg_safe.png" "/usr/share/sddm/themes/sugar-candy/Backgrounds/"

# Kemas kini theme.conf SDDM untuk menggunakan wallpaper baharu
echo "Mengemas kini konfigurasi tema SDDM..."
sudo sed -i 's|^Background=.*|Background="Backgrounds/garuda_bg_safe.png"|' "/usr/share/sddm/themes/sugar-candy/theme.conf"

# --- 7b. PEMASANGAN FON PENGGUNA ---
echo "--- 7b. Memasang fon pengguna ---"
# Cipta direktori fon jika ia tidak wujud
mkdir -p "$HOME/.local/share/fonts"
# Salin semua fon dari repositori ke direktori fon pengguna
cp -r "$DOTFILES_DIR/fonts/"* "$HOME/.local/share/fonts/"
# Bina semula cache fon
echo "Membina semula cache fon..."
fc-cache -fv

set -x
# --- 8. PENYEDIAAN TEMA GRUB ---
echo "--- 8. Menyediakan tema GRUB ---"

# Cipta direktori tema GRUB jika belum ada
sudo mkdir -p /usr/share/grub/themes/

# Salin tema GRUB 'dragonheart'
sudo cp -r "$DOTFILES_DIR/grub/themes/dragonheart" /usr/share/grub/themes/

# Salin fon GRUB
sudo mkdir -p /usr/share/grub/fonts
sudo cp "$DOTFILES_DIR/grub/terminus-14.pf2" /usr/share/grub/fonts/

# Kemas kini fail /etc/default/grub
# Kemas kini atau tambah baris GRUB_BACKGROUND
if grep -q "^#\?GRUB_BACKGROUND=" /etc/default/grub; then
    sudo sed -i 's|^#\?GRUB_BACKGROUND=.*|GRUB_BACKGROUND="/usr/share/grub/themes/dragonheart/garuda_bg_safe.png"|' /etc/default/grub
else
    echo 'GRUB_BACKGROUND="/usr/share/grub/themes/dragonheart/garuda_bg_safe.png"' | sudo tee -a /etc/default/grub
fi

# Kemas kini atau tambah baris GRUB_FONT
if grep -q "^#\?GRUB_FONT=" /etc/default/grub; then
    sudo sed -i 's|^#\?GRUB_FONT=.*|GRUB_FONT="/usr/share/grub/fonts/terminus-14.pf2"|' /etc/default/grub
else
    echo 'GRUB_FONT="/usr/share/grub/fonts/terminus-14.pf2"' | sudo tee -a /etc/default/grub
fi

# Kemas kini atau tambah baris GRUB_THEME
if grep -q "^#\?GRUB_THEME=" /etc/default/grub; then
    sudo sed -i 's|^#\?GRUB_THEME=.*|GRUB_THEME="/usr/share/grub/themes/dragonheart/theme.txt"|' /etc/default/grub
else
    echo 'GRUB_THEME="/usr/share/grub/themes/dragonheart/theme.txt"' | sudo tee -a /etc/default/grub
fi

# Kemas kini atau tambah baris GRUB_GFXMODE
if grep -q "^#\?GRUB_GFXMODE=" /etc/default/grub; then
    sudo sed -i 's|^#\?GRUB_GFXMODE=.*|GRUB_GFXMODE="1280x800"|' /etc/default/grub
else
    echo 'GRUB_GFXMODE="1280x800"' | sudo tee -a /etc/default/grub
fi

# Jana semula konfigurasi GRUB
sudo grub-mkconfig -o /boot/grub/grub.cfg
set +x

echo "✅ PERSIAAPAN DRAGONHEART SELESAI! Sila REBOOT untuk menikmati persediaan baharu."

exec fish
sudo reboot
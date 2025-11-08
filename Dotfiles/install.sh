#!/bin/bash
# Skrip Pemasangan DragonHeart Dotfiles

# Hentikan sekiranya berlaku ralat
set -e

# Tentukan direktori Dotfiles secara dinamik
DOTFILES_DIR="$(dirname "$(realpath \"$0\")")"
USER_HOME="$HOME"

figlet -w 120 "DragonHeart"
figlet -w 120 "Installer"

# --- 0. Maklumat Penting ---
figlet -w 120 "0. Important Info"
read -p "Pastikan anda telah memasang sistem Arch Linux asas. Tekan sebarang kekunci untuk meneruskan..."

# --- 1. Pemasangan Pakej Rasmi & AUR ---
figlet -w 120 "1. Installing Pkgs"

# Pakej Rasmi
if [ -f "$DOTFILES_DIR/pkglist_official.txt" ]; then
    echo "Mengemas kini sistem dan memasang pakej rasmi..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist_official.txt"
else
    echo "Amaran: pkglist_official.txt tidak ditemui."
fi

# Pakej AUR
echo "Memasang pakej AUR..."
# Pasang paru (AUR helper) jika belum ada
if ! command -v paru &> /dev/null; then
    echo "Paru tidak ditemui. Memasang Paru..."
    # Pastikan base-devel dan git dipasang (sepatutnya sudah ada dalam pkglist_official.txt)
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Klon dan pasang paru dari AUR
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm)
    rm -rf /tmp/paru
fi

# Pasang pakej AUR lain dari pkglist_aur.txt menggunakan paru
if [ -f "$DOTFILES_DIR/pkglist_aur.txt" ]; then
    echo "Memasang pakej AUR dari pkglist_aur.txt..."
    paru -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist_aur.txt"
else
    echo "Amaran: pkglist_aur.txt tidak ditemui."
fi


# --- 2. Aktifkan Perkhidmatan Rangkaian ---
figlet -w 120 "2. Networking"
sudo systemctl enable NetworkManager.service
sudo systemctl start NetworkManager.service

# --- 3. Penyalinan Fail Konfigurasi Pengguna ---
figlet -w 120 "3. User Configs"
mkdir -p "$USER_HOME/.config"
cp -rf "$DOTFILES_DIR/.config/xfce4" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/picom" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/fastfetch" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/gtk-3.0" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/Thunar" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/fish" "$USER_HOME/.config/"
cp -f "$DOTFILES_DIR/.config/starship.toml" "$USER_HOME/.config/"
cp -f "$DOTFILES_DIR/.gitconfig" "$USER_HOME/"

# Cipta direktori pengguna standard
mkdir -p "$USER_HOME/Downloads"
mkdir -p "$USER_HOME/Documents"
mkdir -p "$USER_HOME/Music"

# Salin Fail Wallpaper
mkdir -p "$USER_HOME/Pictures/wallpapers"
cp -r "$DOTFILES_DIR/Pictures/wallpapers/" "$USER_HOME/Pictures/"

# Salin Fail Ikon (untuk Fastfetch dll.)
mkdir -p "$USER_HOME/Pictures/icons"
cp -r "$DOTFILES_DIR/Pictures/icons/" "$USER_HOME/Pictures/"

# Salin Tema
mkdir -p "$USER_HOME/.themes"
cp -r "$DOTFILES_DIR/themes/Materia-Vivid/" "$USER_HOME/.themes/"
cp -r "$DOTFILES_DIR/themes/Custom-Rounded/" "$USER_HOME/.themes/"

# --- 4. Penyalinan Konfigurasi Seluruh Sistem ---
figlet -w 120 "4. System Configs"
echo "Mengkonfigurasi SDDM..."
sudo cp -f "$DOTFILES_DIR/etc/sddm.conf" "/etc/sddm.conf"
sudo systemctl enable sddm

# Konfigurasi Latar Belakang SDDM
echo "Mengkonfigurasi latar belakang SDDM..."
sudo cp -f "$DOTFILES_DIR/Pictures/wallpapers/Malefor.jpg" "/usr/share/sddm/themes/sugar-candy/Backgrounds/"
sudo sed -i 's|^Background=.*|Background="Backgrounds/Malefor.jpg"|g' "/usr/share/sddm/themes/sugar-candy/theme.conf"

echo "Mengkonfigurasi GRUB..."
sudo cp -f "$DOTFILES_DIR/etc/default/grub" "/etc/default/grub"
sudo cp -f "$DOTFILES_DIR/boot/grub/garuda_bg_safe.png" "/boot/grub/"
# Pastikan direktori fon GRUB wujud
if [ -f "/usr/share/grub/fonts" ]; then
    sudo rm "/usr/share/grub/fonts" # Padam jika ia adalah fail
fi
sudo mkdir -p "/usr/share/grub/fonts"
sudo cp -f "$DOTFILES_DIR/boot/grub/terminus-14.pf2" "/usr/share/grub/fonts/" # Salin fon
sudo sed -i 's|^GRUB_FONT=".*"|GRUB_FONT="/usr/share/grub/fonts/terminus-14.pf2"|g' "/etc/default/grub"
if ! grep -q "^GRUB_FONT=" "/etc/default/grub"; then
    sudo sed -i "/# Tambah baris ini untuk menetapkan fon tersuai:/a GRUB_FONT=\"/usr/share/grub/fonts/terminus-14.pf2\"" "/etc/default/grub"
fi
echo "Menjana semula konfigurasi GRUB..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

# --- 5. Konfigurasi Shell (Fish) ---
figlet -w 120 "5. Shell Config"
if command -v fish &> /dev/null; then
    echo "Menukar shell lalai kepada Fish untuk pengguna $USER..."
    chsh -s "$(command -v fish)" "$USER"
else
    echo "Amaran: Fish shell tidak ditemui."
fi

# --- 6. Arahan Tambahan ---
figlet -w 120 "6. Final Notes"
echo "✅ Pemasangan Dotfiles asas telah selesai."
echo "Sila pertimbangkan untuk memasang pemacu grafik khusus (NVIDIA, AMD, Intel) secara manual."
echo "Jangan lupa untuk menyalin fail sensitif seperti kunci SSH dan GPG secara manual."

figlet -w 120 "Done!"
read -p "Sistem akan reboot sekarang. Tekan sebarang kekunci untuk reboot atau Ctrl+C untuk membatalkan."
sudo reboot

#!/bin/bash
# Skrip Pemasangan DragonHeart Dotfiles

# Hentikan sekiranya berlaku ralat
set -e

# Tentukan direktori Dotfiles secara dinamik
DOTFILES_DIR="$(dirname "$(realpath "$0")")"
USER_HOME="$HOME"

echo "--- MULA PEMASANGAN DRAGONHEART DOTFILES ---"

# --- 0. Maklumat Penting ---
echo "--- 0. MAKLUMAT PENTING SEBELUM PEMASANGAN ---"
read -p "Pastikan anda telah memasang sistem Arch Linux asas. Tekan sebarang kekunci untuk meneruskan..."

# --- 1. Pemasangan Pakej Rasmi & AUR ---
echo "--- 1. MEMASANG PAKEJ-PAKEJ ---"

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


# --- 2. Penyalinan Fail Konfigurasi Pengguna ---
echo "--- 2. MENYALIN FAIL-FAIL KONFIGURASI PENGGUNA KE $USER_HOME ---"
mkdir -p "$USER_HOME/.config"
cp -rf "$DOTFILES_DIR/.config/xfce4" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/picom" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/fastfetch" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/gtk-3.0" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/Thunar" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/fish" "$USER_HOME/.config/"
cp -f "$DOTFILES_DIR/.config/starship.toml" "$USER_HOME/.config/"
cp -f "$DOTFILES_DIR/.gitconfig" "$USER_HOME/"

mkdir -p "$USER_HOME/Pictures/wallpapers"
cp -f "$DOTFILES_DIR/Pictures/wallpapers/Dr460nized_Honeycomb.png" "$USER_HOME/Pictures/wallpapers/"

# --- 3. Penyalinan Konfigurasi Seluruh Sistem ---
echo "--- 3. MENYALIN KONFIGURASI SELURUH SISTEM (SUDO DIPERLUKAN) ---"
echo "Mengkonfigurasi SDDM..."
sudo cp -f "$DOTFILES_DIR/etc/sddm.conf" "/etc/sddm.conf"
sudo systemctl enable sddm
sudo systemctl start sddm

echo "Mengkonfigurasi GRUB..."
sudo cp -f "$DOTFILES_DIR/etc/default/grub" "/etc/default/grub"
sudo cp -f "$DOTFILES_DIR/boot/grub/garuda_bg_safe.png" "/boot/grub/"
sudo cp -f "$DOTFILES_DIR/boot/grub/terminus-14.pf2" "/usr/share/grub/fonts/"
sudo sed -i 's|^GRUB_FONT=".*"|GRUB_FONT="/usr/share/grub/fonts/terminus-14.pf2"|g' "/etc/default/grub"
if ! grep -q "^GRUB_FONT=" "/etc/default/grub"; then
    sudo sed -i "/# Tambah baris ini untuk menetapkan fon tersuai:/a GRUB_FONT=\"/usr/share/grub/fonts/terminus-14.pf2\"" "/etc/default/grub"
fi
echo "Menjana semula konfigurasi GRUB..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

# --- 4. Konfigurasi Shell (Fish) ---
echo "--- 4. MENGKONFIGURASI SHELL (FISH) ---"
if command -v fish &> /dev/null; then
    echo "Menukar shell lalai kepada Fish untuk pengguna $USER..."
    chsh -s "$(command -v fish)" "$USER"
else
    echo "Amaran: Fish shell tidak ditemui."
fi

# --- 5. Arahan Tambahan ---
echo "--- 5. ARAHAN TAMBAHAN & TINDAKAN PASCA PEMASANGAN ---"
echo "✅ Pemasangan Dotfiles asas telah selesai."
echo "Sila pertimbangkan untuk memasang pemacu grafik khusus (NVIDIA, AMD, Intel) secara manual."
echo "Jangan lupa untuk menyalin fail sensitif seperti kunci SSH dan GPG secara manual."

echo "--- PEMASANGAN SELESAI ---"
read -p "Sistem akan reboot sekarang. Tekan sebarang kekunci untuk reboot atau Ctrl+C untuk membatalkan."
sudo reboot

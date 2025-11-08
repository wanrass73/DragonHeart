#!/bin/bash
# Skrip Pemasangan DragonHeart Dotfiles

# Hentikan sekiranya berlaku ralat
set -e

# Tentukan direktori Dotfiles secara dinamik
DOTFILES_DIR="$(dirname "$(realpath "$0")")"
USER_HOME="$HOME" # Gunakan $HOME sistem baru

echo "--- MULA PEMASANGAN DRAGONHEART DOTFILES ---"

# --- 0. Semak dan Maklumat Penting ---
echo "--- 0. MAKLUMAT PENTING SEBELUM PEMASANGAN ---"
echo "Pastikan anda telah memasang sistem Arch Linux asas, dan skrip ini dijalankan sebagai pengguna biasa (bukan root)."
echo "Setelah ini, skrip akan meminta sudo untuk operasi sistem yang diperlukan (pemasangan pakej, konfigurasi /etc)."
read -p "Tekan sebarang kekunci untuk meneruskan proses pemasangan..."

# --- 1. Pemasangan Pakej dari pkglist.txt ---
echo "--- 1. MEMASANG PAKEJ DARI PKGLIST.TXT (SUDO DIPERLUKAN) ---"
if [ -f "$DOTFILES_DIR/pkglist.txt" ]; then
    echo "Mengemas kini sistem dan memasang pakej dari pkglist.txt..."
    sudo pacman -Syu --noconfirm # Pastikan sistem terkini
    sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist.txt"
else
    echo "Amaran: pkglist.txt tidak ditemui di $DOTFILES_DIR. Pakej tidak dipasang secara automatik."
fi

# --- 2. Penyalinan Fail Konfigurasi Pengguna (.config & Dotfiles di ~) ---
echo "--- 2. MENYALIN FAIL-FAIL KONFIGURASI PENGGUNA KE $USER_HOME ---"

# Cipta direktori .config jika belum ada
mkdir -p "$USER_HOME/.config"

# Salin konfigurasi .config yang dikenal pasti
cp -rf "$DOTFILES_DIR/.config/xfce4" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/picom" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/fastfetch" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/gtk-3.0" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/Thunar" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/fish" "$USER_HOME/.config/" # Untuk Fish shell
# Salin konfigurasi Starship.toml
cp -f "$DOTFILES_DIR/.config/starship.toml" "$USER_HOME/.config/"

# Salin fail-fail dotfiles terus di HOME
cp -f "$DOTFILES_DIR/.gitconfig" "$USER_HOME/"
cp -f "$DOTFILES_DIR/.bashrc" "$USER_HOME/"
cp -f "$DOTFILES_DIR/.bash_profile" "$USER_HOME/"
# Jika terdapat fail lain yang anda kenal pasti di root home, tambah di sini.

# Salin Fail Wallpaper
mkdir -p "$USER_HOME/Pictures/wallpapers"
cp -f "$DOTFILES_DIR/Pictures/wallpapers/Dr460nized_Honeycomb.png" "$USER_HOME/Pictures/wallpapers/"

# --- 3. Penyalinan Konfigurasi Seluruh Sistem (memerlukan sudo) ---
echo "--- 3. MENYALIN KONFIGURASI SELURUH SISTEM (SUDO DIPERLUKAN) ---"

# SDDM Configuration (Theme)
echo "Mengkonfigurasi SDDM..."
sudo cp -f "$DOTFILES_DIR/etc/sddm.conf" "/etc/sddm.conf"
sudo systemctl enable sddm
sudo systemctl start sddm

# GRUB Configuration
echo "Mengkonfigurasi GRUB..."
sudo cp -f "$DOTFILES_DIR/etc/default/grub" "/etc/default/grub"
sudo cp -f "$DOTFILES_DIR/boot/grub/garuda_bg_safe.png" "/boot/grub/"
sudo cp -f "$DOTFILES_DIR/boot/grub/terminus-14.pf2" "/usr/share/grub/fonts/" # Salin fon

# Betulkan laluan fon GRUB dalam /etc/default/grub jika perlu (pastikan ia menunjuk ke lokasi yang betul)
# Asumsi bahawa terminus-14.pf2 disalin ke /usr/share/grub/fonts/
# Ubah GRUB_FONT untuk menunjuk ke lokasi fon yang betul
sudo sed -i 's|^GRUB_FONT=".*"|GRUB_FONT="/usr/share/grub/fonts/terminus-14.pf2"|g' "/etc/default/grub"
# Jika GRUB_FONT tidak wujud, tambahkannya selepas baris komen berkaitan
if ! grep -q "^GRUB_FONT=" "/etc/default/grub"; then
    sudo sed -i "/# Tambah baris ini untuk menetapkan fon tersuai:/a GRUB_FONT=\\
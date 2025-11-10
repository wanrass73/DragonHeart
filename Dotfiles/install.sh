#!/bin/bash
# DragonHeart Dotfiles Installation Script

# Stop on error
set -e

# --- PREREQUISITE: Install figlet and lolcat if not present ---
if ! command -v figlet &> /dev/null; then
    echo "figlet not found. Installing figlet..."
    sudo pacman -S --noconfirm figlet
fi
if ! command -v lolcat &> /dev/null; then
    echo "lolcat not found. Installing lolcat..."
    sudo pacman -S --noconfirm lolcat
fi

# Determine Dotfiles directory dynamically
DOTFILES_DIR="$(dirname "$(realpath "$0")")"
USER_HOME="$HOME"

figlet -w 120 "DragonHeart" | lolcat
figlet -w 120 "Installer" | lolcat

# --- 0. Important Info ---
figlet -w 120 "0. Important Info" | lolcat
read -p "Please ensure you have a base Arch Linux system installed. Press any key to continue..."

# --- 1. Official & AUR Package Installation ---
figlet -w 120 "1. Installing Pkgs" | lolcat

# Official Packages
if [ -f "$DOTFILES_DIR/pkglist_official.txt" ]; then
    echo "Updating system and installing official packages..."
    sudo pacman -Syu --noconfirm
    sudo pacman -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist_official.txt"
else
    echo "Warning: pkglist_official.txt not found."
fi

# AUR Packages
echo "Installing AUR packages..."
# Install paru (AUR helper) if not present
if ! command -v paru &> /dev/null; then
    echo "Paru not found. Installing Paru..."
    # Ensure base-devel and git are installed (should be in pkglist_official.txt)
    sudo pacman -S --needed --noconfirm base-devel git
    
    # Clone and install paru from AUR
    git clone https://aur.archlinux.org/paru.git /tmp/paru
    (cd /tmp/paru && makepkg -si --noconfirm)
    rm -rf /tmp/paru
fi

# Install other AUR packages from pkglist_aur.txt using paru
if [ -f "$DOTFILES_DIR/pkglist_aur.txt" ]; then
    echo "Installing AUR packages from pkglist_aur.txt..."
    paru -S --needed --noconfirm - < "$DOTFILES_DIR/pkglist_aur.txt"
else
    echo "Warning: pkglist_aur.txt not found."
fi


# --- 2. Enable Network Services ---
figlet -w 120 "2. Networking" | lolcat
sudo systemctl enable NetworkManager.service
sudo systemctl start NetworkManager.service

# --- 3. Copying User Configuration Files ---
figlet -w 120 "3. User Configs" | lolcat
mkdir -p "$USER_HOME/.config"
cp -rf "$DOTFILES_DIR/.config/xfce4" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/picom" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/fastfetch" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/gtk-3.0" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/Thunar" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/autostart" "$USER_HOME/.config/"
cp -rf "$DOTFILES_DIR/.config/fish" "$USER_HOME/.config/"
cp -f "$DOTFILES_DIR/.config/starship.toml" "$USER_HOME/.config/"
cp -f "$DOTFILES_DIR/.gitconfig" "$USER_HOME/"

# Create standard user directories
mkdir -p "$USER_HOME/Downloads"
mkdir -p "$USER_HOME/Documents"
mkdir -p "$USER_HOME/Music"

# Copy Wallpaper Files
mkdir -p "$USER_HOME/Pictures/wallpapers"
cp -r "$DOTFILES_DIR/Pictures/wallpapers/"* "$USER_HOME/Pictures/wallpapers/"

# Copy Icon Files (for Fastfetch etc.)
mkdir -p "$USER_HOME/Pictures/icons"
cp -r "$DOTFILES_DIR/Pictures/icons/"* "$USER_HOME/Pictures/icons/"

# Copy Themes
mkdir -p "$USER_HOME/.themes"
cp -r "$DOTFILES_DIR/themes/Materia-Vivid/" "$USER_HOME/.themes/"
cp -r "$DOTFILES_DIR/themes/Custom-Rounded/" "$USER_HOME/.themes/"

# Copy and Install Fonts
echo "Installing fonts..."
mkdir -p "$USER_HOME/.local/share/fonts"
cp -r "$DOTFILES_DIR/fonts/FiraCode/"* "$USER_HOME/.local/share/fonts/"
fc-cache -fv

# --- 4. Copying System-Wide Configurations ---
figlet -w 120 "4. System Configs" | lolcat
echo "Configuring SDDM..."
sudo cp -f "$DOTFILES_DIR/etc/sddm.conf" "/etc/sddm.conf"
sudo systemctl enable sddm

# Configure SDDM Background
echo "Configuring SDDM background..."
sudo cp -f "$DOTFILES_DIR/Pictures/wallpapers/Malefor.jpg" "/usr/share/sddm/themes/sugar-candy/Backgrounds/"
sudo sed -i 's|^Background=.*|Background="Backgrounds/Malefor.jpg"|g' "/usr/share/sddm/themes/sugar-candy/theme.conf"

echo "Configuring GRUB..."
sudo cp -f "$DOTFILES_DIR/etc/default/grub" "/etc/default/grub"
sudo cp -f "$DOTFILES_DIR/boot/grub/garuda_bg_safe.png" "/boot/grub/"
# Ensure GRUB font directory exists
if [ -f "/usr/share/grub/fonts" ]; then
    sudo rm "/usr/share/grub/fonts" # Delete if it's a file
fi
sudo mkdir -p "/usr/share/grub/fonts"
sudo cp -f "$DOTFILES_DIR/boot/grub/terminus-14.pf2" "/usr/share/grub/fonts/" # Copy font
sudo sed -i 's|^GRUB_FONT=".*"|GRUB_FONT="/usr/share/grub/fonts/terminus-14.pf2"|g' "/etc/default/grub"
if ! grep -q "^GRUB_FONT=" "/etc/default/grub"; then
    sudo sed -i "/# Add this line to set a custom font:/a GRUB_FONT=\"/usr/share/grub/fonts/terminus-14.pf2\"" "/etc/default/grub"
fi
echo "Regenerating GRUB configuration..."
sudo grub-mkconfig -o /boot/grub/grub.cfg

# --- 5. Shell Configuration (Fish) ---
figlet -w 120 "5. Shell Config" | lolcat
if command -v fish &> /dev/null; then
    echo "Changing default shell to Fish for user $USER..."
    chsh -s "$(command -v fish)" "$USER"
else
    echo "Warning: Fish shell not found."
fi

# --- 6. Final Notes ---
figlet -w 120 "6. Final Notes" | lolcat
echo "✅ Basic Dotfiles installation is complete."
echo "Please consider installing dedicated graphics drivers (NVIDIA, AMD, Intel) manually."
echo "Don't forget to copy sensitive files like SSH and GPG keys manually."

figlet -w 120 "Done!" | lolcat
read -p "The system will reboot now. Press any key to reboot or Ctrl+C to cancel."
sudo reboot

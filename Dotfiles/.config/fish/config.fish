# ================================================================= #
#       FILE: ~/.config/fish/config.fish (DragonHeart Edition)
# ================================================================= #

# 0. TAMBAH LALUAN (PENTING untuk Starship)
fish_add_path /usr/local/bin

# Fastfetch - Menjalankan konfigurasi yang betul berdasarkan terminal
switch (basename (string replace -- ' ' '' $TERM))
    case 'kitty' 'alacritty'
        # Konfigurasi untuk terminal moden (Imej penuh)
        fastfetch --config ~/.config/fastfetch/kitty_alacritty.jsonc
    case '*'
        # Konfigurasi untuk terminal klasik (Seni Teks Chafa)
        fastfetch --config ~/.config/fastfetch/xfce4.jsonc
end

# Muatkan prompt Starship (Pastikan ini selepas Fastfetch)
starship init fish | source

# ================================================================= #
# 2. INTERACTIVE SESSION (Semua fungsi dan alias diletak di sini)
# ================================================================= #

if status is-interactive
    
    # --- FUNGSI ALIAS PENGURUSAN SISTEM ---
    
    # Fungsi 'update': Mengemas kini sistem menggunakan paru
    function update
        echo "--> Mengemas kini sistem dengan Paru..."
        paru
    end

    # Fungsi ringkas untuk pemasangan (Install)
    function install
        sudo pacman -S $argv
    end
    
    # Fungsi ringkas untuk pembuangan (Remove)
    function remove
        sudo pacman -Rns $argv
    end

# --- FUNGSI ALIAS VISUAL (PENGGANTI LS/TREE) ---

# Alias LS: Menggunakan lsd untuk estetika (dengan ikon yang betul)
alias ls='lsd -F --icon always --long'

# Alias TREE: Menggunakan exa untuk fungsi tree
alias tree='exa --tree --icons --color=always'

    # --- FUNGSI ALIAS MUAT TURUN YOUTUBE ---
    
    # Fungsi 'mp3dl': Lagu tunggal. Disimpan terus di ~/Music.
    function mp3dl
        if test -z "$argv"
            echo (set_color red)"ERROR:" (set_color normal)"Sila berikan URL."
            echo (set_color normal)"Penggunaan: mp3dl [URL]"
            return 1
        end

        echo "--> Memuat turun dan menukar $argv ke MP3 (Kualiti Terbaik)..."
        # Output: ~/Music/Uploader - Tajuk Penuh.mp3 (Tiada Sub-Folder)
        yt-dlp -f bestaudio -x --audio-format mp3 --embed-metadata -o "$HOME/Music/%(uploader)s - %(fulltitle)s.%(ext)s" $argv
    end

    # Fungsi 'mp3list': Senarai main/multi-video. Disimpan dalam SATU folder Playlist.
    function mp3list
        if test -z "$argv"
            echo (set_color red)"ERROR:" (set_color normal)"Sila berikan satu atau lebih URL senarai main/video."
            echo (set_color normal)"Penggunaan: mp3list [URL1] [URL2]..."
            return 1
        end

        echo "--> Memproses $argv dan memuat turun ke MP3 (Kualiti Terbaik) dalam folder Playlist..."
        # Output: ~/Music/Nama Playlist/Artis - Tajuk Lagu.mp3 (Dengan Sub-Folder Playlist)
        yt-dlp -f bestaudio -x --audio-format mp3 --embed-metadata --embed-thumbnail -o "$HOME/Music/%(playlist)s/%(artist)s - %(title)s.%(ext)s" $argv
    end

    # Fungsi 'mp4dl': Video tunggal/multi-video. Disimpan dalam sub-folder Tajuk - Artis.
    function mp4dl
        if test -z "$argv"
            echo (set_color red)"ERROR:" (set_color normal)"Sila berikan URL."
            echo (set_color normal)"Penggunaan: mp4dl [URL]"
            return 1
        end

        echo "--> Memuat turun dan menukar $argv ke MP4 (Kualiti HD 720p)..."
        # Output: ~/Videos/Tajuk - Artis/Tajuk.mp4 (Dengan Sub-Folder Tajuk - Artis)
        yt-dlp -f "bestvideo[height<=720]+bestaudio/best[height<=720]" --recode-video mp4 -o "$HOME/Videos/%(title)s - %(artist)s/%(title)s.%(ext)s" $argv
    end
    
    # Mesej sambutan peribadi
    set -g fish_greeting (set_color green)"Welcome "(set_color yellow)$USER(set_color normal)", have fun with your coding :P"

end

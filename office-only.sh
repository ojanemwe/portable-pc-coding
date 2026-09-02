#!/data/data/com.termux/files/usr/bin/bash

set -e

run_stage() {
    printf '\n============================================================\n'
    printf ' %s\n' "$1"
    printf '============================================================\n\n'
}

# ============================================================
# 1. Instalasi Paket Dasar Termux Native
# ============================================================
run_stage "TAHAP 1/6 - Instalasi Paket Dasar Termux"

pkg update
pkg upgrade -y
pkg install tur-repo x11-repo -y
pkg install termux-x11-nightly pulseaudio wget git xfce4 galculator -y
pkg install chromium ristretto mpv -y
pkg install webp-pixbuf-loader libheif -y

termux-setup-storage

# ============================================================
# 2. Konfigurasi Launcher Script
# ============================================================
run_stage "TAHAP 2/6 - Membuat Launcher PC"

cat << 'EOF_PC' > ~/pc
#!/data/data/com.termux/files/usr/bin/bash

# Matikan proses yang tersisa
pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "xfce4-session" 2>/dev/null
pkill -9 -f "pulseaudio" 2>/dev/null
pkill -9 -f "dbus-launch" 2>/dev/null
pkill -9 -f "dbus-daemon" 2>/dev/null

sleep 2

# Bersihkan file PID dan soket kedaluwarsa
rm -f /data/data/com.termux/files/usr/var/run/dbus/pid
gpgconf --kill gpg-agent 2>/dev/null

# Pastikan symlink penyimpanan internal ada
if [ ! -d "$HOME/storage" ]; then
    termux-setup-storage
fi

# Jalankan PulseAudio
pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1

sleep 1

# Mulai server X
export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :0 >/dev/null &

sleep 3

# Buka aplikasi Termux:X11 di Android
am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1

sleep 1

# Atur variabel lingkungan
export DISPLAY=:0
export PULSE_SERVER=127.0.0.1

# Pengaturan DPI dan Skala
xrdb -merge <<< "Xft.dpi: 144"
export GDK_SCALE=2
export GDK_DPI_SCALE=0.75
export XCURSOR_SIZE=40

# Nonaktifkan GPU untuk QtWebEngine
export QTWEBENGINE_DISABLE_GPU=1
export QT_QUICK_BACKEND=software

# Eksekusi resolusi 16:9 (Landscape) di latar belakang
# (sleep 4 && xrandr -s 1280x720) &

# Pastikan variabel lingkungan dan prompt di-export
export SHELL=/data/data/com.termux/files/usr/bin/bash
export PS1='\[\e[0;32m\]\w\[\e[0m\] \$ '

# Jalankan XFCE4 tanpa peringatan DBUS dan sistem
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax --exit-with-session 2>/dev/null)
fi
exec xfce4-session 2>/dev/null
EOF_PC

chmod +x ~/pc

if ! grep -qxF 'alias pc="~/pc"' ~/.bashrc 2>/dev/null; then
    echo 'alias pc="~/pc"' >> ~/.bashrc
fi

# ============================================================
# 3. Konfigurasi Tombol Shutdown di Desktop
# ============================================================
run_stage "TAHAP 3/6 - Membuat Shortcut Shutdown"

mkdir -p ~/Desktop

cat << 'EOF_SHUTDOWN' > ~/Desktop/shutdown.desktop
[Desktop Entry]
Type=Application
Name=Shutdown
Exec=sh -c "current_pid=$$; pids=$(pgrep -f 'termux.x11' | grep -v $current_pid); if [ -n \"$pids\" ]; then kill -9 $pids; fi"
Icon=xfsm-shutdown
Terminal=true
Categories=System;
Path=
StartupNotify=false
EOF_SHUTDOWN

chmod +x ~/Desktop/shutdown.desktop

# ============================================================
# 4. Termux:Widget
# ============================================================
run_stage "TAHAP 4/6 - Membuat Shortcut Termux:Widget"

cat << 'EOF' > ~/.bash_profile
if [ -f /data/data/com.termux/files/usr/etc/bash.bashrc ]; then
    . /data/data/com.termux/files/usr/etc/bash.bashrc
fi
if [ -f ~/.bashrc ]; then
    . ~/.bashrc
fi
EOF

mkdir -p ~/.shortcuts

cat << 'EOF_WIDGET' > ~/.shortcuts/PC-Desktop.sh
#!/data/data/com.termux/files/usr/bin/bash
exec bash -l "$HOME/pc"
EOF_WIDGET

chmod +x ~/.shortcuts/PC-Desktop.sh

# ============================================================
# 5. Aplikasi Kantoran & Desain - Termux Native
# ============================================================
run_stage "TAHAP 5/6 - Instalasi Aplikasi Kantoran dan Desain"

pkg install libreoffice mousepad featherpad gimp -y

xdg-mime default mousepad.desktop text/plain
xdg-mime default featherpad.desktop text/markdown
xdg-mime default org.xfce.ristretto.desktop image/png image/gif image/jpeg image/webp image/heic image/heif image/bmp image/ico
xdg-mime default org.xfce.ristretto.desktop image/jpg
xdg-mime default mpv.desktop video/mp4 video/x-matroska video/webm
xdg-mime default mpv.desktop audio/mpeg audio/flac audio/mp4 audio/wav audio/x-wav audio/ogg audio/opus

mkdir -p ~/.local/share/fonts
git clone --no-checkout --depth 1 https://github.com/ojanemwe/portable-pc-coding.git temp_repo
cd temp_repo
git sparse-checkout set fonts
git checkout
mv fonts/* ~/.local/share/fonts/
cd ..
rm -rf temp_repo

# ============================================================
# 6. Penambahan Pilihan Tema
# ============================================================
run_stage "TAHAP 6/6 - Penambahan Pilihan Tema"

pkg install -y xfce4-whiskermenu-plugin
xfconf-query -c xfce4-panel -l -v | grep applicationsmenu
xfconf-query -c xfce4-panel -p /plugins/plugin-1 -s whiskermenu
xfconf-query -c xfce4-panel -l -v | grep whiskermenu
xfconf-query -c xfce4-panel -p /plugins/plugin-1/button-title -n -t string -s "Menu"

git clone --depth=1 https://github.com/vinceliuice/Orchis-theme.git /tmp/Orchis-theme
cd /tmp/Orchis-theme
./install.sh -d ~/.themes
rm -rf /tmp/Orchis-theme

git clone --depth=1 https://github.com/vinceliuice/WhiteSur-gtk-theme.git /tmp/WhiteSur-gtk-theme
cd /tmp/WhiteSur-gtk-theme
./install.sh -d ~/.themes
rm -rf /tmp/WhiteSur-gtk-theme

git clone --depth=1 https://github.com/vinceliuice/Colloid-icon-theme.git /tmp/Colloid-icon-theme
cd /tmp/Colloid-icon-theme
./install.sh -d ~/.icons
rm -rf /tmp/Colloid-icon-theme



run_stage "INSTALASI TERMUX NATIVE SELESAI"
echo "Tahap Termux Native 1-7 selesai dan ubuntu-setup.sh telah dijalankan."
echo "Gunakan 'pc' untuk membuka Desktop Xfce4."

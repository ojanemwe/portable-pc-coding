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
run_stage "TAHAP 1/7 - Instalasi Paket Dasar Termux"

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
run_stage "TAHAP 2/7 - Membuat Launcher PC"

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
run_stage "TAHAP 3/7 - Membuat Shortcut Shutdown"

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
xfconf-query -c xfce4-desktop -p /desktop-icons/file-icons/show-filesystem -s false

# ============================================================
# 4. Lingkungan Vibe Coding - bagian Termux Native
# ============================================================
run_stage "TAHAP 4/7 - Menyiapkan PRoot Ubuntu"

pkg install geany proot-distro -y

mkdir -p ~/.9router ~/.config ~/.local-proot ~/.cache-proot ~/workspace ~/Downloads

if proot-distro login ubuntu -- true >/dev/null 2>&1; then
    echo "Ubuntu PRoot sudah tersedia."
else
    echo "Menginstall Ubuntu PRoot..."
    proot-distro install ubuntu
fi

# ============================================================
# 5. Wrapper dan Shortcut AI Agent - bagian Termux Native
# ============================================================
run_stage "TAHAP 5/7 - Membuat Wrapper dan Shortcut AI Agent"

mkdir -p ~/bin ~/Desktop

cat << 'EOF_OPENCODE' > ~/bin/opencode
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login ubuntu -- opencode
EOF_OPENCODE

cat << 'EOF_9ROUTER' > ~/bin/9router
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login ubuntu -- 9router
EOF_9ROUTER

chmod +x ~/bin/opencode ~/bin/9router

if ! grep -qxF 'export PATH="$PATH:$HOME/bin"' ~/.bashrc 2>/dev/null; then
    echo 'export PATH="$PATH:$HOME/bin"' >> ~/.bashrc
fi

if ! grep -qxF 'alias proot="proot-distro login ubuntu"' ~/.bashrc 2>/dev/null; then
    echo 'alias proot="proot-distro login ubuntu"' >> ~/.bashrc
fi

cat << 'EOF_TERMINAL' > ~/Desktop/Terminal-PRoot.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal PRoot
Comment=Buka terminal dan otomatis login ke PRoot Ubuntu
Exec=xfce4-terminal -e "proot-distro login ubuntu"
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF_TERMINAL
chmod +x ~/Desktop/Terminal-PRoot.desktop

cat << 'EOF_OPEN' > ~/Desktop/OpenCode.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=OpenCode
Comment=Menjalankan OpenCode pada direktori root didalam PRoot
Exec=xfce4-terminal --title="OpenCode" -e "proot-distro login ubuntu -- opencode"
Icon=utilities-terminal
Terminal=false
Categories=Development;
EOF_OPEN
chmod +x ~/Desktop/OpenCode.desktop

cat << 'EOF_ROUTER' > ~/Desktop/9router.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=9router
Comment=Menjalankan 9router pada PRoot
Exec=xfce4-terminal --title="9router" -e "proot-distro login ubuntu -- 9router"
Icon=utilities-terminal
Terminal=false
Categories=Development;
EOF_ROUTER
chmod +x ~/Desktop/9router.desktop

cat << 'EOF_AI' > ~/Desktop/Ai-Workspace.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=AI Workspace
Comment=Start 9Router in Tray and OpenCode in Workspace
Exec=proot-distro login ubuntu -- bash -c '9router --tray & until curl -s http://localhost:20128 >/dev/null; do sleep 1; done; cd /root/workspace && exec opencode'
Terminal=true
StartupNotify=false
EOF_AI
chmod +x ~/Desktop/Ai-Workspace.desktop

# ============================================================
# 6. Termux:Widget
# ============================================================
run_stage "TAHAP 6/7 - Membuat Shortcut Termux:Widget"

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
# 7. Aplikasi Kantoran & Desain - Termux Native
# ============================================================
run_stage "TAHAP 7/7 - Instalasi Aplikasi Kantoran dan Desain"

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
# Ubuntu PRoot: lanjutkan dengan ubuntu-setup.sh
# ============================================================
run_stage "Menjalankan ubuntu-setup.sh di Ubuntu PRoot"

proot-distro login ubuntu -- bash -c \
'curl -sL https://raw.githubusercontent.com/ojanemwe/portable-pc-coding/main/ubuntu-setup.sh | bash'

run_stage "INSTALASI TERMUX NATIVE SELESAI"
echo "Tahap Termux Native 1-7 selesai dan ubuntu-setup.sh telah dijalankan."
echo "Gunakan 'pc' untuk membuka Desktop Xfce4."

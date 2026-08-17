#!/data/data/com.termux/files/usr/bin/bash

# 1. Setup Storage
termux-setup-storage
sleep 2

# 2. Update & Install All Packages (Dasar, GUI, Editor, Kantoran & Desain)
pkg update && pkg upgrade -y
pkg install tur-repo x11-repo -y
pkg install termux-x11-nightly pulseaudio wget git xfce4 zen-browser geany proot-distro libreoffice mousepad featherpad gimp -y

# 3. Default File Associations
xdg-mime default mousepad.desktop text/plain
xdg-mime default featherpad.desktop text/markdown

# 4. GIMP to PhotoGIMP (Versi Dinamis)
# Catatan: Direktori dibuat secara otomatis melalui skrip tanpa perlu membuka GIMP terlebih dahulu.
git clone https://github.com/Diolinux/PhotoGIMP.git
GIMP_VER=$(pkg show gimp | grep -i "Version" | grep -oE '[0-9]+\.[0-9]+' | head -n 1)
PHOTOGIMP_VER=$(ls PhotoGIMP/.var/app/org.gimp.GIMP/config/GIMP/ | sort -V | tail -n 1)
mkdir -p ~/.config/GIMP/$GIMP_VER/
cp -r PhotoGIMP/.var/app/org.gimp.GIMP/config/GIMP/$PHOTOGIMP_VER/* ~/.config/GIMP/$GIMP_VER/
rm -rf PhotoGIMP

# 5. Direktori Kerja
mkdir -p ~/Desktop ~/bin ~/.shortcuts ~/.9router ~/.config ~/.local-proot ~/.cache-proot ~/workspace ~/Downloads

# 6. Launcher Script (~/pc)
cat << 'EOF' > ~/pc
#!/data/data/com.termux/files/usr/bin/bash

pkill -9 -f "termux.x11" 2>/dev/null
pkill -9 -f "xfce4-session" 2>/dev/null
pkill -9 -f "pulseaudio" 2>/dev/null
pkill -9 -f "dbus-launch" 2>/dev/null
pkill -9 -f "dbus-daemon" 2>/dev/null
sleep 2

rm -f /data/data/com.termux/files/usr/var/run/dbus/pid
gpgconf --kill gpg-agent 2>/dev/null

if [ ! -d "$HOME/storage" ]; then
    termux-setup-storage
fi

pulseaudio --start --load="module-native-protocol-tcp auth-ip-acl=127.0.0.1 auth-anonymous=1" --exit-idle-time=-1
sleep 1

export XDG_RUNTIME_DIR=${TMPDIR}
termux-x11 :0 >/dev/null &
sleep 3

am start --user 0 -n com.termux.x11/com.termux.x11.MainActivity > /dev/null 2>&1
sleep 1

export DISPLAY=:0
export PULSE_SERVER=127.0.0.1
xrdb -merge <<< "Xft.dpi: 144"
export GDK_SCALE=2
export GDK_DPI_SCALE=0.75
export XCURSOR_SIZE=40
export QTWEBENGINE_DISABLE_GPU=1
export QT_QUICK_BACKEND=software

if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval $(dbus-launch --sh-syntax --exit-with-session 2>/dev/null)
fi
exec xfce4-session 2>/dev/null
EOF

chmod +x ~/pc
grep -q 'alias pc="~/pc"' ~/.bashrc || echo 'alias pc="~/pc"' >> ~/.bashrc
source ~/.bashrc

# 7. Desktop Shortcuts
cat << 'EOF' > ~/Desktop/shutdown.desktop
[Desktop Entry]
Type=Application
Name=Shutdown
Exec=sh -c "current_pid=$$; pids=$(pgrep -f 'termux.x11' | grep -v $current_pid); if [ -n "\$pids" ]; then kill -9 \$pids; fi"
Icon=xfsm-shutdown
Terminal=true
Categories=System;
StartupNotify=false
EOF
chmod +x ~/Desktop/shutdown.desktop

cat << 'EOF' > ~/Desktop/Terminal-PRoot.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=Terminal PRoot
Comment=Buka terminal dan otomatis login ke PRoot Ubuntu
Exec=xfce4-terminal -e "proot-distro login ubuntu"
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF
chmod +x ~/Desktop/Terminal-PRoot.desktop

cat << 'EOF' > ~/Desktop/OpenCode.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=AI Agent Workspace
Comment=Menjalankan AI Agent Workspace
Exec=xfce4-terminal --title="OpenCode" -e "proot-distro login ubuntu -- opencode"
Icon=utilities-terminal
Terminal=false
Categories=Development;
EOF
chmod +x ~/Desktop/OpenCode.desktop

cat << 'EOF' > ~/Desktop/9router.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=AI Agent Workspace
Comment=Menjalankan AI Agent Workspace
Exec=xfce4-terminal --title="9router" -e "proot-distro login ubuntu -- 9router"
Icon=utilities-terminal
Terminal=false
Categories=Development;
EOF
chmod +x ~/Desktop/9router.desktop

cat << 'EOF' > ~/Desktop/Ai-Workspace.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=AI Workspace
Comment=Start 9Router in Tray and OpenCode in Workspace
Exec=proot-distro login ubuntu -- bash -c '9router --tray & until curl -s http://localhost:20128 >/dev/null; do sleep 1; done; cd /root/workspace && exec opencode'
Terminal=true
StartupNotify=false
EOF
chmod +x ~/Desktop/Ai-Workspace.desktop

# 8. Wrappers untuk Terminal Termux (~/bin)
cat << 'EOF' > ~/bin/proot
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login ubuntu
EOF

cat << 'EOF' > ~/bin/opencode
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login ubuntu -- opencode
EOF

cat << 'EOF' > ~/bin/9router
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login ubuntu -- 9router
EOF

chmod +x ~/bin/proot ~/bin/opencode ~/bin/9router
grep -q 'export PATH="$HOME/bin:$PATH"' ~/.bashrc || echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# 9. Termux:Widget Shortcut (Android Homescreen)
echo -e '#!/data/data/com.termux/files/usr/bin/bash
pc' > ~/.shortcuts/PC-Desktop.sh
chmod +x ~/.shortcuts/PC-Desktop.sh

# 10. Install Ubuntu PRoot
proot-distro install ubuntu

echo "Menjalankan setup Ubuntu PRoot..."
# UBAH URL DI BAWAH INI SESUAI DENGAN REPOSITORI GITHUB ANDA
proot-distro login ubuntu -- bash -c "curl -sL https://raw.githubusercontent.com/ojanemwe/portable-pc-coding/main/ubuntu-setup.sh | bash"

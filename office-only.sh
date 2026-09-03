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

set -Eeuo pipefail

PREFIX="${PREFIX:-/data/data/com.termux/files/usr}"
export PATH="$PREFIX/bin:$PATH"

THEME_DIR="$HOME/.local/share/themes"
ICON_DIR="$HOME/.local/share/icons"

WORK_DIR="${TMPDIR:-$PREFIX/tmp}/xfce-theme-install-$$"
SHIM_DIR="$WORK_DIR/shims"

# ------------------------------------------------------------
# Versi release yang digunakan
# ------------------------------------------------------------
ORCHIS_TAG="2026-07-07"
WHITESUR_TAG="2026-07-07"
COLLOID_TAG="2025-07-19"

ORCHIS_URL="https://github.com/vinceliuice/Orchis-theme/archive/refs/tags/${ORCHIS_TAG}.tar.gz"
WHITESUR_URL="https://github.com/vinceliuice/WhiteSur-gtk-theme/archive/refs/tags/${WHITESUR_TAG}.tar.gz"
COLLOID_URL="https://github.com/vinceliuice/Colloid-icon-theme/archive/refs/tags/${COLLOID_TAG}.tar.gz"

# ------------------------------------------------------------
# Cleanup
# ------------------------------------------------------------
cleanup() {
    rm -rf "$WORK_DIR"
}

trap cleanup EXIT

# ------------------------------------------------------------
# Helper: banner
# ------------------------------------------------------------
banner() {
    printf '\n============================================================\n'
    printf ' %s\n' "$1"
    printf '============================================================\n\n'
}

# ------------------------------------------------------------
# Helper: fail
# ------------------------------------------------------------
fail() {
    printf '\n[ERROR] %s\n' "$1" >&2
    printf '[ERROR] Log lengkap tersimpan sementara di: %s\n' "$WORK_DIR" >&2
    exit 1
}

trap 'printf "\n[ERROR] Gagal pada baris %s. Periksa pesan di atas.\n" "$LINENO" >&2' ERR

banner "TAHAP 6/6 - Instalasi Orchis, WhiteSur & Colloid"

mkdir -p "$THEME_DIR" "$ICON_DIR" "$WORK_DIR" "$SHIM_DIR"

# ============================================================
# 6.1 - Dependency
# ============================================================

banner "6.1 - Memastikan paket pembangun tersedia"

# Semua dependency dipasang melalui PKG Termux.
# TIDAK menggunakan apt.
# TIDAK menggunakan sudo.
pkg update -y

pkg install -y \
    wget \
    tar \
    gzip \
    sassc \
    glib \
    libxml2 \
    libxml2-utils \
    gtk-update-icon-cache

# ------------------------------------------------------------
# Verifikasi dependency
# ------------------------------------------------------------

command -v sassc >/dev/null 2>&1 \
    || fail "sassc tidak tersedia setelah instalasi."

command -v gtk-update-icon-cache >/dev/null 2>&1 \
    || fail "gtk-update-icon-cache tidak tersedia."

command -v glib-compile-resources >/dev/null 2>&1 \
    || fail "glib-compile-resources tidak tersedia setelah instalasi paket glib."

command -v xmllint >/dev/null 2>&1 \
    || fail "xmllint tidak tersedia setelah instalasi paket libxml2-utils."

command -v tar >/dev/null 2>&1 \
    || fail "tar tidak tersedia."

command -v wget >/dev/null 2>&1 \
    || fail "wget tidak tersedia."

# ============================================================
# 6.1a - Compatibility shim: getent
# ============================================================

# WhiteSur/Orchis dapat menggunakan:
#     getent passwd ...
#
# Termux tidak selalu menyediakan getent seperti distro Linux.
# Shim ini hanya dibuat di WORK_DIR dan hanya aktif selama
# Stage 6.
# ============================================================

REAL_GETENT="$(command -v getent 2>/dev/null || true)"

cat > "$SHIM_DIR/getent" <<'SHIM'
#!/data/data/com.termux/files/usr/bin/bash

REAL_GETENT="${THEME_INSTALL_REAL_GETENT:-}"

if [[ "${1:-}" == "passwd" ]]; then
    requested="${2:-${USER:-$(id -un)}}"
    current="${USER:-$(id -un)}"

    if [[ "$requested" == "$current" ]]; then
        printf '%s:x:1000:1000:%s:%s:%s\n' \
            "$current" \
            "$current" \
            "$HOME" \
            "${SHELL:-/data/data/com.termux/files/usr/bin/bash}"

        exit 0
    fi
fi

if [[ -n "$REAL_GETENT" && -x "$REAL_GETENT" ]]; then
    exec "$REAL_GETENT" "$@"
fi

exit 2
SHIM

chmod +x "$SHIM_DIR/getent"

export THEME_INSTALL_REAL_GETENT="$REAL_GETENT"

# ============================================================
# 6.1b - Compatibility shim: sudo
# ============================================================

# PENTING:
#
# Android/Termux TIDAK DI-ROOT.
#
# Kita TIDAK memasang sudo.
# Kita TIDAK memberikan privilege tambahan.
#
# WhiteSur hanya membutuhkan keberadaan command "sudo"
# pada beberapa bagian installer, bahkan ketika instalasi
# dilakukan ke direktori user.
#
# Karena semua target instalasi kita berada di:
#
#     $HOME/.local/share/themes
#
# tidak diperlukan privilege root.
#
# Shim ini hanya meneruskan command secara langsung sebagai
# user Termux saat ini.
# ============================================================

cat > "$SHIM_DIR/sudo" <<'SHIM'
#!/data/data/com.termux/files/usr/bin/bash

# Tidak ada argument = tidak melakukan apa-apa.
if [[ "$#" -eq 0 ]]; then
    exit 0
fi

# Jalankan command langsung sebagai user Termux.
# Tidak ada eskalasi privilege.
exec "$@"
SHIM

chmod +x "$SHIM_DIR/sudo"

# Shim harus berada di depan PATH agar:
#
#     which sudo
#
# menemukan shim tersebut.
export PATH="$SHIM_DIR:$PATH"

# ------------------------------------------------------------
# Verifikasi shim
# ------------------------------------------------------------

command -v getent >/dev/null 2>&1 \
    || fail "Shim getent gagal dibuat."

command -v sudo >/dev/null 2>&1 \
    || fail "Shim sudo gagal dibuat."

# Pastikan sudo yang ditemukan memang shim kita.
[[ "$(command -v sudo)" == "$SHIM_DIR/sudo" ]] \
    || fail "PATH sudo tidak menunjuk ke shim Termux."

printf '[INFO] sudo shim: %s\n' "$(command -v sudo)"
printf '[INFO] getent shim: %s\n' "$(command -v getent)"

# ============================================================
# Helper: download + validate tarball
# ============================================================

download_tarball() {
    local url="$1"
    local out="$2"

    printf '[INFO] Download: %s\n' "$url"

    wget \
        -q \
        --show-progress \
        --timeout=30 \
        --tries=3 \
        -O "$out" \
        "$url" \
        || fail "Gagal mengunduh $url"

    [[ -s "$out" ]] \
        || fail "Arsip kosong: $out"

    tar -tzf "$out" >/dev/null 2>&1 \
        || fail "Arsip rusak/tidak valid: $out"
}

# ============================================================
# 6.2 - Install Orchis GTK/XFWM
# ============================================================

banner "6.2 - Install Orchis GTK/XFWM"

ORCHIS_TGZ="$WORK_DIR/Orchis-theme.tar.gz"
ORCHIS_ROOT="$WORK_DIR/orchis"

mkdir -p "$ORCHIS_ROOT"

download_tarball \
    "$ORCHIS_URL" \
    "$ORCHIS_TGZ"

tar -xzf "$ORCHIS_TGZ" -C "$ORCHIS_ROOT"

ORCHIS_SRC="$(
    find "$ORCHIS_ROOT" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -name 'Orchis-theme-*' \
        -print -quit
)"

[[ -n "$ORCHIS_SRC" && -d "$ORCHIS_SRC" ]] \
    || fail "Folder Orchis hasil ekstraksi tidak ditemukan."

printf '[INFO] Orchis source: %s\n' "$ORCHIS_SRC"

(
    cd "$ORCHIS_SRC"

    bash ./install.sh \
        -d "$THEME_DIR"
)

# ============================================================
# 6.3 - Install WhiteSur GTK/XFWM
# ============================================================

banner "6.3 - Install WhiteSur GTK/XFWM"

WHITESUR_TGZ="$WORK_DIR/WhiteSur-gtk-theme.tar.gz"
WHITESUR_ROOT="$WORK_DIR/whitesur"

mkdir -p "$WHITESUR_ROOT"

download_tarball \
    "$WHITESUR_URL" \
    "$WHITESUR_TGZ"

tar -xzf "$WHITESUR_TGZ" -C "$WHITESUR_ROOT"

WHITESUR_SRC="$(
    find "$WHITESUR_ROOT" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -name 'WhiteSur-gtk-theme-*' \
        -print -quit
)"

[[ -n "$WHITESUR_SRC" && -d "$WHITESUR_SRC" ]] \
    || fail "Folder WhiteSur hasil ekstraksi tidak ditemukan."

printf '[INFO] WhiteSur source: %s\n' "$WHITESUR_SRC"

# ------------------------------------------------------------
# WhiteSur + XFCE compatibility
# ------------------------------------------------------------
#
# WhiteSur release 2026.x mempunyai masalah pada installer:
#
# install_themes()
#     |
#     +-- install_theemy()
#     |
#     +-- shell_base()
#     |
#     +-- install_shelly()
#
# install_shelly() adalah builder GNOME Shell.
#
# Pada XFCE tanpa gnome-shell, builder tersebut tidak diperlukan
# dan dapat menyebabkan sassc error karena GNOME_SHELL kosong.
#
# Kita hanya menonaktifkan PEMANGGILAN:
#
#     shell_base
#     install_shelly
#
# GTK dan XFWM tetap diproses oleh install_theemy().
#
# Referensi masalah upstream:
# WhiteSur issue #1401.
# ------------------------------------------------------------

if command -v xfce4-session >/dev/null 2>&1 \
    && ! command -v gnome-shell >/dev/null 2>&1; then

    printf '[INFO] XFCE detected without gnome-shell; skipping GNOME Shell build.\n'

    WHITESUR_LIB_INSTALL="$WHITESUR_SRC/libs/lib-install.sh"

    [[ -f "$WHITESUR_LIB_INSTALL" ]] \
        || fail "WhiteSur: libs/lib-install.sh tidak ditemukan."

    # --------------------------------------------------------
    # Pastikan struktur installer WhiteSur yang kita patch
    # memang sesuai dengan release yang kita download.
    # --------------------------------------------------------

    grep -qE '^[[:space:]]*shell_base([[:space:]]|$)' \
        "$WHITESUR_LIB_INSTALL" \
        || fail "WhiteSur: pemanggilan/fungsi shell_base tidak ditemukan."

    grep -qE '^[[:space:]]*install_shelly([[:space:]]|$)' \
        "$WHITESUR_LIB_INSTALL" \
        || fail "WhiteSur: pemanggilan/fungsi install_shelly tidak ditemukan."

    # --------------------------------------------------------
    # Nonaktifkan pemanggilan shell_base().
    #
    # Hanya baris pemanggilan yang diawali whitespace +
    # shell_base yang dikomentari.
    # --------------------------------------------------------

    sed -i \
        '/^[[:space:]]*shell_base[[:space:]]*$/s/^/# /' \
        "$WHITESUR_LIB_INSTALL"

    # --------------------------------------------------------
    # Nonaktifkan pemanggilan install_shelly().
    #
    # Fungsi install_shelly sendiri TIDAK dihapus.
    # Hanya pemanggilannya yang dilewati.
    # --------------------------------------------------------

    sed -i \
        '/^[[:space:]]*install_shelly[[:space:]]/s/^/# /' \
        "$WHITESUR_LIB_INSTALL"

    # --------------------------------------------------------
    # Verifikasi patch.
    # --------------------------------------------------------

    if grep -nE '^[[:space:]]*shell_base[[:space:]]*$' \
        "$WHITESUR_LIB_INSTALL" >/dev/null 2>&1; then

        fail "WhiteSur: shell_base masih memiliki pemanggilan aktif."
    fi

    if grep -nE '^[[:space:]]*install_shelly[[:space:]]' \
        "$WHITESUR_LIB_INSTALL" >/dev/null 2>&1; then

        fail "WhiteSur: install_shelly masih memiliki pemanggilan aktif."
    fi

    printf '[INFO] WhiteSur GNOME Shell builder dinonaktifkan untuk XFCE.\n'
fi

# ------------------------------------------------------------
# Jalankan installer WhiteSur.
# ------------------------------------------------------------

(
    cd "$WHITESUR_SRC"

    bash ./install.sh \
        -d "$THEME_DIR"
)

# ============================================================
# 6.4 - Install Colloid Icon Theme
# ============================================================

banner "6.4 - Install Colloid Icon Theme"

COLLOID_TGZ="$WORK_DIR/Colloid-icon-theme.tar.gz"
COLLOID_ROOT="$WORK_DIR/colloid"

mkdir -p "$COLLOID_ROOT"

download_tarball \
    "$COLLOID_URL" \
    "$COLLOID_TGZ"

tar -xzf "$COLLOID_TGZ" -C "$COLLOID_ROOT"

COLLOID_SRC="$(
    find "$COLLOID_ROOT" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -name 'Colloid-icon-theme-*' \
        -print -quit
)"

[[ -n "$COLLOID_SRC" && -d "$COLLOID_SRC" ]] \
    || fail "Folder Colloid hasil ekstraksi tidak ditemukan."

printf '[INFO] Colloid source: %s\n' "$COLLOID_SRC"

(
    cd "$COLLOID_SRC"

    ./install.sh \
        -d "$ICON_DIR"
)

# ============================================================
# 6.5 - Refresh Xfce Theme/Icon Cache
# ============================================================

banner "6.5 - Refresh Xfce Theme/Icon Cache"

# GTK icon cache aman diperbarui untuk direktori yang
# mempunyai index.theme.

if command -v gtk-update-icon-cache >/dev/null 2>&1; then

    find "$ICON_DIR" \
        -mindepth 1 \
        -maxdepth 1 \
        -type d \
        -name 'Colloid*' \
        -exec gtk-update-icon-cache -f -t {} \; \
        2>/dev/null \
        || true

fi

# ------------------------------------------------------------
# Jangan memaksa theme tertentu.
#
# Kedua theme tetap tersedia di:
#
#   Settings -> Appearance -> Style
#
# Icon theme:
#
#   Settings -> Appearance -> Icons
# ------------------------------------------------------------

printf '\n[OK] Tema dan ikon selesai diproses.\n'
printf '[OK] GTK themes : %s\n' "$THEME_DIR"
printf '[OK] Icons      : %s\n' "$ICON_DIR"

printf '\n[INFO] Buka/refresh Xfce4 lalu cek:\n'
printf '       Settings -> Appearance -> Style\n'
printf '       Settings -> Appearance -> Icons\n'

printf '\n[INFO] Instalasi dilakukan sebagai user Termux.\n'
printf '[INFO] Tidak membutuhkan root Android.\n'
printf '[INFO] Tidak membutuhkan sudo asli.\n'
printf '[INFO] Tidak ada /bin/getent Termux yang ditimpa.\n'
printf '[INFO] Tidak ada /bin/sudo Termux yang ditimpa.\n'

run_stage "INSTALASI TERMUX NATIVE SELESAI"

echo "Tahap Termux Native 1-6 selesai dan ubuntu-setup.sh telah dijalankan."
echo "Gunakan 'pc' untuk membuka Desktop Xfce4."

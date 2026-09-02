#!/bin/bash

set -e

# ============================================================
# Portable PC - Debian PRoot Installer
# ============================================================

echo "=============================================="
echo " Portable PC - Debian PRoot Setup"
echo "=============================================="

export DEBIAN_FRONTEND=noninteractive

# C. Buat Symlink Konfigurasi & Home
echo
echo "[Debian] Membuat symlink konfigurasi..."

rm -rf /root/.config /root/.9router /root/.local /root/.cache /root/workspace /root/Downloads

ln -s /data/data/com.termux/files/home/.config /root/.config
ln -s /data/data/com.termux/files/home/.9router /root/.9router
ln -s /data/data/com.termux/files/home/.local-proot /root/.local
ln -s /data/data/com.termux/files/home/.cache-proot /root/.cache
ln -s /data/data/com.termux/files/home/workspace /root/workspace
ln -s /data/data/com.termux/files/home/Downloads /root/Downloads

# D. Install Node.js LTS
echo
echo "[Debian] Menginstall paket dasar..."

apt-get update
apt-get -o Dpkg::Options::="--force-confold" upgrade -y
apt-get -o Dpkg::Options::="--force-confold" install -y curl git

echo
echo "[Debian] Menginstall Node.js LTS..."

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get -o Dpkg::Options::="--force-confold" install -y nodejs

# E. Install Paket Global
echo
echo "[Debian] Menginstall 9router dan OpenCode..."

npm install -g 9router opencode-ai

echo
echo "=============================================="
echo " Debian PRoot setup selesai."
echo "=============================================="

#!/bin/bash

set -e

# ============================================================
# Portable PC - Ubuntu PRoot Installer
# ============================================================

echo "=============================================="
echo " Portable PC - Ubuntu PRoot Setup"
echo "=============================================="

export DEBIAN_FRONTEND=noninteractive

# C. Install Node.js LTS
echo
echo "[Ubuntu] Menginstall paket dasar..."

apt-get -o Dpkg::Options::="--force-confold" update
apt-get -o Dpkg::Options::="--force-confold" upgrade -y
apt-get -o Dpkg::Options::="--force-confold" install -y curl git

echo
echo "[Ubuntu] Menginstall Node.js LTS..."

curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt-get -o Dpkg::Options::="--force-confold" install -y nodejs

# D. Buat Symlink Konfigurasi & Home
echo
echo "[Ubuntu] Membuat symlink konfigurasi..."

rm -rf /root/.config /root/.9router /root/.local /root/.cache /root/workspace /root/Downloads

ln -s /data/data/com.termux/files/home/.config /root/.config
ln -s /data/data/com.termux/files/home/.9router /root/.9router
ln -s /data/data/com.termux/files/home/.local-proot /root/.local
ln -s /data/data/com.termux/files/home/.cache-proot /root/.cache
ln -s /data/data/com.termux/files/home/workspace /root/workspace
ln -s /data/data/com.termux/files/home/Downloads /root/Downloads

# E. Install Paket Global
echo
echo "[Ubuntu] Menginstall 9router dan OpenCode..."

npm install -g 9router opencode-ai

echo
echo "=============================================="
echo " Ubuntu PRoot setup selesai."
echo "=============================================="

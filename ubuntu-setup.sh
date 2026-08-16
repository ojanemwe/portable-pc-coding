#!/bin/bash

# 1. Update & Install Dependencies
apt update && apt upgrade -y
apt install curl git -y

# 2. Install Node.js LTS
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
apt install -y nodejs

# 3. Hapus Folder Default Root & Buat Symlink ke Home Termux
rm -rf /root/.config /root/.9router /root/.local /root/.cache /root/workspace /root/Downloads

ln -s /data/data/com.termux/files/home/.config /root/.config
ln -s /data/data/com.termux/files/home/.9router /root/.9router
ln -s /data/data/com.termux/files/home/.local-proot /root/.local
ln -s /data/data/com.termux/files/home/.cache-proot /root/.cache
ln -s /data/data/com.termux/files/home/workspace /root/workspace
ln -s /data/data/com.termux/files/home/Downloads /root/Downloads

# 4. Install Global NPM Packages
npm install -g 9router opencode-ai

# portable-pc-coding - Tutorial

# **Setup Portable PC (Xfce4 di Android) untuk Agentic/Vibe Coding** (Tanpa Root)

## Spesifikasi & Kebutuhan Penyimpanan

-   **Spesifikasi Minimum:** RAM 4GB, CPU Octa-core (setara Snapdragon 400-series / MediaTek Helio G-series).

-   **Spesifikasi Rekomendasi:** RAM 6GB+, CPU Snapdragon 600-series ke atas (untuk _multitasking_ dan Code-OSS).

-   **Total Penyimpanan (Storage):** ~2.5 GB hingga 4 GB (siapkan ruang kosong minimal 5 GB - 10 GB untuk untuk menampung cache NPM dan stabilitas).




## 1. Persiapan Perangkat Android

Langkah ini menyiapkan pondasi aplikasi dan perizinan sistem Android.

  

1.  Unduh dan instal F-Droid dari https://f-droid.org/ .

2.  Unduh dan instal Termux melalui F-Droid.
    
3.  Unduh dan instal Termux-X11 dari rilis GitHub di https://github.com/termux/termux-x11/releases .

4.  Matikan fitur penghemat baterai atau pembatasan baterai untuk aplikasi Termux dan Termux-X11.

5.  Aktifkan Opsi Pengembang (Developer Options) pada pengaturan Android, lalu aktifkan opsi "Disable Child Process Restrictions".
    
      
---    

## 2. Instalasi Paket Dasar Termux

Buka aplikasi Termux dan jalankan perintah berikut secara berurutan untuk memasang repositori dasar dan desktop Xfce4:

```
pkg update && pkg upgrade -y
pkg install tur-repo x11-repo -y
pkg install termux-x11-nightly pulseaudio wget git xfce4 -y
termux-setup-storage

```


---
## 3. Konfigurasi Launcher Script (Resolusi 16:9 & Clean Terminal)

Buat skrip utama Shortcut desktop yang telah dimodifikasi untuk resolusi otomatis dan penghilangan _error output_.

1.  Buat berkas peluncur:
	```
	nano ~/pc
	```

2.  Tempelkan skrip berikut:
	```
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

	# Jalankan XFCE4 tanpa peringatan DBUS dan sistem
	if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
	    eval $(dbus-launch --sh-syntax --exit-with-session 2>/dev/null)
	fi
	exec xfce4-session 2>/dev/null
	```

3.  Simpan (`Ctrl+O`, `Enter`, `Ctrl+X`).
    
4.  Beri izin eksekusi dan buat alias agar mudah dipanggil:
	```
	chmod +x ~/pc
	echo 'alias pc="~/pc"' >> ~/.bashrc
	source ~/.bashrc
	
	```

---
## 4. Konfigurasi Tombol Shutdown di Desktop

Buat ikon _shutdown_ di layar desktop untuk menutup sesi dengan aman.

Jalankan perintah ini di Termux:
```
mkdir -p ~/Desktop
nano ~/Desktop/shutdown.desktop

```

Tempelkan kode berikut:
```
[Desktop Entry]
Type=Application
Name=Shutdown
Exec=sh -c "current_pid=$$; pids=$(pgrep -f 'termux.x11' | grep -v $current_pid); if [ -n \"$pids\" ]; then kill -9 $pids; fi"
Icon=xfsm-shutdown
Terminal=true
Categories=System;
Path=
StartupNotify=false
```
Simpan (`Ctrl+O`, `Enter`, `Ctrl+X`), lalu ketik:
```
chmod +x ~/Desktop/shutdown.desktop

```

> **CATATAN USER KANTORAN:** _Bagi pengguna yang hanya membutuhkan fungsi **pekerjaan kantor** dan **desain ringan**, jalankan Tahap 5 dan **langsung ke Tahap 8**. Anda tidak perlu menerapkan Tahap 6 dan 7._
> 
>   

---
## 5. Instalasi Aplikasi Kantoran & Desain

Jalankan perintah instalasi berikut:
```
pkg install libreoffice mousepad featherpad gimp -y

```

### Konfigurasi Default Pembaca Teks (.txt & .md)
```
xdg-mime default mousepad.desktop text/plain
xdg-mime default featherpad.desktop text/markdown

```

### Konfigurasi GIMP menjadi PhotoGIMP (Mirip Photoshop)
```
git clone https://github.com/Diolinux/PhotoGIMP.git
mkdir -p ~/.config/GIMP/2.10/
cp -r PhotoGIMP/.var/app/org.gimp.GIMP/config/GIMP/2.10/* ~/.config/GIMP/2.10/
rm -rf PhotoGIMP

```

### Konfigurasi Default Format LibreOffice (.docx)

1.  Jalankan `pc` untuk masuk ke Desktop Xfce4.

2.  Buka LibreOffice.

3.  Masuk ke **Tools > Options** (`Alt + F12`).

4.  Navigasi ke **Load/Save > General**.

5.  Ubah _Always save as_ menjadi **Word 2007-365 (.docx)**. Klik Apply dan OK.
    
      
    
---
## 6. Instalasi Lingkungan Vibe Coding (Web App Developer)
Pada bagian ini anda perlu memahami dimana _Command_ akan ditempelkan karena di tahap ini kita akan menggunakan 2 terminal. berikut adalah perbedaan tanda yang akan saya berikan:

**[TERMUX / XFCE]** = **`~ $`** _command_

**[UBUNTU / PRoot]** = **`root@ubuntu:~#`** _command_
> untuk keluar dari PRoot Terminal gunakan command `exit`.

> terminal bisa saja menuliskan **`root@localhost:~#`** keduanya sama saja.


### Editor Kode

Instal **Geany** sebagai editor utama yang sangat ringan *(penggunaan RAM < 50 MB)* dan **Proot Distro** sebagai wadah untuk menjalankan AI CLI.
**`~ $`**
```
pkg install geany proot-distro -y

```
*Optional: **Code-oss** (Versi Open Source **VSCode**) , gantilah `geany` dengan `code-oss` sehingga menjadi:*
**`~ $`**
```
pkg install code-oss proot-distro -y
```
> **Code-oss** berbasis Electron yang membutuhkan RAM 400 MB – 700 MB+

### AI CLI Agent & 9router
**A. Persiapkan folder untuk konfigurasi** (Di Termux Native):
Persiapkan folder untuk "9router" & folder "konfigurasi OpenCode", serta folder "Projects" untuk bekerja dengan AI-CLI dengan Command:
**`~ $`**
```
mkdir -p ~/.9router ~/.config ~/projects

```
> ini akan memeriksa ketersediaan atau membuat folder `home/.9router`, `home/.config`, dan folder `home/projects` untuk keperluan Agentic/Vibe Coding. sehingga memudahkan untuk konfigurasi manual dengan GUI Desktop Xfce4.

**B. Install PRoot dan Masuk ke Lingkungan Ubuntu**
Install dan Jalankan Setup Ubuntu dengan PRoot Distro untuk pemasangan AI-CLI dan 9router. Pasang dan masuk ke lingkungan Ubuntu dengan command:
**`~ $`**
```
proot-distro install ubuntu
proot-distro login ubuntu

```
> Selalu gunakan command `proot-distro login ubuntu` untuk memulai menjalankan **terminal PRoot** untuk memulai Vibe Coding *(9router + OpenCode)*


**C. Install Node.js LTS** (Di dalam PRoot Ubuntu):
**`root@ubuntu:~#`**
```
apt update && apt upgrade -y
apt install curl git -y
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt install -y nodejs

```

**D. Buat Symlink Konfigurasi & Home** (Di dalam PRoot Ubuntu):
pastikan bahwa direktori home anda terletak di `/data/data/com.termux/files/home/` karna letak direktori bisa saja berbeda tergantung jenis device.
Periksa melalui **Thunar File Manager** (masuk ke mode desktop terlebih dahulu `**~ $**` `_pc_`, buka folder "Home" yang ada di desktop)!
Jika berbeda sesuaikanlah baris command dibawah ini. Jika sama, maka bisa langsung menggunakan Command berikut:
**`root@ubuntu:~#`**
```
# Hapus folder/symlink lama jika ada
rm -rf /root/.config /root/.9router /root/home /root/projects

# Buat symlink langsung ke direktori Termux
ln -s /data/data/com.termux/files/home/.config /root/.config
ln -s /data/data/com.termux/files/home/.9router /root/.9router
ln -s /data/data/com.termux/files/home /root/home
ln -s /data/data/com.termux/files/home/projects /root/projects

```
> Pastikan dengan command `ls -la` dan anda dapat melihat folder `.config`, `.9router`, `projects` dan `home` memiliki tanda `-> [folder tujuan]`

**E. Install Paket Global** (Di dalam PRoot Ubuntu):
 Instal 9router dan OpenCode di Dalam PRoot Ubuntu:
 **`root@ubuntu:~#`**
```
npm install -g 9router opencode-ai

```
> anda bisa keluar dari terminal PRoot terlebih dahulu dengan command `exit`, lalu `[Enter]`
>

### Membuat Shortcut Terminal PRoot
Buat pintasan (Shortcut) untuk membuka terminal PRoot di Desktop secara instant, jalankan Command berikut di `Xfce4 Terminal` atau Langsung dari `Termux` (di luar PRoot):
**`~ $`**
```
mkdir -p ~/Desktop

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
```
> Skrip diatas akan membuat file `Terminal-PRoot.desktop` yang bisa di klik. dan langsung bekerja dalam direktori `root` lingkungan PRoot distro Ubuntu.

Jika ingin Langsung menjalankan **Terminal PRoot distro pada home**, kita membutuhkan file `.sh` untuk mengatur `--workdir` berjalan pada home. Jalankan script berikut pada **`Termux`/`Xfce4 Terminal`** di mode desktop (di Luar PRoot Ubuntu):
**`~ $`**
```
cat << 'EOF' > ~/start-proot-home.sh
#!/bin/bash
proot-distro login ubuntu -- bash -c "cd /root/home; exec bash"
EOF

chmod +x ~/start-proot-home.sh

```
Buat file `.desktop`-nya (**`Termux`/`Xfce4 Terminal`**):
**`~ $`**
```
cat << 'EOF' > ~/Desktop/proot-home.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=PRoot Home Terminal
Exec=xfce4-terminal -e "/data/data/com.termux/files/home/start-proot-home.sh"
Icon=utilities-terminal
Terminal=false
Categories=System;TerminalEmulator;
EOF

chmod +x ~/Desktop/proot-home.desktop

```

> membuat terminal PRoot berjalan di lingkungan folder `home` Desktop Xfce4 Termux:X11.


---
## 7. Pintasan AI Agent di Desktop Xfce4

Buat peluncur di desktop yang akan menyalakan `9router` secara otomatis dan mengeksekusi `Open Code` di dalam terminal PRoot.
**A. Jalankan perintah ini di terminal `Termux`/`Xfce4 Terminal` (luar PRoot)**:
**`~ $`**
```
cat << 'EOF' > ~/start-ai.sh
#!/bin/bash

# 1. Pastikan direktori projects ada di Termux
mkdir -p ~/projects

# 2. Eksekusi masuk PRoot, pindah folder, jalankan 9router & opencode
proot-distro login ubuntu -- bash -c "cd /root/projects && 9router & sleep 2 && opencode; exec bash"
EOF

# Beri izin eksekusi
chmod +x ~/start-ai.sh

```
**B. Buat File `.desktop` Menuju Skrip Tersebut**
Buat file `.desktop` yang hanya bertugas memanggil skrip `~/start-ai.sh` **(diluar PRoot)**:
**`~ $`**
```
cat << 'EOF' > ~/Desktop/AI-Agent.desktop
[Desktop Entry]
Version=1.0
Type=Application
Name=AI Agent Workspace
Comment=Menjalankan AI Agent Workspace
Exec=xfce4-terminal --title="AI Agent" -e "/data/data/com.termux/files/home/start-ai.sh"
Icon=utilities-terminal
Terminal=false
Categories=Development;
EOF

chmod +x ~/Desktop/AI-Agent.desktop

```
_Port untuk membuka 9router adalah: `http://localhost:20128` atau `http://127.0.0.1:20128`_

---
## 8. Pembuatan Pintasan Langsung (Shortcut) di Homescreen Android

Langkah ini membuat akses satu kali ketuk dari layar utama _smartphone_ langsung menuju Desktop Xfce4.

1.  Buka F-Droid dan instal aplikasi **Termux:Widget**.

2.  Buka Termux, buat direktori pintasan, dan buat skrip eksekutor:
**`~ $`**
```
mkdir -p ~/.shortcuts
echo -e '#!/data/data/com.termux/files/usr/bin/bash\npc' > ~/.shortcuts/Mulai-Desktop.sh
chmod +x ~/.shortcuts/Mulai-Desktop.sh

```

3.  Kembali ke layar utama Android (Homescreen).

4.  Tekan dan tahan area kosong, lalu pilih **Widget**.

5.  Pilih **Termux:Widget** dan letakkan di layar utama.

6.  Ketuk **Mulai-Desktop.sh** pada widget untuk langsung masuk ke lingkungan kerja Xfce4.

---
---

Bonus:
> **Skrip Pintasan Terminal Opsional (Jika Dibuat)**
> Jika membuat pintasan khusus untuk langsung masuk ke direktori projects via terminal PRoot, ubah target perpindahan foldernya dengan `start-proot-projects.sh`, jalankan script berikut pada Termux/Xfce4 Terminal:
```
cat << 'EOF' > ~/start-proot-projects.sh
#!/bin/bash
proot-distro login ubuntu -- bash -c "cd /root/projects; exec bash"
EOF

chmod +x ~/start-proot-projects.sh
```

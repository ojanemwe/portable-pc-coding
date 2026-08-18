# Portable PC - Agentic Coding Setup
**Setup Portable PC (Xfce4 di Android) untuk Agentic/Vibe Coding** (Tanpa Root)

## Spesifikasi & Kebutuhan Penyimpanan

-   **Spesifikasi Minimum:** RAM 4GB, CPU Octa-core (setara Snapdragon 400-series / MediaTek Helio G-series).

-   **Spesifikasi Rekomendasi:** RAM 6GB+, CPU Snapdragon 600-series ke atas (untuk _multitasking_ dan Code-OSS).

-   **Total Penyimpanan (Storage):** ~2.5 GB hingga 4 GB (siapkan ruang kosong minimal 5 GB - 10 GB untuk untuk menampung cache NPM dan stabilitas).


## Persiapan Perangkat Android dan Install Otomatis

Langkah ini menyiapkan pondasi aplikasi dan perizinan sistem Android.
  

1.  Unduh dan instal F-Droid dari https://f-droid.org .

2.  Unduh dan instal Termux melalui F-Droid.
    
3.  Unduh dan instal Termux-X11 dari rilis GitHub di https://github.com/termux/termux-x11/releases .

4.  Matikan fitur penghemat baterai atau pembatasan baterai untuk aplikasi Termux dan Termux-X11.

5.  Aktifkan Opsi Pengembang (Developer Options) pada pengaturan Android, lalu aktifkan opsi "Disable Child Process Restrictions".

6.  Buka aplikasi Termux _(dari F-Droid)_.

7.  Jalankan perintah berikut pada Termux **`~ $`**:
    ```
	curl -sL https://raw.githubusercontent.com/ojanemwe/portable-pc-coding/main/install.sh -o ~/install.sh && bash ~/install.sh
	```
> Cukup dengan sekali Salin dan tempel, proses instalasi akan berjalan Secara interaktif dan akan meng-install semua paket yang akan saya terangkan dibawah:
>


---
Selanjutnya anda dapat **membuat Shortcut** langsung **di Home Screen** anda untuk **membuka PC-Desktop**, dengan cara:
1. Buka **F-Droid**, cari dan instal aplikasi **Termux:Widget**.

2. Kembali ke layar utama Android (Homescreen).

3. Tekan dan tahan area kosong, lalu pilih **Widget**.

4. Pilih **Termux:Widget** dan letakkan di layar utama.

5. Ketuk **PC-Desktop.sh** pada widget untuk langsung masuk ke lingkungan kerja Xfce4.

---
# Penjelasan Alur kerja `install.sh`:
> Anda dapat melakukan istalasi manual dan menyesuaikan dengan kebutuhan anda tanpa menjalankan script otomatis diatas.
>

## 1. Instalasi Paket Dasar Termux

Buka aplikasi Termux dan jalankan perintah berikut secara berurutan untuk memasang repositori dasar dan desktop Xfce4:

```
pkg update && pkg upgrade -y
pkg install tur-repo x11-repo -y
pkg install termux-x11-nightly pulseaudio wget git xfce4 -y
pkg install zen-browser -y
termux-setup-storage

```


---
## 2. Konfigurasi Launcher Script (Clean Terminal)

Buat skrip utama Shortcut desktop yang telah dimodifikasi untuk resolusi otomatis dan penghilangan _error output_.

1.  Buat berkas peluncur agar bisa membuka GUI Desktop XFCE hanya dengan menulis **`pc`** pada termux:
	```
	cat << 'EOF' > ~/pc
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
	EOF
	
	chmod +x ~/pc
	
	```
    
2.  Beri izin eksekusi dan buat alias agar mudah dipanggil:
	```
	echo 'alias pc="~/pc"' >> ~/.bashrc
	source ~/.bashrc
	
	```

---
## 3. Konfigurasi Tombol Shutdown di Desktop

Buat ikon _shutdown_ di layar desktop untuk menutup sesi dengan aman.

Jalankan perintah ini di Termux:
```
mkdir -p ~/Desktop
cat << 'EOF' > ~/Desktop/shutdown.desktop
[Desktop Entry]
Type=Application
Name=Shutdown
Exec=sh -c "current_pid=$$; pids=$(pgrep -f 'termux.x11' | grep -v $current_pid); if [ -n \"$pids\" ]; then kill -9 $pids; fi"
Icon=xfsm-shutdown
Terminal=true
Categories=System;
Path=
StartupNotify=false
EOF

chmod +x ~/Desktop/shutdown.desktop

```

> **CATATAN USER KANTORAN:** _Bagi pengguna yang hanya membutuhkan fungsi **pekerjaan kantor** dan **desain ringan**, Anda tidak perlu menerapkan Tahap 5 dan 6._
> 
>   

    
---
## 4. Instalasi Lingkungan Vibe Coding (Web App Developer)
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
*OPSI LAIN: **Code-oss** (Versi Open Source **VSCode**) , gantilah `geany` dengan `code-oss` sehingga menjadi:*
**`~ $`**
``
pkg install code-oss proot-distro -y
``
> **Code-oss** berbasis Electron yang membutuhkan RAM 400 MB – 700 MB+

### AI CLI Agent & 9router
**A. Persiapkan folder untuk konfigurasi** (Di Termux Native):

Persiapkan folder untuk "9router" & folder konfigurasi untuk semua aplikasi yang akan diinstall melalui _PRoot-Ubuntu_ seperti "OpenCode", folder PRoot yang mungkin perlu untuk anda intip dengan GUI Desktop Xfce4 seperti ".local", serta folder "Workspace" untuk bekerja dengan AI-CLI dengan Command:
**`~ $`**
```
mkdir -p ~/.9router ~/.config ~/.local-proot ~/.cache-proot ~/workspace ~/Downloads

```
> ini akan memeriksa ketersediaan atau membuat folder `home/.9router`, `home/.config`, `home/.local-proot`, `~/.cache-proot`,dan folder `home/workspace` untuk keperluan Agentic/Vibe Coding. sehingga memudahkan untuk konfigurasi manual dengan GUI Desktop Xfce4.

**B. Install PRoot dan Masuk ke Lingkungan Ubuntu**

Install dan Jalankan Setup Ubuntu dengan PRoot Distro untuk pemasangan AI-CLI dan 9router. Pasang dan masuk ke lingkungan Ubuntu dengan command:
**`~ $`**
```
proot-distro install ubuntu
proot-distro login ubuntu

```
> Sekarang lokasi eksekusi terminal berada di bagian **`root@ubuntu:~#`**

> Pada tahap ini kita akan Selalu menggunakan command `proot-distro login ubuntu` untuk memulai menjalankan **terminal PRoot** saat akan memulai Vibe Coding *(9router + OpenCode)*

**Persingkat command untuk login PRoot** :
anda dapat keluar dari PRoot-distro ubuntu terlebih dahulu dengan mengetik:

**`root@ubuntu:~#`**
```
exit
```
Sekarang Pastikan anda berada pada terminal Termux/Xfce Native **`~ $`**, Untuk mempersingkat `proot-distro login ubuntu` menjadi `~$` **`proot`** saja, tempel command berikut:

**`~ $`**
```
mkdir -p ~/bin

cat > ~/bin/proot <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login ubuntu
EOF

chmod +x ~/bin/proot

echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```
> silahkan coba dengan mengetikkan `proot` pada termux _(keluar dari PRoot terlebih dahulu)_, maka anda akan masuk ke lingkungan PRoot-Ubuntu. `proot-distro login ubuntu` tetap bisa digunakan.


**C. Install Node.js LTS** (Di dalam PRoot Ubuntu):
**`root@ubuntu:~#`**
```
apt update && apt upgrade -y
apt install curl git -y
curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && apt install -y nodejs

```
> lakukan verifikasi dengan versi yang terinstall dengan menjalankan `node --version` dan `npm --version`.

**D. Buat Symlink Konfigurasi & Home** (Di dalam PRoot Ubuntu):

pastikan bahwa direktori home anda terletak di `/data/data/com.termux/files/home/` karna letak direktori bisa saja berbeda tergantung jenis device.
Periksa melalui **Thunar File Manager** (masuk ke mode desktop terlebih dahulu **~$ pc**, buka folder "Home" yang ada di desktop)!
Jika berbeda sesuaikanlah baris command dibawah ini. Jika sama, maka bisa langsung menggunakan Command berikut:

**`root@ubuntu:~#`**
```
# Hapus folder/symlink lama jika ada
rm -rf /root/.config /root/.9router /root/.local /root/.cache /root/workspace /root/Downloads

# Buat symlink langsung ke direktori Termux
ln -s /data/data/com.termux/files/home/.config /root/.config
ln -s /data/data/com.termux/files/home/.9router /root/.9router
ln -s /data/data/com.termux/files/home/.local-proot /root/.local
ln -s /data/data/com.termux/files/home/.cache-proot /root/.cache
ln -s /data/data/com.termux/files/home/workspace /root/workspace
ln -s /data/data/com.termux/files/home/Downloads /root/Downloads

```
> untuk pemeriksaan lebih aman, gunakan `ls -ld /root/.config /root/.9router /root/.local /root/workspace /root/Downloads`. Seharusnya folder `/root/.config`, `/root/.9router`, `/root/.local`, `/root/workspace`, dan `/root/Downloads` memang tidak ada saat awal menggunakan PRoot-distro maka command `rm -rf` tidak akan berdampak.

> Folder `/root/.local` sengaja dibuat tanpa "-proot" karena secara default pemasangan aplikasi akan membaca ".local". Symlink untuk folder `Downloads` juga sengaja saya tambahkan agar ketika bekerja dengan opencode kita dapat meminta AI untuk memeriksa dan bekerja menggunakan file yang kita download pada lingkungan Desktop Xfce4 Native.

> Pastikan dengan command `ls -la` dan anda dapat melihat folder `.config`, `.9router`, dan `workspace` memiliki tanda `-> [folder tujuan]`

**E. Install Paket Global** (Di dalam PRoot Ubuntu):
 
 **Instal 9router dan OpenCode** di Dalam PRoot Ubuntu:
**`root@ubuntu:~#`**
```
npm install -g 9router opencode-ai

```
> anda bisa keluar dari terminal PRoot terlebih dahulu dengan command `exit`, lalu `[Enter]`
>

**F. Menghubungkan 9router dengan OpenCode**

Karena kita telah melakukan Symlink folder `.config` maka Kita dapat melakukan konfigurasi melalui `Thunar File Manager` pada desktop mode (`~$ pc` > `[Enter]`) dengan cara:
1. Buka **Xfce Terminal** (Aplication > System > Xfce Terminal).

2. Jalankan command `proot-distro login ubuntu` (maka anda telah berada di lingkungan PRoot-Ubuntu **`root@ubuntu:~#`**). 

3. Jalankan 9router dengan command: `9router`, dan buka interface 9router dengan **Web UI (Open in Browser)**

4. Anda akan mendapatkan URL untuk dibuka pada browser berupa `http://localhost:20128/dashboard` atau `http://127.0.0.1:20128/dashboard`

5. Masuk ke menu **CLI Tools**, pilih **OpenCode**, dan Klik **Manual Config**

6. Salin Script untuk konfigurasi, 

7. Buka folder `home` melalui **Thunar File Manager** dan masuk ke folder `.config/opencode`

8. Buat file baru dengan cara: klik kanan _(tap 2 jari)_ pada area kosong didalam folder, "`Create Document`" > "`Empty File`" dan buat nama **`opencode.json`** 

9. Buka file tersebut dengan Geany/Mousepad/Fatherpad(_default_), dan **Tempel** Script yang sebelumnya anda salin lalu sesuaikan dengan provider dan model yang telah anda koneksikan.

10. Simpan file. dan _reload_ halaman 9router yang anda buka pada browser.

> Dari langkah ke-4 anda bisa melakukan koneksi ke Provider dan mengatur model terlebih dahulu, maka cara ke 6 dan seterusnya tidak perlu lagi anda atur karena sudah terdapat daftar yang terhubung.

> 9router dan OpenCode telah terkoneksi. anda telah dapat mengatur setup Agent OpenCode dengan 9router.


### Membuat Shortcut untuk Terminal PRoot
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

---
## 5. Pintasan AI Agent di Desktop Xfce4

### A. Membuka 9router dan OpenCode langsung dari Xfce4 Terminal
Kita dapat mempersingkat proses untuk membuka 9router dan OpenCode dengan menggunakan Wrapper yang awalnya perlu menulis `~$ proot-distro login ubuntu` (Xfce Terminal) > `root@ubuntu:~# opencode` _(pada PRoot)_
**menjadi `~$ opencode` saja pada XFce Terminal**. 
> Pastikan terlebih dahulu bahwa struktur direktori anda adalah: **`/data/data/com.termux/`dst** jika berbeda, maka sesuaikanlah wrappernya sebelum menjalankannya!

Gunakan command berikut pada Termux / Xfce Terminal:

**`~ $`**
```
mkdir -p ~/bin

cat > ~/bin/opencode <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login ubuntu -- opencode
EOF

cat > ~/bin/9router <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login ubuntu -- 9router
EOF

chmod +x ~/bin/opencode ~/bin/9router
```
> Sekarang anda dapat membuka OpenCode dan 9router hanya dengan menggunakan **Xfce Terminal** dengan command **`opencode` dan `9router`** langsung.


Buat peluncur di desktop yang akan menyalakan `9router` secara otomatis dan mengeksekusi `Open Code` di dalam terminal PRoot.

### B. Membuat File Shortcut `.desktop`

Anda dapat menempel script berikut untuk membuat Shortcut **OpenCode** di Desktop Xfce4 :
**`~ $`**
```
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

```

untuk **9router**:
**`~ $`**
```
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

```

_Port untuk membuka 9router adalah: `http://localhost:20128` atau `http://127.0.0.1:20128`_

> Jalankan **9router** terlebih dahulu sebelum menjalankan **OpenCode**

Untuk shortcut **9router** (background) + **OpenCode** sekaligus:

**`~ $`**
```
cat <<'EOF' > ~/Desktop/Ai-Workspace.desktop
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
```
> **UNTUK MENJALANKAN SHORTCUT INI ANDA WAJIB MEMERIKSA UPDATE 9ROUTER TERLEBIH DAHULU!**


---
## 6. Pembuatan Pintasan Langsung (Shortcut) di Homescreen Android

Langkah ini membuat akses satu kali ketuk dari layar utama _smartphone_ langsung menuju Desktop Xfce4.

1.  Buka F-Droid dan instal aplikasi **Termux:Widget**.

2.  Buka Termux, buat direktori pintasan, dan buat skrip eksekutor:
**`~ $`**
```
mkdir -p ~/.shortcuts
echo -e '#!/data/data/com.termux/files/usr/bin/bash\npc' > ~/.shortcuts/PC-Desktop.sh
chmod +x ~/.shortcuts/PC-Desktop.sh

```
dan buat agar `PC-Desktop.sh` mengeksekusi perintah `pc`:

```
cat << 'EOF' > ~/.shortcuts/PC-Desktop.sh
#!/data/data/com.termux/files/usr/bin/bash

exec "$HOME/pc"
EOF

chmod 700 ~/.shortcuts/PC-Desktop.sh
```

3.  Kembali ke layar utama Android (Homescreen).

4.  Tekan dan tahan area kosong, lalu pilih **Widget**.

5.  Pilih **Termux:Widget** dan letakkan di layar utama.

6.  Ketuk **PC-Desktop.sh** pada widget untuk langsung masuk ke lingkungan kerja Xfce4.
---

## 7. Instalasi Aplikasi Kantoran & Desain
Masuk Ke Desktop GUI Xfce. Buka terminal,
Jalankan perintah instalasi berikut pada **Xfce4 Terminal**:
```
pkg install libreoffice mousepad featherpad gimp -y

```


### Konfigurasi Default Pembaca Teks (.txt & .md)
```
xdg-mime default mousepad.desktop text/plain
xdg-mime default featherpad.desktop text/markdown

```

### Konfigurasi GIMP menjadi PhotoGIMP (Mirip Photoshop)
Buka GIMP terlebih dahulu pada Desktop XFCE4 Termux:X11 dan tutup kembali agar aplikasi secara otomatis membuat folder yang diperlukan, lalu buka `Xfce Terminal` dengan klik **Aplication > System > Xfce Terminal**, dan tempel command berikut!
```
git clone https://github.com/Diolinux/PhotoGIMP.git
GIMP_VER=$(pkg show gimp | grep -i "Version" | grep -oE '[0-9]+\.[0-9]+' | head -n 1)
PHOTOGIMP_VER=$(ls PhotoGIMP/.var/app/org.gimp.GIMP/config/GIMP/ | sort -V | tail -n 1)
mkdir -p ~/.config/GIMP/$GIMP_VER/
cp -r PhotoGIMP/.var/app/org.gimp.GIMP/config/GIMP/$PHOTOGIMP_VER/* ~/.config/GIMP/$GIMP_VER/
rm -rf PhotoGIMP

```
> Command diatas bersifat dinamis dan akan secara otomatis menempatkan file PhotoGIMP versi terakhir ke folder `.config/GIMP/[versi berapapun]`


### Konfigurasi Default Format LibreOffice (.docx)

1.  Jalankan `pc` untuk masuk ke Desktop Xfce4.

2.  Buka LibreOffice.

3.  Masuk ke **Tools > Options** (`Alt + F12`).

4.  Navigasi ke **Load/Save > General**.

5.  Ubah _Always save as_ menjadi **Word 2007-365 (.docx)**. Klik Apply dan OK.

6. Lakukan hal yang sama untuk Spreadsheet **(Excel .xlsx)** dan Presentation **(PowerPoint .pptx)**. 
    


---
---

## F.A.Q
Q: Kenapa harus menggunakan **Symlink** jika kita bisa menggunakan **--shared-home**?

A: Karena kita menghindari agar AI Agent yang berjalan di PRoot tidak membaca file dan folder yang terkoneksi langsung dengan Android Storage.

**Optional (TIDAK DIREKOMENDASIKAN jika menjalankan AI):**
Jika ingin Langsung menjalankan **Terminal PRoot distro pada home**,
gunakan wrapper dan `--shared-home` dengan script berikut untuk mempersingkat `proot-distro login ubuntu --shared-home` menjadi `~$` **`ubuntu`** saja:

**`~ $`**
```
cat > ~/bin/ubuntu <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash
exec proot-distro login ubuntu --shared-home
EOF
chmod +x ~/bin/ubuntu
```
> Terminal PRoot-distro akan bekerja di `$HOME` Termux hanya dengan command "ubuntu"
> > membuat terminal PRoot berjalan di lingkungan folder `home` Desktop Xfce4 Termux:X11 yang juga dapat mengakses data Android anda. **TIDAK DIREKOMENDASIKAN jika menjalankan AI**

---
---

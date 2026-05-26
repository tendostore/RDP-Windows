# 🚀 Windows RDP Auto Installer untuk VPS Linux

### ⚡ Quick Install (Jalankan perintah ini di Terminal VPS Anda sebagai Root)
Karena skrip ini bersifat interaktif (membutuhkan input pilihan OS, Port, dan Password), gunakan perintah gabungan di bawah ini agar proses instalasi berjalan lancar:

**Menggunakan Wget (Direkomendasikan):**
```bash
wget [https://raw.githubusercontent.com/tendostore/RDP-Windows/main/install.sh](https://raw.githubusercontent.com/tendostore/RDP-Windows/main/install.sh) && chmod +x install.sh && ./install.sh
```

**Atau menggunakan cURL:**
```bash
curl -O [https://raw.githubusercontent.com/tendostore/RDP-Windows/main/install.sh](https://raw.githubusercontent.com/tendostore/RDP-Windows/main/install.sh) && chmod +x install.sh && ./install.sh
```

---

## 📖 Deskripsi
Skrip otomatis (Auto-Installer) untuk memasang dan menjalankan sistem operasi Windows beserta fitur Remote Desktop (RDP) di dalam VPS Linux. Skrip ini menggunakan teknologi virtualisasi QEMU/KVM melalui Docker, sehingga sangat aman dan tidak merusak sistem operasi Linux asli Anda. 

Sangat cocok untuk VPS dengan spesifikasi terbatas karena menyediakan pilihan OS Windows versi "Lite" (Tiny10 & Tiny11).

## ✨ Fitur Utama
- **Interaktif:** Dilengkapi menu pilihan saat skrip dijalankan.
- **Pilihan OS Ringan:** Mendukung Tiny10 (RAM 2GB) dan Tiny11 (RAM 4GB).
- **Custom Port RDP:** Bebas menentukan Port RDP (mencegah brute-force bot dari internet).
- **Custom Password:** Bebas mengatur kata sandi untuk akun Administrator.
- **Anti Account Lockout:** Bebas login berulang kali tanpa khawatir akun terkunci.
- **Auto-Swap 4GB:** Otomatis membuat Virtual RAM tambahan agar VPS tidak hang saat proses instalasi.
- **Auto UFW:** Otomatis membukakan port di firewall internal Linux.

## ⚙️ Persyaratan Sistem
- **OS:** Ubuntu (20.04/22.04/24.04) atau Debian.
- **Akses:** Wajib dijalankan sebagai root.
- **Virtualisasi:** VPS wajib mendukung KVM (Hardware Virtualization).
- **Spesifikasi Minimal:** 2 Core CPU & 2 GB RAM.

## 🛠️ Panduan Penggunaan
1. Login ke VPS Anda menggunakan SSH.
2. Jalankan salah satu perintah **Quick Install** di bagian atas halaman ini.
3. Ikuti instruksi di layar untuk memilih versi Windows, mengetikkan Port RDP, dan Password Anda.
4. **SANGAT PENTING:** Setelah skrip selesai di terminal, segera buka browser (Chrome/Firefox) dan akses `http://<IP_VPS_ANDA>:8006` untuk memantau proses setup awal Windows. Jika proses berhenti di pilihan lisensi atau partisi, silakan klik secara manual menggunakan mouse dari browser.
5. Setelah layar browser berhasil menampilkan Desktop Windows, RDP Anda telah siap digunakan.

## 🔐 Koneksi RDP
Gunakan detail berikut pada aplikasi Remote Desktop Connection (MSTSC) Anda:
- **Computer / IP:** `<IP_VPS_ANDA>:<PORT_YANG_ANDA_BUAT>` (contoh: 192.168.1.1:6677)
- **Username:** `Administrator`
- **Password:** Sesuai dengan yang Anda inputkan saat instalasi.

> **Catatan:** Pastikan Port 8006 dan Port RDP kustom yang Anda buat sudah diizinkan (Allow) pada pengaturan Firewall / Security Group di panel web provider VPS Anda.

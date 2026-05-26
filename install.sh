#!/bin/bash

# ==============================================================================
# Skrip Otomatis Instalasi Windows RDP di VPS Linux (via QEMU Docker)
# File: install.sh
# Fitur: OS Selection, Custom Port & Pass, Fix Account Lockout, Auto-Swap, UFW
# ==============================================================================

# 1. Validasi Akses Root
if [ "$EUID" -ne 0 ]; then
  echo "Error: Harap jalankan skrip ini sebagai root (sudo su)."
  exit 1
fi

clear
echo "=========================================================================="
echo "       SKRIP OTOMATIS INSTALASI WINDOWS RDP DI VPS LINUX                  "
echo "=========================================================================="
echo ""

# 2. Input Kustom dari Pengguna (Interactive)
echo "Silakan atur konfigurasi RDP Anda di bawah ini:"
echo "------------------------------------------------"

# Pilihan OS
echo "Pilih versi Windows yang ingin diinstal:"
echo "1) Tiny10 23H1 x64 (Windows 10 Super Ringan - RAM 2GB)"
echo "2) Tiny11 24H2 x64 (Windows 11 Ringan - RAM 4GB)"
read -p "Masukkan pilihan Anda (1/2) [Default: 1]: " OS_CHOICE

case $OS_CHOICE in
    2)
        WIN_VERSION="https://archive.org/download/tiny-11-24-h-2-x-64-26100.1742/tiny11%2024H2%20x64%20-%2026100.1742.iso"
        RAM_ALLOCATED="4G"
        OS_NAME="Tiny11 24H2 x64"
        ;;
    *)
        WIN_VERSION="https://archive.org/download/tiny-10_202301/tiny10%2023h1%20x64.iso"
        RAM_ALLOCATED="2G"
        OS_NAME="Tiny10 23H1 x64"
        ;;
esac

echo ""
RDP_USER="Administrator"
echo "Username RDP otomatis disetel ke : $RDP_USER"

# Meminta input Port
read -p "Masukkan Port RDP kustom (contoh: 3389, 5500, 6677) [Default: 3389]: " RDP_PORT
if [ -z "$RDP_PORT" ]; then
    RDP_PORT="3389"
fi

# Meminta input Password
read -p "Masukkan Password untuk akun Administrator [Default: AdminVPS123!]: " RDP_PASS
if [ -z "$RDP_PASS" ]; then
    RDP_PASS="AdminVPS123!"
fi
echo "------------------------------------------------"
echo ""

# 3. Cek Akselerasi KVM
echo "[1/6] Memeriksa dukungan virtualisasi hardware (KVM)..."
if [ -e /dev/kvm ]; then
    echo "✓ KVM Terdeteksi. Performa Windows akan berjalan maksimal."
    KVM_DEVICE="--device /dev/kvm"
else
    echo "⚠ KVM TIDAK Terdeteksi. Windows akan berjalan menggunakan emulasi."
    KVM_DEVICE=""
fi
echo ""

# 4. Update Repositori & Install Dependensi Dasar
echo "[2/6] Memperbarui sistem dan menginstal dependensi dasar..."
apt-get update -y
apt-get install -y curl wget apt-transport-https ca-certificates software-properties-common gnupg lsb-release
echo ""

# 5. Konfigurasi Swap Memory (Mencegah VPS Hang/Crash)
echo "[3/6] Memeriksa dan mengatur Swap Memory (Virtual RAM)..."
if [ ! -f /swapfile ]; then
    echo "Membuat Swap File 4GB untuk stabilitas instalasi..."
    fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "✓ Swap 4GB berhasil dibuat."
else
    echo "✓ Swap File sudah ada, melewati tahap ini."
fi
echo ""

# 6. Instalasi Docker Engine
echo "[4/6] Memeriksa dan menginstal Docker Engine..."
if ! command -v docker >/dev/null 2>&1; then
    echo "Docker belum terpasang. Menginstal Docker resmi..."
    mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg --yes
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    apt-get update -y
    apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    systemctl enable docker
    systemctl start docker
    echo "✓ Docker berhasil diinstal dan dijalankan."
else
    echo "✓ Docker sudah terpasang di sistem."
fi
echo ""

# 7. Konfigurasi Kontainer & Firewall OS
echo "[5/6] Mengonfigurasi lingkungan Windows dan Firewall OS..."
CONTAINER_NAME="windows-rdp-vps"

if [ "$(docker ps -a -q -f name=^/${CONTAINER_NAME}$)" ]; then
    echo "Menemukan kontainer lama. Menghapus untuk instalasi bersih..."
    docker stop $CONTAINER_NAME >/dev/null 2>&1
    docker rm $CONTAINER_NAME >/dev/null 2>&1
fi

# Membuka Port di UFW (Jika UFW Aktif)
if command -v ufw >/dev/null 2>&1; then
    echo "UFW terdeteksi. Membuka port 8006 dan $RDP_PORT..."
    ufw allow 8006/tcp >/dev/null 2>&1
    ufw allow $RDP_PORT/tcp >/dev/null 2>&1
    ufw allow $RDP_PORT/udp >/dev/null 2>&1
fi

# Variabel Spesifikasi Default
CPU_CORES="2"
DISK_SIZE="32G"

echo "Spesifikasi yang akan dipasang:"
echo "  - OS Version : $OS_NAME"
echo "  - RAM / CPU  : $RAM_ALLOCATED / $CPU_CORES Cores"
echo "  - Disk Size  : $DISK_SIZE"
echo "  - Username   : $RDP_USER"
echo "  - Password   : (Disembunyikan)"
echo "  - Port RDP   : $RDP_PORT"
echo ""

# 8. Menjalankan Kontainer Windows RDP
echo "[6/6] Mengunduh ISO dan meluncurkan kontainer..."
    
docker run -d \
  --name "$CONTAINER_NAME" \
  --restart always \
  $KVM_DEVICE \
  -p 8006:8006 \
  -p $RDP_PORT:3389/tcp \
  -p $RDP_PORT:3389/udp \
  -e VERSION="$WIN_VERSION" \
  -e RAM_SIZE="$RAM_ALLOCATED" \
  -e CPU_CORES="$CPU_CORES" \
  -e DISK_SIZE="$DISK_SIZE" \
  -e USERNAME="$RDP_USER" \
  -e PASSWORD="$RDP_PASS" \
  -e RDP="true" \
  --vga qxl \
  dockur/windows

IP_PUBLIK=$(curl -s ifconfig.me || curl -s icanhazip.com)

echo ""
echo "=========================================================================="
echo "                  PROSES INSTALASI MULAI BERJALAN!                       "
echo "=========================================================================="
echo "1. PANTAU INSTALASI (WAJIB DIBUKA SEKARANG):"
echo "   URL: http://$IP_PUBLIK:8006"
echo ""
echo "2. AKSES RDP (Setelah Instalasi Selesai & Masuk Desktop):"
echo "   Gunakan aplikasi Remote Desktop Connection dengan detail berikut:"
echo "   Computer/IP : $IP_PUBLIK:$RDP_PORT"
echo "   Username    : $RDP_USER"
echo "   Password    : Sesuai yang Anda inputkan di awal."
echo "=========================================================================="

# === SELESAI ===


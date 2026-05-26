#!/bin/bash

# ==============================================================================
# Skrip Otomatis Instalasi Windows RDP di VPS Linux (via QEMU Docker)
# File: install.sh
# Fitur: OS Selection, Custom Port & Pass, Fix Account Lockout, Auto-Swap, UFW
# Fix: Penyesuaian nama image Docker Hub (dockurr/windows)
# ==============================================================================

if [ "$EUID" -ne 0 ]; then
  echo "Error: Harap jalankan skrip ini sebagai root (sudo su)."
  exit 1
fi

clear
echo "=========================================================================="
echo "       SKRIP OTOMATIS INSTALASI WINDOWS RDP DI VPS LINUX                  "
echo "=========================================================================="
echo ""

echo "Silakan atur konfigurasi RDP Anda di bawah ini:"
echo "------------------------------------------------"
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

read -p "Masukkan Port RDP kustom (contoh: 3389, 5500, 6677) [Default: 3389]: " RDP_PORT
if [ -z "$RDP_PORT" ]; then
    RDP_PORT="3389"
fi

read -p "Masukkan Password untuk akun Administrator [Default: AdminVPS123!]: " RDP_PASS
if [ -z "$RDP_PASS" ]; then
    RDP_PASS="AdminVPS123!"
fi
echo "------------------------------------------------"
echo ""

echo "[1/6] Memeriksa dukungan KVM..."
if [ -e /dev/kvm ]; then
    echo "✓ KVM Terdeteksi."
    KVM_DEVICE="--device /dev/kvm"
else
    echo "⚠ KVM TIDAK Terdeteksi."
    KVM_DEVICE=""
fi
echo ""

echo "[2/6] Memperbarui sistem..."
apt-get update -y >/dev/null 2>&1
echo "✓ Selesai."
echo ""

echo "[3/6] Mengatur Swap Memory..."
if [ ! -f /swapfile ]; then
    fallocate -l 4G /swapfile || dd if=/dev/zero of=/swapfile bs=1M count=4096
    chmod 600 /swapfile
    mkswap /swapfile >/dev/null 2>&1
    swapon /swapfile
    echo '/swapfile none swap sw 0 0' >> /etc/fstab
    echo "✓ Swap 4GB berhasil dibuat."
else
    echo "✓ Swap File sudah ada."
fi
echo ""

echo "[4/6] Memeriksa Docker..."
if ! command -v docker >/dev/null 2>&1; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh >/dev/null 2>&1
    systemctl enable docker
    systemctl start docker
    echo "✓ Docker berhasil diinstal."
else
    echo "✓ Docker sudah terpasang."
fi
echo ""

echo "[5/6] Mengonfigurasi Firewall..."
CONTAINER_NAME="windows-rdp-vps"
docker rm -f $CONTAINER_NAME >/dev/null 2>&1

if command -v ufw >/dev/null 2>&1; then
    ufw allow 8006/tcp >/dev/null 2>&1
    ufw allow $RDP_PORT/tcp >/dev/null 2>&1
    ufw allow $RDP_PORT/udp >/dev/null 2>&1
fi
echo "✓ Lingkungan disiapkan."
echo ""

CPU_CORES="2"
DISK_SIZE="32G"

echo "[6/6] Menjalankan kontainer Windows RDP..."
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
  dockurr/windows

IP_PUBLIK=$(curl -s ifconfig.me || curl -s icanhazip.com)

echo ""
echo "=========================================================================="
echo "                  PROSES INSTALASI MULAI BERJALAN!                       "
echo "=========================================================================="
echo "1. PANTAU INSTALASI (WAJIB DIBUKA SEKARANG):"
echo "   URL: http://$IP_PUBLIK:8006"
echo ""
echo "2. AKSES RDP (Setelah Instalasi Selesai & Masuk Desktop):"
echo "   Computer/IP : $IP_PUBLIK:$RDP_PORT"
echo "   Username    : $RDP_USER"
echo "=========================================================================="

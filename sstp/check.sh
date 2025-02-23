#!/bin/bash
# ==========================================
# SSTP Account Checker
# ==========================================

# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'

# ==========================================
# Cek Izin Akses
MYIP=$(wget -qO- ipinfo.io/ip)
AUTHORIZED_IP=$(curl -s ipinfo.io/ip | grep "$MYIP")

echo -e "${CYAN}Memverifikasi akses VPS Anda...${NC}"

if [ "$AUTHORIZED_IP" ]; then
    echo -e "${GREEN}Akses diizinkan!${NC}"
else
    echo -e "${RED}Akses ditolak!${NC}"
    echo -e "${YELLOW}Hubungi admin jika ini adalah kesalahan.${NC}"
    exit 1
fi

clear

# Menampilkan sesi aktif SSTP
echo -e "${LIGHT}Menampilkan sesi SSTP yang sedang aktif...${NC}"
echo ""
accel-cmd show sessions
echo ""
echo -e "${GREEN}Pengecekan selesai.${NC}"
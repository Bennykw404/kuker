#!/bin/bash
# ==========================================
#            🚀 VPS ACCESS CHECK 🚀
# ==========================================

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
NC='\033[0m'

# ==========================================
# Memeriksa IP VPS
MYIP=$(curl -4 -s https://checkip.amazonaws.com)
echo -e "${CYAN}🔍 Memeriksa VPS Anda...${NC}"
IZIN=$(curl -4 -s https://checkip.amazonaws.com | grep -w "$MYIP")

if [[ -n "$IZIN" ]]; then
    echo -e "${GREEN}✅ Akses Diterima!${NC}"
else
    echo -e "${RED}❌ Akses Ditolak!${NC}"
    echo -e "${ORANGE}🚫 Anda tidak memiliki izin untuk mengakses server ini.${NC}"
    exit 1
fi

# Membersihkan layar
clear

# Menampilkan sesi aktif di Accel
echo -e "${BLUE}📡 Menampilkan sesi aktif di Accel...${NC}"
accel-cmd show sessions

echo -e "\n${GREEN}✅ Proses selesai!${NC}"

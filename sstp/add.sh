#!/bin/bash
# ==========================================
#          🚀 SSTP VPN SETUP 🚀
# ==========================================

# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'

# ==========================================
# Memeriksa IP VPS
MYIP=$(curl -4 -s https://checkip.amazonaws.com)
echo -e "${CYAN}🔍 Memeriksa VPS...${NC}"
IZIN=$(curl -4 -s https://checkip.amazonaws.com | grep $MYIP)

if [[ $MYIP == $MYIP ]]; then
    echo -e "${GREEN}✅ Akses Diterima!${NC}"
else
    echo -e "${RED}❌ Akses Ditolak!${NC}"
    echo -e "${LIGHT}🚫 Anda tidak memiliki izin!${NC}"
    exit 0
fi

clear
source /var/lib/crot/ipvps.conf
domain=${IP2:-$(cat /etc/xray/domain)}
IP=$(curl -4 -s https://checkip.amazonaws.com)
sstp=$(grep 'port' /etc/accel-ppp.conf | cut -d'=' -f2)
if [[ -z "$sstp" ]]; then
    sstp="Tidak ditemukan"
fi

# Input pengguna baru
until [[ $user =~ ^[a-zA-Z0-9_]+$ && $CLIENT_EXISTS -eq 0 ]]; do
    read -rp "👤 Username Baru: " user
    CLIENT_EXISTS=$(grep -w $user /var/lib/crot/data-user-sstp | wc -l)

    if [[ $CLIENT_EXISTS -eq 1 ]]; then
        echo -e "⚠️ Username ${RED}$user${NC} sudah digunakan, silakan pilih yang lain!"
        exit 1
    fi
done

read -sp "🔑 Password: " pass
echo ""
read -p "⏳ Masa Aktif (Hari): " masaaktif

hariini=$(date -d "0 days" +"%Y-%m-%d")
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")

# Menambahkan akun ke file konfigurasi
echo -e "$user * $pass *" >> /home/sstp/sstp_account
echo -e "### $user $exp" >> "/var/lib/crot/data-user-sstp"

# Tampilan informasi akun
clear
cat <<EOF
==========================================
🚀 SSTP VPN AKUN BARU 🚀
==========================================
📌 IP/Host   : $IP
🌐 Domain    : $domain
👤 Username  : $user
🔑 Password  : $pass
🎯 Port      : $sstp
🔖 Sertifikat: http://$IP:89/server.crt
📅 Dibuat    : $hariini
⏳ Kedaluwarsa: $exp
==========================================
🎉 Script Mod By ENVEEPAY 🎉
EOF

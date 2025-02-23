#!/bin/bash
# ==========================================
# Script Renew SSTP Account - ENVEEPAY
# ==========================================

# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[0;37m'
NC='\033[0m'

# Mendapatkan IP VPS
MYIP=$(curl -4 -s https://checkip.amazonaws.com)
IZIN=$(curl -4 -s https://checkip.amazonaws.com | grep "$MYIP")

# Periksa izin akses
echo -e "${CYAN}🔍 Checking VPS...${NC}"
if [[ -z "$IZIN" ]]; then
    echo -e "${RED}❌ Permission Denied!${NC}"
    echo -e "${WHITE}⚠️  Access is restricted.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Permission Accepted...${NC}"
clear

# Periksa jumlah akun SSTP yang ada
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/var/lib/crot/data-user-sstp")
if [[ "$NUMBER_OF_CLIENTS" == '0' ]]; then
    echo -e "${RED}⚠️  No existing SSTP clients!${NC}"
    exit 1
fi

# Menampilkan daftar pengguna
echo -e "${YELLOW}📜 Select the client to renew:${NC}"
echo -e "${WHITE}Press CTRL+C to cancel.${NC}"
echo -e "==============================="
grep -E "^### " "/var/lib/crot/data-user-sstp" | cut -d ' ' -f 2-3 | nl -s ') '

# Memilih pengguna
while true; do
    read -rp "📝 Select a client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
    if [[ "$CLIENT_NUMBER" =~ ^[0-9]+$ ]] && [[ "$CLIENT_NUMBER" -ge 1 ]] && [[ "$CLIENT_NUMBER" -le "$NUMBER_OF_CLIENTS" ]]; then
        break
    fi
    echo -e "${RED}⚠️  Invalid selection! Try again.${NC}"
done

# Memasukkan masa aktif tambahan
while true; do
    read -rp "📅 Extend by (days): " masaaktif
    if [[ "$masaaktif" =~ ^[0-9]+$ ]] && [[ "$masaaktif" -gt 0 ]]; then
        break
    fi
    echo -e "${RED}⚠️  Please enter a valid number of days!${NC}"
done

# Mendapatkan informasi akun
user=$(grep -E "^### " "/var/lib/crot/data-user-sstp" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
exp=$(grep -E "^### " "/var/lib/crot/data-user-sstp" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)
now=$(date +%Y-%m-%d)
d1=$(date -d "$exp" +%s)
d2=$(date -d "$now" +%s)
exp2=$(( (d1 - d2) / 86400 ))
exp3=$((exp2 + masaaktif))
exp4=$(date -d "$exp3 days" +"%Y-%m-%d")

# Memperbarui data pengguna
sed -i "s/### $user $exp/### $user $exp4/g" /var/lib/crot/data-user-sstp

# Menampilkan hasil
clear
echo -e "${GREEN}🎉 SSTP Account Renewed!${NC}"
echo -e "==========================="
echo -e "👤 Username  : ${CYAN}$user${NC}"
echo -e "📆 Expired   : ${YELLOW}$exp4${NC}"
echo -e "==========================="
echo -e "🔧 Script by ENVEEPAY 🚀"

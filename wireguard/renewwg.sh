#!/bin/bash
# SL - Optimized WireGuard Renewal Script
# ==========================================
# Warna untuk output terminal
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
LIGHT='\033[0;37m'

# ==========================================
# Cek IP VPS
MYIP=$(wget -qO- ipinfo.io/ip)
AUTHORIZED_IP=$(curl -s ipinfo.io/ip | grep -w "$MYIP")

if [[ -z "$AUTHORIZED_IP" ]]; then
    echo -e "${NC}${RED}Permission Denied!${NC}"
    echo -e "${NC}${LIGHT}Fuck You!!"
    exit 1
fi

echo -e "${NC}${GREEN}Permission Accepted...${NC}"
clear

# Load parameter WireGuard
source /etc/wireguard/params

WG_CONFIG="/etc/wireguard/$SERVER_WG_NIC.conf"
NUMBER_OF_CLIENTS=$(grep -c "^### Client" "$WG_CONFIG")

if [[ "$NUMBER_OF_CLIENTS" -eq 0 ]]; then
    echo -e "${RED}You have no existing clients!${NC}"
    exit 1
fi

# Menampilkan daftar klien
clear
echo -e "\n============================="
echo "   Select a client to renew"
echo "   Press CTRL+C to cancel"
echo "============================="
echo "No   | Expired   | Username"
echo "-----------------------------"

grep "^### Client" "$WG_CONFIG" | awk '{print NR ") " $4, $3}'

# Meminta input dari pengguna dengan validasi angka
while true; do
    read -rp "Select one client [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
    if [[ "$CLIENT_NUMBER" =~ ^[0-9]+$ ]] && (( CLIENT_NUMBER >= 1 && CLIENT_NUMBER <= NUMBER_OF_CLIENTS )); then
        break
    fi
    echo -e "${RED}Invalid input! Please enter a number between 1 and ${NUMBER_OF_CLIENTS}.${NC}"
done

while true; do
    read -rp "Extend expiration (days): " masaaktif
    if [[ "$masaaktif" =~ ^[0-9]+$ ]] && (( masaaktif > 0 )); then
        break
    fi
    echo -e "${RED}Invalid input! Please enter a positive number.${NC}"
done

# Mengambil informasi klien berdasarkan pilihan
CLIENT_INFO=$(grep "^### Client" "$WG_CONFIG" | sed -n "${CLIENT_NUMBER}p")
USER=$(echo "$CLIENT_INFO" | awk '{print $3}')
EXPIRY_OLD=$(echo "$CLIENT_INFO" | awk '{print $4}')

# Menghitung tanggal expired baru
EXPIRY_NEW=$(date -d "$EXPIRY_OLD + $masaaktif days" +"%Y-%m-%d")

# Memperbarui tanggal expired dalam konfigurasi WireGuard
sed -i "s/### Client $USER $EXPIRY_OLD/### Client $USER $EXPIRY_NEW/g" "$WG_CONFIG"

# Restart WireGuard
systemctl restart "wg-quick@$SERVER_WG_NIC"

# Menampilkan pesan sukses
clear
echo -e "\n============================="
echo -e "  WireGuard Account Renewed  "
echo -e "============================="
echo -e "Username  : $USER"
echo -e "Old Expiry: $EXPIRY_OLD"
echo -e "New Expiry: $EXPIRY_NEW"
echo -e "============================="
echo -e "Script Mod By ENVEEPAY"

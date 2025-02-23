#!/bin/bash
# ==========================================
# Warna
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
NC='\033[0m' # No Color
# ==========================================
# Mendapatkan IP VPS
MYIP=$(wget -qO- ipinfo.io/ip);
echo -e "${CYAN}Checking VPS...${NC}"

# Cek izin akses VPS
IZIN=$(curl -s ipinfo.io/ip | grep $MYIP)
if [[ -n "$IZIN" ]]; then
    echo -e "${GREEN}Permission Accepted...${NC}"
else
    echo -e "${RED}Permission Denied!${NC}"
    echo -e "${ORANGE}Akses ditolak!${NC}"
    exit 1
fi

clear
source /var/lib/crot/ipvps.conf
if [[ -z "$IP2" ]]; then
    domain=$(cat /etc/xray/domain)
else
    domain=$IP2
fi

IP=$(wget -qO- ipinfo.io/ip);
sstp=$(grep -i SSTP ~/log-install.txt | cut -d: -f2 | sed 's/ //g')

# Meminta username baru
while true; do
    read -rp "Masukkan Username Baru: " user
    CLIENT_EXISTS=$(grep -w $user /var/lib/crot/data-user-sstp | wc -l)

    if [[ $CLIENT_EXISTS -eq 0 ]]; then
        break
    else
        echo -e "${RED}Username sudah ada. Silakan pilih yang lain.${NC}"
    fi
done

read -sp "Masukkan Password: " pass
echo ""
read -p "Masa Aktif (Hari): " masaaktif

# Menghitung tanggal kadaluarsa
hariini=$(date -d "0 days" +"%Y-%m-%d")
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")

# Menyimpan akun SSTP
echo "$user * $pass *" >> /home/sstp/sstp_account
echo -e "### $user $exp" >> "/var/lib/crot/data-user-sstp"

clear

# Output hasil dengan tampilan menarik
echo -e "${CYAN}========================================${NC}"
echo -e "${BLUE}         SSTP VPN Account Created       ${NC}"
echo -e "${CYAN}========================================${NC}"
echo -e "${GREEN}IP/Host   : ${NC}$IP"
echo -e "${GREEN}Domain    : ${NC}$domain"
echo -e "${GREEN}Username  : ${NC}$user"
echo -e "${GREEN}Password  : ${NC}$pass"
echo -e "${GREEN}Port      : ${NC}$sstp"
echo -e "${GREEN}Cert      : ${NC}http://$IP:89/server.crt"
echo -e "${GREEN}Created   : ${NC}$hariini"
echo -e "${GREEN}Expired   : ${NC}$exp"
echo -e "${CYAN}========================================${NC}"
echo -e "${PURPLE}      Script Mod By ENVEEPAY      ${NC}"
echo -e "${CYAN}========================================${NC}"
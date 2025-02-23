#!/bin/bash
# ==========================================
# Perpanjangan Akun SSTP
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
    echo -e "${YELLOW}Silakan hubungi admin jika ini adalah kesalahan.${NC}"
    exit 1
fi

clear

# Cek jumlah akun yang tersedia
DATA_FILE="/var/lib/crot/data-user-sstp"
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "$DATA_FILE")

if [[ $NUMBER_OF_CLIENTS -eq 0 ]]; then
    echo -e "${RED}Tidak ada akun SSTP yang terdaftar.${NC}"
    exit 1
fi

# Menampilkan daftar akun yang dapat diperpanjang
echo ""
echo -e "${CYAN}Pilih akun SSTP yang ingin diperpanjang:${NC}"
echo "--------------------------------------"
echo "   No   |  Expired   |   Username   "
echo "--------------------------------------"
grep -E "^### " "$DATA_FILE" | cut -d ' ' -f 2-3 | nl -s ') '

# Memilih akun
until [[ $CLIENT_NUMBER -ge 1 && $CLIENT_NUMBER -le $NUMBER_OF_CLIENTS ]]; do
    read -rp "Pilih akun [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
done

# Memasukkan durasi perpanjangan
read -p "Tambahkan masa aktif (Hari): " masaaktif

# Mendapatkan informasi akun
user=$(grep -E "^### " "$DATA_FILE" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}p")
exp=$(grep -E "^### " "$DATA_FILE" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}p")
now=$(date +%Y-%m-%d)
d1=$(date -d "$exp" +%s)
d2=$(date -d "$now" +%s)
exp2=$(( (d1 - d2) / 86400 ))
exp3=$((exp2 + masaaktif))
exp4=$(date -d "$exp3 days" +"%Y-%m-%d")

# Memperbarui masa aktif akun
sed -i "s/### $user $exp/### $user $exp4/g" "$DATA_FILE"

clear
# Menampilkan hasil perpanjangan
echo ""
echo -e "${GREEN}==================================${NC}"
echo -e "     ${YELLOW}Akun SSTP Berhasil Diperpanjang${NC}     "
echo -e "${GREEN}==================================${NC}"
echo -e "Username  : ${CYAN}$user${NC}"
echo -e "Masa Aktif Baru  : ${CYAN}$exp4${NC}"
echo -e "${GREEN}==================================${NC}"
echo -e "Script By Enveepay"
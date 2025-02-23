#!/bin/bash
# ==========================================
# Hapus Akun SSTP
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
ACCOUNT_FILE="/home/sstp/sstp_account"
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "$DATA_FILE")

if [[ $NUMBER_OF_CLIENTS -eq 0 ]]; then
    echo -e "${RED}Tidak ada akun SSTP yang terdaftar.${NC}"
    exit 1
fi

# Menampilkan daftar akun yang dapat dihapus
echo ""
echo -e "${CYAN}Pilih akun SSTP yang ingin dihapus:${NC}"
echo "--------------------------------------"
echo "   No   |  Expired   |   Username   "
echo "--------------------------------------"
grep -E "^### " "$DATA_FILE" | cut -d ' ' -f 2-3 | nl -s ') '

# Memilih akun yang akan dihapus
until [[ $CLIENT_NUMBER -ge 1 && $CLIENT_NUMBER -le $NUMBER_OF_CLIENTS ]]; do
    read -rp "Pilih akun [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
done

# Mendapatkan informasi akun yang dipilih
user=$(grep -E "^### " "$DATA_FILE" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}p")
exp=$(grep -E "^### " "$DATA_FILE" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}p")

# Menghapus akun dari sistem
sed -i "/^### $user $exp/d" "$DATA_FILE"
sed -i "/^$user/d" "$ACCOUNT_FILE"

clear
# Menampilkan hasil penghapusan
echo ""
echo -e "${GREEN}==================================${NC}"
echo -e "     ${RED}Akun SSTP Berhasil Dihapus${NC}     "
echo -e "${GREEN}==================================${NC}"
echo -e "Username  : ${YELLOW}$user${NC}"
echo -e "Expired   : ${YELLOW}$exp${NC}"
echo -e "${GREEN}==================================${NC}"
echo -e "Script By Enveepay"
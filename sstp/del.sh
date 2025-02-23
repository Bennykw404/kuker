#!/bin/bash
# ==========================================
#            🚀 SSTP USER REMOVAL 🚀
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

# Mengecek jumlah klien
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/var/lib/crot/data-user-sstp")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
    echo -e "${RED}🚫 Tidak ada klien SSTP yang tersedia!${NC}"
    exit 1
fi

# Menampilkan daftar klien
echo -e "${BLUE}🔹 Pilih pengguna SSTP yang ingin dihapus:${NC}"
echo -e "${LIGHT}Tekan CTRL+C untuk kembali.${NC}"
echo "==============================="
echo -e "  ${ORANGE}No   Expired    Username${NC}"
grep -E "^### " "/var/lib/crot/data-user-sstp" | cut -d ' ' -f 2-3 | nl -s ') '

# Memilih klien untuk dihapus
until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
    read -rp "🔹 Pilih salah satu [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
done

# Menghapus pengguna yang dipilih
user=$(grep -E "^###" /var/lib/crot/data-user-sstp | cut -d ' ' -f 2 | sed -n "$CLIENT_NUMBER"p)
exp=$(grep -E "^###" /var/lib/crot/data-user-sstp | cut -d ' ' -f 3 | sed -n "$CLIENT_NUMBER"p)

sed -i "/^### $user $exp/d" /var/lib/crot/data-user-sstp
sed -i "/^$user/d" /home/sstp/sstp_account

# Membersihkan layar
clear

# Menampilkan konfirmasi penghapusan
echo -e "${GREEN}✅ Akun SSTP berhasil dihapus!${NC}"
echo "==============================="
echo -e "👤 ${BLUE}Username :${NC} $user"
echo -e "📅 ${RED}Expired  :${NC} $exp"
echo "==============================="
echo -e "${PURPLE}📌 Script Mod By ENVEEPAY${NC}"

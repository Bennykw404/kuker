#!/bin/bash
# ENVEEPAY - Renew Shadowsocks OBFS User
# ==========================================

# Warna & Ikon
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
SUCCESS_ICON="${GREEN}✔${NC}"
ERROR_ICON="${RED}✘${NC}"
INFO_ICON="${CYAN}ℹ${NC}"
EYE_ICON="${PURPLE}👁️${NC}"
USER_ICON="${CYAN}👤${NC}"
PORT_ICON="${CYAN}📶${NC}"
ACTIVE_ICON="${GREEN}🟢${NC}"
INACTIVE_ICON="${RED}🔴${NC}"

# ==========================================
# Mendapatkan IP Publik
MYIP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1)
if [[ -z ${MYIP} ]]; then
    MYIP=$(ip -6 addr | sed -ne 's|^.* inet6 \([^/]*\)/.* scope global.*$|\1|p' | head -1)
fi

echo -e "${INFO_ICON} ${EYE_ICON} Memeriksa izin akses VPS..."

IZIN=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1 | grep -o "$MYIP")

if [[ -n "$IZIN" ]]; then
    echo -e "${SUCCESS_ICON} ${EYE_ICON} Akses Diterima ✅"
else
    echo -e "${ERROR_ICON} ${EYE_ICON} Akses Ditolak ❌"
    echo -e "${LIGHT} ${EYE_ICON} Silakan hubungi administrator!"
    exit 1
fi

# ==========================================
# Mengecek jumlah klien yang ada
clear
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/etc/shadowsocks-libev/akun.conf")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
    clear
    echo -e "${ERROR_ICON} ${USER_ICON} Anda tidak memiliki klien yang ada!"
    exit 1
fi

# ==========================================
# Menampilkan daftar klien yang ada
clear
echo -e "${INFO_ICON} ${USER_ICON} Pilih klien yang ingin diperbarui"
echo -e "${INFO_ICON} ${CYAN} Tekan CTRL+C untuk kembali"
echo " ================================"
grep -E "^### " "/etc/shadowsocks-libev/akun.conf" | cut -d ' ' -f 2-3 | nl -s ') '
echo " ================================"

# Memilih klien untuk diperbarui
until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
    read -rp "Pilih salah satu klien [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
done

# Mengambil informasi klien yang dipilih
user=$(grep -E "^### " "/etc/shadowsocks-libev/akun.conf" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
exp=$(grep -E "^### " "/etc/shadowsocks-libev/akun.conf" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)

# Menampilkan informasi dan mengonfirmasi perpanjangan masa aktif
read -p "Masukkan jumlah hari untuk perpanjangan (misalnya 30): " masaaktif
now=$(date +%Y-%m-%d)
d1=$(date -d "$exp" +%s)
d2=$(date -d "$now" +%s)
exp2=$(( (d1 - d2) / 86400 ))  # Menghitung sisa hari dari tanggal kadaluarsa
exp3=$(($exp2 + $masaaktif))   # Menambah masa aktif
exp4=$(date -d "$exp3 days" +"%Y-%m-%d")  # Menetapkan tanggal baru sebagai kadaluarsa

# Memperbarui konfigurasi
sed -i "s/### $user $exp/### $user $exp4/g" /etc/shadowsocks-libev/akun.conf

# Menampilkan hasil
clear
echo -e "${SUCCESS_ICON} ${USER_ICON} Akun berhasil diperbarui"
echo "==========================="
echo -e "  ${SUCCESS_ICON} Akun SS OBFS Diperbarui  "
echo "==========================="
echo -e "Username  : $user"
echo -e "Expired   : $exp4"
echo "==========================="
echo -e "${INFO_ICON} Script Mod By ENVEEPAY"

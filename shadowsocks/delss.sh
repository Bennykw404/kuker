#!/bin/bash
# ENVEEPAY - Shadowsocks OBFS User Management Script
# ==========================================

# Color & Icon Definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
ORANGE='\033[0;33m'
BLUE='\033[0;34m'
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

clear

# Memeriksa apakah ada klien yang ada
NUMBER_OF_CLIENTS=$(grep -c -E "^### " "/etc/shadowsocks-libev/akun.conf")
if [[ ${NUMBER_OF_CLIENTS} == '0' ]]; then
    clear
    echo -e "${ERROR_ICON} ${USER_ICON} Tidak ada klien yang tersedia!"
    exit 1
fi

# Menampilkan pilihan klien untuk dihapus
clear
echo -e "${INFO_ICON} ${USER_ICON} Pilih klien yang ingin dihapus"
echo -e "${INFO_ICON} ${CYAN} Tekan CTRL+C untuk kembali"
echo " ==============================="
echo -e "     ${CYAN}No ${SUCCESS_ICON} Expired   ${USER_ICON} User"
echo " ==============================="
grep -E "^### " "/etc/shadowsocks-libev/akun.conf" | cut -d ' ' -f 2-3 | nl -s ') '

# Memilih klien untuk dihapus
until [[ ${CLIENT_NUMBER} -ge 1 && ${CLIENT_NUMBER} -le ${NUMBER_OF_CLIENTS} ]]; do
    read -rp "Pilih salah satu [1-${NUMBER_OF_CLIENTS}]: " CLIENT_NUMBER
done

# Mengambil informasi pengguna berdasarkan pilihan
CLIENT_NAME=$(grep -E "^### " "/etc/shadowsocks-libev/akun.conf" | cut -d ' ' -f 2-3 | sed -n "${CLIENT_NUMBER}"p)
user=$(grep -E "^### " "/etc/shadowsocks-libev/akun.conf" | cut -d ' ' -f 2 | sed -n "${CLIENT_NUMBER}"p)
exp=$(grep -E "^### " "/etc/shadowsocks-libev/akun.conf" | cut -d ' ' -f 3 | sed -n "${CLIENT_NUMBER}"p)

# Menghapus akun
echo -e "${INFO_ICON} ${USER_ICON} Menghapus akun untuk $user dengan masa berlaku $exp..."

# Menghapus blok konfigurasi [Peer] yang sesuai
sed -i "/^### $user $exp/,/^port_http/d" "/etc/shadowsocks-libev/akun.conf"

# Menghentikan dan menonaktifkan layanan terkait
systemctl stop shadowsocks-libev-server@$user-tls.service
systemctl stop shadowsocks-libev-server@$user-http.service
systemctl stop shadowsocks-libev-server@$user-v2rayws.service
systemctl stop shadowsocks-libev-server@$user-v2raywss.service
systemctl stop shadowsocks-libev-server@$user-v2rayquic.service
systemctl stop shadowsocks-libev-server@$user-v2raygrpc.service
systemctl stop shadowsocks-libev-server@$user-xrayws.service
systemctl stop shadowsocks-libev-server@$user-xraywss.service
systemctl stop shadowsocks-libev-server@$user-xraygrpctls.service
systemctl stop shadowsocks-libev-server@$user-xraygrpchttp.service
systemctl stop shadowsocks-libev-server@$user-xrayquic.service
systemctl stop shadowsocks-libev-server@$user-gostls.service
systemctl stop shadowsocks-libev-server@$user-gostmtls.service
systemctl stop shadowsocks-libev-server@$user-gostxtls.service
systemctl stop shadowsocks-libev-server@$user-gostgrpc.service
systemctl stop shadowsocks-libev-server@$user-gostws.service
systemctl stop shadowsocks-libev-server@$user-gostwss.service
systemctl stop shadowsocks-libev-server@$user-gostmws.service
systemctl stop shadowsocks-libev-server@$user-gostmwss.service
systemctl stop shadowsocks-libev-server@$user-gostquic.service
systemctl stop shadowsocks-libev-server@$user-gosth2.service

# Menghapus file konfigurasi terkait
rm -f "/etc/shadowsocks-libev/$user-tls.json"
rm -f "/etc/shadowsocks-libev/$user-http.json"
rm -f "/etc/shadowsocks-libev/$user-v2rayws.json"
rm -f "/etc/shadowsocks-libev/$user-v2raywss.json"
rm -f "/etc/shadowsocks-libev/$user-v2rayquic.json"
rm -f "/etc/shadowsocks-libev/$user-v2raygrpc.json"
rm -f "/etc/shadowsocks-libev/$user-xrayws.json"
rm -f "/etc/shadowsocks-libev/$user-xraywss.json"
rm -f "/etc/shadowsocks-libev/$user-xraygrpctls.json"
rm -f "/etc/shadowsocks-libev/$user-xraygrpchttp.json"
rm -f "/etc/shadowsocks-libev/$user-xrayquic.json"
rm -f "/etc/shadowsocks-libev/$user-gosttls.json"
rm -f "/etc/shadowsocks-libev/$user-gostmtls.json"
rm -f "/etc/shadowsocks-libev/$user-gostxtls.json"
rm -f "/etc/shadowsocks-libev/$user-gostgrpc.json"
rm -f "/etc/shadowsocks-libev/$user-gostws.json"
rm -f "/etc/shadowsocks-libev/$user-gostwss.json"
rm -f "/etc/shadowsocks-libev/$user-gostmws.json"
rm -f "/etc/shadowsocks-libev/$user-gostmwss.json"
rm -f "/etc/shadowsocks-libev/$user-gostquic.json"
rm -f "/etc/shadowsocks-libev/$user-gosth2.json"
rm -f "/home/vps/public_html/$user.json"

# Restart cron dan disable layanan untuk akun
service cron restart
systemctl disable shadowsocks-libev-server@$user-tls.service
systemctl disable shadowsocks-libev-server@$user-http.service
systemctl disable shadowsocks-libev-server@$user-v2rayws.service
systemctl disable shadowsocks-libev-server@$user-v2raywss.service
systemctl disable shadowsocks-libev-server@$user-v2rayquic.service
systemctl disable shadowsocks-libev-server@$user-v2raygrpc.service
systemctl disable shadowsocks-libev-server@$user-xrayws.service
systemctl disable shadowsocks-libev-server@$user-xraywss.service
systemctl disable shadowsocks-libev-server@$user-xraygrpctls.service
systemctl disable shadowsocks-libev-server@$user-xraygrpchttp.service
systemctl disable shadowsocks-libev-server@$user-xrayquic.service
systemctl disable shadowsocks-libev-server@$user-gostls.service
systemctl disable shadowsocks-libev-server@$user-gostmtls.service
systemctl disable shadowsocks-libev-server@$user-gostxtls.service
systemctl disable shadowsocks-libev-server@$user-gostgrpc.service
systemctl disable shadowsocks-libev-server@$user-gostws.service
systemctl disable shadowsocks-libev-server@$user-gostwss.service
systemctl disable shadowsocks-libev-server@$user-gostmws.service
systemctl disable shadowsocks-libev-server@$user-gostmwss.service
systemctl disable shadowsocks-libev-server@$user-gostquic.service
systemctl disable shadowsocks-libev-server@$user-gosth2.service

# Tampilan hasil penghapusan
clear
echo -e "${SUCCESS_ICON} ${USER_ICON} Akun berhasil dihapus"
echo "==========================="
echo "  SS OBFS Account Deleted  "
echo "==========================="
echo "Username  : $user"
echo "Expired   : $exp"
echo "==========================="
echo "Script Mod By ENVEEPAY"

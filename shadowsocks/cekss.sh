#!/bin/bash
# SL
# ==========================================
# Color
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
clear
echo "----------------------------------"
echo "=====[ ${SUCCESS_ICON} SS - OBFS User Login ${SUCCESS_ICON} ]====="
echo "----------------------------------"
echo ""

# Optimasi dan tampilkan daftar user
data=( $(grep '^###' /etc/shadowsocks-libev/akun.conf | cut -d ' ' -f 2) )
x=1

echo -e "${INFO_ICON} ${USER_ICON} Menampilkan Status Pengguna..."
echo "----------------------------------"
echo -e "${USER_ICON} User | ${PORT_ICON} TLS"
echo "----------------------------------"

# Menampilkan status TLS
for akun in "${data[@]}"
do
    port=$(awk -v x=$x 'NR==x {print $2}' /etc/shadowsocks-libev/akun.conf | grep '^port_tls')
    jum=$(netstat -anp | grep ESTABLISHED | grep obfs-server | cut -d ':' -f 2 | grep -w $port | awk '{print $2}' | sort | uniq | nl)
    if [[ -n "$jum" ]]; then
        echo -e "${USER_ICON} $akun - $port"
        echo "$jum"
        echo "----------------------------------"
    fi
    x=$((x + 1))
done

# Menampilkan status No TLS
x=1
echo ""
echo "----------------------------------"
echo -e "${USER_ICON} User | ${PORT_ICON} No TLS"
echo "----------------------------------"
for akun in "${data[@]}"
do
    port=$(awk -v x=$x 'NR==x {print $2}' /etc/shadowsocks-libev/akun.conf | grep '^port_http')
    jum=$(netstat -anp | grep ESTABLISHED | grep obfs-server | cut -d ':' -f 2 | grep -w $port | awk '{print $2}' | sort | uniq | nl)
    if [[ -n "$jum" ]]; then
        echo -e "${USER_ICON} $akun - $port"
        echo "$jum"
        echo "----------------------------------"
    fi
    x=$((x + 1))
done

# Tampilkan status jika tidak ada user aktif
if [[ -z "$jum" ]]; then
    echo -e "${INACTIVE_ICON} Tidak ada pengguna aktif di server saat ini."
fi

echo -e "${INFO_ICON} ${EYE_ICON} Selesai"

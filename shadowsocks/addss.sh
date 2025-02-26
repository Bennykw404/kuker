#!/bin/bash
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
SUCCESS_ICON="${GREEN}✔${NC}"
ERROR_ICON="${RED}✘${NC}"
INFO_ICON="${CYAN}ℹ${NC}"
EYE_ICON="${PURPLE}👁️${NC}"
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

IP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1)
lastport1=$(grep "port_tls" /etc/shadowsocks-libev/akun.conf | tail -n1 | awk '{print $2}')
lastport2=$(grep "port_http" /etc/shadowsocks-libev/akun.conf | tail -n1 | awk '{print $2}')
if [[ $lastport1 == '' ]]; then
tls=2443
else
tls="$((lastport1+1))"
fi
if [[ $lastport2 == '' ]]; then
http=3443
else
http="$((lastport2+1))"
fi
source /var/lib/crot/ipvps.conf
if [[ "$IP2" = "" ]]; then
domain=$(cat /etc/xray/domain)
else
domain=$IP2
fi

# Membuat konfigurasi default
cat > /etc/shadowsocks-libev/tls.json<<END
{   
    "server":"0.0.0.0",
    "server_port":$tls,
    "password":"tls",
    "timeout":60,
    "method":"aes-256-cfb",
    "fast_open":true,
    "no_delay":true,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=tls"
}
END
cat > /etc/shadowsocks-libev/http.json <<-END
{
    "server":"0.0.0.0",
    "server_port":$http,
    "password":"http",
    "timeout":60,
    "method":"aes-256-cfb",
    "fast_open":true,
    "no_delay":true,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=http"
}
END
chmod +x /etc/shadowsocks-libev/tls.json
chmod +x /etc/shadowsocks-libev/http.json

systemctl enable shadowsocks-libev-server@tls.service
systemctl start shadowsocks-libev-server@tls.service
systemctl enable shadowsocks-libev-server@http.service
systemctl start shadowsocks-libev-server@http.service

echo ""
echo -e "${INFO_ICON} ${EYE_ICON} Masukkan Password untuk User"

until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
		read -rp "Password : " -e user
		CLIENT_EXISTS=$(grep -w $user /etc/shadowsocks-libev/akun.conf | wc -l)

		if [[ ${CLIENT_EXISTS} == '1' ]]; then
			echo ""
			echo -e "${ERROR_ICON} ${EYE_ICON} Username ${RED}${user}${NC} sudah ada di VPS, silakan pilih username lain."
			exit 1
		fi
	done

read -p "Masa Aktif (Hari) : " masaaktif
hariini=$(date -d "0 days" +"%Y-%m-%d")
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")

# Membuat konfigurasi untuk user baru
cat > /etc/shadowsocks-libev/$user-tls.json<<END
{   
    "server":"0.0.0.0",
    "server_port":$tls,
    "password":"$user",
    "timeout":60,
    "method":"aes-256-cfb",
    "fast_open":true,
    "no_delay":true,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=tls"
}
END
cat > /etc/shadowsocks-libev/$user-http.json <<-END
{
    "server":"0.0.0.0",
    "server_port":$http,
    "password":"$user",
    "timeout":60,
    "method":"aes-256-cfb",
    "fast_open":true,
    "no_delay":true,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp",
    "plugin":"obfs-server",
    "plugin_opts":"obfs=http"
}
END
chmod +x /etc/shadowsocks-libev/$user-tls.json
chmod +x /etc/shadowsocks-libev/$user-http.json

systemctl enable shadowsocks-libev-server@$user-tls.service
systemctl start shadowsocks-libev-server@$user-tls.service
systemctl enable shadowsocks-libev-server@$user-http.service
systemctl start shadowsocks-libev-server@$user-http.service

tmp1=$(echo -n "aes-256-cfb:${user}@${MYIP}:$tls" | base64 -w0)
tmp2=$(echo -n "aes-256-cfb:${user}@${MYIP}:$http" | base64 -w0)
linkss1="ss://${tmp1}?plugin=obfs-local;obfs=tls;obfs-host=bing.com"
linkss2="ss://${tmp2}?plugin=obfs-local;obfs=http;obfs-host=bing.com"

echo -e "### $user $exp
port_tls $tls
port_http $http" >> "/etc/shadowsocks-libev/akun.conf"

service cron restart
clear

echo -e ""
echo -e "${INFO_ICON} ${EYE_ICON} ====== INFORMASI SHADOWSOCKS ======"
echo -e "${CYAN}IP/Host    : $MYIP"
echo -e "${CYAN}Domain     : $domain"
echo -e "${CYAN}Port TLS   : $tls"
echo -e "${CYAN}Port No TLS: $http"
echo -e "${CYAN}Password   : $user"
echo -e "${CYAN}Metode     : aes-256-cfb"
echo -e "${CYAN}Dibuat     : $hariini"
echo -e "${CYAN}Kadaluarsa : $exp"
echo -e "===================================="
echo -e "${CYAN}Link TLS   : $linkss1"
echo -e "===================================="
echo -e "${CYAN}Link No TLS: $linkss2"
echo -e "===================================="
echo -e "${SUCCESS_ICON} ${EYE_ICON} Script Modifikasi oleh ENVEEPAY"

#!/bin/bash
# Instalasi Shadowsocks-libev Obfs oleh ENVEPAY
# ==========================================
# Definisi Warna & Ikon
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
# ==========================================
# Mendapatkan IP Publik
MYIP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1)
if [[ -z ${MYIP} ]]; then
    MYIP=$(ip -6 addr | sed -ne 's|^.* inet6 \([^/]*\)/.* scope global.*$|\1|p' | head -1)
fi

echo -e "${INFO_ICON} Memeriksa izin akses VPS..."

IZIN=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1 | grep -o "$MYIP")

if [[ -n "$IZIN" ]]; then
    echo -e "${SUCCESS_ICON} Akses Diterima ✅"
else
    echo -e "${ERROR_ICON} Akses Ditolak ❌"
    echo -e "${LIGHT} Silakan hubungi administrator!"
    exit 1
fi

# Link Hosting (Perbarui dengan link Anda)
SHADOWSOCKS_REPO="https://raw.githubusercontent.com/Bennykw404/kuker/refs/heads/main/shadowsocks"

# Memeriksa Versi OS
echo -e "${INFO_ICON} Memeriksa kompatibilitas OS..."

if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    OS=$ID
    if [[ ${OS} == "debian" ]]; then
        if [[ ${VERSION_ID} -lt 10 ]]; then
            echo -e "${ERROR_ICON} Versi Debian (${VERSION_ID}) tidak didukung. Harap gunakan Debian 10 Buster atau yang lebih baru."
            exit 1
        fi
        OS=debian # menimpa jika raspbian
    elif [[ ${OS} == "ubuntu" ]]; then
        RELEASE_YEAR=$(echo "${VERSION_ID}" | cut -d'.' -f1)
        if [[ ${RELEASE_YEAR} -lt 18 ]]; then
            echo -e "${ERROR_ICON} Versi Ubuntu (${VERSION_ID}) tidak didukung. Harap gunakan Ubuntu 18.04 atau yang lebih baru."
            exit 1
        fi
    else
        echo -e "${ERROR_ICON} OS tidak didukung ❌"
        exit 1
    fi
fi

# Instalasi Paket yang Dibutuhkan
echo -e "${INFO_ICON} Menginstal paket yang dibutuhkan..."
apt-get install --no-install-recommends build-essential autoconf libtool libssl-dev libpcre3-dev libev-dev asciidoc xmlto automake -y
echo -e "${SUCCESS_ICON} Paket berhasil diinstal!"

# Instalasi Shadowsocks-libev & Simple-Obfs
echo -e "${INFO_ICON} Menginstal Shadowsocks-libev..."
apt-get install software-properties-common -y

if [[ $OS == 'ubuntu' ]]; then
    apt install shadowsocks-libev -y
    apt install simple-obfs -y
elif [[ $OS == 'debian' ]]; then
    if [[ "$ver" = "9" ]]; then
        echo "deb http://deb.debian.org/debian stretch-backports main" | tee /etc/apt/sources.list.d/stretch-backports.list
        apt update
        apt -t stretch-backports install shadowsocks-libev -y
        apt -t stretch-backports install simple-obfs -y
    elif [[ "$ver" = "10" ]]; then
        echo "deb http://deb.debian.org/debian buster-backports main" | tee /etc/apt/sources.list.d/buster-backports.list
        apt update
        apt -t buster-backports install shadowsocks-libev -y
        apt -t buster-backports install simple-obfs -y
    fi
fi
echo -e "${SUCCESS_ICON} Shadowsocks-libev berhasil diinstal!"

# Konfigurasi Server
echo -e "${INFO_ICON} Mengonfigurasi server Shadowsocks..."
cat > /etc/shadowsocks-libev/config.json <<END
{
    "server":"0.0.0.0",
    "server_port":8488,
    "password":"tes",
    "timeout":60,
    "method":"aes-256-cfb",
    "fast_open":true,
    "nameserver":"8.8.8.8",
    "mode":"tcp_and_udp"
}
END
echo -e "${SUCCESS_ICON} Konfigurasi server selesai!"

# Memulai Layanan Shadowsocks-libev
echo -e "${INFO_ICON} Memulai server Shadowsocks..."
systemctl enable shadowsocks-libev.service
systemctl start shadowsocks-libev.service
echo -e "${SUCCESS_ICON} Server Shadowsocks dimulai!"

# Membuat Konfigurasi Klien untuk Obfs
echo -e "${INFO_ICON} Membuat konfigurasi klien untuk obfs..."
cat > /etc/shadowsocks-libev.json <<END
{
    "server":"127.0.0.1",
    "server_port":8388,
    "local_port":1080,
    "password":"",
    "timeout":60,
    "method":"chacha20-ietf-poly1305",
    "mode":"tcp_and_udp",
    "fast_open":true,
    "plugin":"/usr/bin/obfs-local",
    "plugin_opts":"obfs=tls;failover=127.0.0.1:1443;fast-open"
}
END
chmod +x /etc/shadowsocks-libev.json
echo -e "${SUCCESS_ICON} Konfigurasi klien dibuat!"

# Menambahkan Peraturan Firewall
echo -e "${INFO_ICON} Mengatur aturan firewall..."
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 2443:3543 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 2443:3543 -j ACCEPT
iptables-save > /etc/iptables.up.rules
ip6tables-save > /etc/ip6tables.up.rules

# Mengunduh Skrip Manajemen Shadowsocks
echo -e "${INFO_ICON} Mengunduh skrip manajemen..."
cd /usr/bin
wget -O addss "${SHADOWSOCKS_REPO}/addss.sh"
wget -O delss "${SHADOWSOCKS_REPO}/delss.sh"
wget -O cekss "${SHADOWSOCKS_REPO}/cekss.sh"
wget -O renewss "${SHADOWSOCKS_REPO}/renewss.sh"
chmod +x addss
chmod +x delss
chmod +x cekss
chmod +x renewss
cd
rm -f /root/sodosok.sh

echo -e "${SUCCESS_ICON} Instalasi Shadowsocks-libev selesai!"

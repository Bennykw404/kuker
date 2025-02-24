#!/bin/bash
# WireGuard Installer - Ubuntu & Debian
# Mod By ENVEEPAY
# ==========================================
# Warna
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
INFO="${CYAN}[INFO]${NC}"
ERROR="${RED}[ERROR]${NC}"
SUCCESS="${GREEN}[SUCCESS]${NC}"

# Mendapatkan IP Publik IPv4
MYIP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1);
if [[ -z ${MYIP} ]]; then
	# Detect public IPv6 address
	MYIP=$(ip -6 addr | sed -ne 's|^.* inet6 \([^/]*\)/.* scope global.*$|\1|p' | head -1)
fi
echo -e "${INFO} Mengecek izin akses VPS..."
IZIN=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1 | grep -o "$MYIP")

if [[ -n "$IZIN" ]]; then
    echo -e "${SUCCESS} Akses Diterima ✅"
else
    echo -e "${ERROR} Akses Ditolak ❌"
    echo -e "${LIGHT} Silakan hubungi administrator!"
    exit 1
fi

# ==========================================
# Link Hosting Script
WIREGUARD_REPO="https://raw.githubusercontent.com/Bennykw404/kuker/refs/heads/main/wireguard"

# Cek OS
if [[ -f /etc/os-release ]]; then
    source /etc/os-release
    OS=$ID
    if [[ ${OS} == "debian" ]]; then
        if [[ ${VERSION_ID} -lt 10 ]]; then
            echo "Versi Debian (${VERSION_ID}) Anda tidak didukung. Harap gunakan Debian 10 Buster atau yang lebih baru"
            exit 1
        fi
        OS=debian # overwrite if raspbian
    elif [[ ${OS} == "ubuntu" ]]; then
        RELEASE_YEAR=$(echo "${VERSION_ID}" | cut -d'.' -f1)
        if [[ ${RELEASE_YEAR} -lt 18 ]]; then
            echo "Versi Ubuntu (${VERSION_ID}) Anda tidak didukung. Harap gunakan Ubuntu 18.04 atau yang lebih baru"
            exit 1
        fi
    else
        echo -e "OS tidak didukung ❌"
        exit 1
    fi
fi

# Cek jika WireGuard sudah terinstal
if [[ -f /etc/wireguard/params ]]; then
    echo -e "${INFO} WireGuard sudah terinstal, gunakan perintah 'addwg' untuk menambah client."
    exit 1
fi

echo -e "${INFO} Menginstal WireGuard..."
# Instal paket yang dibutuhkan
apt update -y
apt install -y wireguard wireguard-tools iptables resolvconf iptables-persistent

# Pastikan direktori WireGuard tersedia
mkdir -p /etc/wireguard && chmod 600 -R /etc/wireguard/

# Generate Kunci WireGuard
SERVER_PRIV_KEY=$(wg genkey)
SERVER_PUB_KEY=$(echo "$SERVER_PRIV_KEY" | wg pubkey)

# Dapatkan interface jaringan utama
SERVER_PUB_NIC=$(ip -4 route ls | grep default | awk '/dev/ {for (i=1; i<=NF; i++) if ($i == "dev") print $(i+1)}' | head -1)

# Simpan konfigurasi WireGuard
cat << EOF > /etc/wireguard/params
SERVER_PUB_IP=${MYIP}
SERVER_PUB_NIC=${SERVER_PUB_NIC}
SERVER_WG_NIC=wg0
SERVER_WG_IPV4=10.66.66.1
SERVER_WG_IPV6=fd42:42:42::1
SERVER_PORT=7070
SERVER_PRIV_KEY=${SERVER_PRIV_KEY}
SERVER_PUB_KEY=${SERVER_PUB_KEY}
CLIENT_DNS_1=1.1.1.1
CLIENT_DNS_2=1.0.0.1
ALLOWED_IPS=0.0.0.0/0,::/0
EOF

source /etc/wireguard/params

# Buat konfigurasi WireGuard
cat <<EOF > /etc/wireguard/${SERVER_WG_NIC}.conf
[Interface]
Address = $SERVER_WG_IPV4/24,${SERVER_WG_IPV6}/64
ListenPort = $SERVER_PORT
PrivateKey = $SERVER_PRIV_KEY
PostUp = iptables -I INPUT -p udp --dport ${SERVER_PORT} -j ACCEPT \
        && iptables -I FORWARD -i ${SERVER_PUB_NIC} -o ${SERVER_WG_NIC} -j ACCEPT \
        && iptables -I FORWARD -i ${SERVER_WG_NIC} -j ACCEPT \
        && iptables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE \
        && ip6tables -I FORWARD -i ${SERVER_WG_NIC} -j ACCEPT \
        && ip6tables -t nat -A POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE
PostDown = iptables -D INPUT -p udp --dport ${SERVER_PORT} -j ACCEPT \
        && iptables -D FORWARD -i ${SERVER_PUB_NIC} -o ${SERVER_WG_NIC} -j ACCEPT \
        && iptables -D FORWARD -i ${SERVER_WG_NIC} -j ACCEPT \
        && iptables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE \
        && ip6tables -D FORWARD -i ${SERVER_WG_NIC} -j ACCEPT \
        && ip6tables -t nat -D POSTROUTING -o ${SERVER_PUB_NIC} -j MASQUERADE
EOF

# Terapkan aturan iptables
iptables -t nat -I POSTROUTING -s ${SERVER_WG_IPV4}/24 -o ${SERVER_PUB_NIC} -j MASQUERADE
iptables -I INPUT 1 -i ${SERVER_WG_NIC} -j ACCEPT
iptables -I FORWARD 1 -i ${SERVER_PUB_NIC} -o ${SERVER_WG_NIC} -j ACCEPT
iptables -I FORWARD 1 -i ${SERVER_WG_NIC} -o ${SERVER_PUB_NIC} -j ACCEPT
iptables -I INPUT 1 -i ${SERVER_PUB_NIC} -p udp --dport ${SERVER_PORT} -j ACCEPT

# Simpan dan muat ulang aturan firewall secara persisten
iptables-save > /etc/iptables.up.rules
iptables-restore < /etc/iptables.up.rules
netfilter-persistent save
netfilter-persistent reload

# Enable routing on the server
echo "net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1" >/etc/sysctl.d/wg.conf

# Terapkan aturan sysctl untuk network forwarding
sysctl --system

# Jalankan WireGuard
systemctl start "wg-quick@${SERVER_WG_NIC}"

# Aktifkan WireGuard agar berjalan otomatis saat boot
systemctl enable "wg-quick@${SERVER_WG_NIC}"

# Cek apakah WireGuard sedang berjalan
systemctl is-active --quiet "wg-quick@${SERVER_WG_NIC}"
WG_RUNNING=$?

# Jika WireGuard tidak berjalan, tampilkan peringatan
if [[ ${WG_RUNNING} -ne 0 ]]; then
    echo -e "\n🚨 \033[0;31mPERINGATAN: WireGuard tidak berjalan!\033[0m"
    echo -e "🔍 \033[0;33mPeriksa status WireGuard dengan perintah berikut:\033[0m"
    echo -e "   👉 systemctl status wg-quick@${SERVER_WG_NIC}"
    echo -e "⚠️  \033[0;33mJika muncul pesan \"Cannot find device ${SERVER_WG_NIC}\", silakan reboot server!\033[0m"
else
    echo -e "\n✅ \033[0;32mWireGuard sedang berjalan.\033[0m"
    echo -e "ℹ️  \033[0;32mUntuk memeriksa status WireGuard, jalankan perintah berikut:\033[0m"
    echo -e "   👉 systemctl status wg-quick@${SERVER_WG_NIC}\n"
    echo -e "🌐 \033[0;33mJika klien tidak memiliki koneksi internet, coba reboot server.\033[0m"
fi

# Tambahan: Download script tambahan
echo -e "${INFO} Mengunduh script tambahan..."
cd /usr/bin
wget -O addwg "${WIREGUARD_REPO}/addwg.sh"
wget -O delwg "${WIREGUARD_REPO}/delwg.sh"
wget -O renewwg "${WIREGUARD_REPO}/renewwg.sh"

chmod +x addwg delwg renewwg
cd

echo -e "${SUCCESS} Instalasi selesai! 🚀"
echo -e "Gunakan perintah berikut untuk mengelola WireGuard:"
echo -e "➡ Tambah user: ${GREEN}addwg${NC}"
echo -e "➡ Hapus user: ${RED}delwg${NC}"
echo -e "➡ Perpanjang user: ${CYAN}renewwg${NC}"

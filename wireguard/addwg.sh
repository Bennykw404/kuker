#!/bin/bash
# 🔰 WIREGUARD CLIENT GENERATOR 🔰
# ==========================================
# 🎨 Warna untuk tampilan menarik
RED='\033[0;31m'
NC='\033[0m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[0;33m'
LIGHT='\033[0;37m'

# 🔹 Mendapatkan IP Server
MYIP=$(curl -4 -s https://checkip.amazonaws.com)

echo -e "${CYAN}🔍 Checking VPS..."
if [[ -z "$MYIP" ]]; then
    echo -e "${RED}❌ Permission Denied!${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Permission Accepted...${NC}"
fi

clear
# 🔹 Load parameter konfigurasi
source /etc/wireguard/params
source /var/lib/crot/ipvps.conf

# 🔹 Menentukan IP Publik
SERVER_PUB_IP=${IP2:-$(curl -4 -s https://checkip.amazonaws.com)}
portwg=$(awk -F' = ' '/ListenPort/ {print $2}' /etc/wireguard/wg0.conf)

# 🔹 Input Username
while :; do
    read -rp "👤 Username: " CLIENT_NAME
    [[ $CLIENT_NAME =~ ^[a-zA-Z0-9_]+$ ]] || { echo -e "${RED}⚠️ Gunakan karakter alfanumerik saja!${NC}"; continue; }
    grep -qw "$CLIENT_NAME" /etc/wireguard/wg0.conf || break
    echo -e "⚠️ Username ${RED}$CLIENT_NAME${NC} sudah ada, silakan pilih yang lain."
done

# 🔹 Konfigurasi IP Klien
LAST_OCTET=$(grep "/32" /etc/wireguard/wg0.conf | awk '{print $3}' | cut -d '.' -f 4 | sort -n | tail -1)
CLIENT_ADDRESS="10.66.66.$((LAST_OCTET+1))"
CLIENT_ADDRESS_IPV6="fd42:42:42::$((LAST_OCTET+1))"

# 🔹 DNS Default
CLIENT_DNS_1="1.1.1.1"
CLIENT_DNS_2="1.0.0.1"

# 🔹 Input Masa Aktif
read -rp "📆 Expired (Days): " masaaktif
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")

# 🔹 Generate Key Pair
CLIENT_PRIV_KEY=$(wg genkey)
CLIENT_PUB_KEY=$(echo "$CLIENT_PRIV_KEY" | wg pubkey)
CLIENT_PRE_SHARED_KEY=$(wg genpsk)

# 🔹 Buat file konfigurasi client
CONFIG_PATH="$HOME/wg0-client-$CLIENT_NAME.conf"
cat <<EOF > "$CONFIG_PATH"
[Interface]
PrivateKey = $CLIENT_PRIV_KEY
Address = $CLIENT_ADDRESS/32
DNS = $CLIENT_DNS_1,$CLIENT_DNS_2

[Peer]
PublicKey = $SERVER_PUB_KEY
PresharedKey = $CLIENT_PRE_SHARED_KEY
Endpoint = $SERVER_PUB_IP:$portwg
AllowedIPs = 0.0.0.0/0,::/0
EOF

# 🔹 Tambahkan client ke konfigurasi server
echo -e "### Client $CLIENT_NAME $exp
[Peer]
PublicKey = $CLIENT_PUB_KEY
PresharedKey = $CLIENT_PRE_SHARED_KEY
AllowedIPs = $CLIENT_ADDRESS/32,$CLIENT_ADDRESS_IPV6/128" >> "/etc/wireguard/wg0.conf"

# 🔹 Restart WireGuard
systemctl restart "wg-quick@wg0"

# 🔹 Simpan konfigurasi client di folder public
cp "$CONFIG_PATH" "/home/vps/public_html/$CLIENT_NAME.conf"

clear
# 🔹 Menampilkan Informasi Akun WireGuard
echo -e "${LIGHT}================================"
echo -e "  🔰 ${CYAN}WIREGUARD CLIENT CONFIG${NC} 🔰"
echo -e "================================"
echo -e "👤 Username : ${GREEN}$CLIENT_NAME${NC}"
echo -e "🌍 IP/Host  : ${GREEN}$MYIP${NC}"
echo -e "🔹 Domain   : ${GREEN}$SERVER_PUB_IP${NC}"
echo -e "📡 Port     : ${GREEN}$portwg${NC}"
echo -e "🕒 Created  : ${GREEN}$(date +"%Y-%m-%d")${NC}"
echo -e "📆 Expired  : ${RED}$exp${NC}"
echo -e "================================"
echo -e "🔗 Download Config:"
echo -e "   ${BLUE}http://$MYIP:89/$CLIENT_NAME.conf${NC}"
echo -e "================================"
echo -e "🔰 Script Mod By ENVEEPAY"

rm -f "$CONFIG_PATH"

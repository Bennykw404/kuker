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
MYIP=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1)

echo -e "${CYAN}🔍 Checking VPS..."
IZIN=$(ip -4 addr | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk '{print $1}' | head -1 | grep $MYIP)

if [ "$MYIP" = "$MYIP" ]; then
    echo -e "${GREEN}✅ Permission Accepted...${NC}"
else
    echo -e "${RED}❌ Permission Denied!${NC}"
    exit 1
fi

clear
# 🔹 Load parameter konfigurasi
source /etc/wireguard/params
source /var/lib/crot/ipvps.conf

# 🔹 Menentukan IP Publik
if [[ -z "$IP" ]]; then
    SERVER_PUB_IP=$(ip -4 addr show | sed -ne 's|^.* inet \([^/]*\)/.* scope global.*$|\1|p' | awk 'NR==1 {print $1}')
else
    SERVER_PUB_IP=$IP
fi

if [[ -z "$IP2" ]]; then
    domain=$(cat /etc/xray/domain)
else
    domain=$IP2
fi


echo ""
portwg=$(grep "ListenPort" /etc/wireguard/${SERVER_WG_NIC}.conf | awk -F' = ' '{print $2}')

# 🔹 Input Username
until [[ ${CLIENT_NAME} =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
    read -rp "👤 Username: " -e CLIENT_NAME
    CLIENT_EXISTS=$(grep -w $CLIENT_NAME /etc/wireguard/${SERVER_WG_NIC}.conf | wc -l)

    if [[ ${CLIENT_EXISTS} == '1' ]]; then
        echo -e "⚠️ Username ${RED}$CLIENT_NAME${NC} sudah ada, silakan pilih yang lain."
        exit 1
    fi
done

echo -e "🌍 IPv4 Detected"
ENDPOINT="${SERVER_PUB_IP}:${SERVER_PORT}"

for DOT_IP in {2..254}; do
	DOT_EXISTS=$(grep -c "${SERVER_WG_IPV4::-1}${DOT_IP}" "/etc/wireguard/${SERVER_WG_NIC}.conf")
	if [[ ${DOT_EXISTS} == '0' ]]; then
		break
	fi
done

if [[ ${DOT_EXISTS} == '1' ]]; then
    echo ""
    echo -e "🚫 ⚠️ Subnet yang dikonfigurasi hanya mendukung 253 klien. ⚠️ 🚫"
    echo ""
    exit 1
fi

# Menentukan base IP dari alamat IPv4 server
BASE_IP=$(echo "$SERVER_WG_IPV4" | awk -F '.' '{ print $1"."$2"."$3 }')
DOT_IP=1 
until [[ ${IPV4_EXISTS} == '0' ]]; do
    CLIENT_WG_IPV4="${BASE_IP}.${DOT_IP}"
    IPV4_EXISTS=$(grep -c "$CLIENT_WG_IPV4/32" "/etc/wireguard/${SERVER_WG_NIC}.conf")
    if [[ ${IPV4_EXISTS} == '0' ]]; then
        break
    else
        DOT_IP=$((DOT_IP + 1))
    fi
done

BASE_IP=$(echo "$SERVER_WG_IPV6" | awk -F '::' '{ print $1 }')
DOT_IP=1
until [[ ${IPV6_EXISTS} == '0' ]]; do
    CLIENT_WG_IPV6="${BASE_IP}::${DOT_IP}"
    IPV6_EXISTS=$(grep -c "${CLIENT_WG_IPV6}/128" "/etc/wireguard/${SERVER_WG_NIC}.conf")

    if [[ ${IPV6_EXISTS} == '0' ]]; then
        break
    else
        DOT_IP=$((DOT_IP + 1))
    fi
done

# 🔹 Input Masa Aktif
read -p "📆 Expired (Days): " masaaktif
hariini=$(date -d "0 days" +"%Y-%m-%d")
exp=$(date -d "$masaaktif days" +"%Y-%m-%d")

# 🔹 Generate Key Pair
CLIENT_PRIV_KEY=$(wg genkey)
CLIENT_PUB_KEY=$(echo "$CLIENT_PRIV_KEY" | wg pubkey)
CLIENT_PRE_SHARED_KEY=$(wg genpsk)

# 🔹 Buat file konfigurasi client
cat <<EOF > "$HOME/$SERVER_WG_NIC-client-$CLIENT_NAME.conf"
[Interface]
PrivateKey = $CLIENT_PRIV_KEY
Address = $CLIENT_WG_IPV4/32,$CLIENT_WG_IPV6/128
DNS = $CLIENT_DNS_1,$CLIENT_DNS_2

[Peer]
PublicKey = $SERVER_PUB_KEY
PresharedKey = $CLIENT_PRE_SHARED_KEY
Endpoint = $ENDPOINT
AllowedIPs = $ALLOWED_IPS
EOF

# 🔹 Tambahkan client ke konfigurasi server
echo -e "### Client $CLIENT_NAME $exp
[Peer]
PublicKey = $CLIENT_PUB_KEY
PresharedKey = $CLIENT_PRE_SHARED_KEY
AllowedIPs = $CLIENT_WG_IPV4}/32,$CLIENT_WG_IPV6/128" >> "/etc/wireguard/$SERVER_WG_NIC.conf"

# 🔹 Restart WireGuard
systemctl restart "wg-quick@$SERVER_WG_NIC"

# 🔹 Simpan konfigurasi client di folder public
cp "$HOME/$SERVER_WG_NIC-client-$CLIENT_NAME.conf" "/home/vps/public_html/$CLIENT_NAME.conf"

clear
echo -e "${GREEN}🔑 Generating Keys..."
sleep 0.5
echo -e "${BLUE}🔑 PrivateKey Generated"
sleep 0.5
echo -e "${CYAN}🔑 PublicKey Generated"
sleep 0.5
echo -e "${YELLOW}🔑 PresharedKey Generated"
clear

# 🔹 Menampilkan Informasi Akun WireGuard
echo -e "${LIGHT}================================"
echo -e "  🔰 ${CYAN}WIREGUARD CLIENT CONFIG${NC} 🔰"
echo -e "================================"
echo -e "👤 Username : ${GREEN}$CLIENT_NAME${NC}"
echo -e "🌍 IP/Host  : ${GREEN}$MYIP${NC}"
echo -e "🔹 Domain   : ${GREEN}$domain${NC}"
echo -e "📡 Port     : ${GREEN}$portwg${NC}"
echo -e "🕒 Created  : ${GREEN}$hariini${NC}"
echo -e "📆 Expired  : ${RED}$exp${NC}"
echo -e "================================"
echo -e "🔗 Download Config:"
echo -e "   ${BLUE}http://$MYIP:89/$CLIENT_NAME.conf${NC}"
echo -e "================================"
echo -e "🔰 Script Mod By ENVEEPAY"
rm -f "/root/wg0-client-$CLIENT_NAME.conf"

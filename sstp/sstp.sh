#!/bin/bash

==========================================

VPN Setup Script

==========================================

Warna ANSI

RED='\033[0;31m' NC='\033[0m' GREEN='\033[0;32m' BLUE='\033[0;34m' YELLOW='\033[0;33m' CYAN='\033[0;36m'

clear

echo -e "${CYAN}=============================================" echo -e "${GREEN}        SETUP SSTP VPN SERVER        " echo -e "${CYAN}=============================================${NC}"

Cek IP VPS

MYIP=$(wget -qO- ipinfo.io/ip); echo -e "${BLUE}Checking VPS IP...${NC}" IZIN=$(curl -s ipinfo.io/ip | grep $MYIP) if [[ -n "$IZIN" ]]; then echo -e "${GREEN}Permission Accepted...${NC}\n" else echo -e "${RED}Permission Denied!\nExiting...${NC}\n" exit 1 fi

Link Hosting

akbarvpn="raw.githubusercontent.com/fisabiliyusri/Mantap/main/sstp"

Konfigurasi IP

MYIP2="s/xxxxxxxxx/$MYIP/g" NIC=$(ip -o -4 route show to default | awk '{print $5}')

Deteksi OS

source /etc/os-release OS=$ID ver=$VERSION_ID if [[ $OS == 'ubuntu' ]]; then if [[ "$ver" = "18.04" ]]; then yoi=Ubuntu18 elif [[ "$ver" = "20.04" ]]; then yoi=Ubuntu20 fi elif [[ $OS == 'debian' ]]; then if [[ "$ver" = "9" ]]; then yoi=Debian9 elif [[ "$ver" = "10" ]]; then yoi=Debian10 fi fi

Persiapan direktori

mkdir -p /home/sstp mkdir -p /var/lib/crot/ touch /home/sstp/sstp_account touch /var/lib/crot/data-user-sstp

Detail organisasi

country=ID state=Indonesia locality=Indonesia organization=infinity organizationalunit=infinity commonname=cdn.covid19.go.id email=hayuk69@gmail.com

Install dependensi

echo -e "${YELLOW}Installing dependencies...${NC}" apt-get update && apt-get install -y build-essential cmake gcc linux-headers-$(uname -r) git libpcre3-dev libssl-dev liblua5.1-0-dev ppp

echo -e "${YELLOW}Cloning and building accel-ppp...${NC}" git clone https://github.com/accel-ppp/accel-ppp.git /opt/accel-ppp-code mkdir -p /opt/accel-ppp-code/build cd /opt/accel-ppp-code/build/ cmake -DBUILD_IPOE_DRIVER=TRUE -DBUILD_VLAN_MON_DRIVER=TRUE -DCMAKE_INSTALL_PREFIX=/usr -DKDIR=/usr/src/linux-headers-$(uname -r) -DLUA=TRUE -DCPACK_TYPE=$yoi .. make cpack -G DEB dpkg -i accel-ppp.deb

Konfigurasi accel-ppp

mv /etc/accel-ppp.conf.dist /etc/accel-ppp.conf wget -O /etc/accel-ppp.conf "https://${akbarvpn}/accel.conf" sed -i "$MYIP2" /etc/accel-ppp.conf chmod 644 /etc/accel-ppp.conf

Menjalankan layanan

systemctl start accel-ppp systemctl enable accel-ppp

echo -e "${GREEN}SSTP VPN Setup Completed!${NC}\n"

echo -e "${YELLOW}==============================${NC}"
echo -e "${BLUE}        GENERATE CERT         ${NC}"
echo -e "${YELLOW}==============================${NC}"
cd /home/sstp
echo -e "${GREEN}Membuat kunci CA...${NC}"
openssl genrsa -out ca.key 4096

echo -e "${GREEN}Membuat sertifikat CA...${NC}"
openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"

echo -e "${GREEN}Membuat private key untuk server...${NC}"
openssl genrsa -out server.key 4096

echo -e "${GREEN}Membuat permintaan sertifikat (CSR)...${NC}"
openssl req -new -key server.key -out ia.csr \
-subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"

echo -e "${GREEN}Menandatangani sertifikat server dengan CA...${NC}"
openssl x509 -req -days 3650 -in ia.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt

echo -e "${GREEN}Menyalin sertifikat ke direktori web...${NC}"
cp /home/sstp/server.crt /home/vps/public_html/server.crt

echo -e "${YELLOW}==============================${NC}"
echo -e "${BLUE}    KONFIGURASI FIREWALL      ${NC}"
echo -e "${YELLOW}==============================${NC}"
iptables -I INPUT -m state --state NEW -m tcp -p tcp --dport 444 -j ACCEPT
iptables -I INPUT -m state --state NEW -m udp -p udp --dport 444 -j ACCEPT
iptables-save > /etc/iptables.up.rules
iptables-restore -t < /etc/iptables.up.rules
netfilter-persistent save > /dev/null
netfilter-persistent reload > /dev/null

echo -e "${GREEN}Firewall telah dikonfigurasi.${NC}"

echo -e "${YELLOW}==============================${NC}"
echo -e "${BLUE}    MENGUNDUH SKRIP SSTP      ${NC}"
echo -e "${YELLOW}==============================${NC}"
wget -O /usr/bin/addsstp https://${akbarvpn}/addsstp.sh && chmod +x /usr/bin/addsstp
wget -O /usr/bin/delsstp https://${akbarvpn}/delsstp.sh && chmod +x /usr/bin/delsstp
wget -O /usr/bin/ceksstp https://${akbarvpn}/ceksstp.sh && chmod +x /usr/bin/ceksstp
wget -O /usr/bin/renewsstp https://${akbarvpn}/renewsstp.sh && chmod +x /usr/bin/renewsstp

echo -e "${GREEN}Semua skrip SSTP berhasil diunduh dan diberikan izin eksekusi.${NC}"

echo -e "${RED}Menghapus skrip instalasi...${NC}"
rm -f /root/sstp.sh
echo -e "${GREEN}Instalasi selesai!${NC}"
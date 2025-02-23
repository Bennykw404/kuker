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


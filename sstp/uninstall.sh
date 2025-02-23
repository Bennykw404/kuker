#!/bin/bash
# ==========================================
#  🛑 SSTP VPN Uninstaller Script 🛑
# ==========================================
# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
NC='\033[0m'

# Banner
clear
echo -e "${CYAN}"
echo "===================================="
echo "   🛑 SSTP VPN Uninstaller 🛑   "
echo "===================================="
echo -e "${NC}"

# Stop and disable accel-ppp service
echo -e "${BLUE}📌 Stopping SSTP VPN service...${NC}"
systemctl stop accel-ppp
systemctl disable accel-ppp

# Remove installed packages
echo -e "${BLUE}📌 Removing installed packages...${NC}"
apt-get remove --purge -y accel-ppp ppp netfilter-persistent
apt-get autoremove -y
apt-get clean

# Remove configuration files
echo -e "${BLUE}📌 Deleting configuration files...${NC}"
rm -rf /opt/accel-ppp-code
rm -f /etc/accel-ppp.conf
rm -rf /home/sstp
rm -f /var/lib/crot/data-user-sstp

# Remove scripts
echo -e "${BLUE}📌 Removing SSTP scripts...${NC}"
rm -f /usr/bin/addsstp
rm -f /usr/bin/delsstp
rm -f /usr/bin/ceksstp
rm -f /usr/bin/renewsstp

# Flush and remove firewall rules
echo -e "${BLUE}📌 Resetting firewall rules...${NC}"
iptables -D INPUT -p tcp --dport 444 -m state --state NEW -j ACCEPT
iptables -D INPUT -p udp --dport 444 -m state --state NEW -j ACCEPT
iptables-save > /etc/iptables.up.rules
netfilter-persistent save > /dev/null
netfilter-persistent reload > /dev/null

# Final Message
echo -e "${GREEN}"
echo "===================================="
echo " ✅ SSTP VPN Uninstallation Complete! ✅ "
echo "===================================="
echo -e "${NC}"
rm -f /root/uninstall_sstp.sh

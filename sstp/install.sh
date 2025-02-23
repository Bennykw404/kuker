#!/bin/bash
# ==========================================
#  🌟 SSTP VPN Installer Script 🌟
# ==========================================
# Color Codes
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
LIGHT='\033[0;37m'
NC='\033[0m'

LOG_FILE="/var/log/sstp_install.log"
exec 2> >(tee -a "$LOG_FILE" >&2)  # Redirect stderr to log file


# Banner
clear
echo -e "${CYAN}"
echo "===================================="
echo "   🌍 SSTP VPN Auto Installer 🌍   "
echo "===================================="
echo -e "${NC}"

# Get Public IP
MYIP=$(curl -4 -s https://checkip.amazonaws.com)
echo -e "🔍 Checking VPS IP: ${LIGHT}$MYIP${NC}"

# IP Authorization
AUTHORIZED_IP=$(curl -4 -s https://checkip.amazonaws.com | grep "$MYIP")
if [[ -z "$AUTHORIZED_IP" ]]; then
    echo -e "${RED}🚫 Permission Denied!${NC}"
    exit 1
else
    echo -e "${GREEN}✅ Permission Accepted...${NC}"
fi

# Variables
REPO_URL="https://raw.githubusercontent.com/Bennykw404/kuker/main/sstp"
OS_NAME=$(source /etc/os-release && echo "$ID")
OS_VER=$(source /etc/os-release && echo "$VERSION_ID")

case "$OS_NAME" in
    ubuntu)
        [[ "$OS_VER" == "18.04" ]] && DISTRO="Ubuntu18"
        [[ "$OS_VER" == "20.04" ]] && DISTRO="Ubuntu20"
        ;;
    debian)
        [[ "$OS_VER" == "9" ]] && DISTRO="Debian9"
        [[ "$OS_VER" == "10" ]] && DISTRO="Debian10"
        ;;
    *)
        echo -e "${RED}❌ OS not supported!${NC}"
        exit 1
        ;;
esac

# Create required directories
mkdir -p /home/sstp /var/lib/crot
touch /home/sstp/sstp_account /var/lib/crot/data-user-sstp

# Organization details
country="ID"
state="Indonesia"
locality="Indonesia"
organization="enveepay"
organizationalunit="enveepay"
commonname="enveepay.games"
email="muhamadsyabaini@gmail.com"

# Function to show progress
progress() {
    local PERCENT=$1
    echo -ne "${BLUE}🔄 Installation Progress: ${PERCENT}%\r${NC}"
}

# Function to install dependencies
install_packages() {
    echo -e "${BLUE}📦 Installing dependencies...${NC}"
    apt-get update && apt-get install -y build-essential cmake gcc linux-headers-$(uname -r) git \
        libpcre2-dev libssl-dev liblua5.1-0-dev ppp netfilter-persistent || {
        echo -e "${RED}❌ Failed to install dependencies!${NC}" | tee -a "$LOG_FILE"
        exit 1
    }
    progress 20
}


# Install SSTP
install_sstp() {
    echo -e "${BLUE}🚀 Installing SSTP VPN...${NC}"
    git clone https://github.com/accel-ppp/accel-ppp.git /opt/accel-ppp-code
    mkdir -p /opt/accel-ppp-code/build
    cd /opt/accel-ppp-code/build || exit 1

    cmake -DBUILD_IPOE_DRIVER=TRUE -DBUILD_VLAN_MON_DRIVER=TRUE \
        -DCMAKE_INSTALL_PREFIX=/usr -DKDIR=/usr/src/linux-headers-$(uname -r) \
        -DLUA=TRUE -DCPACK_TYPE=$DISTRO .. || {
        echo -e "${RED}❌ Failed to configure SSTP build!${NC}" | tee -a "$LOG_FILE"
        exit 1
    }

    make && cpack -G DEB && dpkg -i accel-ppp.deb || {
        echo -e "${RED}❌ Failed to build SSTP VPN!${NC}" | tee -a "$LOG_FILE"
        exit 1
    }

    mv /etc/accel-ppp.conf.dist /etc/accel-ppp.conf
    wget -O /etc/accel-ppp.conf "$REPO_URL/accel.conf"
    sed -i "s/xxxxxxxxx/$MYIP/g" /etc/accel-ppp.conf
    chmod +x /etc/accel-ppp.conf

    systemctl enable --now accel-ppp
    progress 50
}

# Generate SSL Certificates
generate_certificates() {
    echo -e "${BLUE}🔑 Generating SSL certificates...${NC}"
    cd /home/sstp || exit 1

    openssl genrsa -out ca.key 4096
    openssl req -new -x509 -days 3650 -key ca.key -out ca.crt \
        -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"

    openssl genrsa -out server.key 4096
    openssl req -new -key server.key -out ia.csr \
        -subj "/C=$country/ST=$state/L=$locality/O=$organization/OU=$organizationalunit/CN=$commonname/emailAddress=$email"

    openssl x509 -req -days 3650 -in ia.csr -CA ca.crt -CAkey ca.key -set_serial 01 -out server.crt
    cp server.crt /home/vps/public_html/server.crt

    progress 70
}

# Configure Firewall Rules
configure_firewall() {
    echo -e "${BLUE}🛡️ Configuring Firewall...${NC}"
    iptables -I INPUT -p tcp --dport 444 -m state --state NEW -j ACCEPT
    iptables -I INPUT -p udp --dport 444 -m state --state NEW -j ACCEPT
    iptables-save > /etc/iptables.up.rules
    netfilter-persistent save > /dev/null
    netfilter-persistent reload > /dev/null

    progress 85
}

# Download SSTP Scripts
download_scripts() {
    echo -e "${BLUE}📥 Downloading SSTP scripts...${NC}"
    for script in add del list renew uninstall; do
        wget -O /usr/bin/$script "$REPO_URL/$script.sh"
        chmod +x /usr/bin/$script
    done

    progress 100
}

# Run all functions
install_packages
install_sstp
generate_certificates
configure_firewall
download_scripts

# Final Message
echo -e "${GREEN}"
echo "===================================="
echo " 🎉 SSTP VPN Installation Complete! 🎉"
echo "✅ Use 'addsstp' to add a user"
echo "✅ Use 'delsstp' to delete a user"
echo "✅ Use 'ceksstp' to check users"
echo "✅ Use 'renewsstp' to renew accounts"
echo "===================================="
echo -e "${NC}"
rm -f /root/sstp.sh

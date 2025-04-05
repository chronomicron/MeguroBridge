#!/bin/bash

# MeguroBridge Setup Script
# This script configures a Raspberry Pi to act as a Wi-Fi repeater
# using internal Wi-Fi for upstream and USB dongle for hotspot.
# It can also revert all configuration changes made by this script.

set -e

clear

echo "\nMeguroBridge Script"
echo "================================"
echo "This script can INSTALL or UNINSTALL MeguroBridge on your Raspberry Pi."
echo "Make sure your Pi has an internal Wi-Fi and a USB Wi-Fi dongle plugged in."
echo ""
echo "1) Install MeguroBridge"
echo "2) Uninstall MeguroBridge"
echo ""
read -p "Enter your choice [1-2]: " choice

if [[ "$choice" == "2" ]]; then
    echo "\nUninstalling MeguroBridge..."
    step=1

    echo "($step/6) Disabling services..."
    sudo systemctl stop hostapd
    sudo systemctl stop dnsmasq
    sudo systemctl disable hostapd
    sudo systemctl disable dnsmasq
    step=$((step+1))

    echo "($step/6) Restoring /etc/dnsmasq.conf..."
    if [ -f /etc/dnsmasq.conf.orig ]; then
        sudo mv /etc/dnsmasq.conf.orig /etc/dnsmasq.conf
    fi
    step=$((step+1))

    echo "($step/6) Removing static IP config in /etc/dhcpcd.conf..."
    sudo sed -i '/# MeguroBridge start/,/# MeguroBridge end/d' /etc/dhcpcd.conf
    step=$((step+1))

    echo "($step/6) Clearing NAT rules and IP forwarding..."
    sudo iptables -t nat -D POSTROUTING -o wlan0 -j MASQUERADE || true
    sudo iptables -D FORWARD -i wlan0 -o wlan1 -m state --state RELATED,ESTABLISHED -j ACCEPT || true
    sudo iptables -D FORWARD -i wlan1 -o wlan0 -j ACCEPT || true
    sudo sed -i '/net.ipv4.ip_forward=1/d' /etc/sysctl.conf
    sudo netfilter-persistent save
    step=$((step+1))

    echo "($step/6) Deleting hostapd config..."
    sudo rm -f /etc/hostapd/hostapd.conf
    sudo sed -i 's|DAEMON_CONF="/etc/hostapd/hostapd.conf"|#DAEMON_CONF=""|' /etc/default/hostapd
    step=$((step+1))

    echo "($step/6) Uninstallation complete!"
    exit 0
fi

step=1

# Step 1: Update system
echo "($step/9) Updating system packages..."
sudo apt update && sudo apt upgrade -y
step=$((step+1))

# Step 2: Install required packages
echo "($step/9) Installing required packages..."
sudo apt install -y dnsmasq hostapd netfilter-persistent iptables-persistent
step=$((step+1))

# Step 3: Enable system services
echo "($step/9) Enabling system services..."
sudo systemctl unmask hostapd
sudo systemctl enable hostapd
step=$((step+1))

# Step 4: Configure static IP for hotspot (USB Wi-Fi assumed as wlan1)
echo "($step/9) Configuring static IP for wlan1..."
echo "# MeguroBridge start" | sudo tee -a /etc/dhcpcd.conf > /dev/null
echo "interface wlan1" | sudo tee -a /etc/dhcpcd.conf > /dev/null
echo "    static ip_address=192.168.4.1/24" | sudo tee -a /etc/dhcpcd.conf > /dev/null
echo "    nohook wpa_supplicant" | sudo tee -a /etc/dhcpcd.conf > /dev/null
echo "# MeguroBridge end" | sudo tee -a /etc/dhcpcd.conf > /dev/null
step=$((step+1))

# Step 5: Configure dnsmasq (DHCP server)
echo "($step/9) Setting up dnsmasq..."
sudo mv /etc/dnsmasq.conf /etc/dnsmasq.conf.orig
sudo tee /etc/dnsmasq.conf > /dev/null <<EOF
interface=wlan1
  dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
EOF
step=$((step+1))

# Step 6: Configure hostapd
read -p "Enter your desired Wi-Fi password for network 'Meguro' (min 8 characters): " wifi_password

sudo tee /etc/hostapd/hostapd.conf > /dev/null <<EOF
interface=wlan1
driver=nl80211
ssid=Meguro
hw_mode=g
channel=7
wmm_enabled=0
auth_algs=1
wpa=2
wpa_passphrase=$wifi_password
wpa_key_mgmt=WPA-PSK
rsn_pairwise=CCMP
EOF

sudo sed -i 's|#DAEMON_CONF=""|DAEMON_CONF="/etc/hostapd/hostapd.conf"|' /etc/default/hostapd
step=$((step+1))

# Step 7: Set up IP forwarding and NAT
echo "($step/9) Enabling IP forwarding and NAT..."
echo "# MeguroBridge start" | sudo tee -a /etc/sysctl.conf > /dev/null
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf > /dev/null
echo "# MeguroBridge end" | sudo tee -a /etc/sysctl.conf > /dev/null
sudo sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"
sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo iptables -A FORWARD -i wlan0 -o wlan1 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i wlan1 -o wlan0 -j ACCEPT
sudo netfilter-persistent save
step=$((step+1))

# Step 8: Restart services
echo "($step/9) Restarting services..."
sudo systemctl restart dhcpcd
sudo systemctl restart hostapd
sudo systemctl restart dnsmasq
step=$((step+1))

# Step 9: Done
echo "($step/9) Setup complete!"
echo "\nYou can now configure your internal interface (wlan0) to connect to a public Wi-Fi, and devices can connect to 'Meguro'."
echo "\nReboot your Pi to ensure everything starts correctly."
echo "\nTo reboot now, press Enter or Ctrl+C to cancel."
read
sudo reboot

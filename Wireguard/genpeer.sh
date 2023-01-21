#!/bin/bash

# 2023.01.21 - Giacomo Girotto - V 0.1 - 2023.01.21
# This code is provided under the terms of the GNU General Public License version 2 only (GPL-2.0)

# This is a crude beta version of a simple script that generates peer configuration files
# for wireguard tunnel[s] in /etc/wireguard/peers/ given the self exolanatory parameters
# run it without parameters to get the correct syntax.
# The IP addresses are substituted by letters for obvious reasons but it should be easy 
# to replace them with the correct ones.


if [[ -z $1 && -z $2 && -z $3 && -z $4 ]]
  then
    echo "No arguments; use peer name as \$1, tunnel as \$2 and the last digit of the private ip as \$3"
    echo "To select the allowed ip range[s] type in place of \$4"
    echo "0 to allow only the VPN range, 1 to add the server's LAN, 2 to add the server's gateway LAN to that and 3 to add Internet; 4 for only internet and VPN addresses"
    echo "Otherwise write your own custom networks and subnets separated by comma eg. 172.16.20.16/30,10.50.90.0/24" 
    exit
fi


if [[ ! ( -f "/etc/wireguard/peers/$1_private.key" && -f "/etc/wireguard/peers/$1_public.key" ) ]]
  then

    wg genkey | sudo tee /etc/wireguard/peers/$1_private.key
    sudo chmod go= /etc/wireguard/peers/$1_private.key
    sudo cat /etc/wireguard/peers/$1_private.key | wg pubkey | sudo tee /etc/wireguard/peers/$1_public.key

fi


case $4 in

  0)												# ONLY TRAFFIC TO IPS IN THE VPN SUBNET ARE ROUTED THROUGH THE TUNNEL
    ALLOWEDIPS="Z.Z.Z.0/24"
    NET="VPN"
    ;;

  1)												# ONLY TRAFFIC TO IPS IN THE VPN SUBNET AND THE SERVER'S SUBNET ARE ROUTED THROUGH THE TUNNEL
    ALLOWEDIPS="Z.Z.Z.0/24,B.B.B.B/B"
    NET="VPN, LAN"
    ;;

  2)												# ONLY TRAFFIC TO IPS IN THE VPN SUBNET AND THE SERVER'S LAN AND IPS ON ANOTHER LAN ARE ROUTED THROUGH THE TUNNEL
    ALLOWEDIPS="Z.Z.Z.0/24,B.B.B.B/B,C.C.C.C/C"
    NET="VPN, LAN, GW_LAN"
    ;;

  3)
    ALLOWEDIPS="0.0.0.0/0"							# ALL THE TRAFFIC IS ROUTED THROUGH THE TUNNEL
    NET="VPN, LAN, GW_LAN, INTERNET"
    ;;

  4)												# ONLY THE TRAFFIC TO THE INTERNET IS ROUTED THROUGH THE TUNNEL (I'VE EXCLUDED ALL THE PRIVATE IP ADDRESS RANGES - 10.0.0.0/8,172.16.0.0/12,192.168.0.0/16)
    ALLOWEDIPS="0.0.0.0/5,8.0.0.0/7,11.0.0.0/8,12.0.0.0/6,16.0.0.0/4,32.0.0.0/3,64.0.0.0/2,128.0.0.0/3,160.0.0.0/5,168.0.0.0/6,172.0.0.0/12,172.32.0.0/11,172.64.0.0/10,172.128.0.0/9,173.0.0.0/8,174.0.0.0/7,176.0.0.0/4,192.0.0.0/9,192.128.0.0/11,192.160.0.0/13,192.169.0.0/16,192.170.0.0/15,192.172.0.0/14,192.176.0.0/12,192.192.0.0/10,193.0.0.0/8,194.0.0.0/7,196.0.0.0/6,200.0.0.0/5,208.0.0.0/4,224.0.0.0/3"
    NET="INTERNET"
    ;;

  *)
    ALLOWEDIPS=$4									# ONLY THE TRAFFIC TO THE SPECIFIED SUBNETS WILL BE ROUTED THROUGH THE TUNNEL
    NET="Custom: $4"
    ;;
esac



rm /etc/wireguard/peers/$1_$2.conf
echo "[interface]" >> /etc/wireguard/peers/$1_$2.conf
echo "PrivateKey = $(</etc/wireguard/peers/$1_private.key)" >> /etc/wireguard/peers/$1_$2.conf
echo "Address = Z.Z.Z.$3/24" >> /etc/wireguard/peers/$1_$2.conf
echo "" >> /etc/wireguard/peers/$1_$2.conf
echo "[Peer]" >> /etc/wireguard/peers/$1_$2.conf
echo "PublicKey = $(</etc/wireguard/public.key)" >> /etc/wireguard/peers/$1_$2.conf
echo "AllowedIPs = $ALLOWEDIPS" >> /etc/wireguard/peers/$1_$2.conf
echo "Endpoint = D.D.D.D:EEEE" >> /etc/wireguard/peers/$1_$2.conf
echo "" >> /etc/wireguard/peers/$1_$2.conf

qrencode -t ansiutf8 < /etc/wireguard/peers/$1_$2.conf

echo 
echo "Config for peer $1: tunnel $2, IP: Z.Z.Z.$3/24, Network[s]: $NET" 

sudo wg set $2 peer $(</etc/wireguard/peers/$1_public.key) allowed-ips $ALLOWEDIPS

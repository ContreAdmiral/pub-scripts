#!/usr/bin/env bash

# print a pretty header

echo
echo " +---------------------------------------------------+"
echo " |            CREATING USER ON CLOUD VPN SERVER      |"
echo " +---------------------------------------------------+"
echo

# ask the user questions about his/her preferences
vpnclientpwhash=$(echo $password | makepasswd --chars 40)

read -ep " mkusername. Example: mkusername: " -i "" mkusername
read -ep " Cluster number. Example: 001: " -i "" clusternumber
read -ep " Confirm Cluster Name and Number: " -i "CLUSTER$clusternumber" clientsitename
read -ep " Confirm Cluster internal LAN subnet: " -i "2.27.245$(echo $clusternumber | sed 's/^0*//').0/24" internallansubnet
read -ep " VPN Local Address (no spaces): " -i "2.27.245.$(echo $clusternumber | sed 's/^0*//')" vpnlocaladdress
read -ep " VPN Remote Address (no spaces): " -i "2.27.245.$(echo $clusternumber | sed 's/^0*//')" vpnremoteaddress



# creating script file to run on the cloud vpn server

# creation of vpn profile
echo '/ppp profile'  > $clientsitename.txt
echo 'add name='$clientsitename' use-encryption=yes'  >> $clientsitename.txt
echo '/interface ovpn-server' >> $clientsitename.txt
echo 'add name=<ovpn-'$clientsitename'> user='$clientsitename'' >> $clientsitename.txt
echo '/ip firewall nat' >> $clientsitename.txt
echo 'add action=dst-nat chain=dstnat comment="Xeoma DST to '$clientsitename'" dst-port=\' >> $clientsitename.txt
echo '    10'$clusternumber' in-interface=ether1 protocol=tcp to-addresses='$vpnremoteaddress' \' >> $clientsitename.txt
echo '    to-ports=10090' >> $clientsitename.txt
echo 'add action=masquerade chain=srcnat comment=\' >> $clientsitename.txt
echo '    "'$clientsitename' MSQ rule to allow NAT from Public" out-interface=\' >> $clientsitename.txt
echo '    <ovpn-'$clientsitename'>' >> $clientsitename.txt
    
# creation of vpn user
echo '/ppp secret'  >> $clientsitename.txt
echo 'add local-address='$vpnlocaladdress' name='$clientsitename' password='$vpnclientpwhash' \'  >> $clientsitename.txt
echo '    profile='$clientsitename' remote-address='$vpnremoteaddress' service=ovpn'  >> $clientsitename.txt
# outputting the file and instructions of what to do next
echo
echo " +---------------------------------------------------+"
echo " |      CREATED USER SCRIPT ON CLOUD VPN SERVER      |"
echo " | Copy the code below in between the dotted lines   |"
echo " |      into the terminal of the cloud VPN server    |"
echo " | Allow Port 10$clusternumber on the Amazon AWS                |"
echo " +---------------------------------------------------+"
echo 
echo -------------------------------------------------------------------------------------
echo 
cat $clientsitename.txt > $clientsitename.cloudcreationg.txt
echo 
echo -------------------------------------------------------------------------------------
#This is the end of creating script to run on the cloud vpn server
#creating a script to run on new client Mikrotik client
# ask if user has been created on the cloud server
echo 
while true; do
    echo " Did you create a user on the Cloud VPN Server:"
    echo
    echo "  [1] Yes, I have created a user on the Cloud VPN Server"
    echo "  [2] No, I have NOT yet created a user on the Cloud VPN Server"
    echo "  [3] I need help"
    echo
    read -p " please enter your preference: [1|2|3]: " ubver
    case $ubver in
        [1]* )  echo 
                echo Please make sure that the user that has been created on the
                echo cloud vpn was properly created and does not have any issues
                echo 
                break;;
        [2]* )  echo 
                echo Make sure to create a user first and then re-run the script
                echo 
                exit
                break;;
        [3]* )  echo 
                echo please ask for help on how to create a user on cloud vpn 
                exit
                break;;
        * ) echo " please answer [1], [2] or [3]";;
    esac
done

echo
echo " +---------------------------------------------------+"
echo " |            CREATING A SCRIPT FOR CLIENT DEVICE    |"
echo " +---------------------------------------------------+"
echo

read -ep " Confirm Cluster LAN DHCP Pool is: " -i "2.27.245$(echo $clusternumber | sed 's/^0*//').200-2.27.245$(echo $clusternumber | sed 's/^0*//').250" lanpool
read -ep " Confirm Cluster LAN Gateway is: " -i "2.27.245$(echo $clusternumber | sed 's/^0*//').1" gateway
read -ep " Confirm Cluster Subnet ID is: " -i "2.27.245$(echo $clusternumber | sed 's/^0*//').0/24" subnetid
read -ep " Confirm Cluster Subnet: " -i "255.255.255.0" subnetnetwork

echo '
/interface bridge
add fast-forward=no name=LAN
/interface ethernet
set [ find default-name=ether1 ] name=WAN
/ip pool
add name=LAN-Pool ranges='$lanpool'
/ip dhcp-server
add address-pool=LAN-Pool disabled=no interface=LAN name=LAN-DHCP
/ppp profile
add name=CLUSTER-VPN
/interface ovpn-client
add cipher=aes256 connect-to=sg-mk-chr-001.dynns.com \
    name=CLUSTER-VPN password="'$vpnclientpwhash'\
    " profile=CLUSTER-VPN user='$clientsitename'
/interface bridge port  
add bridge=LAN interface=ether2
add bridge=LAN interface=ether3
add bridge=LAN interface=ether4
add bridge=LAN interface=ether5
/ip accounting
set account-local-traffic=yes enabled=yes
/ip address
add address=2.27.245'$(echo $clusternumber | sed 's/^0*//')'.1/24 interface=LAN network=2.27.245'$(echo $clusternumber | sed 's/^0*//')'.0
/ip dhcp-client
add dhcp-options=hostname,clientid disabled=no interface=WAN
/ip dhcp-server network
add address=2.27.245'$(echo $clusternumber | sed 's/^0*//')'.0/24 dns-server=2.27.245'$(echo $clusternumber | sed 's/^0*//')'.1,8.8.8.8,75.75.76.76 domain=\
    '$clientsitename'.local gateway=2.27.245'$(echo $clusternumber | sed 's/^0*//')'.1 netmask=24 ntp-server=\
    2.27.245'$(echo $clusternumber | sed 's/^0*//')'.1,138.68.46.177
/ip dns
set allow-remote-requests=yes cache-max-ttl=2w servers=8.8.8.8
/ip firewall filter
add action=accept chain=forward disabled=yes log-prefix=\
    "Forward Logging:       :        ::::::"
add action=accept chain=input disabled=yes
add action=accept chain=input comment="Allow ICMP" protocol=icmp src-address=\
    24.19.67.219
add action=accept chain=input comment="Allow ICMP" in-interface=CLUSTER-VPN \
    protocol=icmp
add action=accept chain=input comment="Allow ICMP" in-interface=LAN protocol=\
    icmp
add action=accept chain=input comment="Allow Winbox" dst-port=8291 \
    in-interface=CLUSTER-VPN protocol=tcp
add action=accept chain=input comment="Allow Winbox" dst-port=8291 \
    in-interface=LAN protocol=tcp
add action=accept chain=input comment="Allow Winbox" dst-port=8291 \
    in-interface=WAN protocol=tcp src-address=x.x.x.x
add action=accept chain=input comment="Allow Winbox" dst-port=8291 \
    in-interface=WAN protocol=tcp src-address=10.10.10.0/24
add action=accept chain=input comment="Allow Winbox" dst-port=8291 \
    in-interface=WAN protocol=tcp src-address=10.0.0.0/24
add action=accept chain=input comment="Allow SSH" dst-port=22 in-interface=\
    CLUSTER-VPN protocol=tcp
add action=accept chain=input comment="Allow SSH" dst-port=22 in-interface=\
    LAN protocol=tcp
add action=accept chain=input comment="Allow SSH" dst-port=22 protocol=tcp \
    src-address=x.x.x.x
add action=drop chain=input comment="Drop Invalid" connection-state=invalid
add chain=input comment="Allow Established" connection-state=established
add chain=input comment="Allow Related" connection-state=related
add action=log chain=input comment="Log before drop" dst-address=\
    !255.255.255.255 log-prefix="Input Logging: "
add action=drop chain=input comment="Drop Traffic"
add action=accept chain=forward comment="Allow Custom Ports" dst-port=10050 \
    protocol=tcp

/ip firewall nat
add action=masquerade chain=srcnat out-interface=WAN
add action=masquerade chain=srcnat out-interface=CLUSTER-VPN
add action=dst-nat chain=dstnat comment="'$clientsitename' Web APPLIANCE" \
    dst-port=10090 in-interface=CLUSTER-VPN protocol=tcp to-addresses=\
    2.27.245'$(echo $clusternumber | sed 's/^0*//')'.10 to-ports=10090
add action=dst-nat chain=dstnat comment="'$clientsitename' Zabbix Agent" \
    dst-port=10050 in-interface=CLUSTER-VPN protocol=tcp to-addresses=\
    2.27.245'$(echo $clusternumber | sed 's/^0*//')'.10 to-ports=10050




/ip route
add distance=1 dst-address=182.57.230.0/20 gateway=CLUSTER-VPN
add distance=1 dst-address=182.57.240.0/24 gateway=CLUSTER-VPN
/ip service
set telnet disabled=yes
set ftp disabled=yes
set api disabled=yes
set api-ssl disabled=yes
/snmp
set contact='$clientsitename' enabled=yes location='$clientsitename' trap-generators=\
    interfaces trap-interfaces=all
/system clock
set time-zone-name=America/Los_Angeles
/system identity
set name='$clientsitename'
/system ntp client
set enabled=yes primary-ntp=138.68.46.177 secondary-ntp=69.10.161.7
/system ntp server
set enabled=yes
/system routerboard settings
set silent-boot=no
/user add name=%mkusername% password=TempP@ssw0rdChangeNow group=full
/system package disable hotspot
/system package disable wireless
/system package disable ipv6
/system package disable mpls
/snmp
set contact=StableGuard enabled=yes location='$clientsitename' trap-generators=\
    interfaces trap-interfaces=all trap-version=2
'  > $clientsitename.txt

# outputting the file and instructions of what to do next
echo 
echo -------------------------------------------------------------------------------------
#This is the end of creating script to run on the cloud vpn server
echo -------------------------------------------------------------------------------------
echo -------------------------------------------------------------------------------------
echo " finished creating the script"
echo " the new files are located at:"
echo "$(echo | readlink -f $clientsitename.txt)"
echo -------------------------------------------------------------------------------------
echo 
echo Below are your site settings. Confirm to make sure everything is correct.
echo If anything is incorrect, re-run the script.
echo 
echo " your Clinet Name is:         $clientsitename"
echo " your VPN Local IP is:        $vpnlocaladdress"
echo " your VPN Remote IP is:       $vpnremoteaddress"
echo " your VPN UserName is:        $clientsitename"
echo " Your LAN subnet is:          $internallansubnet"
echo " Your LAN DHCP Pool is:       $lanpool"
echo " Your LAN Gateway is:         $gateway"
echo " Your Subnet ID is:           $subnetid"
echo
echo -------------------------------------------------------------------------------------

exit

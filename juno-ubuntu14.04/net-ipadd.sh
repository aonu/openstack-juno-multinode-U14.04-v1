#!/bin/bash -ex


source config.cfg
#Update cho Ubuntu
apt-get -y install ubuntu-cloud-keyring
echo "deb http://ubuntu-cloud.archive.canonical.com/ubuntu" \
"trusty-updates/juno main" > /etc/apt/sources.list.d/cloudarchive-juno.list

apt-get update -y && apt-get upgrade -y && apt-get dist-upgrade -y

echo "########## Cai dat va cau hinh OpenvSwitch ##########"
apt-get install -y openvswitch-controller openvswitch-switch openvswitch-datapath-dkms

echo "############ Cai dat NTP va cau hinh can thiet ############ "
sleep 7 

apt-get install ntp -y
apt-get install python-mysqldb -y
#
echo "############ Sao luu cau hinh cua NTP ############ "
sleep 7 
cp /etc/ntp.conf /etc/ntp.conf.bka
rm /etc/ntp.conf
cat /etc/ntp.conf.bka | grep -v ^# | grep -v ^$ >> /etc/ntp.conf
#

sed -i 's/server ntp.ubuntu.com/server $CON_MGNT_IP iburst/g' /etc/ntp.conf


echo "########## Cau hinh br-int va br-ex cho OpenvSwitch ##########"
sleep 5
ovs-vsctl add-br br-int
ovs-vsctl add-br br-ex
ovs-vsctl add-port br-ex eth1

echo "########## Cau hinh dia chi IP cho br-ex ##########"

ifaces=/etc/network/interfaces
test -f $ifaces.orig1 || cp $ifaces $ifaces.orig1
rm $ifaces
cat << EOF > $ifaces
# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
auto br-ex
iface br-ex inet static
address $NET_EXT_IP
netmask $NETMASK_ADD
gateway $GATEWAY_IP
dns-nameservers 8.8.8.8

auto eth1
iface eth1 inet manual
   up ifconfig \$IFACE 0.0.0.0 up
   up ip link set \$IFACE promisc on
   down ip link set \$IFACE promisc off
   down ifconfig \$IFACE down

auto eth0
iface eth0 inet static
address $NET_MGNT_IP
netmask $NETMASK_ADD

auto eth2
iface eth2 inet static
address $NET_DATA_VM_IP
netmask $NETMASK_ADD
EOF

echo "Cau hinh hostname cho NETWORK NODE"
sleep 3
echo "network" > /etc/hostname
hostname -F /etc/hostname

echo "##########  Khoi dong lai may sau khi cau hinh IP Address ##########"
init 6


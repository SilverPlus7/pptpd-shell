#!/bin/sh

######################################
#   pptpd 1.4.0 通过源码安装 a shell for install pptpd. 
#   Version 1.0
#   Editor: licheng007169@gmail.com
#   Date: 2014-7-5 19:01
######################################

yum remove -y pptpd ppp-*
iptables --flush POSTROUTING --table nat
iptables --flush FORWARD
rm -rf /etc/pptpd.conf
rm -rf /etc/ppp
rm -rf /usr/lib/pptpd/

yum -y install gcc
yum -y install ppp-*
mkdir ~/src
cd ~/src
wget http://downloads.sourceforge.net/project/poptop/pptpd/pptpd-1.4.0/pptpd-1.4.0.tar.gz
tar xzvf pptpd-1.4.0.tar.gz
cd pptpd-1.4.0
./configure
make
make install

mkdir /usr/lib/pptpd/
cp /usr/local/lib/pptpd/pptpd-logwtmp.so /usr/lib/pptpd/
cp /usr/local/sbin/bcrelay /usr/sbin/
cp /usr/local/sbin/pptpctrl /usr/sbin/
cp /usr/local/sbin/pptpd /usr/sbin/

cp ./samples/pptpd.conf /etc/
cp ./samples/options.pptpd /etc/ppp/

cp -f ./pptpd.init /etc/rc.d/init.d/pptpd
chmod +x /etc/rc.d/init.d/pptpd
chkconfig --add pptpd

sed -i 's/^logwtmp/#logwtmp/g' /etc/pptpd.conf
sed -i 's/^net.ipv4.ip_forward = 0/net.ipv4.ip_forward = 1/g' /etc/sysctl.conf
sysctl -p
echo "localip 192.168.240.1" >> /etc/pptpd.conf
echo "remoteip 192.168.240.2-100" >> /etc/pptpd.conf
echo "ms-dns 172.16.0.23" >> /etc/ppp/options.pptpd
echo "ms-dns 8.8.8.8" >> /etc/ppp/options.pptpd

pass=`openssl rand 6 -base64`
if [ "$1" != "" ]
then pass=$1
fi

echo "vpn pptpd ${pass} *" >> /etc/ppp/chap-secrets

iptables -t nat -A POSTROUTING -s 192.168.240.0/24 -j SNAT --to-source `ifconfig  | grep 'inet addr:'| grep -v '127.0.0.1' | cut -d: -f2 | awk 'NR==1 { print $1}'`
iptables -A FORWARD -p tcp --syn -s 192.168.240.0/24 -j TCPMSS --set-mss 1356
service iptables save

chkconfig iptables on
chkconfig pptpd on

service iptables start
service pptpd start

echo -e "VPN service is installed, your VPN username is \033[1mvpn\033[0m, VPN password is \033[1m${pass}\033[1m"


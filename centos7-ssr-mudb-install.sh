#!/bin/bash

#specify the access infromation
USER="MUDB"
PORT="443"
PASSWORD="centos7-ssr-mudb-sh"
METHOD="chacha20"
PROTOCOL="auth_aes128_md5"
OBFS="tls1.2_ticket_auth"

#use firewalld service to specify the port for the access permission. 
firewall-cmd --add-port=${PORT}/tcp --permanent
firewall-cmd --add-port=${PORT}/udp --permanent
firewall-cmd --reload

#make yum cache for serach packages
yum makecache

#install the EPEL-release packages
yum install epel-release -y

#download the repository for updating the latest version kernel, such as 4.10
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm
yum --enablerepo=elrepo-kernel install kernel-ml -y

#check which is the latest kernel
awk -F\' '$1=="menuentry " {print ++i":"$2}' /etc/grub2.cfg
#set the latest kernel for grub2 default kernel boot up
grub2-set-default 1

#install the shadowsocksr service
yum install git python-gevent supervisor -y
#install the libsodium library for supporting the encryption of chacha20 and chacha20-ietf
yum install libsodium -y
#git clone the latest source code to /usr/local/
cd /usr/local/ && git clone https://github.com/shadowsocksrr/shadowsocksr -b akkariiin/master && cd /usr/local/shadowsocksr && bash initcfg.sh
sed -i 's/sspanelv2/mudbjson/' userapiconfig.py
#add the access infromation as below.
python mujson_mgr.py -a -u ${USER} -p ${PORT} -m ${METHOD} -k ${PASSWORD} -O ${PROTOCOL} -o ${OBFS} -G "#"

#add supervisor config for ssr autostart
systemctl enable supervisord
cat <<EOF > /etc/supervisord.d/ssr.ini
[program:ssr]
command=/usr/bin/python /usr/local/shadowsocksr/server.py m
autostart=true
autorestart=true
user=root
EOF

#unlimit the conection
sed -i '/#@student        -/a \*               hard    nofile          1024000' /etc/security/limits.conf
sed -i '/#@student        -/a \*               soft    nofile           512000' /etc/security/limits.conf
sed -i '/SysVStartPriority=99/a\LimitNOFILE=512000' /usr/lib/systemd/system/supervisord.service

#setup the newest congestion google bbr and add to sysctl.conf
cat <<EOF >> /etc/sysctl.conf
# max open files
fs.file-max = 1024000
# max read buffer
net.core.rmem_max = 67108864
# max write buffer
net.core.wmem_max = 67108864
# default read buffer
net.core.rmem_default = 65536
# default write buffer
net.core.wmem_default = 65536
# max processor input queue
net.core.netdev_max_backlog = 4096
# max backlog
net.core.somaxconn = 4096

# resist SYN flood attacks
net.ipv4.tcp_syncookies = 1
# reuse timewait sockets when safe
net.ipv4.tcp_tw_reuse = 1
# turn off fast timewait sockets recycling
net.ipv4.tcp_tw_recycle = 0
# short FIN timeout
net.ipv4.tcp_fin_timeout = 30
# short keepalive time
net.ipv4.tcp_keepalive_time = 1200
# outbound port range
net.ipv4.ip_local_port_range = 10000 65000
# max SYN backlog
net.ipv4.tcp_max_syn_backlog = 4096
# max timewait sockets held by system simultaneously
net.ipv4.tcp_max_tw_buckets = 5000
# turn on TCP Fast Open on both client and server side
net.ipv4.tcp_fastopen = 3
# TCP receive buffer
net.ipv4.tcp_rmem = 4096 87380 67108864
# TCP write buffer
net.ipv4.tcp_wmem = 4096 65536 67108864
# turn on path MTU discovery
net.ipv4.tcp_mtu_probing = 1

# for high-latency network
#net.ipv4.tcp_congestion_control = hybla

# for low-latency network, use cubic instead
# net.ipv4.tcp_congestion_control = cubic

#for 4.9 kernel bbr congestion settings
net.core.default_qdisc=fq_codel
net.ipv4.tcp_congestion_control=bbr
EOF

#reboot the centos7
sync; shutdown -r now

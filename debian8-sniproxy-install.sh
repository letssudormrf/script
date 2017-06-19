#!/bin/bash

apt-get update
apt-get upgrade -y
apt-get install -y libev4 libudns0 wget

wget --no-check-certificate "https://drive.google.com/uc?export=download&id=0B3SWmHp1WoIgX0sxVUdJM3NOREE" -O sniproxy-dbg_0.5.0_amd64.deb
wget --no-check-certificate "https://drive.google.com/uc?export=download&id=0B3SWmHp1WoIgU1ktWE5kdjFXcVE" -O sniproxy_0.5.0_amd64.deb
dpkg -i sniproxy-dbg_0.5.0_amd64.deb sniproxy_0.5.0_amd64.deb

cp /etc/sniproxy.conf /etc/sniproxy.conf.old

cat <<EOF > /etc/sniproxy.conf
# sniproxy example configuration file
# lines that start with # are comments
# lines with only white space are ignored

user daemon

# PID file
pidfile /var/run/sniproxy.pid

error_log {
    # Log to the daemon syslog facility
    syslog daemon

    # Alternatively we could log to file
    #filename /var/log/sniproxy/sniproxy.log

    # Control the verbosity of the log
    priority notice
}

# blocks are delimited with {...}
#listen 80 {
#    proto http
#    table http_hosts
    # Fallback backend server to use if we can not parse the client request
#    fallback localhost:8080

#    access_log {
#        filename /var/log/sniproxy/http_access.log
#        priority notice
#    }
#}

listen 443 {
    proto tls
    table https_hosts

    access_log {
        filename /var/log/sniproxy/https_access.log
        priority notice
    }
}

# named tables are defined with the table directive
table http_hosts {
    example.com 192.0.2.10:8001
    example.net 192.0.2.10:8002
    example.org 192.0.2.10:8003

# pattern:
# 	valid Perl-compatible Regular Expression that matches the
# 	hostname
#
# target:
#	- a DNS name
#	- an IP address (with optional port)
#	- '*' to use the hostname that the client requested
#
# pattern	target
#.*\.itunes\.apple\.com$	*:443
#.*	127.0.0.1:4443
}

# named tables are defined with the table directive
table https_hosts {
    # When proxying to local sockets you should use different tables since the
    # local socket server most likely will not autodetect which protocol is
    # being used
#    example.org unix:/var/run/server.sock
.* *:443
}

# if no table specified the default 'default' table is defined
table {
    # if no port is specified default HTTP (80) and HTTPS (443) ports are
    # assumed based on the protocol of the listen block using this table
#    example.com 192.0.2.10
#    example.net 192.0.2.20
}
EOF

sed -i 's/#DAEMON_ARGS="-c \/etc\/sniproxy.conf"/DAEMON_ARGS="-c \/etc\/sniproxy.conf"/' /etc/default/sniproxy
sed -i 's/ENABLED=0/ENABLED=1/' /etc/default/sniproxy
systemctl enable sniproxy
systemctl stop sniproxy
systemctl start sniproxy

sed -i '/#@student        -/a \*               hard    nofile          1024000' /etc/security/limits.conf
sed -i '/#@student        -/a \*               soft    nofile           512000' /etc/security/limits.conf

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
net.ipv4.tcp_congestion_control = htcp
#for 4.9 kernel bbr congestion settings
#net.core.default_qdisc=fq_codel
#net.ipv4.tcp_congestion_control=bbr
EOF

wget --no-check-certificate -qO /tmp/appex.sh "https://raw.githubusercontent.com/0oVicero0/serverSpeeder_Install/master/appex.sh" && bash /tmp/appex.sh 'install'

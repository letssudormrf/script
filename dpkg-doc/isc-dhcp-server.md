apt install isc-dhcp-server

vim /etc/default/isc-dhcp-server

INTERFACES="br0"

vim /etc/dhcp/dhcpd.conf

subnet 192.168.1.0 netmask 255.255.255.0 {
  range 192.168.1.43 192.168.1.43;
  range 192.168.1.45 192.168.1.45;
  option subnet-mask 255.255.255.0;
  option domain-name-servers 8.8.8.8, 8.8.4.4;
  option routers 192.168.1.1;
  default-lease-time 600;
  max-lease-time 7200;
}

vim /etc/dhcp/dhcpd6.conf

option dhcp6.name-servers 2001:4860:4860::8888, 2001:4860:4860::8844;
subnet6 fd90::/64 {
        range6 fd90::0001 fd90::ffff;
        prefix6 fd90:: fd90:: /56;
        default-lease-time 600;
        max-lease-time 7200;
}


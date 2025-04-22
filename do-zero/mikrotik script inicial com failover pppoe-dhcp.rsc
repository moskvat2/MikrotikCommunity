# CONFIGURACAO COM DOIS LINKS DE INTERNET ATIVOS POR PPPOE e DHCP

:global prov1iface "ether1"
:global prov1routecomment "ROTA PRINCIPAL"
:global prov1netwatchtarget "8.8.8.8"

:global prov2iface "ether2"
:global prov2user "usuario02"
:global prov2pass "usuario02"
:global prov2routecomment "ROTA BACKUP"


:global internaliface "bridge1"
:global internaladdress "192.168.88.1/24"
:global internalnetwork "192.168.88.0"
:global dhcprangestart "192.168.88.50"
:global dhcprangeend "192.168.88.200"
:global dnsserver "1.1.1.1"


:global internalnetworkdhcp "192.168.88.0/24"
:global internaladdressdhcp "192.168.88.1"

/interface bridge
    add name="$internaliface"

/interface bridge port
    add bridge="$internaliface" interface="ether3"

/ip dhcp-client
    add interface=$prov1iface add-default-route=yes \
    default-route-distance=1 use-peer-dns=yes

/interface/pppoe-client
    add name="pppoe-out-provedor02" interface="$prov2iface" user="$prov2user" password="$prov2pass" add-default-route=yes use-peer-dns=yes default-route-distance=2 disable=no

/ip address
    add interface="$internaliface" address="$internaladdress" network="$internalnetwork"

/ip pool
    add name="dhcppoolinterno" ranges="$dhcprangestart-$dhcprangeend"

/ip dhcp-server
    add name="dhcp-pool-interno" interface="$internaliface" address-pool=dhcppoolinterno

/ip dhcp-server network
    add address="$internalnetworkdhcp" gateway="$internaladdressdhcp" dns-server="$dnsserver"

/interface list add name=internet

/interface list member
    add interface=ether1 list=internet
    add interface=pppoe-out-provedor02 list=internet

/ip/firewall/nat
    add action=masquerade out-interface-list=internet chain=nat

/tool netwatch
    add host="$prov1netwatchtarget" interval=5 timeout=1 up-script="/ip route set distance=1 [find dst-address=0.0.0.0/0 and gateway=$prov2iface]" down-script="/ip route set distance=3 [find dst-address=0.0.0.0/0 and gateway=$prov2iface]" comment="Monitor Provedor 01"

/ip dns
    set servers="$dnsserver" allow-remote-requests=yes

/ip/route/add dst-address=8.8.8.8 gateway=[/ip/dhcp-client/get ether1 gateway]


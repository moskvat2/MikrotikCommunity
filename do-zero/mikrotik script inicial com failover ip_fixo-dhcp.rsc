# CONFIGURACAO COM DOIS LINKS DE INTERNET ATIVOS IP FIXO E DHCP

:global prov1iface "ether1"
:global prov1routecomment "ROTA PRINCIPAL"
:global prov1netwatchtarget "8.8.8.8"
:global ipdedicado1 "10.10.88.2/29"
:global rotaipdedicado1 "10.10.88.1"

:global prov2iface "ether2"
:global prov2routecomment "ROTA BACKUP"
:global ipdedicado2 "10.10.99.2/29"
:global rotaipdedicado2 "10.10.99.1"

:global internaliface "bridge1"
:global internaladdress "192.168.88.1/24"
:global internalnetwork "192.168.88.0"
:global dhcprangestart "192.168.88.50"
:global dhcprangeend "192.168.88.200"
:global dnsserver "1.1.1.1"

:global internalnetworkdhcp "192.168.88.0/24"
:global internaladdressdhcp "192.168.88.1"

delay 2

/interface bridge
    add name="$internaliface"

/interface bridge port
    add bridge="$internaliface" interface="ether3"


/ip address
    add address="$ipdedicado1" interface="$prov1iface" \
    comment="Link Dedicado"

/ip dhcp-client
    add interface=$prov2iface add-default-route=yes \
    default-route-distance=2 use-peer-dns=yes


/ip address
    add interface="$internaliface" address="$internaladdress" network="$internalnetwork"


/ip pool
    add name="dhcppoolinterno" ranges="$dhcprangestart-$dhcprangeend"

/ip dhcp-server
    add name="dhcp-pool-interno" interface="$internaliface" address-pool=dhcppoolinterno

/ip dhcp-server network
    add address="$internalnetworkdhcp" gateway="$internaladdressdhcp" dns-server="$dnsserver"

/ip route
    add dst-address="0.0.0.0/0" gateway="$rotaipdedicado1" distance=1 comment="$prov1routecomment"


/interface list add name=internet

/interface list member
    add interface=ether1 list=internet
    add interface=ether2 list=internet

/ip/firewall/nat
    add action=masquerade out-interface-list=internet chain=nat

/tool netwatch
    add host="$prov1netwatchtarget" interval=5 timeout=1 up-script="/ip route set distance=1 [find comment=\"$prov1routecomment\"]" down-script="/ip route set distance=3 [find comment=\"$prov1routecomment\"]" comment="Monitor Provedor 01"

/ip dns
set servers="$dnsserver" allow-remote-requests=yes

/ip/route/add dst-address=8.8.8.8 gateway=$rotaipdedicado1 distance=10


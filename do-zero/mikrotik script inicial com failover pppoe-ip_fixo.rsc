# CONFIGURACAO COM DOIS LINKS DE INTERNET ATIVOS POR PPPOE e IP FIXO

:global prov1iface "ether1"
:global prov1routecomment "ROTA PRINCIPAL"
:global prov1netwatchtarget "8.8.8.8"
:global ipdedicado "10.10.88.2/29"
:global rotaipdedicado "10.10.88.1"

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
:if ([/interface bridge find name="$internaliface"] = "") do={
    add name="$internaliface"
}


/interface bridge port
:if ([/interface bridge port find bridge="$internaliface" interface="ether3"] = "") do={
    add bridge="$internaliface" interface="ether3"
}

    # configurando ip fixo
/ip address
:if ([/ip address find name="Link Dedicado"] = ""]) do={
    add address="$ipdedicado" interface="$prov1iface" \
    comment="Link Dedicado"
} else={
    set [find name="Link Dedicado"]
    add address="$ipdedicado" interface="prov1iface" \
}
    # fim do ip fixo

/interface/pppoe-client
:if ([/interface/pppoe-client find name="pppoe-out-provedor02"] = "") do={
    add name="pppoe-out-provedor02" interface="$prov2iface" user="$prov2user" password="$prov2pass" add-default-route=no use-peer-dns=yes
} else={
    set [find name="pppoe-out-provedor02"] interface="$prov2iface" user="$prov2user" password="$prov2pass" add-default-route=no use-peer-dns=yes
}

/ip address
:if ([/ip address find interface="$internaliface" address="$internaladdress"] = "") do={
    add interface="$internaliface" address="$internaladdress" network="$internalnetwork"
} else={
    set [find interface="$internaliface" address="$internaladdress"] address="$internaladdress" network="$internalnetwork"
}

/ip pool
:if ([/ip pool find name="dhcppoolinterno"] = "") do={
    add name="dhcppoolinterno" ranges="$dhcprangestart-$dhcprangeend"
} else={
    set [find name="dhcppoolinterno"] ranges="$dhcprangestart-$dhcprangeend"
}

/ip dhcp-server
:if ([/ip dhcp-server find name="dhcp-pool-interno"] = "") do={
    add name="dhcp-pool-interno" interface="$internaliface" address-pool=dhcppoolinterno
} else={
    set [find name="dhcp-pool-interno"] interface="$internaliface" address-pool=dhcppool-interno
}

/ip dhcp-server network
:if ([/ip dhcp-server network find address="$internalnetwork"] = "") do={
    add address="$internalnetworkdhcp" gateway="$internaladdressdhcp" dns-server="$dnsserver"
} else={
    set [find address="$internalnetwork"] gateway="$internaladdress" dns-server="$dnsserver"
}

    # ROTA LINK DEDICADO
/ip route
:if ([/ip route find comment="ROTA PRINCIPAL" <> ""]) do={
    add dst-address="0.0.0.0/0" gateway="$rotaipdedicado" distance=1 comment="$prov1routecomment"
} else={
    set [find dst-address="0.0.0.0/0" comment="ROTA PRINCIPAL"] distance=1 comment="$prov1routecomment"
}
    # FIM ROTA LINK DEDICADO

/ip route
:if ([/ip route find dst-address="0.0.0.0/0" gateway="pppoe-out-provedor02"] = "") do={
    add dst-address="0.0.0.0/0" gateway="pppoe-out-provedor02" distance=2 comment="$prov2routecomment"
} else={
    set [find dst-address="0.0.0.0/0" gateway="pppoe-out-provedor02"] distance=2 comment="$prov2routecomment"
}

/interface list add name=internet

/interface list member
    add interface=ether1 list=internet
    add interface=pppoe-out-provedor02 list=internet

/ip/firewall/nat
    add action=masquerade out-interface-list=internet chain=nat

/tool netwatch
:if ([/tool netwatch find host="$prov1netwatchtarget"] = "") do={
    add host="$prov1netwatchtarget" interval=5 timeout=1 up-script="/ip route set distance=1 [find comment=\"$prov1routecomment\"]" down-script="/ip route set distance=3 [find comment=\"$prov1routecomment\"]" comment="Monitor Provedor 01"
} else={
    set [find host="$prov1netwatchtarget"] interval=5 timeout=1 up-script="/ip route set distance=1 [find comment=\"$prov1routecomment\"]" down-script="/ip route set distance=3 [find comment=\"$prov1routecomment\"]" comment="Monitor Provedor 01"
}


/ip dns
set servers="$dnsserver" allow-remote-requests=yes

/interface pppoe-client
    set disabled=no [find name="pppoe-out-provedor02"] 

/ip/route/add dst-address=8.8.8.8 gateway=ether1


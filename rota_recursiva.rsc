# CONFIGURACAO BÁSICA DE ROTA RECURSIVA
# VANTAGEM: VOCÊ TERÁ UM FAILOVER SIMPLES E PRÁTICO
# DESVANTAGEM: PRECISA MONITORAR UM IP CONFIGÁVEL
# PARA NÃO GERAR FALSO POSITIVO
# NO EXEMPLO FOI UTILIZADO DNS DO GOOGLE, ENTÃO NÃO
# PODE SER UTILIZADO NOS COMPUTADORES DA REDE INTERNA
# AJUSTE AS CONFIGURAÇÕES CONFORME NECESSÁRIO

/interface bridge
    add name=bridge-LAN
/interface ethernet
    set [ find default-name=ether1 ] disable-running-check=no name=ether1-Provedor01
    set [ find default-name=ether2 ] disable-running-check=no name=ether2-Provedor02
/interface pppoe-client
    add disabled=no interface=ether1-Provedor01 name=pppoe-Provedor01 password=senhaProvedor01 use-peer-dns=yes user=usuarioProvedor01
    add disabled=no interface=ether2-Provedor02 name=pppoe-Provedor02 password=senhaProvedor02 use-peer-dns=yes user=usuarioProvedor02
/interface list
    add name=WAN
/ip pool
    add name=dhcp_pool0 ranges=172.16.0.2-172.16.0.254
/ip dhcp-server
    add address-pool=dhcp_pool0 interface=bridge-LAN lease-time=8h name=dhcp1
/interface bridge port
    add bridge=bridge-LAN interface=ether3
    add bridge=bridge-LAN interface=ether4
    add bridge=bridge-LAN interface=ether5
/interface list member
    add interface=pppoe-Provedor01 list=WAN
    add interface=pppoe-Provedor02 list=WAN
/ip address
    add address=172.16.0.1/24 interface=bridge-LAN network=172.16.0.0
/ip dhcp-server network
    add address=172.16.0.0/24 dns-server=172.16.0.1 gateway=172.16.0.1
/ip dns
    set allow-remote-requests=yes
/ip firewall filter
    add action=drop chain=input comment=invalidas connection-state=invalid in-interface-list=WAN
    add action=accept chain=input comment=estabelecidas/relacionadas connection-state=established,related in-interface-list=WAN
    add action=accept chain=input comment="gerencia mikrotik" dst-port=8291 in-interface-list=WAN protocol=tcp
    add action=accept chain=input comment=ping in-interface-list=WAN limit=3,5:packet protocol=icmp
    add action=drop chain=input comment="drop geral" in-interface-list=WAN
/ip firewall nat
    add action=masquerade chain=srcnat comment=navegacao out-interface-list=WAN
/ip route
    add disabled=no distance=1 dst-address=8.8.8.8/32 gateway=pppoe-Provedor01 pref-src="" routing-table=main scope=10 suppress-hw-offload=no \
        target-scope=10
    add disabled=no distance=1 dst-address=8.8.4.4/32 gateway=pppoe-Provedor02 pref-src="" routing-table=main scope=10 suppress-hw-offload=no \
        target-scope=10
    add check-gateway=ping disabled=no distance=1 dst-address=0.0.0.0/0 gateway=8.8.8.8 pref-src="" routing-table=main scope=30 \
        suppress-hw-offload=no target-scope=11
    add check-gateway=ping disabled=no distance=2 dst-address=0.0.0.0/0 gateway=8.8.4.4 pref-src="" routing-table=main scope=30 \
        suppress-hw-offload=no target-scope=12
/system clock
    set time-zone-name=America/Sao_Paulo
/system ntp client
    set enabled=yes
/system ntp client servers
    add address=a.st1.ntp.br

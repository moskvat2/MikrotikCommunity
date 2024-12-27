# CONFIGURAÇÃO BÁSICO DE 2 LINKS COM ECMP (LOADBALANCE) E REGRAS DE FIREWALL
# DESVANTAGEM DO ECMP: BALANCEAMENTO PODE NÃO SER IGUAL, SE HOUVER ACESSO A SITES BANCÁRIOS PODE HAVER ALTERAÇÃO
# CONSTANTE DOS IP'S E O BANCO PODE OU NÃO BLOQUEAR A CONEXÃO

/interface bridge
    add name=bridge-LAN
/interface ethernet
    set [ find default-name=ether1 ] disable-running-check=no name=ether1-Provedor01
    set [ find default-name=ether2 ] disable-running-check=no name=ether2-Provedor02

/interface pppoe-client
    add add-default-route=yes disabled=no interface=ether1-Provedor01 name=pppoe-Provedor01 use-peer-dns=yes user=usuarioProvedor01
    add add-default-route=yes disabled=no interface=ether2-Provedor02 name=pppoe-Provedor02 use-peer-dns=yes user=usuarioProvedor02
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
/ip dns set allow-remote-requests=yes
/ip firewall filter
    add action=drop chain=input comment=invalidas connection-state=invalid in-interface-list=WAN
    add action=accept chain=input comment=estabelecidas/relacionadas connection-state=established,related in-interface-list=WAN
    add action=accept chain=input comment="gerencia mikrotik" dst-port=8291 in-interface-list=WAN protocol=tcp
    add action=accept chain=input comment=ping in-interface-list=WAN limit=3,5:packet protocol=icmp
    add action=drop chain=input comment="drop geral" in-interface-list=WAN
/ip firewall nat
    add action=masquerade chain=srcnat comment=navegacao out-interface-list=WAN
/ip route
    add disabled=no distance=5 dst-address=8.8.8.8/32 gateway=pppoe-Provedor01 pref-src="" routing-table=main scope=30 suppress-hw-offload=no \
    target-scope=10
    add disabled=no distance=5 dst-address=8.8.4.4/32 gateway=pppoe-Provedor02 pref-src="" routing-table=main scope=30 suppress-hw-offload=no \
    target-scope=10
/system clock
    set time-zone-name=America/Sao_Paulo
/system ntp client 
    set enabled=yes
/system ntp client servers
    add address=a.st1.ntp.br
/tool netwatch
    add comment=Teste_Provedor02 disabled=no down-script=" /ip/route/disable [find dst-address=\"0.0.0.0/0\" gateway=\"pppoe-Provedor02\"]" \
        host=8.8.4.4 http-codes="" interval=30s packet-count=3 packet-interval=1s startup-delay=1m test-script="" thr-loss-count=2 type=icmp \
        up-script=" /ip/route/enable [find dst-address=\"0.0.0.0/0\" gateway=\"pppoe-Provedor02\"]"
    add comment=Teste_Provedor01 disabled=no down-script=" /ip/route/disable [find dst-address=\"0.0.0.0/0\" gateway=\"pppoe-Provedor01\"]" \
        host=8.8.8.8 http-codes="" interval=30s packet-count=3 packet-interval=1s startup-delay=1m test-script="" thr-loss-count=2 type=icmp \
        up-script=" /ip/route/enable [find dst-address=\"0.0.0.0/0\" gateway=\"pppoe-Provedor01\"]"

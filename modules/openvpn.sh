#!/bin/bash
# Módulo de OpenVPN para NexusVPN Pro
# Funciones: instalación, configuración, gestión de clientes

OPENVPN_CONFIG_DIR="/etc/openvpn"
OPENVPN_LOG_DIR="/var/log/openvpn"
OPENVPN_CLIENT_DIR="${INSTALL_DIR}/openvpn-clients"

install_openvpn() {
    inf "Instalando OpenVPN (TCP/UDP)..."
    log_info "Instalando OpenVPN"
    
    apt_install openvpn easy-rsa
    
    mkdir -p "$OPENVPN_CONFIG_DIR"/{client,server}
    mkdir -p "$OPENVPN_CLIENT_DIR"
    
    setup_openvpn_pki
    configure_openvpn_server
    
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p
    
    ok "OpenVPN instalado correctamente"
}

setup_openvpn_pki() {
    cd "$OPENVPN_CONFIG_DIR" || return 1
    
    if [[ ! -d easy-rsa ]]; then
        make-cadir easy-rsa
    fi
    
    cd easy-rsa || return 1
    
    ./easyrsa init-pki >> "$INSTALL_LOG" 2>&1
    ./easyrsa --batch build-ca nopass >> "$INSTALL_LOG" 2>&1
    ./easyrsa --batch gen-req server nopass >> "$INSTALL_LOG" 2>&1
    ./easyrsa --batch sign-req server server >> "$INSTALL_LOG" 2>&1
    ./easyrsa gen-dh >> "$INSTALL_LOG" 2>&1
    openvpn --genkey --secret ta.key >> "$INSTALL_LOG" 2>&1
    
    cp pki/ca.crt "$OPENVPN_CONFIG_DIR/server/"
    cp pki/issued/server.crt "$OPENVPN_CONFIG_DIR/server/"
    cp pki/private/server.key "$OPENVPN_CONFIG_DIR/server/"
    cp pki/dh.pem "$OPENVPN_CONFIG_DIR/server/"
    cp ta.key "$OPENVPN_CONFIG_DIR/server/"
    
    log_info "PKI de OpenVPN configurada"
}

configure_openvpn_server() {
    local server_ip=$(get_server_ip)
    local openvpn_tcp_port=$(cfg_get "ports.openvpn_tcp" "$DEFAULT_OPENVPN_TCP")
    local openvpn_udp_port=$(cfg_get "ports.openvpn_udp" "$DEFAULT_OPENVPN_UDP")
    
    cat > "$OPENVPN_CONFIG_DIR/server/tcp.conf" << TCPEOF
port ${openvpn_tcp_port}
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp-tcp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 1.1.1.1"
keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status-tcp.log
verb 3
client-config-dir /etc/openvpn/client
client-to-client
duplicate-cn
TCPEOF

    sed 's/proto tcp/proto udp/;s/port [0-9]*/port '"$openvpn_udp_port"'/;s/ipp-tcp.txt/ipp-udp.txt/' \
        "$OPENVPN_CONFIG_DIR/server/tcp.conf" > "$OPENVPN_CONFIG_DIR/server/udp.conf"
    
    cat > /usr/local/bin/openvpn-add-client << 'OVPNCLIENT'
#!/bin/bash
CLIENT_NAME="$1"

if [[ -z "$CLIENT_NAME" ]]; then
    echo "Uso: openvpn-add-client <nombre_cliente>"
    exit 1
fi

cd /etc/openvpn/easy-rsa || exit 1

./easyrsa --batch build-client-full "$CLIENT_NAME" nopass >> /var/log/nexusvpn/openvpn.log 2>&1

SERVER_IP=$(curl -s ifconfig.me)
TCP_PORT=$(grep '^port' /etc/openvpn/server/tcp.conf | awk '{print $2}')
UDP_PORT=$(grep '^port' /etc/openvpn/server/udp.conf | awk '{print $2}')

mkdir -p "/etc/openvpn/client-configs/$CLIENT_NAME"

cat > "/etc/openvpn/client-configs/$CLIENT_NAME/${CLIENT_NAME}-tcp.ovpn" << EOF
client
dev tun
proto tcp
remote ${SERVER_IP} ${TCP_PORT}
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
auth-user-pass

<ca>
$(cat /etc/openvpn/server/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/easy-rsa/pki/issued/${CLIENT_NAME}.crt)
</cert>
<key>
$(cat /etc/openvpn/easy-rsa/pki/private/${CLIENT_NAME}.key)
</key>
<tls-auth>
$(cat /etc/openvpn/server/ta.key)
</tls-auth>
EOF

cp "/etc/openvpn/client-configs/$CLIENT_NAME/${CLIENT_NAME}-tcp.ovpn" \
   "/etc/openvpn/client-configs/$CLIENT_NAME/${CLIENT_NAME}-udp.ovpn"
sed -i 's/proto tcp/proto udp/;s/remote [0-9.]* [0-9]*/remote '"$SERVER_IP $UDP_PORT"'/' \
   "/etc/openvpn/client-configs/$CLIENT_NAME/${CLIENT_NAME}-udp.ovpn"

echo "📱 TCP Config QR:"
qrencode -t ansiutf8 < "/etc/openvpn/client-configs/$CLIENT_NAME/${CLIENT_NAME}-tcp.ovpn"
echo ""
echo "📱 UDP Config QR:"
qrencode -t ansiutf8 < "/etc/openvpn/client-configs/$CLIENT_NAME/${CLIENT_NAME}-udp.ovpn"
echo ""
echo "✅ Cliente $CLIENT_NAME creado correctamente"
OVPNCLIENT
    chmod +x /usr/local/bin/openvpn-add-client
    
    systemctl enable openvpn@server/tcp
    systemctl enable openvpn@server/udp
    systemctl start openvpn@server/tcp
    systemctl start openvpn@server/udp
    
    ufw allow "${openvpn_tcp_port}/tcp" >> "$INSTALL_LOG" 2>&1
    ufw allow "${openvpn_udp_port}/udp" >> "$INSTALL_LOG" 2>&1
    
    log_info "OpenVPN configurado (TCP:$openvpn_tcp_port, UDP:$openvpn_udp_port)"
}

openvpn_add_client() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        read_input "Nombre del cliente" name
    fi
    
    /usr/local/bin/openvpn-add-client "$name"
}

openvpn_list_clients() {
    echo -e "\n${C}Clientes OpenVPN configurados:${NC}"
    ls -1 /etc/openvpn/client-configs/ 2>/dev/null | while read client; do
        echo "  $client"
    done
}

openvpn_revoke_client() {
    local name="$1"
    
    if [[ -z "$name" ]]; then
        read_input "Nombre del cliente a revocar" name
    fi
    
    cd /etc/openvpn/easy-rsa || return 1
    ./easyrsa --batch revoke "$name" >> "$INSTALL_LOG" 2>&1
    ./easyrsa gen-crl >> "$INSTALL_LOG" 2>&1
    cp pki/crl.pem /etc/openvpn/server/
    rm -rf "/etc/openvpn/client-configs/$name"
    ok "Certificado de $name revocado"
}

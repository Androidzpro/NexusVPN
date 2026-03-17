#!/bin/bash
# Módulo de WireGuard + AmneziaWG para NexusVPN Pro
# Funciones: instalación, configuración, gestión de clientes

WIREGUARD_CONFIG_DIR="/etc/wireguard"
WIREGUARD_LOG_DIR="/var/log/wireguard"

install_wireguard() {
    inf "Instalando WireGuard y AmneziaWG..."
    log_info "Instalando WireGuard"
    
    apt_install wireguard wireguard-tools linux-headers-$(uname -r)
    
    if confirm "¿Instalar también AmneziaWG (versión mejorada)?" "s"; then
        install_amneziawg
    fi
    
    local server_private_key=$(wg genkey)
    local server_public_key=$(echo "$server_private_key" | wg pubkey)
    
    mkdir -p "$WIREGUARD_CONFIG_DIR"
    echo "$server_private_key" > "$WIREGUARD_CONFIG_DIR/server_private.key"
    echo "$server_public_key" > "$WIREGUARD_CONFIG_DIR/server_public.key"
    chmod 600 "$WIREGUARD_CONFIG_DIR/server_private.key"
    
    configure_wireguard "$server_private_key" "$server_public_key"
    
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/99-wireguard.conf
    echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.d/99-wireguard.conf
    sysctl -p /etc/sysctl.d/99-wireguard.conf
    
    ok "WireGuard instalado correctamente"
}

install_amneziawg() {
    inf "Instalando AmneziaWG..."
    curl -fsSL https://pkg.amnezia.org/install.sh | bash >> "$INSTALL_LOG" 2>&1
    apt_install awg awg-tools
    
    if command -v awg &>/dev/null; then
        ok "AmneziaWG instalado correctamente"
        cfg_set "wireguard.amnezia_enabled" "true"
    else
        warn "Error instalando AmneziaWG"
        cfg_set "wireguard.amnezia_enabled" "false"
    fi
}

configure_wireguard() {
    local server_private_key="$1"
    local server_public_key="$2"
    local wg_port=$(cfg_get "ports.wireguard" "$DEFAULT_WIREGUARD_PORT")
    local server_ip=$(get_server_ip)
    local iface=$(ip route | grep default | awk '{print $5}' | head -1)
    
    cat > "$WIREGUARD_CONFIG_DIR/wg0.conf" << WGEOF
[Interface]
Address = 10.66.66.1/24, fd42:42:42::1/64
ListenPort = ${wg_port}
PrivateKey = ${server_private_key}
SaveConfig = false

PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o ${iface} -j MASQUERADE
PostUp = ip6tables -A FORWARD -i wg0 -j ACCEPT
PostUp = ip6tables -t nat -A POSTROUTING -o ${iface} -j MASQUERADE

PreDown = iptables -D FORWARD -i wg0 -j ACCEPT
PreDown = iptables -t nat -D POSTROUTING -o ${iface} -j MASQUERADE
PreDown = ip6tables -D FORWARD -i wg0 -j ACCEPT
PreDown = ip6tables -t nat -D POSTROUTING -o ${iface} -j MASQUERADE
WGEOF

    chmod 600 "$WIREGUARD_CONFIG_DIR/wg0.conf"
    
    cat > /usr/local/bin/wireguard-add-client << 'WGCLIENT'
#!/bin/bash
CLIENT_NAME="$1"
CLIENT_IP="${2:-10.66.66.2}"

if [[ -z "$CLIENT_NAME" ]]; then
    echo "Uso: wireguard-add-client <nombre_cliente> [IP]"
    exit 1
fi

CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
CLIENT_PRE_SHARED_KEY=$(wg genpsk)

SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
SERVER_PORT=$(grep ListenPort /etc/wireguard/wg0.conf | awk '{print $3}')
SERVER_IP=$(curl -s ifconfig.me)

cat >> /etc/wireguard/wg0.conf << EOF

[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
AllowedIPs = ${CLIENT_IP}/32
EOF

CLIENT_CONF="/etc/wireguard/clients/${CLIENT_NAME}.conf"
mkdir -p /etc/wireguard/clients

cat > "$CLIENT_CONF" << EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_IP}/24
DNS = 8.8.8.8, 1.1.1.1

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
Endpoint = ${SERVER_IP}:${SERVER_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

chmod 600 "$CLIENT_CONF"
qrencode -t ansiutf8 < "$CLIENT_CONF"
echo ""
echo "✅ Cliente $CLIENT_NAME creado: $CLIENT_CONF"
WGCLIENT
    chmod +x /usr/local/bin/wireguard-add-client
    
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    ufw allow "${wg_port}/udp" >> "$INSTALL_LOG" 2>&1
    
    log_info "WireGuard configurado en puerto $wg_port"
}

wireguard_add_client() {
    local name="$1"
    local ip="$2"
    
    if [[ -z "$name" ]]; then
        read_input "Nombre del cliente" name
    fi
    
    if [[ -z "$ip" ]]; then
        local last_ip=$(grep AllowedIPs /etc/wireguard/wg0.conf | tail -1 | grep -oE '10\.66\.66\.[0-9]+' | cut -d. -f4)
        local next_ip=$(( ${last_ip:-1} + 1 ))
        ip="10.66.66.$next_ip"
    fi
    
    /usr/local/bin/wireguard-add-client "$name" "$ip"
}

wireguard_list_clients() {
    echo -e "\n${C}Clientes WireGuard:${NC}"
    grep -E "^# Client:|^\[Peer\]|^PublicKey|^AllowedIPs" /etc/wireguard/wg0.conf | while read line; do
        case $line in
            "# Client:"*) echo -e "\n${Y}${line#\# Client: }${NC}" ;;
            "PublicKey ="*) echo "  PublicKey: ${line#PublicKey = }" ;;
            "AllowedIPs ="*) echo "  IP: ${line#AllowedIPs = }" ;;
        esac
    done
}

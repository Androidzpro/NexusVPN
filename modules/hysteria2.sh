#!/bin/bash
# Módulo de Hysteria2 para NexusVPN Pro
# Funciones: instalación, configuración, gestión

HYSTERIA_BIN="/usr/local/bin/hysteria"
HYSTERIA_CONFIG="/etc/hysteria/config.yaml"
HYSTERIA_LOG_DIR="/var/log/hysteria"

install_hysteria2() {
    inf "Instalando Hysteria2 con soporte de obfs múltiples..."
    log_info "Instalando Hysteria2"
    
    if [[ -x "$HYSTERIA_BIN" ]]; then
        warn "Hysteria2 ya está instalado"
        if ! confirm "¿Reinstalar?" "n"; then
            return 0
        fi
    fi
    
    if bash <(curl -fsSL https://get.hy2.sh/) >> "$INSTALL_LOG" 2>&1; then
        ok "Hysteria2 instalado mediante script oficial"
    else
        install_hysteria2_alternative
    fi
    
    local auth_pass=$(openssl rand -base64 20 | tr -d '=' | tr '+/' '-_')
    cfg_set "hysteria2.auth_pass" "\"${auth_pass}\""
    
    mkdir -p /etc/hysteria
    openssl req -x509 -newkey rsa:2048 -keyout /etc/hysteria/key.pem \
        -out /etc/hysteria/cert.pem -days 3650 -nodes \
        -subj "/C=US/O=NexusVPN/CN=nexusvpn.local" >> "$INSTALL_LOG" 2>&1
    
    configure_hysteria2 "$auth_pass"
}

install_hysteria2_alternative() {
    local arch=$(uname -m)
    local h_arch="amd64"
    
    case "$arch" in
        x86_64) h_arch="amd64" ;;
        aarch64) h_arch="arm64" ;;
        armv7l) h_arch="arm" ;;
        *) err "Arquitectura no soportada: $arch"; return 1 ;;
    esac
    
    local latest=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep '"tag_name"' | sed 's/.*"app\/v\([^"]*\)".*/\1/')
    latest="${latest:-2.4.5}"
    local url="https://github.com/apernet/hysteria/releases/download/app/v${latest}/hysteria-linux-${h_arch}"
    
    wget -q -O "$HYSTERIA_BIN" "$url" >> "$INSTALL_LOG" 2>&1
    chmod +x "$HYSTERIA_BIN"
    ok "Hysteria2 descargado correctamente"
}

configure_hysteria2() {
    local auth_pass="$1"
    local hysteria_port=$(cfg_get "ports.hysteria2" "$DEFAULT_HYSTERIA2_PORT")
    local obfs_type="salamander"
    
    if confirm "¿Usar obfs 'random' en lugar de 'salamander'?" "n"; then
        obfs_type="random"
    fi
    
    if confirm "¿Establecer contraseña personalizada?" "n"; then
        read_password "Nueva contraseña" custom_pass
        if [[ -n "$custom_pass" ]]; then
            auth_pass="$custom_pass"
            cfg_set "hysteria2.auth_pass" "\"${auth_pass}\""
        fi
    fi
    
    cat > "$HYSTERIA_CONFIG" << HYEOF
listen: :${hysteria_port}
tls:
  cert: /etc/hysteria/cert.pem
  key: /etc/hysteria/key.pem
obfs:
  type: ${obfs_type}
  ${obfs_type}:
    password: nexusvpn-obfs
auth:
  type: password
  password: ${auth_pass}
masquerade:
  type: proxy
  proxy:
    url: https://www.google.com
    rewriteHost: true
bandwidth:
  up: 1 gbps
  down: 1 gbps
HYEOF

    cat > /etc/systemd/system/hysteria.service << 'HYSVCEOF'
[Unit]
Description=Hysteria2 VPN Server
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/hysteria server --config /etc/hysteria/config.yaml
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
HYSVCEOF

    systemctl daemon-reload
    systemctl enable hysteria
    systemctl restart hysteria
    ufw allow "${hysteria_port}/udp" >> "$INSTALL_LOG" 2>&1
    
    log_info "Hysteria2 configurado en puerto $hysteria_port con obfs $obfs_type"
    ok "Hysteria2 configurado correctamente"
}

show_hysteria2_config() {
    local auth_pass=$(cfg_get "hysteria2.auth_pass")
    local port=$(cfg_get "ports.hysteria2")
    local ip=$(get_server_ip)
    
    echo -e "\n${Y}Link Hysteria2:${NC}"
    echo -e "hysteria2://${auth_pass}@${ip}:${port}/?insecure=1&obfs=salamander&obfs-password=nexusvpn-obfs#NexusVPN-HY2"
    
    echo -e "\n${Y}QR Code:${NC}"
    local link="hysteria2://${auth_pass}@${ip}:${port}/?insecure=1&obfs=salamander&obfs-password=nexusvpn-obfs#NexusVPN-HY2"
    qrencode -t ansiutf8 "$link"
}

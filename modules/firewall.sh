#!/bin/bash
# Módulo de Firewall para NexusVPN Pro
# Funciones: configuración UFW/iptables, gestión de reglas

configure_firewall() {
    inf "Configurando firewall avanzado..."
    log_info "Configurando firewall"
    
    if ! command -v ufw &>/dev/null; then
        apt_install ufw
    fi
    
    ufw --force disable >> "$INSTALL_LOG" 2>&1
    ufw --force reset >> "$INSTALL_LOG" 2>&1
    
    ufw default deny incoming >> "$INSTALL_LOG" 2>&1
    ufw default allow outgoing >> "$INSTALL_LOG" 2>&1
    
    local ssh_port=$(cfg_get "ports.ssh" "$DEFAULT_SSH_PORT")
    ufw allow "${ssh_port}/tcp" comment 'SSH' >> "$INSTALL_LOG" 2>&1
    
    ufw allow "$(cfg_get ports.xray_vless_tcp)/tcp" comment 'VLESS TCP' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_vmess_ws)/tcp" comment 'VMess WS' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_vmess_ws_alt)/tcp" comment 'VMess WS Alt' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_vmess_mkcp)/udp" comment 'VMess mKCP' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_trojan)/tcp" comment 'Trojan' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_shadowsocks)/tcp" comment 'Shadowsocks TCP' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_shadowsocks)/udp" comment 'Shadowsocks UDP' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_vless_grpc)/tcp" comment 'VLESS gRPC' >> "$INSTALL_LOG" 2>&1
    
    ufw allow "$(cfg_get ports.hysteria2)/udp" comment 'Hysteria2' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.wireguard)/udp" comment 'WireGuard' >> "$INSTALL_LOG" 2>&1
    ufw allow 500/udp comment 'IKEv2' >> "$INSTALL_LOG" 2>&1
    ufw allow 4500/udp comment 'IKEv2 NAT-T' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.openvpn_tcp)/tcp" comment 'OpenVPN TCP' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.openvpn_udp)/udp" comment 'OpenVPN UDP' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.slowdns)/udp" comment 'SlowDNS' >> "$INSTALL_LOG" 2>&1
    
    local badvpn_ports=$(cfg_get "badvpn.ports" "[7100,7200,7300]")
    badvpn_ports=$(echo "$badvpn_ports" | tr -d '[]' | tr ',' ' ')
    for port in $badvpn_ports; do
        port=$(echo "$port" | xargs)
        [[ -n "$port" ]] && ufw allow "${port}/udp" comment "BadVPN $port" >> "$INSTALL_LOG" 2>&1
    done
    
    local udp_range=$(cfg_get "udp_custom.range" "$DEFAULT_UDP_CUSTOM_RANGE")
    if [[ "$udp_range" != "none" ]]; then
        ufw allow "$udp_range/udp" comment 'UDP Custom' >> "$INSTALL_LOG" 2>&1
    fi
    
    if [[ "$(cfg_get features.web_panel false)" == "true" ]]; then
        ufw allow "$(cfg_get ports.webpanel)/tcp" comment 'Web Panel' >> "$INSTALL_LOG" 2>&1
    fi
    
    ufw limit "${ssh_port}/tcp" comment 'SSH rate limit' >> "$INSTALL_LOG" 2>&1
    ufw logging on >> "$INSTALL_LOG" 2>&1
    
    echo "y" | ufw enable >> "$INSTALL_LOG" 2>&1
    
    cat > /etc/ufw/before.rules.new << 'EOF'
*nat
:POSTROUTING ACCEPT [0:0]
-A POSTROUTING -o eth0 -j MASQUERADE
COMMIT
*mangle
:PREROUTING ACCEPT [0:0]
COMMIT
EOF
    
    cat /etc/ufw/before.rules >> /etc/ufw/before.rules.new
    mv /etc/ufw/before.rules.new /etc/ufw/before.rules
    ufw reload >> "$INSTALL_LOG" 2>&1
    
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/99-nexusvpn.conf
    echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.d/99-nexusvpn.conf
    sysctl -p /etc/sysctl.d/99-nexusvpn.conf
    
    log_info "Firewall configurado correctamente"
    ok "Firewall configurado con $(ufw status numbered | grep -c "\[") reglas"
}

firewall_add_rule() {
    local rule="$1"
    ufw allow "$rule" >> "$INSTALL_LOG" 2>&1 && ok "Regla añadida: $rule" || err "Error añadiendo regla"
}

firewall_delete_rule() {
    local rule="$1"
    ufw delete allow "$rule" >> "$INSTALL_LOG" 2>&1 && ok "Regla eliminada: $rule" || err "Error eliminando regla"
}

firewall_block_ip() {
    local ip="$1"
    ufw deny from "$ip" >> "$INSTALL_LOG" 2>&1 && ok "IP $ip bloqueada" || err "Error bloqueando IP"
}

firewall_unblock_ip() {
    local ip="$1"
    ufw delete deny from "$ip" >> "$INSTALL_LOG" 2>&1 && ok "IP $ip desbloqueada" || err "Error desbloqueando IP"
}

firewall_list_rules() {
    ufw status numbered 2>/dev/null
}

firewall_open_port_range() {
    local start="$1"
    local end="$2"
    local proto="${3:-tcp}"
    ufw allow "$start:$end/$proto" >> "$INSTALL_LOG" 2>&1 && ok "Rango $start-$end/$proto abierto" || err "Error abriendo rango"
}

firewall_status() {
    echo -e "\n${C}Estado del firewall:${NC}"
    ufw status verbose
}

firewall_reset() {
    if confirm "¿Resetear firewall a configuración por defecto?" "n"; then
        ufw --force reset >> "$INSTALL_LOG" 2>&1
        configure_firewall
        ok "Firewall reiniciado"
    fi
}

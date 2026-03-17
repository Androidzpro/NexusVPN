#!/bin/bash
# Módulo de BadVPN para NexusVPN Pro
# Funciones: instalación, configuración, gestión de puertos

install_badvpn() {
    inf "Instalando BadVPN UDP Gateway con puertos dinámicos..."
    log_info "Instalando BadVPN"
    
    if [[ -x /usr/local/bin/badvpn-udpgw ]]; then
        warn "BadVPN ya está instalado"
        if ! confirm "¿Reinstalar?" "n"; then
            return 0
        fi
    fi
    
    apt_install cmake make gcc g++ build-essential
    
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir" || return 1
    
    if ! git clone --depth 1 https://github.com/ambrop72/badvpn.git >> "$INSTALL_LOG" 2>&1; then
        warn "Error clonando repositorio, usando binario precompilado"
        install_badvpn_binary
        cd / && rm -rf "$tmp_dir"
        return 0
    fi
    
    cd badvpn
    mkdir build
    cd build
    
    cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >> "$INSTALL_LOG" 2>&1
    make >> "$INSTALL_LOG" 2>&1
    
    if [[ -f udpgw/badvpn-udpgw ]]; then
        cp udpgw/badvpn-udpgw /usr/local/bin/
        chmod +x /usr/local/bin/badvpn-udpgw
        ok "BadVPN compilado correctamente"
    else
        warn "Error en compilación, usando binario alternativo"
        install_badvpn_binary
    fi
    
    cd /
    rm -rf "$tmp_dir"
    
    configure_badvpn
}

install_badvpn_binary() {
    wget -q -O /usr/local/bin/badvpn-udpgw "https://github.com/ambrop72/badvpn/raw/master/badvpn-udpgw" >> "$INSTALL_LOG" 2>&1
    if [[ -f /usr/local/bin/badvpn-udpgw ]]; then
        chmod +x /usr/local/bin/badvpn-udpgw
        ok "BadVPN binario descargado"
    else
        wget -q -O /usr/local/bin/badvpn-udpgw "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64" >> "$INSTALL_LOG" 2>&1
        chmod +x /usr/local/bin/badvpn-udpgw
    fi
}

configure_badvpn() {
    local badvpn_ports=$(cfg_get "badvpn.ports" "[7100,7200,7300]")
    
    inf "Configurando BadVPN en puertos: ${badvpn_ports//[\[\]]/}"
    
    if confirm "¿Configurar puertos BadVPN personalizados?" "n"; then
        read_input "Puertos separados por comas (ej: 7100,7200,7300,7400)" custom_ports
        if [[ -n "$custom_ports" ]]; then
            ports_json="["
            IFS=',' read -ra port_array <<< "$custom_ports"
            for port in "${port_array[@]}"; do
                port=$(echo "$port" | xargs)
                ports_json+="$port,"
            done
            ports_json="${ports_json%,}]"
            badvpn_ports="$ports_json"
            cfg_set "badvpn.ports" "$badvpn_ports"
        fi
    fi
    
    local port_list=$(echo "$badvpn_ports" | tr -d '[]' | tr ',' ' ')
    
    for port in $port_list; do
        port=$(echo "$port" | xargs)
        if [[ -n "$port" ]]; then
            inf "Configurando BadVPN en puerto $port..."
            
            cat > "/etc/systemd/system/badvpn-${port}.service" << EOF
[Unit]
Description=BadVPN UDP Gateway port ${port}
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 0.0.0.0:${port} --max-clients 512 --max-connections-for-client 10
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

            systemctl daemon-reload
            systemctl enable "badvpn-${port}"
            systemctl start "badvpn-${port}"
            ufw allow "${port}/udp" >> "$INSTALL_LOG" 2>&1
            log_info "BadVPN activado en puerto $port"
        fi
    done
    
    ok "BadVPN configurado en puertos: ${badvpn_ports//[\[\]]/}"
}

add_badvpn_port() {
    local port="$1"
    
    if [[ -z "$port" ]]; then
        read_input "Puerto BadVPN a agregar" port
    fi
    
    cat > "/etc/systemd/system/badvpn-${port}.service" << EOF
[Unit]
Description=BadVPN UDP Gateway port ${port}
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 0.0.0.0:${port} --max-clients 512 --max-connections-for-client 10
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "badvpn-${port}"
    systemctl start "badvpn-${port}"
    ufw allow "${port}/udp" >> "$INSTALL_LOG" 2>&1
    
    ok "BadVPN puerto $port agregado"
}

remove_badvpn_port() {
    local port="$1"
    
    if [[ -z "$port" ]]; then
        read_input "Puerto BadVPN a eliminar" port
    fi
    
    systemctl stop "badvpn-${port}" 2>/dev/null
    systemctl disable "badvpn-${port}" 2>/dev/null
    rm -f "/etc/systemd/system/badvpn-${port}.service"
    systemctl daemon-reload
    ufw delete allow "${port}/udp" 2>/dev/null
    
    ok "BadVPN puerto $port eliminado"
}

list_badvpn_ports() {
    echo -e "\n${C}Puertos BadVPN activos:${NC}"
    systemctl list-units --all | grep badvpn | awk '{print "  " $1}' | sed 's/badvpn-//;s/.service//'
}

restart_badvpn() {
    for port in $(systemctl list-units --all | grep badvpn | awk '{print $1}'); do
        systemctl restart "$port" 2>/dev/null
    done
    ok "BadVPN reiniciado"
}

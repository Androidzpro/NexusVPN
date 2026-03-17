#!/bin/bash
# Módulo de UDP Custom para NexusVPN Pro
# Funciones: instalación, configuración, gestión de puertos

install_udp_custom() {
    inf "Instalando UDP Custom con rango completo 1-65535..."
    log_info "Instalando UDP Custom"
    
    apt_install socat netcat-openbsd python3 python3-pip
    
    local udp_range
    read_input "Rango UDP (ej: 10000-65000 o '1-65535' para todos)" udp_range "$DEFAULT_UDP_CUSTOM_RANGE"
    
    cat > /usr/local/bin/udp-custom << 'EOF'
#!/bin/bash
LOCAL_PORT="$1"
DEST_PORT="$2"
PROTOCOL="${3:-udp}"

if [[ -z "$LOCAL_PORT" || -z "$DEST_PORT" ]]; then
    echo "Uso: udp-custom <puerto_local> <puerto_destino> [protocolo]"
    exit 1
fi

echo "Iniciando UDP Custom: $LOCAL_PORT -> 127.0.0.1:$DEST_PORT ($PROTOCOL)"

while true; do
    socat ${PROTOCOL}4-LISTEN:${LOCAL_PORT},reuseaddr,fork ${PROTOCOL}4:127.0.0.1:${DEST_PORT}
    sleep 1
done
EOF
    chmod +x /usr/local/bin/udp-custom
    
    cat > /etc/systemd/system/udp-custom@.service << 'EOF'
[Unit]
Description=UDP Custom redirection on port %i
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/udp-custom %i 7300 udp
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
EOF

    local start_port end_port
    if [[ "$udp_range" == *-* ]]; then
        start_port=$(echo "$udp_range" | cut -d- -f1)
        end_port=$(echo "$udp_range" | cut -d- -f2)
    else
        start_port="$udp_range"
        end_port="$udp_range"
    fi
    
    inf "Configurando puertos UDP del $start_port al $end_port..."
    
    cat > /usr/local/bin/udp-custom-activate << ACTIVATE
#!/bin/bash
for port in \$(seq $start_port $end_port); do
    systemctl enable udp-custom@\${port} 2>/dev/null
    systemctl start udp-custom@\${port} 2>/dev/null
    echo -n "."
done
echo " ¡Listo!"
ACTIVATE
    chmod +x /usr/local/bin/udp-custom-activate
    
    if confirm "¿Activar todos los puertos UDP ahora? (puede tardar)" "n"; then
        /usr/local/bin/udp-custom-activate
        ok "Puertos UDP activados"
    else
        inf "Puedes activarlos después con: udp-custom-activate"
    fi
    
    cfg_set "udp_custom.range" "\"$udp_range\""
    cfg_set "udp_custom.enabled" "true"
    
    ufw allow "$start_port:$end_port/udp" >> "$INSTALL_LOG" 2>&1
    
    log_info "UDP Custom configurado con rango: $udp_range"
    ok "UDP Custom instalado correctamente (rango $udp_range)"
}

add_udp_port() {
    local port="$1"
    local dest="${2:-7300}"
    
    if [[ -z "$port" ]]; then
        read_input "Puerto a abrir" port
    fi
    
    if [[ -z "$dest" ]]; then
        read_input "Puerto destino (local)" dest "7300"
    fi
    
    cat > "/etc/systemd/system/udp-custom@${port}.service" << EOF
[Unit]
Description=UDP Custom on port $port
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/udp-custom $port $dest udp
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable "udp-custom@${port}"
    systemctl start "udp-custom@${port}"
    ufw allow "${port}/udp"
    
    ok "Puerto UDP $port abierto (-> $dest)"
}

remove_udp_port() {
    local port="$1"
    
    if [[ -z "$port" ]]; then
        read_input "Puerto a cerrar" port
    fi
    
    systemctl stop "udp-custom@${port}" 2>/dev/null
    systemctl disable "udp-custom@${port}" 2>/dev/null
    rm -f "/etc/systemd/system/udp-custom@${port}.service"
    systemctl daemon-reload
    ufw delete allow "${port}/udp" 2>/dev/null
    
    ok "Puerto UDP $port cerrado"
}

list_udp_ports() {
    echo -e "\n${C}Puertos UDP Custom activos:${NC}"
    systemctl list-units --all | grep udp-custom | awk '{print "  " $1}' | sed 's/udp-custom@//;s/.service//'
}

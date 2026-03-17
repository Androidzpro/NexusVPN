#!/bin/bash
# Módulo de SlowDNS para NexusVPN Pro
# Funciones: instalación, configuración, gestión

SLOWDNS_DIR="${INSTALL_DIR}/slowdns"
SLOWDNS_PORT=$(cfg_get "ports.slowdns" "$DEFAULT_SLOWDNS_PORT")

install_slowdns() {
    inf "Instalando SlowDNS (dnstt)..."
    log_info "Instalando SlowDNS"
    
    local arch=$(uname -m)
    local darch="amd64"
    
    case "$arch" in
        x86_64) darch="amd64" ;;
        aarch64) darch="arm64" ;;
        armv7l) darch="arm" ;;
        *)
            warn "Arquitectura no soportada para SlowDNS: $arch"
            if ! confirm "¿Continuar sin SlowDNS?" "s"; then
                return 0
            fi
            ;;
    esac
    
    if [[ ! -x /usr/local/bin/dnstt-server ]]; then
        wget -q -O /tmp/dnstt-server "https://www.bamsoftware.com/software/dnstt/dnstt-server-linux-${darch}" >> "$INSTALL_LOG" 2>&1 || {
            warn "Error descargando dnstt, usando método alternativo"
            install_slowdns_alternative
            return
        }
        chmod +x /tmp/dnstt-server
        cp /tmp/dnstt-server /usr/local/bin/dnstt-server
        rm /tmp/dnstt-server
    fi
    
    mkdir -p "$SLOWDNS_DIR"
    if [[ ! -f "$SLOWDNS_DIR/server.key" ]]; then
        /usr/local/bin/dnstt-server -gen-key \
            -privkey-file "$SLOWDNS_DIR/server.key" \
            -pubkey-file "$SLOWDNS_DIR/server.pub" >> "$INSTALL_LOG" 2>&1
    fi
    
    configure_slowdns
}

install_slowdns_alternative() {
    inf "Usando método alternativo para SlowDNS..."
    
    cat > /usr/local/bin/slowdns-proxy << 'PYSLOW'
#!/usr/bin/env python3
import socket
import threading
import sys
import select

def handle_client(client_socket, remote_host, remote_port):
    try:
        remote_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
        remote_socket.connect((remote_host, remote_port))
        sockets = [client_socket, remote_socket]
        
        while True:
            r, w, e = select.select(sockets, [], [])
            for sock in r:
                if sock == client_socket:
                    data = client_socket.recv(4096)
                    if not data:
                        return
                    remote_socket.send(data)
                elif sock == remote_socket:
                    data = remote_socket.recv(4096)
                    if not data:
                        return
                    client_socket.send(data)
    except:
        pass
    finally:
        client_socket.close()
        remote_socket.close()

def main():
    if len(sys.argv) != 4:
        print(f"Uso: {sys.argv[0]} <listen_port> <remote_host> <remote_port>")
        sys.exit(1)
    
    listen_port = int(sys.argv[1])
    remote_host = sys.argv[2]
    remote_port = int(sys.argv[3])
    
    server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
    server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    server.bind(('0.0.0.0', listen_port))
    server.listen(100)
    
    print(f"SlowDNS proxy listening on port {listen_port}")
    
    while True:
        client, addr = server.accept()
        threading.Thread(target=handle_client, args=(client, remote_host, remote_port)).start()

if __name__ == "__main__":
    main()
PYSLOW
    chmod +x /usr/local/bin/slowdns-proxy
    
    cat > /etc/systemd/system/slowdns-proxy.service << 'SDEOF'
[Unit]
Description=SlowDNS Proxy
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/slowdns-proxy 5300 127.0.0.1 22
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SDEOF

    systemctl daemon-reload
    systemctl enable slowdns-proxy
    systemctl start slowdns-proxy
    ok "SlowDNS alternativo instalado"
    cfg_set "slowdns.method" "\"alternative\""
}

configure_slowdns() {
    local slowdns_port=$(cfg_get "ports.slowdns" "$DEFAULT_SLOWDNS_PORT")
    local server_ip=$(get_server_ip)
    local ns_domain
    
    read_input "Subdominio NS para SlowDNS (ej: ns.tudominio.com)" ns_domain
    
    if [[ -n "$ns_domain" ]]; then
        cfg_set "slowdns.domain" "\"$ns_domain\""
        cat > /etc/systemd/system/slowdns.service << SDNS
[Unit]
Description=SlowDNS Server (dnstt)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/dnstt-server -udp :${slowdns_port} -privkey-file ${SLOWDNS_DIR}/server.key ${ns_domain} 127.0.0.1:22
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
SDNS
    else
        cat > /etc/systemd/system/slowdns.service << SDNS
[Unit]
Description=SlowDNS Server (dnstt)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/dnstt-server -udp :${slowdns_port} -privkey-file ${SLOWDNS_DIR}/server.key ${server_ip} 127.0.0.1:22
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
SDNS
    fi
    
    systemctl daemon-reload
    systemctl enable slowdns
    systemctl start slowdns
    ufw allow "${slowdns_port}/udp" >> "$INSTALL_LOG" 2>&1
    
    if [[ -f "$SLOWDNS_DIR/server.pub" ]]; then
        local pubkey=$(cat "$SLOWDNS_DIR/server.pub")
        box_message "Clave pública SlowDNS: $pubkey"
    fi
    
    cfg_set "slowdns.method" "\"official\""
    cfg_set "slowdns.enabled" "true"
    log_info "SlowDNS configurado en puerto $slowdns_port"
    ok "SlowDNS instalado correctamente"
}

show_slowdns_key() {
    if [[ -f "$SLOWDNS_DIR/server.pub" ]]; then
        echo -e "\n${Y}Clave pública SlowDNS:${NC}"
        cat "$SLOWDNS_DIR/server.pub"
    else
        warn "Clave pública no encontrada"
    fi
}

test_slowdns() {
    local port=$(cfg_get "ports.slowdns")
    local ip=$(get_server_ip)
    echo -e "\n${Y}Prueba de conexión SlowDNS:${NC}"
    echo -e "nslookup -port=$port google.com $ip"
}

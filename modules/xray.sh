#!/bin/bash
# Módulo de Xray/V2Ray para NexusVPN Pro
# Funciones: instalación, configuración, gestión de usuarios

XRAY_BIN="/usr/local/bin/xray"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
XRAY_LOG_DIR="/var/log/xray"
XRAY_ACCESS_LOG="${XRAY_LOG_DIR}/access.log"
XRAY_ERROR_LOG="${XRAY_LOG_DIR}/error.log"

install_xray() {
    inf "Instalando Xray-Core..."
    log_info "Instalando Xray"
    
    if [[ -x "$XRAY_BIN" ]]; then
        local current_version
        current_version=$("$XRAY_BIN" version 2>/dev/null | head -1 | awk '{print $2}' || echo "desconocida")
        warn "Xray ya instalado (versión: $current_version)"
        if ! confirm "¿Reinstalar?" "n"; then
            return 0
        fi
    fi
    
    if bash <(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh) >> "$INSTALL_LOG" 2>&1; then
        ok "Xray instalado mediante script oficial"
    else
        install_xray_alternative
    fi
    
    if [[ -x "$XRAY_BIN" ]]; then
        local new_version
        new_version=$("$XRAY_BIN" version 2>/dev/null | head -1 | awk '{print $2}' || echo "desconocida")
        ok "Xray instalado (versión: $new_version)"
    else
        err "Error instalando Xray"
        return 1
    fi
    
    configure_xray
}

install_xray_alternative() {
    local arch=$(uname -m)
    local xray_arch="64"
    
    case "$arch" in
        x86_64) xray_arch="64" ;;
        aarch64) xray_arch="arm64-v8a" ;;
        armv7l) xray_arch="arm32-v7a" ;;
        *) err "Arquitectura no soportada: $arch"; return 1 ;;
    esac
    
    local latest_ver=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
    latest_ver="${latest_ver:-24.9.30}"
    local url="https://github.com/XTLS/Xray-core/releases/download/v${latest_ver}/Xray-linux-${xray_arch}.zip"
    local tmp_dir="/tmp/xray_install_$$"
    
    mkdir -p "$tmp_dir"
    cd "$tmp_dir" || return 1
    
    wget -q -O xray.zip "$url" >> "$INSTALL_LOG" 2>&1 || { err "Error descargando Xray"; cd /; rm -rf "$tmp_dir"; return 1; }
    unzip -q xray.zip -d xray_files/
    cp xray_files/xray "$XRAY_BIN"
    chmod +x "$XRAY_BIN"
    mkdir -p /usr/local/share/xray
    cp xray_files/geoip.dat /usr/local/share/xray/ 2>/dev/null || true
    cp xray_files/geosite.dat /usr/local/share/xray/ 2>/dev/null || true
    
    cd /
    rm -rf "$tmp_dir"
    ok "Xray instalado manualmente"
}

configure_xray() {
    inf "Configurando Xray..."
    
    local uuid=$(gen_uuid)
    local ss_pass=$(openssl rand -base64 16 | tr -d '=' | tr '+/' '-_')
    local srv_ip=$(get_server_ip)
    
    cfg_set "xray.uuid" "\"${uuid}\""
    cfg_set "xray.ss_password" "\"${ss_pass}\""
    
    mkdir -p /usr/local/etc/xray
    
    cat > "$XRAY_CONFIG" << 'XRAYEOF'
{
    "log": {
        "loglevel": "warning",
        "access": "/var/log/xray/access.log",
        "error": "/var/log/xray/error.log"
    },
    "stats": {},
    "api": {
        "tag": "api",
        "services": ["StatsService"]
    },
    "policy": {
        "levels": { "0": { "statsUserUplink": true, "statsUserDownlink": true } },
        "system": { "statsInboundUplink": true, "statsInboundDownlink": true }
    },
    "inbounds": [
        {
            "tag": "vless-tcp",
            "port": PORT_VLESS_TCP,
            "protocol": "vless",
            "settings": {
                "clients": [{ "id": "UUID_PLACEHOLDER", "level": 0, "email": "default@nexusvpn" }],
                "decryption": "none",
                "fallbacks": [
                    { "dest": 8443, "xver": 1 },
                    { "path": "/nexus", "dest": "@vmess-ws.sock", "xver": 1 }
                ]
            },
            "streamSettings": { "network": "tcp", "security": "none" }
        },
        {
            "tag": "vmess-ws",
            "listen": "@vmess-ws.sock",
            "protocol": "vmess",
            "settings": {
                "clients": [{ "id": "UUID_PLACEHOLDER", "alterId": 0, "level": 0, "email": "default@nexusvpn" }]
            },
            "streamSettings": { "network": "ws", "wsSettings": { "path": "/nexus" } }
        },
        {
            "tag": "vmess-ws-80",
            "port": PORT_VMESS_WS,
            "protocol": "vmess",
            "settings": {
                "clients": [{ "id": "UUID_PLACEHOLDER", "alterId": 0, "level": 0, "email": "ws80@nexusvpn" }]
            },
            "streamSettings": { "network": "ws", "wsSettings": { "path": "/nexus" } }
        },
        {
            "tag": "vmess-ws-8080",
            "port": PORT_VMESS_WS_ALT,
            "protocol": "vmess",
            "settings": {
                "clients": [{ "id": "UUID_PLACEHOLDER", "alterId": 0, "level": 0, "email": "ws8080@nexusvpn" }]
            },
            "streamSettings": { "network": "ws", "wsSettings": { "path": "/nexus" } }
        },
        {
            "tag": "vmess-mkcp",
            "port": PORT_VMESS_MKCP,
            "protocol": "vmess",
            "settings": {
                "clients": [{ "id": "UUID_PLACEHOLDER", "alterId": 0, "level": 0, "email": "mkcp@nexusvpn" }]
            },
            "streamSettings": {
                "network": "kcp",
                "kcpSettings": {
                    "mtu": 1350, "tti": 50, "uplinkCapacity": 100, "downlinkCapacity": 100,
                    "congestion": false, "readBufferSize": 2, "writeBufferSize": 2,
                    "header": { "type": "none" }, "seed": "nexusvpn"
                }
            }
        },
        {
            "tag": "trojan-tcp",
            "port": PORT_TROJAN,
            "protocol": "trojan",
            "settings": {
                "clients": [{ "password": "UUID_PLACEHOLDER", "level": 0, "email": "trojan@nexusvpn" }],
                "fallbacks": [{ "dest": 80 }]
            },
            "streamSettings": { "network": "tcp", "security": "none" }
        },
        {
            "tag": "shadowsocks",
            "port": PORT_SHADOWSOCKS,
            "protocol": "shadowsocks",
            "settings": {
                "method": "chacha20-ietf-poly1305",
                "password": "SS_PASSWORD",
                "network": "tcp,udp",
                "clients": []
            }
        },
        {
            "tag": "vless-grpc",
            "port": PORT_VLESS_GRPC,
            "protocol": "vless",
            "settings": {
                "clients": [{ "id": "UUID_PLACEHOLDER", "level": 0, "email": "grpc@nexusvpn" }],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "grpc",
                "grpcSettings": { "serviceName": "nexus-grpc" }
            }
        },
        {
            "tag": "api-in",
            "listen": "127.0.0.1",
            "port": 62789,
            "protocol": "dokodemo-door",
            "settings": { "address": "127.0.0.1" }
        }
    ],
    "outbounds": [
        { "tag": "direct", "protocol": "freedom" },
        { "tag": "blocked", "protocol": "blackhole" }
    ],
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            { "type": "field", "inboundTag": ["api"], "outboundTag": "api" },
            { "type": "field", "ip": ["geoip:private"], "outboundTag": "blocked" }
        ]
    }
}
XRAYEOF

    sed -i "s/UUID_PLACEHOLDER/${uuid}/g" "$XRAY_CONFIG"
    sed -i "s/SS_PASSWORD/${ss_pass}/g" "$XRAY_CONFIG"
    sed -i "s/PORT_VLESS_TCP/$(cfg_get ports.xray_vless_tcp)/g" "$XRAY_CONFIG"
    sed -i "s/PORT_VMESS_WS/$(cfg_get ports.xray_vmess_ws)/g" "$XRAY_CONFIG"
    sed -i "s/PORT_VMESS_WS_ALT/$(cfg_get ports.xray_vmess_ws_alt)/g" "$XRAY_CONFIG"
    sed -i "s/PORT_VMESS_MKCP/$(cfg_get ports.xray_vmess_mkcp)/g" "$XRAY_CONFIG"
    sed -i "s/PORT_TROJAN/$(cfg_get ports.xray_trojan)/g" "$XRAY_CONFIG"
    sed -i "s/PORT_SHADOWSOCKS/$(cfg_get ports.xray_shadowsocks)/g" "$XRAY_CONFIG"
    sed -i "s/PORT_VLESS_GRPC/$(cfg_get ports.xray_vless_grpc)/g" "$XRAY_CONFIG"
    
    chmod 600 "$XRAY_CONFIG"
    
    cat > /etc/systemd/system/xray.service << 'SVCEOF'
[Unit]
Description=Xray Service
Documentation=https://github.com/xtls
After=network.target nss-lookup.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartPreventExitStatus=23
LimitNPROC=10000
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
SVCEOF

    systemctl daemon-reload
    systemctl enable xray
    systemctl restart xray
    
    log_info "Xray configurado con UUID: ${uuid:0:8}..."
    inf "Xray configurado correctamente"
}

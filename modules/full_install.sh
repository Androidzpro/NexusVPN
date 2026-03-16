#!/bin/bash
# ============================================================
#   MÓDULO: Instalación Completa
#   Instala todo en un solo script sin necesidad de GitHub
# ============================================================

set -e

# ─── Variables globales ────────────────────────────────────
PANEL_DIR="/etc/vpn-panel"
LOG_FILE="/var/log/nexusvpn-install.log"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
HYSTERIA_CONFIG="/etc/hysteria/config.yaml"
SLOWDNS_DIR="/etc/slowdns"
UDP_CONF="/etc/vpn-panel/udp-ports.conf"
KEYS_DB="/etc/vpn-panel/keys.db"
USERS_DB="/etc/vpn-panel/users.db"
MENU_BIN="/usr/local/bin/vpn-panel"
MYIP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org)

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
B='\033[0;34m'; C='\033[0;36m'; W='\033[1;37m'; NC='\033[0m'

log() { echo -e "$1" | tee -a "$LOG_FILE"; }
ok()  { log "${G}  ✅ $1${NC}"; }
err() { log "${R}  ❌ $1${NC}"; }
inf() { log "${Y}  ➜  $1${NC}"; }
step(){ log "\n${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"; log "${W}  [$1] $2${NC}"; }

# ─── Preparar directorios ──────────────────────────────────
mkdir -p "$PANEL_DIR" /var/log
touch "$LOG_FILE" "$KEYS_DB" "$USERS_DB"

# ═══════════════════════════════════════════════════════════
# PASO 1: DEPENDENCIAS
# ═══════════════════════════════════════════════════════════
step "1/8" "Instalando dependencias del sistema"

export DEBIAN_FRONTEND=noninteractive
apt-get update -qq 2>&1 | tail -1
apt-get install -y -qq \
    curl wget jq unzip socat git \
    build-essential golang-go \
    net-tools ufw iptables \
    uuid-runtime openssl \
    python3 python3-pip \
    netcat-openbsd lsof \
    cron bc sed gawk \
    2>&1 | tail -5

ok "Dependencias instaladas"

# ═══════════════════════════════════════════════════════════
# PASO 2: XRAY (V2Ray moderno)
# ═══════════════════════════════════════════════════════════
step "2/8" "Instalando Xray (V2Ray)"

# Instalar Xray
bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install 2>&1 | tail -5

# Configuración multi-protocolo
cat > "$XRAY_CONFIG" << 'XRAYEOF'
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray-access.log",
    "error": "/var/log/xray-error.log"
  },
  "api": {
    "tag": "api",
    "services": ["HandlerService", "StatsService"]
  },
  "stats": {},
  "policy": {
    "levels": { "0": { "statsUserUplink": true, "statsUserDownlink": true } },
    "system": { "statsInboundUplink": true, "statsInboundDownlink": true }
  },
  "inbounds": [
    {
      "tag": "vless-tcp",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none",
        "tcpSettings": {
          "header": { "type": "none" }
        }
      },
      "sniffing": { "enabled": true, "destOverride": ["http", "tls"] }
    },
    {
      "tag": "vmess-ws",
      "port": 8080,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/vpnpanel" }
      }
    },
    {
      "tag": "vmess-mkcp",
      "port": 1194,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "kcp",
        "kcpSettings": {
          "mtu": 1350, "tti": 50,
          "uplinkCapacity": 100,
          "downlinkCapacity": 100,
          "congestion": false,
          "readBufferSize": 2,
          "writeBufferSize": 2,
          "header": { "type": "none" },
          "seed": "vpnpanel2024"
        }
      }
    },
    {
      "tag": "trojan-tcp",
      "port": 8443,
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    },
    {
      "tag": "api-inbound",
      "port": 62789,
      "protocol": "dokodemo-door",
      "settings": { "address": "127.0.0.1" },
      "tag": "api"
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "blocked" }
  ],
  "routing": {
    "rules": [
      { "type": "field", "inboundTag": ["api"], "outboundTag": "api" },
      { "type": "field", "protocol": ["bittorrent"], "outboundTag": "blocked" }
    ]
  }
}
XRAYEOF

systemctl restart xray && systemctl enable xray
ok "Xray instalado → Puertos: 443(VLESS-TCP) 8080(VMess-WS) 1194(VMess-mKCP) 8443(Trojan)"

# ═══════════════════════════════════════════════════════════
# PASO 3: HYSTERIA 2
# ═══════════════════════════════════════════════════════════
step "3/8" "Instalando Hysteria 2 (UDP ultra-rápido)"

# Instalar Hysteria2
bash -c "$(curl -fsSL https://get.hy2.sh/)" 2>&1 | tail -5 || {
    # Fallback manual
    ARCH=$(uname -m)
    [[ "$ARCH" == "x86_64" ]] && HARCH="amd64" || HARCH="arm64"
    HY2_VER=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | jq -r .tag_name)
    wget -qO /usr/local/bin/hysteria \
        "https://github.com/apernet/hysteria/releases/download/${HY2_VER}/hysteria-linux-${HARCH}"
    chmod +x /usr/local/bin/hysteria
}

mkdir -p /etc/hysteria

# Generar certificado self-signed para Hysteria
openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
    -keyout /etc/hysteria/server.key \
    -out /etc/hysteria/server.crt \
    -subj "/CN=$MYIP" \
    -days 3650 2>/dev/null
chmod 600 /etc/hysteria/server.key

# Contraseña obfuscación
HY2_OBFS_PASS=$(openssl rand -hex 16)
echo "$HY2_OBFS_PASS" > /etc/hysteria/obfs.key

cat > "$HYSTERIA_CONFIG" << HYEOF
listen: :36712

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

obfs:
  type: salamander
  salamander:
    password: "${HY2_OBFS_PASS}"

quic:
  initStreamReceiveWindow: 26843545
  maxStreamReceiveWindow: 26843545
  initConnReceiveWindow: 67108864
  maxConnReceiveWindow: 67108864

bandwidth:
  up: 1 gbps
  down: 1 gbps

auth:
  type: userpass
  userpass: {}

masquerade:
  type: proxy
  proxy:
    url: https://news.ycombinator.com/
    rewriteHost: true

speedTest: true
HYEOF

# Servicio systemd Hysteria
cat > /etc/systemd/system/hysteria-server.service << 'EOF'
[Unit]
Description=Hysteria2 Server
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=/etc/hysteria
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable hysteria-server
systemctl start hysteria-server 2>/dev/null || true
ok "Hysteria2 instalado → Puerto UDP: 36712"

# ═══════════════════════════════════════════════════════════
# PASO 4: SLOWDNS (dnstt)
# ═══════════════════════════════════════════════════════════
step "4/8" "Instalando SlowDNS (dnstt-server)"

mkdir -p "$SLOWDNS_DIR"

# Compilar dnstt si no existe binario pre-compilado
if ! command -v dnstt-server &>/dev/null; then
    # Intentar descargar binario pre-compilado
    ARCH=$(uname -m)
    [[ "$ARCH" == "x86_64" ]] && DARCH="amd64" || DARCH="arm64"
    
    wget -qO "$SLOWDNS_DIR/dnstt-server" \
        "https://github.com/lemon4ex/dnstt-compiled/releases/latest/download/dnstt-server-linux-${DARCH}" 2>/dev/null \
    || {
        # Compilar desde fuente
        inf "Compilando dnstt desde fuente (puede tardar ~2 min)..."
        cd /tmp
        rm -rf dnstt
        git clone --depth=1 https://www.bamsoftware.com/git/dnstt.git 2>&1 | tail -2
        cd dnstt/server
        go build -o dnstt-server . 2>&1 | tail -3
        mv dnstt-server "$SLOWDNS_DIR/"
    }
    
    chmod +x "$SLOWDNS_DIR/dnstt-server"
    ln -sf "$SLOWDNS_DIR/dnstt-server" /usr/local/bin/dnstt-server
fi

# Generar claves del servidor
cd "$SLOWDNS_DIR"
if [[ ! -f server.key ]]; then
    dnstt-server -gen-key -privkey server.key -pubkey server.pub 2>/dev/null \
    || "$SLOWDNS_DIR/dnstt-server" -gen-key -privkey server.key -pubkey server.pub
fi
SLOWDNS_PUBKEY=$(cat "$SLOWDNS_DIR/server.pub")
echo "$SLOWDNS_PUBKEY" > "$PANEL_DIR/slowdns_pubkey.txt"

# Servicio SlowDNS
cat > /etc/systemd/system/slowdns.service << EOF
[Unit]
Description=SlowDNS (dnstt) Server
After=network.target

[Service]
Type=simple
ExecStart=$SLOWDNS_DIR/dnstt-server -udp :5300 -privkey $SLOWDNS_DIR/server.key 127.0.0.1:22
Restart=always
RestartSec=3
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable slowdns
systemctl start slowdns 2>/dev/null || true
ok "SlowDNS instalado → Puerto UDP: 5300"
inf "Clave pública SlowDNS: $SLOWDNS_PUBKEY"

# ═══════════════════════════════════════════════════════════
# PASO 5: UDP CUSTOM (socat multi-puerto)
# ═══════════════════════════════════════════════════════════
step "5/8" "Configurando UDP Custom (multi-puerto)"

mkdir -p /etc/udp-custom

# Crear script manager de puertos UDP
cat > /usr/local/bin/udp-custom << 'UDPEOF'
#!/bin/bash
# UDP Custom Port Manager

UDP_CONF="/etc/vpn-panel/udp-ports.conf"
[[ ! -f "$UDP_CONF" ]] && touch "$UDP_CONF"

add_port() {
    local port=$1 dest=${2:-"8.8.8.8:53"}
    cat > "/etc/systemd/system/udp-proxy-${port}.service" << EOF
[Unit]
Description=UDP Proxy port ${port}
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/socat -T120 UDP4-LISTEN:${port},fork,reuseaddr UDP4:${dest}
Restart=always
RestartSec=3
User=nobody
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload
    systemctl enable "udp-proxy-${port}"
    systemctl start "udp-proxy-${port}"
    echo "${port}:${dest}" >> "$UDP_CONF"
    echo "✅ Puerto UDP $port → $dest activado"
}

del_port() {
    local port=$1
    systemctl stop "udp-proxy-${port}" 2>/dev/null
    systemctl disable "udp-proxy-${port}" 2>/dev/null
    rm -f "/etc/systemd/system/udp-proxy-${port}.service"
    sed -i "/^${port}:/d" "$UDP_CONF"
    echo "🗑️ Puerto UDP $port eliminado"
}

list_ports() {
    echo "Puertos UDP activos:"
    while IFS=: read -r port dest rest; do
        status=$(systemctl is-active "udp-proxy-${port}" 2>/dev/null)
        echo "  Puerto $port → $port:$rest  [$status]"
    done < "$UDP_CONF"
}

case $1 in
    add)  add_port "$2" "$3" ;;
    del)  del_port "$2" ;;
    list) list_ports ;;
    *)    echo "Uso: udp-custom [add PORT DEST|del PORT|list]" ;;
esac
UDPEOF
chmod +x /usr/local/bin/udp-custom

# Puertos UDP por defecto (para bypass DNS)
for port in 53 5353 5300; do
    udp-custom add $port "8.8.8.8:53" 2>/dev/null || true
done

echo "53:8.8.8.8:53" > "$UDP_CONF"
echo "5353:1.1.1.1:53" >> "$UDP_CONF"
echo "5300:8.8.8.8:53" >> "$UDP_CONF"

ok "UDP Custom configurado → Puertos: 53, 5353, 5300"

# ═══════════════════════════════════════════════════════════
# PASO 6: BADVPN (UDP-GW para SSH tunnel)
# ═══════════════════════════════════════════════════════════
step "6/8" "Instalando BadVPN UDP Gateway"

# Intentar compilar BadVPN
BADVPN_INSTALLED=false

# Opción 1: Binario pre-compilado
if wget -qO /usr/local/bin/badvpn-udpgw \
    "https://github.com/ambrop72/badvpn/releases/latest/download/badvpn-udpgw-linux-x86_64" 2>/dev/null; then
    chmod +x /usr/local/bin/badvpn-udpgw
    BADVPN_INSTALLED=true
fi

# Opción 2: Compilar desde fuente
if [[ "$BADVPN_INSTALLED" == "false" ]]; then
    apt-get install -y -qq cmake libssl-dev 2>/dev/null
    cd /tmp
    rm -rf badvpn
    git clone --depth=1 https://github.com/ambrop72/badvpn.git 2>/dev/null \
    && cd badvpn \
    && cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 . 2>/dev/null \
    && make 2>/dev/null \
    && cp udpgw/badvpn-udpgw /usr/local/bin/ \
    && chmod +x /usr/local/bin/badvpn-udpgw \
    && BADVPN_INSTALLED=true
fi

if [[ "$BADVPN_INSTALLED" == "true" ]]; then
    # Crear servicios BadVPN en puertos populares
    for bvport in 7300 7100 7200; do
        cat > "/etc/systemd/system/badvpn-${bvport}.service" << EOF
[Unit]
Description=BadVPN UDP GW port ${bvport}
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:${bvport} --max-clients 500 --max-connections-for-client 10
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable "badvpn-${bvport}"
        systemctl start "badvpn-${bvport}" 2>/dev/null || true
    done
    ok "BadVPN UDP-GW instalado → Puertos: 7100, 7200, 7300"
else
    err "BadVPN no pudo compilarse (sistema continúa sin él)"
fi

# ═══════════════════════════════════════════════════════════
# PASO 7: SISTEMA DE KEYS CON TIEMPO DE EXPIRACIÓN
# ═══════════════════════════════════════════════════════════
step "7/8" "Configurando sistema de llaves (Keys) por tiempo"

cat > /usr/local/bin/vpn-keys << 'KEYSEOF'
#!/bin/bash
# ============================================================
#   NexusVPN Pro - Gestor de Keys con Expiración
# ============================================================

KEYS_DB="/etc/vpn-panel/keys.db"
USERS_DB="/etc/vpn-panel/users.db"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
HYSTERIA_CONFIG="/etc/hysteria/config.yaml"
MYIP=$(curl -s ifconfig.me 2>/dev/null)

R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; W='\033[1;37m'; NC='\033[0m'

[[ ! -f "$KEYS_DB" ]] && touch "$KEYS_DB"
[[ ! -f "$USERS_DB" ]] && touch "$USERS_DB"

# Generar key única
generate_key() {
    local prefix=${1:-"VPN"}
    local rand=$(openssl rand -hex 8 | tr '[:lower:]' '[:upper:]')
    echo "${prefix}-${rand:0:4}-${rand:4:4}-${rand:8:4}"
}

# Calcular fecha de expiración
calc_expiry() {
    local days=$1
    date -d "+${days} days" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
    || date -v "+${days}d" '+%Y-%m-%d %H:%M:%S' 2>/dev/null
}

# Crear nueva key
create_key() {
    local duration_days=$1
    local max_users=${2:-1}
    local description=${3:-"Key VPN"}
    local limit_gb=${4:-0}     # 0 = ilimitado
    
    local key=$(generate_key "VPN")
    local created=$(date '+%Y-%m-%d %H:%M:%S')
    local expiry=$(calc_expiry "$duration_days")
    local uuid=$(cat /proc/sys/kernel/random/uuid)
    
    # Guardar en DB: KEY|UUID|CREATED|EXPIRY|MAX_USERS|USED|LIMIT_GB|USED_GB|DESCRIPTION|STATUS
    echo "${key}|${uuid}|${created}|${expiry}|${max_users}|0|${limit_gb}|0|${description}|ACTIVE" \
        >> "$KEYS_DB"
    
    echo "$key"
}

# Verificar key
verify_key() {
    local key=$1
    local line=$(grep "^${key}|" "$KEYS_DB" 2>/dev/null)
    
    [[ -z "$line" ]] && echo "INVALID" && return
    
    local status=$(echo "$line" | cut -d'|' -f10)
    local expiry=$(echo "$line" | cut -d'|' -f4)
    local max_users=$(echo "$line" | cut -d'|' -f5)
    local used=$(echo "$line" | cut -d'|' -f6)
    local limit_gb=$(echo "$line" | cut -d'|' -f7)
    local used_gb=$(echo "$line" | cut -d'|' -f8)
    
    # Verificar estado
    [[ "$status" == "REVOKED" ]] && echo "REVOKED" && return
    
    # Verificar expiración
    local now=$(date '+%Y-%m-%d %H:%M:%S')
    [[ "$now" > "$expiry" ]] && {
        update_key_status "$key" "EXPIRED"
        echo "EXPIRED"
        return
    }
    
    # Verificar límite de usuarios
    [[ $max_users -gt 0 && $used -ge $max_users ]] && echo "USER_LIMIT" && return
    
    # Verificar límite de datos
    [[ $limit_gb -gt 0 ]] && (( $(echo "$used_gb >= $limit_gb" | bc -l) )) && {
        echo "DATA_LIMIT"
        return
    }
    
    echo "VALID"
}

# Activar key para un usuario
activate_key() {
    local key=$1
    local username=$2
    
    local status=$(verify_key "$key")
    
    case $status in
        VALID)
            local uuid=$(grep "^${key}|" "$KEYS_DB" | cut -d'|' -f2)
            local expiry=$(grep "^${key}|" "$KEYS_DB" | cut -d'|' -f4)
            
            # Agregar usuario a Xray
            add_xray_user "$username" "$uuid"
            
            # Registrar en users.db
            echo "${username}|${key}|${uuid}|$(date '+%Y-%m-%d %H:%M:%S')|${expiry}" >> "$USERS_DB"
            
            # Incrementar contador de uso
            sed -i "s/^${key}|\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)|\([^|]*\)|/\${key}|\1|\2|\3|\4|$(( $(grep "^${key}|" "$KEYS_DB" | cut -d'|' -f6) + 1))|/" "$KEYS_DB"
            
            echo -e "${G}✅ Key activada para usuario: $username${NC}"
            echo -e "${Y}   UUID: $uuid${NC}"
            echo -e "${Y}   Expira: $expiry${NC}"
            
            show_connection_info "$username" "$uuid" "$expiry"
            return 0
            ;;
        INVALID) echo -e "${R}❌ Key inválida${NC}" ;;
        EXPIRED) echo -e "${R}❌ Key expirada${NC}" ;;
        REVOKED) echo -e "${R}❌ Key revocada${NC}" ;;
        USER_LIMIT) echo -e "${R}❌ Límite de usuarios alcanzado${NC}" ;;
        DATA_LIMIT) echo -e "${R}❌ Límite de datos alcanzado${NC}" ;;
    esac
    return 1
}

# Agregar usuario a Xray
add_xray_user() {
    local username=$1
    local uuid=$2
    
    # Agregar a todos los inbounds
    jq --arg uuid "$uuid" --arg user "$username" \
       '.inbounds[0].settings.clients += [{"id": $uuid, "email": $user, "flow": ""}]' \
       "$XRAY_CONFIG" > /tmp/xray_tmp.json
    
    jq --arg uuid "$uuid" --arg user "$username" \
       '.inbounds[1].settings.clients += [{"id": $uuid, "alterId": 0, "email": $user}]' \
       /tmp/xray_tmp.json > /tmp/xray_tmp2.json
    
    jq --arg uuid "$uuid" --arg user "$username" \
       '.inbounds[2].settings.clients += [{"id": $uuid, "alterId": 0, "email": $user}]' \
       /tmp/xray_tmp2.json > /tmp/xray_tmp3.json
    
    jq --arg uuid "$uuid" --arg user "$username" \
       '.inbounds[3].settings.clients += [{"password": $uuid, "email": $user}]' \
       /tmp/xray_tmp3.json > "$XRAY_CONFIG"
    
    rm -f /tmp/xray_tmp*.json
    systemctl restart xray
}

# Agregar usuario Hysteria2
add_hysteria_user() {
    local username=$1
    local password=$2
    
    python3 - << PYEOF
import yaml
with open('/etc/hysteria/config.yaml', 'r') as f:
    config = yaml.safe_load(f)
if 'auth' not in config:
    config['auth'] = {'type': 'userpass', 'userpass': {}}
config['auth']['userpass']['$username'] = '$password'
with open('/etc/hysteria/config.yaml', 'w') as f:
    yaml.dump(config, f, default_flow_style=False, allow_unicode=True)
print('OK')
PYEOF
    systemctl restart hysteria-server 2>/dev/null || true
}

# Mostrar info de conexión
show_connection_info() {
    local username=$1
    local uuid=$2
    local expiry=$3
    local myip=$(curl -s ifconfig.me 2>/dev/null)
    
    echo ""
    echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${W}  📱 CONFIGURACIONES DE CONEXIÓN - $username${NC}"
    echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # VLESS TCP
    local vless_link="vless://${uuid}@${myip}:443?type=tcp&security=none&headerType=none#VPN-${username}"
    echo -e "${Y}  [VLESS TCP]:${NC}"
    echo -e "  $vless_link"
    echo ""
    
    # VMess WebSocket
    local vmess_json="{\"v\":\"2\",\"ps\":\"VMess-WS-${username}\",\"add\":\"${myip}\",\"port\":\"8080\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/vpnpanel\",\"type\":\"none\"}"
    local vmess_link="vmess://$(echo -n "$vmess_json" | base64 -w0)"
    echo -e "${Y}  [VMess WS]:${NC}"
    echo -e "  $vmess_link"
    echo ""
    
    # VMess mKCP
    local mkcp_json="{\"v\":\"2\",\"ps\":\"VMess-KCP-${username}\",\"add\":\"${myip}\",\"port\":\"1194\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"kcp\",\"type\":\"none\",\"seed\":\"vpnpanel2024\"}"
    local mkcp_link="vmess://$(echo -n "$mkcp_json" | base64 -w0)"
    echo -e "${Y}  [VMess mKCP]:${NC}"
    echo -e "  $mkcp_link"
    echo ""
    
    # Trojan
    echo -e "${Y}  [Trojan]:${NC}"
    echo -e "  trojan://${uuid}@${myip}:8443?security=none#Trojan-${username}"
    echo ""
    
    # Guardar en archivo
    local outfile="/root/vpn-${username}-$(date +%Y%m%d).txt"
    {
        echo "=== NexusVPN Pro - Usuario: $username ==="
        echo "Expira: $expiry"
        echo "VLESS:  $vless_link"
        echo "VMess:  $vmess_link"
        echo "KCP:    $mkcp_link"
        echo "Trojan: trojan://${uuid}@${myip}:8443?security=none#Trojan-${username}"
    } > "$outfile"
    echo -e "${G}  📁 Config guardada en: $outfile${NC}"
    echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

update_key_status() {
    local key=$1 status=$2
    sed -i "s/^${key}\(.*\)|[A-Z]*$/${key}\1|${status}/" "$KEYS_DB"
}

# Listar todas las keys
list_keys() {
    echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${W}  KEYS REGISTRADAS${NC}"
    echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    printf "  %-30s %-12s %-22s %-6s %-8s\n" "KEY" "ESTADO" "EXPIRA" "USERS" "DESC"
    echo -e "${C}  ─────────────────────────────────────────────────────────${NC}"
    
    while IFS='|' read -r key uuid created expiry max_users used limit_gb used_gb desc status; do
        # Verificar si expiró
        local now=$(date '+%Y-%m-%d %H:%M:%S')
        [[ "$now" > "$expiry" && "$status" == "ACTIVE" ]] && status="EXPIRED"
        
        local color="${G}"
        [[ "$status" == "EXPIRED" ]] && color="${R}"
        [[ "$status" == "REVOKED" ]] && color="${Y}"
        
        printf "  ${color}%-30s %-12s %-22s %s/%s    %s${NC}\n" \
            "$key" "$status" "$expiry" "$used" "$max_users" "${desc:0:15}"
    done < "$KEYS_DB"
    
    echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# Eliminar usuario
delete_user() {
    local username=$1
    local uuid=$(grep "^${username}|" "$USERS_DB" | cut -d'|' -f3)
    
    if [[ -z "$uuid" ]]; then
        echo -e "${R}Usuario no encontrado${NC}"; return 1
    fi
    
    # Remover de Xray
    for i in 0 1 2 3; do
        jq --arg uuid "$uuid" \
           "del(.inbounds[${i}].settings.clients[] | select(.id == \$uuid or .password == \$uuid))" \
           "$XRAY_CONFIG" > /tmp/xray_del.json \
        && mv /tmp/xray_del.json "$XRAY_CONFIG"
    done
    
    # Remover de users.db
    sed -i "/^${username}|/d" "$USERS_DB"
    
    systemctl restart xray
    echo -e "${G}✅ Usuario $username eliminado${NC}"
}

# Verificar y limpiar keys expiradas
cleanup_expired() {
    local count=0
    while IFS='|' read -r key uuid created expiry max_users used limit_gb used_gb desc status; do
        local now=$(date '+%Y-%m-%d %H:%M:%S')
        if [[ "$now" > "$expiry" && "$status" == "ACTIVE" ]]; then
            update_key_status "$key" "EXPIRED"
            
            # Deshabilitar usuario en Xray
            for i in 0 1 2 3; do
                jq --arg uuid "$uuid" \
                   "del(.inbounds[${i}].settings.clients[] | select(.id == \$uuid or .password == \$uuid))" \
                   "$XRAY_CONFIG" > /tmp/xray_exp.json 2>/dev/null \
                && mv /tmp/xray_exp.json "$XRAY_CONFIG"
            done
            ((count++))
        fi
    done < "$KEYS_DB"
    
    [[ $count -gt 0 ]] && systemctl restart xray && echo "Limpiadas $count keys expiradas"
}

# Menú interactivo de keys
keys_menu() {
    while true; do
        clear
        echo -e "${C}"
        echo "╔══════════════════════════════════════════════════════╗"
        echo "║        GESTOR DE KEYS - NexusVPN Pro               ║"
        echo "╚══════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        echo -e "  ${Y}1)${NC} Crear key (1 día)"
        echo -e "  ${Y}2)${NC} Crear key (7 días)"
        echo -e "  ${Y}3)${NC} Crear key (30 días)"
        echo -e "  ${Y}4)${NC} Crear key personalizada"
        echo -e "  ${Y}5)${NC} Activar key para usuario"
        echo -e "  ${Y}6)${NC} Listar todas las keys"
        echo -e "  ${Y}7)${NC} Revocar key"
        echo -e "  ${Y}8)${NC} Eliminar usuario"
        echo -e "  ${Y}9)${NC} Limpiar keys expiradas"
        echo -e "  ${Y}0)${NC} Volver"
        echo ""
        read -p "  Opción: " opt
        
        case $opt in
            1)
                read -p "  Descripción (opcional): " desc
                read -p "  Max. usuarios [1]: " maxu; maxu=${maxu:-1}
                key=$(create_key 1 "$maxu" "${desc:-Key 1 día}")
                echo -e "\n  ${G}Key creada:${NC} ${W}$key${NC}"
                sleep 3
                ;;
            2)
                read -p "  Descripción (opcional): " desc
                read -p "  Max. usuarios [1]: " maxu; maxu=${maxu:-1}
                key=$(create_key 7 "$maxu" "${desc:-Key 7 días}")
                echo -e "\n  ${G}Key creada:${NC} ${W}$key${NC}"
                sleep 3
                ;;
            3)
                read -p "  Descripción (opcional): " desc
                read -p "  Max. usuarios [1]: " maxu; maxu=${maxu:-1}
                key=$(create_key 30 "$maxu" "${desc:-Key 30 días}")
                echo -e "\n  ${G}Key creada:${NC} ${W}$key${NC}"
                sleep 3
                ;;
            4)
                read -p "  Duración en días: " dias
                read -p "  Max. usuarios [1]: " maxu; maxu=${maxu:-1}
                read -p "  Límite GB [0=ilimitado]: " lgb; lgb=${lgb:-0}
                read -p "  Descripción: " desc
                key=$(create_key "$dias" "$maxu" "${desc:-Key custom}" "$lgb")
                echo -e "\n  ${G}Key creada:${NC} ${W}$key${NC}"
                sleep 3
                ;;
            5)
                read -p "  Ingresa la KEY: " key
                read -p "  Nombre de usuario: " username
                activate_key "$key" "$username"
                read -p "  Presiona Enter..."
                ;;
            6)
                list_keys
                echo ""; read -p "  Presiona Enter..."
                ;;
            7)
                read -p "  KEY a revocar: " key
                update_key_status "$key" "REVOKED"
                echo -e "  ${G}Key revocada${NC}"
                sleep 2
                ;;
            8)
                read -p "  Usuario a eliminar: " username
                delete_user "$username"
                sleep 2
                ;;
            9)
                cleanup_expired
                sleep 2
                ;;
            0) break ;;
        esac
    done
}

# Ejecutar según argumento
case $1 in
    create)  create_key "${2:-30}" "${3:-1}" "${4:-Key VPN}" ;;
    verify)  verify_key "$2" ;;
    activate) activate_key "$2" "$3" ;;
    list)    list_keys ;;
    cleanup) cleanup_expired ;;
    menu)    keys_menu ;;
    *)       keys_menu ;;
esac
KEYSEOF
chmod +x /usr/local/bin/vpn-keys

# Cron para limpiar keys expiradas cada hora
(crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/vpn-keys cleanup >> /var/log/vpn-panel.log 2>&1") | crontab -

ok "Sistema de Keys instalado"

# ═══════════════════════════════════════════════════════════
# PASO 8: FIREWALL + OPTIMIZACIÓN + MENÚ PRINCIPAL
# ═══════════════════════════════════════════════════════════
step "8/8" "Configurando firewall, optimizaciones y menú"

# Firewall UFW
ufw --force disable
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 22/tcp comment 'SSH'
ufw allow 443/tcp comment 'VLESS TCP'
ufw allow 8080/tcp comment 'VMess WS'
ufw allow 1194/udp comment 'VMess mKCP'
ufw allow 8443/tcp comment 'Trojan'
ufw allow 36712/udp comment 'Hysteria2'
ufw allow 5300/udp comment 'SlowDNS'
ufw allow 53/udp comment 'DNS'
ufw allow 5353/udp comment 'DNS Alt'
ufw allow 7100:7300/udp comment 'BadVPN'
echo "y" | ufw enable

# Optimización del kernel (BBR)
cat >> /etc/sysctl.conf << 'SYSCTL'

# NexusVPN Pro - Optimizaciones
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_slow_start_after_idle = 0
net.ipv4.ip_forward = 1
net.ipv4.tcp_fastopen = 3
net.core.netdev_max_backlog = 250000
SYSCTL
sysctl -p 2>/dev/null | tail -3

# Instalar menú principal
install_main_menu

ok "Firewall, optimizaciones y menú instalados"

# ─── Función menú principal ────────────────────────────────
install_main_menu() {
    cat > "$MENU_BIN" << 'MENUEOF'
#!/bin/bash
# ============================================================
#   NexusVPN Pro - Menú Principal
# ============================================================

MYIP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org)
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; W='\033[1;37m'; NC='\033[0m'

show_banner() {
    clear
    echo -e "${C}"
    cat << 'BANNER'
╔══════════════════════════════════════════════════════════════╗
║                  NexusVPN Pro v2.0.0                       ║
║       V2Ray • Hysteria2 • SlowDNS • UDP Custom              ║
╚══════════════════════════════════════════════════════════════╝
BANNER
    echo -e "${NC}"
    echo -e "  ${Y}IP:${NC} $MYIP  ${Y}|${NC}  ${Y}Fecha:${NC} $(date '+%d/%m/%Y %H:%M')"
    
    # Estado de servicios
    printf "  "
    for svc in xray hysteria-server slowdns; do
        if systemctl is-active --quiet "$svc" 2>/dev/null; then
            printf "${G}● $svc${NC}  "
        else
            printf "${R}○ $svc${NC}  "
        fi
    done
    echo ""
    echo -e "  ${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

menu_servicios() {
    while true; do
        show_banner
        echo -e "\n  ${W}SERVICIOS${NC}"
        echo -e "  ${Y}1)${NC} Reiniciar todos los servicios"
        echo -e "  ${Y}2)${NC} Reiniciar Xray"
        echo -e "  ${Y}3)${NC} Reiniciar Hysteria2"
        echo -e "  ${Y}4)${NC} Reiniciar SlowDNS"
        echo -e "  ${Y}5)${NC} Ver logs Xray"
        echo -e "  ${Y}6)${NC} Ver logs Hysteria2"
        echo -e "  ${Y}0)${NC} Volver"
        read -p "  Opción: " opt
        case $opt in
            1) systemctl restart xray hysteria-server slowdns; echo -e "${G}✅ Todos reiniciados${NC}"; sleep 2 ;;
            2) systemctl restart xray; echo -e "${G}✅ Xray reiniciado${NC}"; sleep 2 ;;
            3) systemctl restart hysteria-server; echo -e "${G}✅ Hysteria2 reiniciado${NC}"; sleep 2 ;;
            4) systemctl restart slowdns; echo -e "${G}✅ SlowDNS reiniciado${NC}"; sleep 2 ;;
            5) journalctl -u xray -n 50 --no-pager; read -p "Enter..." ;;
            6) journalctl -u hysteria-server -n 50 --no-pager; read -p "Enter..." ;;
            0) break ;;
        esac
    done
}

menu_puertos_udp() {
    while true; do
        show_banner
        echo -e "\n  ${W}GESTIÓN UDP CUSTOM${NC}"
        echo -e "  ${Y}1)${NC} Agregar puerto UDP"
        echo -e "  ${Y}2)${NC} Eliminar puerto UDP"
        echo -e "  ${Y}3)${NC} Listar puertos activos"
        echo -e "  ${Y}0)${NC} Volver"
        read -p "  Opción: " opt
        case $opt in
            1)
                read -p "  Puerto UDP a abrir: " port
                echo -e "  ${Y}Destino:${NC}"
                echo "  1) Google DNS (8.8.8.8:53)"
                echo "  2) Cloudflare (1.1.1.1:53)"
                echo "  3) Local BadVPN (127.0.0.1:7300)"
                echo "  4) Personalizado"
                read -p "  [1-4]: " dest_opt
                case $dest_opt in
                    1) dest="8.8.8.8:53" ;;
                    2) dest="1.1.1.1:53" ;;
                    3) dest="127.0.0.1:7300" ;;
                    4) read -p "  IP:PUERTO destino: " dest ;;
                esac
                udp-custom add "$port" "$dest"
                ufw allow "${port}/udp" >/dev/null
                sleep 2
                ;;
            2)
                read -p "  Puerto UDP a eliminar: " port
                udp-custom del "$port"
                ufw delete allow "${port}/udp" >/dev/null
                sleep 2
                ;;
            3) udp-custom list; read -p "  Enter..." ;;
            0) break ;;
        esac
    done
}

show_info() {
    show_banner
    echo -e "\n  ${W}INFORMACIÓN DEL SERVIDOR${NC}\n"
    echo -e "  ${Y}IP:${NC}      $MYIP"
    echo -e "  ${Y}SO:${NC}      $(. /etc/os-release && echo "$PRETTY_NAME")"
    echo -e "  ${Y}Kernel:${NC}  $(uname -r)"
    echo -e "  ${Y}Uptime:${NC}  $(uptime -p)"
    echo -e "  ${Y}RAM:${NC}     $(free -h | awk '/^Mem:/ {print $3 "/" $2}')"
    echo -e "  ${Y}Disco:${NC}   $(df -h / | awk 'NR==2 {print $3 "/" $2}')"
    echo -e "  ${Y}CPU:${NC}     $(nproc) cores - $(cat /proc/loadavg | cut -d' ' -f1-3)"
    
    echo -e "\n  ${Y}Puertos activos:${NC}"
    ss -tulpn 2>/dev/null | grep -E ':(443|8080|1194|8443|36712|5300|7[123]00)' \
    | awk '{printf "  %-8s %s\n", $1, $5}' | sort -u
    
    echo -e "\n  ${Y}SlowDNS Public Key:${NC}"
    [[ -f /etc/vpn-panel/slowdns_pubkey.txt ]] \
        && cat /etc/vpn-panel/slowdns_pubkey.txt \
        || echo "  No disponible"
    
    echo ""
    read -p "  Presiona Enter..."
}

# Menú principal
while true; do
    show_banner
    echo -e "\n  ${W}MENÚ PRINCIPAL${NC}"
    echo -e "  ${C}─────────────────────────────────────────────${NC}"
    echo -e "  ${Y}1)${NC} 🔑 Gestionar Keys (crear/activar/listar)"
    echo -e "  ${Y}2)${NC} 👥 Gestionar Usuarios V2Ray"
    echo -e "  ${Y}3)${NC} 🌐 Gestionar Puertos UDP Custom"
    echo -e "  ${Y}4)${NC} ⚙️  Servicios (reiniciar/logs)"
    echo -e "  ${Y}5)${NC} 📊 Información del servidor"
    echo -e "  ${Y}6)${NC} 🔒 Configurar Firewall"
    echo -e "  ${Y}7)${NC} 📦 Actualizar Panel"
    echo -e "  ${Y}0)${NC} 🚪 Salir"
    echo -e "  ${C}─────────────────────────────────────────────${NC}"
    read -p "  Opción [0-7]: " opt
    
    case $opt in
        1) vpn-keys menu ;;
        2) vpn-keys menu ;;
        3) menu_puertos_udp ;;
        4) menu_servicios ;;
        5) show_info ;;
        6)
            echo -e "\n  ${Y}Puertos abiertos actualmente:${NC}"
            ufw status numbered
            echo ""
            read -p "  Abrir puerto extra (o Enter para omitir): " extra_port
            [[ -n "$extra_port" ]] && ufw allow "$extra_port" && echo -e "${G}✅ Puerto $extra_port abierto${NC}"
            sleep 2
            ;;
        7)
            echo -e "${Y}Actualizando...${NC}"
            bash -c "$(curl -fsSL https://raw.githubusercontent.com/TU_USUARIO/vpn-panel/main/install.sh)"
            ;;
        0) echo -e "\n  ${G}¡Hasta luego!${NC}\n"; exit 0 ;;
        *) echo -e "  ${R}Opción inválida${NC}"; sleep 1 ;;
    esac
done
MENUEOF
    chmod +x "$MENU_BIN"
}

install_main_menu

# ─── RESUMEN FINAL ─────────────────────────────────────────
clear
echo -e "${B}"
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║   ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗              ║"
echo "║   ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝              ║"
echo "║   ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗              ║"
echo "║   ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║              ║"
echo "║   ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║              ║"
echo "║   ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝              ║"
echo "║        ██╗   ██╗██████╗ ███╗   ██╗    ██████╗ ██████╗       ║"
echo "║        ██║   ██║██╔══██╗████╗  ██║    ██╔══██╗██╔══██╗      ║"
echo "║        ██║   ██║██████╔╝██╔██╗ ██║    ██████╔╝██████╔╝      ║"
echo "║        ╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║    ██╔═══╝ ██╔══██╗      ║"
echo "║         ╚████╔╝ ██║     ██║ ╚████║    ██║     ██║  ██║       ║"
echo "║          ╚═══╝  ╚═╝     ╚═╝  ╚═══╝    ╚═╝     ╚═╝  ╚═╝       ║"
echo "║                                                              ║"
echo "║              ✅ NexusVPN Pro - INSTALADO                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo -e "  ${W}PROTOCOLOS INSTALADOS:${NC}"
echo -e "  ${G}●${NC} Xray (VLESS TCP :443, VMess WS :8080, VMess mKCP :1194, Trojan :8443)"
echo -e "  ${G}●${NC} Hysteria2 (UDP :36712 con obfuscación)"
echo -e "  ${G}●${NC} SlowDNS / dnstt-server (UDP :5300)"
echo -e "  ${G}●${NC} UDP Custom via socat (DNS bypass)"
echo -e "  ${G}●${NC} BadVPN UDP-GW (:7100, :7200, :7300)"
echo -e ""
echo -e "  ${W}GESTIÓN:${NC}"
echo -e "  ${G}●${NC} Sistema de Keys con expiración por tiempo"
echo -e "  ${G}●${NC} Cron automático para limpiar keys expiradas"
echo -e "  ${G}●${NC} Firewall UFW configurado"
echo -e "  ${G}●${NC} BBR + optimizaciones de kernel activas"
echo -e ""
echo -e "  ${Y}IP del servidor:${NC} $MYIP"
echo -e "  ${Y}SlowDNS PubKey:${NC}  $(cat /etc/vpn-panel/slowdns_pubkey.txt 2>/dev/null || echo 'ver /etc/vpn-panel/slowdns_pubkey.txt')"
echo -e ""
echo -e "  ${W}Para acceder al panel:${NC}"
echo -e "  ${C}  vpn-panel${NC}"
echo -e ""
echo -e "  ${Y}Log de instalación:${NC} $LOG_FILE"
echo -e "${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

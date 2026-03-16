#!/bin/bash
# ============================================================
#   NexusVPN Pro v3.0 - Script de instalación + Panel
#   Repo: https://github.com/Androidzpro/NexusVPN
#   Ubuntu 20.04 / 22.04 / Debian 11
# ============================================================

# ── Colores ──────────────────────────────────────────────────
R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
B='\033[0;34m'
C='\033[0;36m'
W='\033[1;37m'
P='\033[0;35m'
NC='\033[0m'
BOLD='\033[1m'

# ── Rutas globales ────────────────────────────────────────────
PANEL_DIR="/etc/NexusVPN"
XRAY_CONF="/usr/local/etc/xray/config.json"
HY2_CONF="/etc/hysteria/config.yaml"
SDNS_DIR="/etc/slowdns"
KEYS_DB="$PANEL_DIR/keys.db"
USERS_DB="$PANEL_DIR/users.db"
CONTACTS_FILE="$PANEL_DIR/contacts.conf"
BANNER_FILE="$PANEL_DIR/banner.txt"
SERVER_KEY_FILE="$PANEL_DIR/server.key"
PANEL_BIN="/usr/local/bin/nexusvpn"
VERSION="3.0"
MYIP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org 2>/dev/null)

# ════════════════════════════════════════════════════════════
#  FUNCIONES UTILITARIAS
# ════════════════════════════════════════════════════════════
ok()   { echo -e "${G}  ✔ $1${NC}"; }
err()  { echo -e "${R}  ✘ $1${NC}"; }
inf()  { echo -e "${C}  » $1${NC}"; }
warn() { echo -e "${Y}  ! $1${NC}"; }
sep()  { echo -e "${C}  ════════════════════════════════════════════════════${NC}"; }
sep2() { echo -e "${Y}  ────────────────────────────────────────────────────${NC}"; }

pause() { echo ""; read -p "  $(echo -e "${Y}Presiona Enter para continuar...${NC}")" _; }

check_root() {
    [[ $EUID -ne 0 ]] && err "Ejecutar como root: sudo bash install.sh" && exit 1
}

get_users_count() {
    [[ -f "$USERS_DB" ]] && wc -l < "$USERS_DB" || echo "0"
}

get_server_key_expiry() {
    [[ -f "$SERVER_KEY_FILE" ]] && cut -d'|' -f2 "$SERVER_KEY_FILE" || echo "No activado"
}

check_server_activated() {
    [[ ! -f "$SERVER_KEY_FILE" ]] && return 1
    local expiry=$(cut -d'|' -f2 "$SERVER_KEY_FILE")
    local now=$(date '+%Y-%m-%d %H:%M:%S')
    [[ "$now" < "$expiry" ]] && return 0 || return 1
}

service_status() {
    systemctl is-active --quiet "$1" 2>/dev/null && echo -e "${G}●${NC}" || echo -e "${R}●${NC}"
}

# ════════════════════════════════════════════════════════════
#  BANNER PRINCIPAL
# ════════════════════════════════════════════════════════════
show_banner() {
    clear
    local users=$(get_users_count)
    local expiry=$(get_server_key_expiry)
    local sxray=$(service_status xray)
    local shy2=$(service_status hysteria-server)
    local ssdns=$(service_status slowdns)

    echo -e "${B}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║  ███╗  ██╗███████╗██╗  ██╗██╗   ██╗███████╗        ║"
    echo "  ║  ████╗ ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝        ║"
    echo "  ║  ██╔██╗██║█████╗   ╚███╔╝ ██║   ██║███████╗        ║"
    echo "  ║  ██║╚████║██╔══╝   ██╔██╗ ██║   ██║╚════██║        ║"
    echo "  ║  ██║ ╚███║███████╗██╔╝ ██╗╚██████╔╝███████║        ║"
    echo "  ║  ╚═╝  ╚══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝        ║"
    echo "  ║            VPN  PRO  v${VERSION}                         ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    # Info del servidor
    echo -e "  ${Y}IP Servidor :${NC} ${W}$MYIP${NC}   ${Y}Usuarios Activos :${NC} ${W}$users${NC}"
    echo -e "  ${Y}Licencia    :${NC} ${W}$expiry${NC}"
    echo -e "  ${Y}Servicios   :${NC}  ${sxray} Xray  ${shy2} Hysteria2  ${ssdns} SlowDNS"
    # Banner publicitario si existe
    if [[ -f "$BANNER_FILE" && -s "$BANNER_FILE" ]]; then
        sep2
        echo -e "${P}"
        while IFS= read -r line; do echo "  $line"; done < "$BANNER_FILE"
        echo -e "${NC}"
    fi
    # Contactos si existen
    if [[ -f "$CONTACTS_FILE" && -s "$CONTACTS_FILE" ]]; then
        sep2
        while IFS='=' read -r key val; do
            [[ -n "$val" ]] && echo -e "  ${C}$key:${NC} ${W}$val${NC}"
        done < "$CONTACTS_FILE"
    fi
    sep
}

# ════════════════════════════════════════════════════════════
#  INSTALACIÓN SILENCIOSA (sin preguntas)
# ════════════════════════════════════════════════════════════
install_silent() {
    clear
    echo -e "${B}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║         NexusVPN Pro - INSTALANDO...                ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    local LOG="/var/log/nexusvpn-install.log"
    exec > >(tee -a "$LOG") 2>&1

    mkdir -p "$PANEL_DIR"
    touch "$KEYS_DB" "$USERS_DB"
    [[ ! -f "$CONTACTS_FILE" ]] && cat > "$CONTACTS_FILE" << 'EOF'
WhatsApp=
Telegram=
Instagram=
Canal=
EOF
    [[ ! -f "$BANNER_FILE" ]] && echo "NexusVPN Pro - El mejor panel VPN" > "$BANNER_FILE"

    # ── 1. Dependencias ───────────────────────────────────────
    inf "[1/7] Instalando dependencias..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq \
        curl wget jq unzip socat git uuid-runtime openssl \
        python3 python3-pip net-tools ufw iptables \
        build-essential golang-go cron bc lsof netcat-openbsd \
        2>/dev/null | tail -2
    ok "Dependencias OK"

    # ── 2. Xray ───────────────────────────────────────────────
    inf "[2/7] Instalando Xray..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -q 2>/dev/null

    mkdir -p "$(dirname $XRAY_CONF)"
    cat > "$XRAY_CONF" << 'XCFG'
{
  "log": { "loglevel": "warning" },
  "inbounds": [
    {
      "tag": "vless-tcp", "port": 443, "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": { "network": "tcp", "tcpSettings": { "header": { "type": "none" } } },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"] }
    },
    {
      "tag": "vmess-ws", "port": 80, "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/nexus" } }
    },
    {
      "tag": "vmess-ws-tls", "port": 8443, "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "/nexus" } }
    },
    {
      "tag": "vmess-mkcp", "port": 1194, "protocol": "vmess",
      "settings": { "clients": [] },
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
      "tag": "trojan", "port": 2083, "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": { "network": "tcp" }
    },
    {
      "tag": "ss", "port": 8388, "protocol": "shadowsocks",
      "settings": {
        "method": "chacha20-ietf-poly1305",
        "password": "nexusvpn2024",
        "network": "tcp,udp"
      }
    }
  ],
  "outbounds": [
    { "protocol": "freedom", "tag": "direct" },
    { "protocol": "blackhole", "tag": "blocked" }
  ],
  "routing": {
    "rules": [{ "type": "field", "protocol": ["bittorrent"], "outboundTag": "blocked" }]
  }
}
XCFG
    systemctl restart xray && systemctl enable xray -q
    ok "Xray OK → 443(VLESS) 80(VMess-WS) 8443(VMess-WS) 1194(KCP) 2083(Trojan) 8388(SS)"

    # ── 3. Hysteria2 ──────────────────────────────────────────
    inf "[3/7] Instalando Hysteria2..."
    bash -c "$(curl -fsSL https://get.hy2.sh/)" -- --version latest 2>/dev/null || {
        ARCH=$(uname -m); [[ "$ARCH" == "x86_64" ]] && HA="amd64" || HA="arm64"
        wget -qO /usr/local/bin/hysteria \
            "https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-${HA}"
        chmod +x /usr/local/bin/hysteria
    }
    mkdir -p /etc/hysteria
    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt \
        -subj "/CN=$MYIP" -days 3650 2>/dev/null
    HY2_PASS=$(openssl rand -hex 16)
    echo "$HY2_PASS" > /etc/hysteria/obfs.key
    cat > "$HY2_CONF" << HYCFG
listen: :36712
tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key
obfs:
  type: salamander
  salamander:
    password: "${HY2_PASS}"
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
    url: https://www.google.com/
    rewriteHost: true
HYCFG
    cat > /etc/systemd/system/hysteria-server.service << 'HYSVC'
[Unit]
Description=Hysteria2 Server
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/hysteria server -c /etc/hysteria/config.yaml
Restart=on-failure
RestartSec=5
[Install]
WantedBy=multi-user.target
HYSVC
    systemctl daemon-reload
    systemctl enable hysteria-server -q
    systemctl start hysteria-server 2>/dev/null || true
    ok "Hysteria2 OK → UDP 36712"

    # ── 4. SlowDNS ────────────────────────────────────────────
    inf "[4/7] Instalando SlowDNS..."
    mkdir -p "$SDNS_DIR"
    ARCH=$(uname -m); [[ "$ARCH" == "x86_64" ]] && DA="amd64" || DA="arm64"
    wget -qO "$SDNS_DIR/dnstt-server" \
        "https://github.com/lemon4ex/dnstt-compiled/releases/latest/download/dnstt-server-linux-${DA}" 2>/dev/null || {
        cd /tmp && rm -rf dnstt
        git clone --depth=1 https://www.bamsoftware.com/git/dnstt.git 2>/dev/null
        cd dnstt/server && go build -o "$SDNS_DIR/dnstt-server" . 2>/dev/null
    }
    chmod +x "$SDNS_DIR/dnstt-server" 2>/dev/null
    ln -sf "$SDNS_DIR/dnstt-server" /usr/local/bin/dnstt-server 2>/dev/null
    cd "$SDNS_DIR"
    [[ ! -f server.key ]] && \
        "$SDNS_DIR/dnstt-server" -gen-key -privkey server.key -pubkey server.pub 2>/dev/null
    SDNS_PUB=$(cat "$SDNS_DIR/server.pub" 2>/dev/null || echo "N/A")
    echo "$SDNS_PUB" > "$PANEL_DIR/slowdns_pubkey.txt"
    cat > /etc/systemd/system/slowdns.service << EOF
[Unit]
Description=SlowDNS Server
After=network.target
[Service]
Type=simple
ExecStart=$SDNS_DIR/dnstt-server -udp :5300 -privkey $SDNS_DIR/server.key 127.0.0.1:22
Restart=always
RestartSec=3
User=nobody
[Install]
WantedBy=multi-user.target
EOF
    systemctl daemon-reload && systemctl enable slowdns -q
    systemctl start slowdns 2>/dev/null || true
    ok "SlowDNS OK → UDP 5300"

    # ── 5. BadVPN UDP-GW ─────────────────────────────────────
    inf "[5/7] Instalando BadVPN..."
    ARCH=$(uname -m); [[ "$ARCH" == "x86_64" ]] && BA="x86_64" || BA="aarch64"
    wget -qO /usr/local/bin/badvpn-udpgw \
        "https://github.com/ambrop72/badvpn/releases/latest/download/badvpn-udpgw-linux-${BA}" 2>/dev/null || {
        apt-get install -y -qq cmake libssl-dev 2>/dev/null
        cd /tmp && rm -rf badvpn
        git clone --depth=1 https://github.com/ambrop72/badvpn.git 2>/dev/null
        cd badvpn
        cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 . 2>/dev/null
        make 2>/dev/null && cp udpgw/badvpn-udpgw /usr/local/bin/
    }
    chmod +x /usr/local/bin/badvpn-udpgw 2>/dev/null
    for BVPORT in 7100 7200 7300; do
        cat > "/etc/systemd/system/badvpn-${BVPORT}.service" << EOF
[Unit]
Description=BadVPN UDP-GW :${BVPORT}
After=network.target
[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:${BVPORT} --max-clients 500 --max-connections-for-client 10
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable "badvpn-${BVPORT}" -q
        systemctl start "badvpn-${BVPORT}" 2>/dev/null || true
    done
    ok "BadVPN OK → 7100 / 7200 / 7300"

    # ── 6. Firewall ───────────────────────────────────────────
    inf "[6/7] Configurando firewall..."
    ufw --force disable && ufw --force reset
    ufw default deny incoming && ufw default allow outgoing
    for p in 22/tcp 80/tcp 443/tcp 1194/udp 2083/tcp 5300/udp \
              8080/tcp 8388/tcp 8443/tcp 36712/udp 53/udp 7100:7300/udp; do
        ufw allow $p >/dev/null
    done
    echo "y" | ufw enable >/dev/null
    ok "Firewall OK"

    # ── 7. Optimización kernel + instalación del panel ────────
    inf "[7/7] Optimizando sistema e instalando panel..."
    grep -q "nexusvpn" /etc/sysctl.conf || cat >> /etc/sysctl.conf << 'SYSCTL'

# NexusVPN Pro optimizations
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.ip_forward = 1
net.ipv4.tcp_fastopen = 3
SYSCTL
    sysctl -p >/dev/null 2>&1

    # Cron de expiración cada hora
    (crontab -l 2>/dev/null | grep -v nexusvpn; \
     echo "0 * * * * $PANEL_BIN --cleanup >/dev/null 2>&1") | crontab -

    # Copiar este mismo script como panel principal
    cp "$0" "$PANEL_BIN" 2>/dev/null || curl -fsSL \
        "https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh" \
        -o "$PANEL_BIN" 2>/dev/null
    chmod +x "$PANEL_BIN"

    ok "Panel instalado → comando: nexusvpn"

    # ── Resumen ───────────────────────────────────────────────
    clear
    echo -e "${B}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════╗"
    echo "  ║       ✅  NexusVPN Pro - INSTALADO                  ║"
    echo "  ╚══════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${G}Protocolos activos:${NC}"
    echo -e "  ${W}VLESS TCP     :${NC} $MYIP:443"
    echo -e "  ${W}VMess WS      :${NC} $MYIP:80  path /nexus"
    echo -e "  ${W}VMess WS TLS  :${NC} $MYIP:8443  path /nexus"
    echo -e "  ${W}VMess mKCP    :${NC} $MYIP:1194"
    echo -e "  ${W}Trojan        :${NC} $MYIP:2083"
    echo -e "  ${W}Shadowsocks   :${NC} $MYIP:8388"
    echo -e "  ${W}Hysteria2     :${NC} $MYIP:36712 (UDP)"
    echo -e "  ${W}SlowDNS       :${NC} $MYIP:5300 (UDP)"
    echo -e "  ${W}BadVPN UDP-GW :${NC} 127.0.0.1:7100/7200/7300"
    sep2
    echo -e "  ${Y}SlowDNS PubKey:${NC} $(cat $PANEL_DIR/slowdns_pubkey.txt 2>/dev/null)"
    echo -e "  ${Y}Hysteria2 Obfs:${NC} $(cat /etc/hysteria/obfs.key 2>/dev/null)"
    sep2
    echo -e "  ${C}Para activar el servidor necesitas una KEY de licencia.${NC}"
    echo -e "  ${W}Ejecuta:${NC} ${C}nexusvpn${NC}"
    sep
}

# ════════════════════════════════════════════════════════════
#  SISTEMA DE KEYS (Licencia del servidor)
# ════════════════════════════════════════════════════════════

# Generar key de activación del servidor
gen_server_key() {
    local dias=$1
    local rand=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')
    local key="NEXUS-${rand:0:4}-${rand:4:4}-${rand:8:4}-${rand:12:4}"
    local expiry=$(date -d "+${dias} days" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
                || date -v "+${dias}d" '+%Y-%m-%d %H:%M:%S')
    # Guardar en keys.db: KEY|EXPIRY|DIAS|ESTADO
    echo "${key}|${expiry}|${dias}|PENDIENTE" >> "$KEYS_DB"
    echo "$key"
}

# Activar servidor con key
activate_server() {
    local key=$1
    local line=$(grep "^${key}|" "$KEYS_DB" 2>/dev/null)
    [[ -z "$line" ]] && err "Key inválida: $key" && return 1

    local estado=$(echo "$line" | cut -d'|' -f4)
    [[ "$estado" == "USADA" ]] && err "Esta key ya fue usada" && return 1

    local expiry=$(echo "$line" | cut -d'|' -f2)
    local now=$(date '+%Y-%m-%d %H:%M:%S')
    [[ "$now" > "$expiry" ]] && err "Key expirada desde: $expiry" && return 1

    # Marcar como usada y guardar activación
    sed -i "s/^${key}|.*/${key}|${expiry}|$(echo $line | cut -d'|' -f3)|USADA/" "$KEYS_DB"
    echo "${key}|${expiry}" > "$SERVER_KEY_FILE"

    ok "Servidor activado hasta: ${W}$expiry${NC}"
}

# ── Menú gestión de keys ──────────────────────────────────
menu_keys() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ GESTIÓN DE KEYS ══════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Generar key  1 día"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Generar key  7 días"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Generar key 15 días"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Generar key 30 días"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Generar key personalizada"
        echo -e "  ${C}║${NC}  ${Y}6)${NC}  Activar servidor con key"
        echo -e "  ${C}║${NC}  ${Y}7)${NC}  Listar todas las keys"
        echo -e "  ${C}║${NC}  ${Y}8)${NC}  Revocar key"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1|2|3|4)
                dias_arr=(0 1 7 15 30); dias=${dias_arr[$opt]}
                key=$(gen_server_key $dias)
                sep2
                echo -e "  ${G}Key generada ($dias días):${NC}"
                echo -e "  ${W}${BOLD}$key${NC}"
                sep2; pause ;;
            5)
                read -p "  Días de vigencia: " dias
                key=$(gen_server_key $dias)
                sep2
                echo -e "  ${G}Key generada ($dias días):${NC}"
                echo -e "  ${W}${BOLD}$key${NC}"
                sep2; pause ;;
            6)
                read -p "  Ingresa la key: " key
                activate_server "$key"; pause ;;
            7) list_keys; pause ;;
            8)
                read -p "  Key a revocar: " key
                sed -i "s/^${key}|\(.*\)|[A-Z]*$/${key}|\1|REVOCADA/" "$KEYS_DB"
                ok "Key revocada"; pause ;;
            0) break ;;
        esac
    done
}

list_keys() {
    sep2
    printf "  ${C}%-36s %-22s %-6s %-10s${NC}\n" "KEY" "EXPIRA" "DÍAS" "ESTADO"
    sep2
    while IFS='|' read -r key expiry dias estado; do
        local col="${G}"
        [[ "$estado" == "USADA" ]] && col="${Y}"
        [[ "$estado" == "REVOCADA" ]] && col="${R}"
        printf "  ${col}%-36s %-22s %-6s %-10s${NC}\n" "$key" "$expiry" "$dias" "$estado"
    done < "$KEYS_DB"
    sep2
}

# ════════════════════════════════════════════════════════════
#  GESTIÓN DE USUARIOS V2RAY
# ════════════════════════════════════════════════════════════
add_xray_user() {
    local user=$1 uuid=$2
    # VLESS
    jq --arg u "$uuid" --arg e "$user" \
       '.inbounds[0].settings.clients += [{"id":$u,"email":$e,"flow":""}]' \
       "$XRAY_CONF" > /tmp/x1.json
    # VMess WS
    jq --arg u "$uuid" --arg e "$user" \
       '.inbounds[1].settings.clients += [{"id":$u,"alterId":0,"email":$e}]' \
       /tmp/x1.json > /tmp/x2.json
    # VMess WS TLS
    jq --arg u "$uuid" --arg e "$user" \
       '.inbounds[2].settings.clients += [{"id":$u,"alterId":0,"email":$e}]' \
       /tmp/x2.json > /tmp/x3.json
    # VMess KCP
    jq --arg u "$uuid" --arg e "$user" \
       '.inbounds[3].settings.clients += [{"id":$u,"alterId":0,"email":$e}]' \
       /tmp/x3.json > /tmp/x4.json
    # Trojan
    jq --arg u "$uuid" --arg e "$user" \
       '.inbounds[4].settings.clients += [{"password":$u,"email":$e}]' \
       /tmp/x4.json > "$XRAY_CONF"
    rm -f /tmp/x{1..4}.json
    systemctl restart xray
}

del_xray_user() {
    local uuid=$1
    local tmp="$XRAY_CONF"
    for i in 0 1 2 3; do
        jq --arg u "$uuid" \
           "del(.inbounds[$i].settings.clients[] | select(.id == \$u))" \
           "$tmp" > /tmp/xdel.json && mv /tmp/xdel.json "$tmp"
    done
    jq --arg u "$uuid" \
       'del(.inbounds[4].settings.clients[] | select(.password == $u))' \
       "$tmp" > /tmp/xdel.json && mv /tmp/xdel.json "$tmp"
    systemctl restart xray
}

show_user_links() {
    local user=$1 uuid=$2 expiry=$3
    sep2
    echo -e "  ${W}📱 LINKS DE CONEXIÓN — $user${NC}"
    sep2
    # VLESS TCP
    echo -e "  ${Y}[VLESS TCP]:${NC}"
    echo -e "  vless://${uuid}@${MYIP}:443?type=tcp&security=none#NEXUS-${user}"
    echo ""
    # VMess WS
    local ws_b64=$(echo -n "{\"v\":\"2\",\"ps\":\"WS-${user}\",\"add\":\"${MYIP}\",\"port\":\"80\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/nexus\",\"type\":\"none\"}" | base64 -w0)
    echo -e "  ${Y}[VMess WS]:${NC}"
    echo -e "  vmess://${ws_b64}"
    echo ""
    # VMess KCP
    local kcp_b64=$(echo -n "{\"v\":\"2\",\"ps\":\"KCP-${user}\",\"add\":\"${MYIP}\",\"port\":\"1194\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"kcp\",\"type\":\"none\",\"seed\":\"nexusvpn\"}" | base64 -w0)
    echo -e "  ${Y}[VMess KCP]:${NC}"
    echo -e "  vmess://${kcp_b64}"
    echo ""
    # Trojan
    echo -e "  ${Y}[Trojan]:${NC}"
    echo -e "  trojan://${uuid}@${MYIP}:2083?security=none#NEXUS-${user}"
    echo ""
    # SS
    local ss_b64=$(echo -n "chacha20-ietf-poly1305:nexusvpn2024" | base64 -w0)
    echo -e "  ${Y}[Shadowsocks]:${NC}"
    echo -e "  ss://${ss_b64}@${MYIP}:8388#NEXUS-${user}"
    echo ""
    echo -e "  ${Y}Expira:${NC} ${W}$expiry${NC}"
    # Guardar archivo
    local outf="/root/nexus-${user}-$(date +%Y%m%d).txt"
    {
        echo "=== NexusVPN Pro === Usuario: $user === Expira: $expiry ==="
        echo "VLESS:  vless://${uuid}@${MYIP}:443?type=tcp&security=none#NEXUS-${user}"
        echo "VMess:  vmess://${ws_b64}"
        echo "KCP:    vmess://${kcp_b64}"
        echo "Trojan: trojan://${uuid}@${MYIP}:2083?security=none#NEXUS-${user}"
        echo "SS:     ss://${ss_b64}@${MYIP}:8388#NEXUS-${user}"
    } > "$outf"
    echo -e "  ${G}Guardado en: $outf${NC}"
    sep2
}

menu_usuarios() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ GESTIÓN DE USUARIOS V2RAY ════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Crear usuario"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Listar usuarios"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Ver links de usuario"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Renovar usuario"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Eliminar usuario"
        echo -e "  ${C}║${NC}  ${Y}6)${NC}  Limpiar expirados"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1)
                read -p "  Nombre usuario: " user
                read -p "  Días de acceso [30]: " dias; dias=${dias:-30}
                local uuid=$(cat /proc/sys/kernel/random/uuid)
                local expiry=$(date -d "+${dias} days" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
                            || date -v "+${dias}d" '+%Y-%m-%d %H:%M:%S')
                add_xray_user "$user" "$uuid"
                echo "${user}|${uuid}|$(date '+%Y-%m-%d %H:%M:%S')|${expiry}|0" >> "$USERS_DB"
                show_user_links "$user" "$uuid" "$expiry"
                pause ;;
            2) list_users; pause ;;
            3)
                read -p "  Nombre usuario: " user
                local line=$(grep "^${user}|" "$USERS_DB")
                if [[ -z "$line" ]]; then err "Usuario no encontrado"; else
                    local uuid=$(echo "$line" | cut -d'|' -f2)
                    local expiry=$(echo "$line" | cut -d'|' -f4)
                    show_user_links "$user" "$uuid" "$expiry"
                fi; pause ;;
            4)
                read -p "  Nombre usuario: " user
                read -p "  Días adicionales: " dias
                local line=$(grep "^${user}|" "$USERS_DB")
                if [[ -z "$line" ]]; then err "Usuario no encontrado"; else
                    local uuid=$(echo "$line" | cut -d'|' -f2)
                    local new_exp=$(date -d "+${dias} days" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
                                 || date -v "+${dias}d" '+%Y-%m-%d %H:%M:%S')
                    sed -i "s/^${user}|\([^|]*\)|\([^|]*\)|[^|]*|/${user}|\1|\2|${new_exp}|/" "$USERS_DB"
                    ok "Usuario $user renovado hasta: $new_exp"
                fi; pause ;;
            5)
                read -p "  Nombre usuario a eliminar: " user
                local uuid=$(grep "^${user}|" "$USERS_DB" | cut -d'|' -f2)
                if [[ -z "$uuid" ]]; then err "No encontrado"; else
                    del_xray_user "$uuid"
                    sed -i "/^${user}|/d" "$USERS_DB"
                    ok "Usuario $user eliminado"
                fi; pause ;;
            6) cleanup_expired; pause ;;
            0) break ;;
        esac
    done
}

list_users() {
    sep2
    printf "  ${C}%-20s %-22s %-22s${NC}\n" "USUARIO" "CREADO" "EXPIRA"
    sep2
    while IFS='|' read -r user uuid created expiry gb; do
        local now=$(date '+%Y-%m-%d %H:%M:%S')
        local col="${G}"; [[ "$now" > "$expiry" ]] && col="${R}"
        printf "  ${col}%-20s %-22s %-22s${NC}\n" "$user" "$created" "$expiry"
    done < "$USERS_DB"
    sep2
}

cleanup_expired() {
    local count=0
    while IFS='|' read -r user uuid created expiry gb; do
        local now=$(date '+%Y-%m-%d %H:%M:%S')
        if [[ "$now" > "$expiry" ]]; then
            del_xray_user "$uuid" 2>/dev/null
            sed -i "/^${user}|/d" "$USERS_DB"
            ((count++))
        fi
    done < "$USERS_DB"
    ok "Expirados eliminados: $count"
}

# ════════════════════════════════════════════════════════════
#  HYSTERIA2 - USUARIOS
# ════════════════════════════════════════════════════════════
menu_hysteria() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ HYSTERIA2 ════════════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Crear usuario Hysteria2"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Eliminar usuario"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Ver config cliente"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Reiniciar Hysteria2"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1)
                read -p "  Usuario: " user
                read -p "  Contraseña [auto]: " pass
                [[ -z "$pass" ]] && pass=$(openssl rand -hex 8)
                python3 -c "
import yaml, sys
with open('/etc/hysteria/config.yaml') as f: c=yaml.safe_load(f)
c['auth']['userpass']['$user']='$pass'
with open('/etc/hysteria/config.yaml','w') as f: yaml.dump(c,f,allow_unicode=True)
print('OK')"
                systemctl restart hysteria-server
                sep2
                echo -e "  ${G}Usuario Hysteria2 creado:${NC}"
                echo -e "  ${Y}Usuario:${NC} $user  ${Y}Contraseña:${NC} $pass"
                local obfs=$(cat /etc/hysteria/obfs.key)
                echo -e "\n  ${Y}Config cliente:${NC}"
                echo "  server: $MYIP:36712"
                echo "  auth: $user:$pass"
                echo "  obfs:"
                echo "    type: salamander"
                echo "    salamander:"
                echo "      password: $obfs"
                echo "  tls:"
                echo "    insecure: true"
                sep2; pause ;;
            2)
                read -p "  Usuario a eliminar: " user
                python3 -c "
import yaml
with open('/etc/hysteria/config.yaml') as f: c=yaml.safe_load(f)
c['auth']['userpass'].pop('$user', None)
with open('/etc/hysteria/config.yaml','w') as f: yaml.dump(c,f,allow_unicode=True)"
                systemctl restart hysteria-server
                ok "Usuario $user eliminado"; pause ;;
            3)
                local obfs=$(cat /etc/hysteria/obfs.key)
                echo -e "\n  ${Y}Hysteria2 obfs key:${NC} $obfs"
                echo -e "  ${Y}Servidor:${NC} $MYIP:36712"; pause ;;
            4) systemctl restart hysteria-server; ok "Hysteria2 reiniciado"; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  UDP CUSTOM
# ════════════════════════════════════════════════════════════
menu_udp() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ UDP CUSTOM / BADVPN ═════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Abrir puerto UDP (socat)"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Cerrar puerto UDP"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Listar puertos UDP activos"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Abrir rango de puertos UDP"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Estado BadVPN"
        echo -e "  ${C}║${NC}  ${Y}6)${NC}  Reiniciar BadVPN"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1)
                read -p "  Puerto UDP a abrir: " port
                echo -e "  ${Y}Destino:${NC} 1)DNS Google  2)DNS CF  3)BadVPN local  4)Custom"
                read -p "  [1-4]: " d
                case $d in
                    1) dest="8.8.8.8:53" ;;
                    2) dest="1.1.1.1:53" ;;
                    3) dest="127.0.0.1:7300" ;;
                    4) read -p "  IP:Puerto: " dest ;;
                esac
                cat > "/etc/systemd/system/udp-${port}.service" << EOF
[Unit]
Description=UDP proxy :${port}
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/socat -T120 UDP4-LISTEN:${port},fork,reuseaddr UDP4:${dest}
Restart=always
RestartSec=3
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload
                systemctl enable "udp-${port}" -q
                systemctl start "udp-${port}"
                ufw allow "${port}/udp" >/dev/null
                ok "Puerto UDP $port → $dest activo"; pause ;;
            2)
                read -p "  Puerto a cerrar: " port
                systemctl stop "udp-${port}" && systemctl disable "udp-${port}" -q
                rm -f "/etc/systemd/system/udp-${port}.service"
                ufw delete allow "${port}/udp" >/dev/null
                ok "Puerto $port cerrado"; pause ;;
            3)
                sep2
                systemctl list-units --type=service --state=running 2>/dev/null | grep "udp-"
                sep2; pause ;;
            4)
                read -p "  Puerto inicio: " p1; read -p "  Puerto fin: " p2
                read -p "  Destino [8.8.8.8:53]: " dest; dest=${dest:-"8.8.8.8:53"}
                for p in $(seq $p1 $p2); do
                    socat -T120 "UDP4-LISTEN:${p},fork,reuseaddr" "UDP4:${dest}" &
                done
                ufw allow "${p1}:${p2}/udp" >/dev/null
                ok "Rango $p1-$p2 → $dest activo"; pause ;;
            5)
                for p in 7100 7200 7300; do
                    status=$(systemctl is-active "badvpn-${p}" 2>/dev/null)
                    echo -e "  BadVPN :$p → $status"
                done; pause ;;
            6)
                for p in 7100 7200 7300; do systemctl restart "badvpn-${p}"; done
                ok "BadVPN reiniciado"; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  SLOWDNS
# ════════════════════════════════════════════════════════════
menu_slowdns() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ SLOWDNS ══════════════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Ver clave pública"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Regenerar claves"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Cambiar puerto SlowDNS"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Reiniciar SlowDNS"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Ver logs"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1)
                sep2
                echo -e "  ${Y}Public Key:${NC}"
                cat "$PANEL_DIR/slowdns_pubkey.txt" 2>/dev/null
                echo -e "\n  ${Y}Servidor:${NC} $MYIP:5300 UDP"
                sep2; pause ;;
            2)
                cd "$SDNS_DIR"
                rm -f server.key server.pub
                "$SDNS_DIR/dnstt-server" -gen-key -privkey server.key -pubkey server.pub
                cp server.pub "$PANEL_DIR/slowdns_pubkey.txt"
                systemctl restart slowdns
                ok "Claves regeneradas"; pause ;;
            3)
                read -p "  Nuevo puerto UDP [actual 5300]: " port
                sed -i "s/-udp :[0-9]*/-udp :${port}/" /etc/systemd/system/slowdns.service
                systemctl daemon-reload && systemctl restart slowdns
                ufw allow "${port}/udp" >/dev/null
                ok "Puerto cambiado a $port"; pause ;;
            4) systemctl restart slowdns; ok "SlowDNS reiniciado"; pause ;;
            5) journalctl -u slowdns -n 30 --no-pager; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  CLOUDFLARE / DNS
# ════════════════════════════════════════════════════════════
menu_cloudflare() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ CLOUDFLARE / DNS ════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Configurar dominio con Cloudflare"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Instalar certificado SSL (Let's Encrypt)"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Cambiar DNS del servidor"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Activar WebSocket por dominio (Nginx)"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Ver configuración actual"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1)
                sep2
                echo -e "  ${Y}Pasos para Cloudflare:${NC}"
                echo -e "  1. Entra a dash.cloudflare.com"
                echo -e "  2. Agrega tu dominio"
                echo -e "  3. Crea registro A apuntando a ${W}$MYIP${NC}"
                echo -e "  4. Activa el proxy naranja (CDN)"
                echo -e "  5. Usa el dominio en lugar de la IP en los configs"
                read -p "  Ingresa tu dominio (ej: vpn.midominio.com): " domain
                echo "$domain" > "$PANEL_DIR/domain.txt"
                ok "Dominio guardado: $domain"
                sep2; pause ;;
            2)
                local domain=$(cat "$PANEL_DIR/domain.txt" 2>/dev/null)
                [[ -z "$domain" ]] && read -p "  Dominio: " domain
                apt-get install -y -qq certbot 2>/dev/null
                certbot certonly --standalone -d "$domain" --non-interactive \
                    --agree-tos --email admin@"$domain" 2>&1 | tail -5
                ok "Certificado en /etc/letsencrypt/live/$domain/"
                pause ;;
            3)
                echo -e "  ${Y}1)${NC} Google (8.8.8.8)  ${Y}2)${NC} Cloudflare (1.1.1.1)  ${Y}3)${NC} Custom"
                read -p "  [1-3]: " d
                case $d in
                    1) dns="8.8.8.8\nnameserver 8.8.4.4" ;;
                    2) dns="1.1.1.1\nnameserver 1.0.0.1" ;;
                    3) read -p "  DNS primario: " dns1; read -p "  DNS secundario: " dns2
                       dns="${dns1}\nnameserver ${dns2}" ;;
                esac
                echo -e "nameserver $dns" > /etc/resolv.conf
                ok "DNS actualizado"; pause ;;
            4)
                local domain=$(cat "$PANEL_DIR/domain.txt" 2>/dev/null)
                [[ -z "$domain" ]] && read -p "  Dominio: " domain
                apt-get install -y -qq nginx 2>/dev/null
                cat > "/etc/nginx/sites-available/nexusvpn" << NGCFG
server {
    listen 80;
    server_name $domain;
    location /nexus {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
NGCFG
                ln -sf /etc/nginx/sites-available/nexusvpn /etc/nginx/sites-enabled/
                nginx -t && systemctl reload nginx
                ok "WebSocket configurado para $domain"; pause ;;
            5)
                echo -e "  ${Y}Dominio:${NC} $(cat $PANEL_DIR/domain.txt 2>/dev/null || echo 'No configurado')"
                echo -e "  ${Y}DNS activo:${NC} $(cat /etc/resolv.conf | grep nameserver | head -2)"
                pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  BANNER PUBLICITARIO
# ════════════════════════════════════════════════════════════
menu_banner() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ BANNER PUBLICITARIO ════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Editar banner"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Ver banner actual"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Limpiar banner"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Editar contactos (WhatsApp/Telegram/etc)"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1)
                echo -e "\n  ${Y}Escribe el texto del banner (Enter dos veces para terminar):${NC}"
                echo -e "  ${C}Puedes usar varias líneas. Ctrl+D para guardar.${NC}\n"
                cat > "$BANNER_FILE"
                ok "Banner actualizado"; pause ;;
            2)
                sep2
                cat "$BANNER_FILE" 2>/dev/null || echo "  (vacío)"
                sep2; pause ;;
            3)
                > "$BANNER_FILE"
                ok "Banner limpiado"; pause ;;
            4)
                sep2
                echo -e "  ${Y}Contactos actuales:${NC}"
                cat "$CONTACTS_FILE" 2>/dev/null
                sep2
                echo -e "\n  Edita cada campo (Enter para conservar actual):"
                for field in WhatsApp Telegram Instagram Canal; do
                    current=$(grep "^${field}=" "$CONTACTS_FILE" 2>/dev/null | cut -d'=' -f2)
                    read -p "  $field [$current]: " val
                    [[ -n "$val" ]] && sed -i "s/^${field}=.*/${field}=${val}/" "$CONTACTS_FILE"
                done
                ok "Contactos actualizados"; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  ESTADÍSTICAS
# ════════════════════════════════════════════════════════════
menu_stats() {
    show_banner
    echo -e "  ${W}╔══ ESTADÍSTICAS DEL SERVIDOR ══════════════════════╗${NC}"
    sep2
    echo -e "  ${Y}Sistema:${NC}"
    echo -e "    SO      : $(. /etc/os-release && echo "$PRETTY_NAME")"
    echo -e "    Kernel  : $(uname -r)"
    echo -e "    Uptime  : $(uptime -p)"
    echo -e "    CPU     : $(nproc) cores  |  Load: $(cat /proc/loadavg | cut -d' ' -f1-3)"
    echo -e "    RAM     : $(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
    echo -e "    Disco   : $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
    sep2
    echo -e "  ${Y}Tráfico de red:${NC}"
    local iface=$(ip route | grep default | awk '{print $5}' | head -1)
    local rx=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo 0)
    local tx=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null || echo 0)
    echo -e "    Interfaz: $iface"
    echo -e "    RX      : $(echo "$rx / 1024 / 1024" | bc) MB"
    echo -e "    TX      : $(echo "$tx / 1024 / 1024" | bc) MB"
    sep2
    echo -e "  ${Y}Servicios:${NC}"
    for svc in xray hysteria-server slowdns nginx; do
        status=$(systemctl is-active "$svc" 2>/dev/null)
        [[ "$status" == "active" ]] && col="${G}" || col="${R}"
        printf "    ${col}%-20s %s${NC}\n" "$svc" "$status"
    done
    sep2
    echo -e "  ${Y}Puertos escuchando:${NC}"
    ss -tulpn 2>/dev/null | grep -E ':(80|443|1194|2083|5300|8080|8388|8443|36712|7[123]00)' \
    | awk '{printf "    %-8s %s\n", $1, $5}' | sort -u
    sep2
    echo -e "  ${Y}Usuarios V2Ray:${NC} $(get_users_count)"
    echo -e "  ${Y}Licencia hasta:${NC} $(get_server_key_expiry)"
    sep
    pause
}

# ════════════════════════════════════════════════════════════
#  FIREWALL
# ════════════════════════════════════════════════════════════
menu_firewall() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ FIREWALL ════════════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Ver reglas activas"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Abrir puerto"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Cerrar puerto"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Abrir rango de puertos"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Reiniciar firewall completo"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1) ufw status numbered; pause ;;
            2)
                read -p "  Puerto (ej: 9000 o 9000/udp): " port
                ufw allow "$port"; ok "Puerto $port abierto"; pause ;;
            3)
                read -p "  Puerto a cerrar: " port
                ufw delete allow "$port"; ok "Puerto $port cerrado"; pause ;;
            4)
                read -p "  Puerto inicio: " p1; read -p "  Puerto fin: " p2
                read -p "  Protocolo [tcp/udp/both]: " proto
                [[ "$proto" == "both" || -z "$proto" ]] && { ufw allow "${p1}:${p2}/tcp"; ufw allow "${p1}:${p2}/udp"; } \
                || ufw allow "${p1}:${p2}/${proto}"
                ok "Rango ${p1}-${p2} abierto"; pause ;;
            5)
                ufw --force reset
                ufw default deny incoming && ufw default allow outgoing
                for p in 22/tcp 80/tcp 443/tcp 1194/udp 2083/tcp 5300/udp \
                          8080/tcp 8388/tcp 8443/tcp 36712/udp 53/udp 7100:7300/udp; do
                    ufw allow $p >/dev/null
                done
                echo "y" | ufw enable >/dev/null
                ok "Firewall reiniciado con reglas por defecto"; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  SERVICIOS
# ════════════════════════════════════════════════════════════
menu_servicios() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ SERVICIOS ═══════════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Reiniciar TODOS"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Reiniciar Xray"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Reiniciar Hysteria2"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Reiniciar SlowDNS"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Reiniciar BadVPN"
        echo -e "  ${C}║${NC}  ${Y}6)${NC}  Ver logs Xray"
        echo -e "  ${C}║${NC}  ${Y}7)${NC}  Ver logs Hysteria2"
        echo -e "  ${C}║${NC}  ${Y}8)${NC}  Ver logs SlowDNS"
        echo -e "  ${C}║${NC}  ${Y}9)${NC}  Verificar config Xray"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1)
                for s in xray hysteria-server slowdns badvpn-7100 badvpn-7200 badvpn-7300; do
                    systemctl restart "$s" 2>/dev/null
                done
                ok "Todos los servicios reiniciados"; pause ;;
            2) systemctl restart xray; ok "Xray reiniciado"; pause ;;
            3) systemctl restart hysteria-server; ok "Hysteria2 reiniciado"; pause ;;
            4) systemctl restart slowdns; ok "SlowDNS reiniciado"; pause ;;
            5)
                for p in 7100 7200 7300; do systemctl restart "badvpn-${p}"; done
                ok "BadVPN reiniciado"; pause ;;
            6) journalctl -u xray -n 50 --no-pager; pause ;;
            7) journalctl -u hysteria-server -n 50 --no-pager; pause ;;
            8) journalctl -u slowdns -n 50 --no-pager; pause ;;
            9) xray -test -config "$XRAY_CONF" 2>&1; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  MENÚ PRINCIPAL
# ════════════════════════════════════════════════════════════
main_menu() {
    # Si no está activado, pedir key primero
    if ! check_server_activated; then
        clear
        echo -e "${B}${BOLD}"
        echo "  ╔══════════════════════════════════════════════════════╗"
        echo "  ║         NexusVPN Pro - ACTIVACIÓN REQUERIDA         ║"
        echo "  ╚══════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        echo -e "  ${Y}Este servidor necesita una KEY de licencia para funcionar.${NC}"
        echo -e "  ${C}Contacta al proveedor para obtener tu key.${NC}\n"
        read -p "  Ingresa tu KEY de licencia: " key
        activate_server "$key"
        check_server_activated || { err "Key inválida. Saliendo."; exit 1; }
    fi

    while true; do
        show_banner
        echo -e "  ${W}╔══ MENÚ PRINCIPAL ══════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y} 1)${NC}  🔑  Keys del servidor"
        echo -e "  ${C}║${NC}  ${Y} 2)${NC}  👥  Usuarios V2Ray / Xray"
        echo -e "  ${C}║${NC}  ${Y} 3)${NC}  ⚡  Hysteria2"
        echo -e "  ${C}║${NC}  ${Y} 4)${NC}  🌀  SlowDNS"
        echo -e "  ${C}║${NC}  ${Y} 5)${NC}  📡  UDP Custom / BadVPN"
        echo -e "  ${C}║${NC}  ${Y} 6)${NC}  ☁️   Cloudflare / Dominio / DNS"
        echo -e "  ${C}║${NC}  ${Y} 7)${NC}  📢  Banner & Contactos"
        echo -e "  ${C}║${NC}  ${Y} 8)${NC}  📊  Estadísticas del servidor"
        echo -e "  ${C}║${NC}  ${Y} 9)${NC}  🔥  Firewall"
        echo -e "  ${C}║${NC}  ${Y}10)${NC}  ⚙️   Servicios / Logs"
        echo -e "  ${C}║${NC}  ${Y}11)${NC}  🔄  Actualizar panel"
        echo -e "  ${C}║${NC}  ${Y} 0)${NC}  🚪  Salir"
        echo -e "  ${W}╚════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "  Opción [0-11]: " opt
        case $opt in
            1)  menu_keys ;;
            2)  menu_usuarios ;;
            3)  menu_hysteria ;;
            4)  menu_slowdns ;;
            5)  menu_udp ;;
            6)  menu_cloudflare ;;
            7)  menu_banner ;;
            8)  menu_stats ;;
            9)  menu_firewall ;;
            10) menu_servicios ;;
            11)
                inf "Actualizando panel..."
                curl -fsSL \
                    "https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh" \
                    -o "$PANEL_BIN" && chmod +x "$PANEL_BIN"
                ok "Panel actualizado. Reiniciando..."
                sleep 1; exec "$PANEL_BIN" ;;
            0)  echo -e "\n  ${G}¡Hasta luego!${NC}\n"; exit 0 ;;
            *)  warn "Opción inválida"; sleep 1 ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  PUNTO DE ENTRADA
# ════════════════════════════════════════════════════════════
check_root

case "$1" in
    --install)  install_silent ;;
    --cleanup)  cleanup_expired ;;
    --menu)     main_menu ;;
    *)
        # Primera vez: instalar si no existe panel
        if [[ ! -f "$PANEL_BIN" || ! -d "$PANEL_DIR" ]]; then
            install_silent
        fi
        main_menu
        ;;
esac


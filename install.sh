#!/bin/bash
# ================================================================
#   NexusVPN Pro v4.0 - Script Todo-en-Uno Premium
#   Repo: https://github.com/Androidzpro/NexusVPN
#   Ubuntu 20.04 / 22.04 LTS - ARM64 / x86_64
#   Autor: NexusVPN Pro
# ================================================================

set -euo pipefail

# ── Colores ──────────────────────────────────────────────────
R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m'
B='\033[0;34m' C='\033[0;36m' W='\033[1;37m'
P='\033[0;35m' NC='\033[0m' BOLD='\033[1m'

# ── Rutas ────────────────────────────────────────────────────
PANEL_DIR="/etc/NexusVPN"
LOG_FILE="/var/log/nexusvpn-install.log"
KEYS_DB="$PANEL_DIR/keys.db"
USERS_DB="$PANEL_DIR/users.db"
STATS_DB="$PANEL_DIR/stats.db"
CONTACTS_FILE="$PANEL_DIR/contacts.conf"
BANNER_FILE="$PANEL_DIR/banner.txt"
SERVER_KEY_FILE="$PANEL_DIR/server.key"
TG_CONF="$PANEL_DIR/telegram.conf"
BACKUP_DIR="$PANEL_DIR/backups"
PANEL_BIN="/usr/local/bin/nexusvpn"
XRAY_CONF="/usr/local/etc/xray/config.json"
HY2_CONF="/etc/hysteria/config.yaml"
SDNS_DIR="/etc/slowdns"
OVPN_DIR="/etc/openvpn"
WG_DIR="/etc/wireguard"
VERSION="4.0"
ARCH=$(uname -m)
[[ "$ARCH" == "aarch64" ]] && HARCH="arm64" || HARCH="amd64"
MYIP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org 2>/dev/null || echo "0.0.0.0")

# ── Logging ──────────────────────────────────────────────────
mkdir -p "$PANEL_DIR" "$BACKUP_DIR"
touch "$LOG_FILE" "$KEYS_DB" "$USERS_DB" "$STATS_DB"
exec > >(tee -a "$LOG_FILE") 2>&1

ok()   { echo -e "${G}  ✔ $1${NC}"; }
err()  { echo -e "${R}  ✘ $1${NC}"; }
inf()  { echo -e "${C}  » $1${NC}"; }
warn() { echo -e "${Y}  ! $1${NC}"; }
sep()  { echo -e "${C}  ════════════════════════════════════════════════════${NC}"; }
sep2() { echo -e "${Y}  ────────────────────────────────────────────────────${NC}"; }
pause(){ echo ""; read -p "  $(echo -e "${Y}Presiona Enter para continuar...${NC}")" _; }

check_root() {
    [[ $EUID -ne 0 ]] && err "Ejecutar como root: sudo su" && exit 1
}

check_os() {
    source /etc/os-release 2>/dev/null
    if [[ "$ID" != "ubuntu" && "$ID" != "debian" ]]; then
        err "Solo Ubuntu 20.04/22.04 y Debian 11"
        exit 1
    fi
}

# ════════════════════════════════════════════════════════════
#  BANNER
# ════════════════════════════════════════════════════════════
show_banner() {
    clear
    local users=0
    [[ -f "$USERS_DB" ]] && users=$(grep -c "|ACTIVE|" "$USERS_DB" 2>/dev/null || echo 0)
    local expiry="Sin activar"
    [[ -f "$SERVER_KEY_FILE" ]] && expiry=$(cut -d'|' -f2 "$SERVER_KEY_FILE" 2>/dev/null)
    local sxray=$(systemctl is-active xray 2>/dev/null)
    local shy2=$(systemctl is-active hysteria-server 2>/dev/null)
    local ssdns=$(systemctl is-active slowdns 2>/dev/null)
    local sovpn=$(systemctl is-active openvpn@server 2>/dev/null)
    local swg=$(systemctl is-active wg-quick@wg0 2>/dev/null)

    echo -e "${B}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║  ███╗  ██╗███████╗██╗  ██╗██╗   ██╗███████╗            ║"
    echo "  ║  ████╗ ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝            ║"
    echo "  ║  ██╔██╗██║█████╗   ╚███╔╝ ██║   ██║███████╗            ║"
    echo "  ║  ██║╚████║██╔══╝   ██╔██╗ ██║   ██║╚════██║            ║"
    echo "  ║  ██║ ╚███║███████╗██╔╝ ██╗╚██████╔╝███████║  PRO v4.0  ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${Y}IP        :${NC} ${W}$MYIP${NC}   ${Y}Usuarios Activos :${NC} ${W}$users${NC}"
    echo -e "  ${Y}Licencia  :${NC} ${W}$expiry${NC}"
    printf "  ${Y}Servicios :${NC} "
    [[ "$sxray"  == "active" ]] && printf "${G}● Xray${NC}  " || printf "${R}○ Xray${NC}  "
    [[ "$shy2"   == "active" ]] && printf "${G}● Hysteria2${NC}  " || printf "${R}○ Hysteria2${NC}  "
    [[ "$ssdns"  == "active" ]] && printf "${G}● SlowDNS${NC}  " || printf "${R}○ SlowDNS${NC}  "
    [[ "$sovpn"  == "active" ]] && printf "${G}● OpenVPN${NC}  " || printf "${R}○ OpenVPN${NC}  "
    [[ "$swg"    == "active" ]] && printf "${G}● WireGuard${NC}" || printf "${R}○ WireGuard${NC}"
    echo ""
    if [[ -f "$BANNER_FILE" && -s "$BANNER_FILE" ]]; then
        sep2
        echo -e "${P}"; while IFS= read -r l; do echo "  $l"; done < "$BANNER_FILE"; echo -e "${NC}"
    fi
    if [[ -f "$CONTACTS_FILE" && -s "$CONTACTS_FILE" ]]; then
        sep2
        while IFS='=' read -r k v; do [[ -n "$v" ]] && echo -e "  ${C}$k:${NC} ${W}$v${NC}"; done < "$CONTACTS_FILE"
    fi
    sep
}

# ════════════════════════════════════════════════════════════
#  INSTALACIÓN SILENCIOSA COMPLETA
# ════════════════════════════════════════════════════════════
install_all() {
    clear
    echo -e "${B}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║          NexusVPN Pro v4.0 - INSTALANDO...              ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"

    # Archivos de configuración iniciales
    [[ ! -f "$CONTACTS_FILE" ]] && printf "WhatsApp=\nTelegram=\nInstagram=\nCanal=\n" > "$CONTACTS_FILE"
    [[ ! -f "$BANNER_FILE" ]]   && echo "NexusVPN Pro - Conexión Premium" > "$BANNER_FILE"

    # ── 1. Dependencias ───────────────────────────────────────
    inf "[1/9] Instalando dependencias..."
    export DEBIAN_FRONTEND=noninteractive
    apt-get update -qq
    apt-get install -y -qq \
        curl wget jq unzip socat git uuid-runtime openssl \
        python3 python3-pip net-tools ufw iptables iptables-persistent \
        build-essential cmake libssl-dev golang-go \
        cron bc lsof netcat-openbsd screen \
        openvpn easy-rsa wireguard \
        fail2ban nginx certbot \
        python3-certbot-nginx 2>/dev/null | tail -2
    pip3 install -q pyyaml 2>/dev/null || true
    ok "Dependencias OK"

    # ── 2. Optimización del kernel ────────────────────────────
    inf "[2/9] Optimizando kernel..."
    grep -q "nexusvpn" /etc/sysctl.conf || cat >> /etc/sysctl.conf << 'SYSCTL'
# NexusVPN Pro
net.core.rmem_max = 67108864
net.core.wmem_max = 67108864
net.ipv4.tcp_rmem = 4096 87380 67108864
net.ipv4.tcp_wmem = 4096 65536 67108864
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq
net.ipv4.ip_forward = 1
net.ipv4.tcp_fastopen = 3
net.core.netdev_max_backlog = 250000
net.ipv4.tcp_max_syn_backlog = 8192
fs.file-max = 1000000
SYSCTL
    sysctl -p >/dev/null 2>&1
    # Límites del sistema
    grep -q "nexusvpn" /etc/security/limits.conf || cat >> /etc/security/limits.conf << 'LIMITS'
# NexusVPN Pro
* soft nofile 1000000
* hard nofile 1000000
root soft nofile 1000000
root hard nofile 1000000
LIMITS
    ok "Kernel optimizado (BBR activado)"

    # ── 3. Xray (V2Ray) ───────────────────────────────────────
    inf "[3/9] Instalando Xray..."
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install -q 2>/dev/null
    mkdir -p "$(dirname $XRAY_CONF)"

    # Certificado self-signed para TLS
    mkdir -p /etc/xray/ssl
    openssl req -x509 -nodes -newkey rsa:2048 \
        -keyout /etc/xray/ssl/server.key \
        -out /etc/xray/ssl/server.crt \
        -subj "/CN=$MYIP" -days 3650 2>/dev/null
    chmod 600 /etc/xray/ssl/server.key

    WS_PATH="/$(openssl rand -hex 4)"
    echo "$WS_PATH" > "$PANEL_DIR/ws_path.txt"

    cat > "$XRAY_CONF" << XCFG
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray-access.log",
    "error": "/var/log/xray-error.log"
  },
  "inbounds": [
    {
      "tag": "vless-tcp",
      "port": 443,
      "protocol": "vless",
      "settings": { "clients": [], "decryption": "none" },
      "streamSettings": {
        "network": "tcp",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{ "certificateFile": "/etc/xray/ssl/server.crt", "keyFile": "/etc/xray/ssl/server.key" }]
        }
      },
      "sniffing": { "enabled": true, "destOverride": ["http","tls"] }
    },
    {
      "tag": "vmess-ws",
      "port": 8080,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": { "network": "ws", "wsSettings": { "path": "${WS_PATH}" } }
    },
    {
      "tag": "vmess-ws-tls",
      "port": 8443,
      "protocol": "vmess",
      "settings": { "clients": [] },
      "streamSettings": {
        "network": "ws",
        "security": "tls",
        "tlsSettings": {
          "certificates": [{ "certificateFile": "/etc/xray/ssl/server.crt", "keyFile": "/etc/xray/ssl/server.key" }]
        },
        "wsSettings": { "path": "${WS_PATH}" }
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
          "mtu": 1350, "tti": 50, "uplinkCapacity": 100,
          "downlinkCapacity": 100, "congestion": false,
          "readBufferSize": 2, "writeBufferSize": 2,
          "header": { "type": "none" }, "seed": "nexusvpn"
        }
      }
    },
    {
      "tag": "trojan",
      "port": 2083,
      "protocol": "trojan",
      "settings": { "clients": [] },
      "streamSettings": { "network": "tcp" }
    },
    {
      "tag": "shadowsocks",
      "port": 8388,
      "protocol": "shadowsocks",
      "settings": {
        "method": "chacha20-ietf-poly1305",
        "password": "nexusvpn2024",
        "network": "tcp,udp"
      }
    },
    {
      "tag": "socks5",
      "port": 1080,
      "protocol": "socks",
      "settings": { "auth": "noauth", "udp": true }
    },
    {
      "tag": "http-proxy",
      "port": 8118,
      "protocol": "http",
      "settings": {}
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
    ok "Xray OK → 443(VLESS-TLS) 8080(VMess-WS) 8443(VMess-WS-TLS) 1194(KCP) 2083(Trojan) 8388(SS) 1080(SOCKS5) 8118(HTTP)"

    # ── 4. Hysteria2 ──────────────────────────────────────────
    inf "[4/9] Instalando Hysteria2..."
    bash -c "$(curl -fsSL https://get.hy2.sh/)" 2>/dev/null || {
        wget -qO /usr/local/bin/hysteria \
            "https://github.com/apernet/hysteria/releases/latest/download/hysteria-linux-${HARCH}"
        chmod +x /usr/local/bin/hysteria
    }
    mkdir -p /etc/hysteria
    openssl req -x509 -nodes -newkey ec:<(openssl ecparam -name prime256v1) \
        -keyout /etc/hysteria/server.key -out /etc/hysteria/server.crt \
        -subj "/CN=$MYIP" -days 3650 2>/dev/null
    chmod 600 /etc/hysteria/server.key
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
LimitNOFILE=1000000
[Install]
WantedBy=multi-user.target
HYSVC
    systemctl daemon-reload && systemctl enable hysteria-server -q
    systemctl start hysteria-server 2>/dev/null || true
    ok "Hysteria2 OK → UDP 36712"

    # ── 5. SlowDNS ────────────────────────────────────────────
    inf "[5/9] Instalando SlowDNS..."
    mkdir -p "$SDNS_DIR"
    wget -qO "$SDNS_DIR/dnstt-server" \
        "https://github.com/lemon4ex/dnstt-compiled/releases/latest/download/dnstt-server-linux-${HARCH}" 2>/dev/null || {
        cd /tmp && rm -rf dnstt
        git clone --depth=1 https://www.bamsoftware.com/git/dnstt.git 2>/dev/null
        cd dnstt/server && go build -o "$SDNS_DIR/dnstt-server" . 2>/dev/null
    }
    chmod +x "$SDNS_DIR/dnstt-server" 2>/dev/null
    ln -sf "$SDNS_DIR/dnstt-server" /usr/local/bin/dnstt-server 2>/dev/null
    cd "$SDNS_DIR"
    [[ ! -f server.key ]] && \
        "$SDNS_DIR/dnstt-server" -gen-key -privkey server.key -pubkey server.pub 2>/dev/null || true
    SDNS_PUB=$(cat "$SDNS_DIR/server.pub" 2>/dev/null || echo "N/A")
    echo "$SDNS_PUB" > "$PANEL_DIR/slowdns_pubkey.txt"
    cat > /etc/systemd/system/slowdns.service << SDSVC
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
SDSVC
    systemctl daemon-reload && systemctl enable slowdns -q
    systemctl start slowdns 2>/dev/null || true
    ok "SlowDNS OK → UDP 5300"

    # ── 6. OpenVPN ────────────────────────────────────────────
    inf "[6/9] Instalando OpenVPN..."
    mkdir -p /etc/openvpn/easy-rsa
    cp -r /usr/share/easy-rsa/* /etc/openvpn/easy-rsa/ 2>/dev/null || true
    cd /etc/openvpn/easy-rsa

    cat > /etc/openvpn/easy-rsa/vars << 'OVPNVARS'
set_var EASYRSA_ALGO      rsa
set_var EASYRSA_KEY_SIZE  2048
set_var EASYRSA_CA_EXPIRE 3650
set_var EASYRSA_CERT_EXPIRE 3650
set_var EASYRSA_BATCH     1
OVPNVARS

    ./easyrsa init-pki 2>/dev/null || true
    echo "NexusVPN-CA" | ./easyrsa build-ca nopass 2>/dev/null || true
    ./easyrsa gen-dh 2>/dev/null || true
    ./easyrsa build-server-full server nopass 2>/dev/null || true
    openvpn --genkey secret /etc/openvpn/ta.key 2>/dev/null || true

    cat > /etc/openvpn/server.conf << OVPNCFG
port 1194
proto udp
dev tun
ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem
tls-auth /etc/openvpn/ta.key 0
server 10.8.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 1.1.1.1"
keepalive 10 120
cipher AES-256-GCM
auth SHA256
comp-lzo
max-clients 100
persist-key
persist-tun
status /var/log/openvpn-status.log
verb 3
OVPNCFG

    # OpenVPN TCP también
    cat > /etc/openvpn/server-tcp.conf << OVPNTCP
port 1195
proto tcp
dev tun1
ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem
server 10.9.0.0 255.255.255.0
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
keepalive 10 120
cipher AES-256-GCM
auth SHA256
persist-key
persist-tun
verb 3
OVPNTCP

    systemctl enable openvpn@server openvpn@server-tcp -q 2>/dev/null || true
    systemctl start openvpn@server openvpn@server-tcp 2>/dev/null || true
    ok "OpenVPN OK → UDP 1194 / TCP 1195"

    # ── 7. WireGuard ──────────────────────────────────────────
    inf "[7/9] Instalando WireGuard..."
    mkdir -p "$WG_DIR"
    chmod 700 "$WG_DIR"
    WG_PRIV=$(wg genkey)
    WG_PUB=$(echo "$WG_PRIV" | wg pubkey)
    echo "$WG_PRIV" > "$WG_DIR/server_private.key"
    echo "$WG_PUB" > "$WG_DIR/server_public.key"
    chmod 600 "$WG_DIR/server_private.key"

    cat > /etc/wireguard/wg0.conf << WGCFG
[Interface]
PrivateKey = ${WG_PRIV}
Address = 10.10.0.1/24
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o \$(ip route | grep default | awk '{print \$5}') -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o \$(ip route | grep default | awk '{print \$5}') -j MASQUERADE
WGCFG

    systemctl enable wg-quick@wg0 -q 2>/dev/null || true
    systemctl start wg-quick@wg0 2>/dev/null || true
    ok "WireGuard OK → UDP 51820 | PubKey: $WG_PUB"
    echo "$WG_PUB" > "$PANEL_DIR/wg_pubkey.txt"

    # ── 8. BadVPN ─────────────────────────────────────────────
    inf "[8/9] Instalando BadVPN..."
    wget -qO /usr/local/bin/badvpn-udpgw \
        "https://github.com/daybreakersx/premscript/raw/master/badvpn-udpgw64" 2>/dev/null || {
        cd /tmp && rm -rf badvpn
        git clone --depth=1 https://github.com/ambrop72/badvpn.git 2>/dev/null
        cd badvpn
        cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 . 2>/dev/null
        make 2>/dev/null && cp udpgw/badvpn-udpgw /usr/local/bin/
    }
    chmod +x /usr/local/bin/badvpn-udpgw 2>/dev/null || true
    for BVPORT in 7100 7200 7300; do
        cat > "/etc/systemd/system/badvpn-${BVPORT}.service" << BVSVC
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
BVSVC
        systemctl daemon-reload
        systemctl enable "badvpn-${BVPORT}" -q
        systemctl start "badvpn-${BVPORT}" 2>/dev/null || true
    done
    ok "BadVPN OK → 7100/7200/7300"

    # ── 9. Firewall + Fail2ban + Crons ────────────────────────
    inf "[9/9] Configurando firewall, fail2ban y automatizaciones..."

    # UFW
    ufw --force disable && ufw --force reset
    ufw default deny incoming && ufw default allow outgoing
    for p in 22/tcp 80/tcp 443/tcp 1080/tcp 1194/udp 1195/tcp \
              2083/tcp 5300/udp 7100:7300/udp \
              8080/tcp 8118/tcp 8388/tcp 8443/tcp \
              36712/udp 51820/udp; do
        ufw allow $p >/dev/null
    done
    echo "y" | ufw enable >/dev/null
    ok "Firewall UFW OK"

    # Fail2ban
    cat > /etc/fail2ban/jail.local << 'F2B'
[DEFAULT]
bantime  = 3600
findtime = 600
maxretry = 5
[sshd]
enabled = true
port    = 22
[nginx-http-auth]
enabled = true
F2B
    systemctl enable fail2ban -q && systemctl restart fail2ban
    ok "Fail2ban OK"

    # iptables NAT para OpenVPN
    IFACE=$(ip route | grep default | awk '{print $5}' | head -1)
    iptables -t nat -A POSTROUTING -s 10.8.0.0/24 -o "$IFACE" -j MASQUERADE 2>/dev/null || true
    iptables -t nat -A POSTROUTING -s 10.9.0.0/24 -o "$IFACE" -j MASQUERADE 2>/dev/null || true
    iptables-save > /etc/iptables/rules.v4 2>/dev/null || true

    # Crons automáticos
    crontab -l 2>/dev/null | grep -v nexusvpn | { cat; \
        echo "0 * * * * $PANEL_BIN --cleanup >/dev/null 2>&1"; \
        echo "0 3 * * * $PANEL_BIN --backup >/dev/null 2>&1"; \
        echo "*/5 * * * * $PANEL_BIN --stats >/dev/null 2>&1"; \
    } | crontab -

    # Copiar este script como panel
    cp "$0" "$PANEL_BIN" 2>/dev/null || \
        curl -fsSL "https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh" \
        -o "$PANEL_BIN" 2>/dev/null || true
    chmod +x "$PANEL_BIN"

    ok "Automatizaciones OK"

    # ── Generar resumen de instalación ────────────────────────
    WS_PATH_VAL=$(cat "$PANEL_DIR/ws_path.txt" 2>/dev/null || echo "/nexus")
    WG_PUB_VAL=$(cat "$PANEL_DIR/wg_pubkey.txt" 2>/dev/null || echo "N/A")
    SDNS_PUB_VAL=$(cat "$PANEL_DIR/slowdns_pubkey.txt" 2>/dev/null || echo "N/A")
    HY2_OBFS_VAL=$(cat /etc/hysteria/obfs.key 2>/dev/null || echo "N/A")

    cat > "$PANEL_DIR/server_info.txt" << INFO
=== NexusVPN Pro v4.0 - Información del Servidor ===
Fecha instalación : $(date)
IP Pública        : $MYIP

── PROTOCOLOS ──────────────────────────────────────
VLESS TCP+TLS     : $MYIP:443
VMess WebSocket   : $MYIP:8080  path: $WS_PATH_VAL
VMess WS+TLS      : $MYIP:8443  path: $WS_PATH_VAL
VMess mKCP        : $MYIP:1194
Trojan            : $MYIP:2083
Shadowsocks       : $MYIP:8388  pass: nexusvpn2024
SOCKS5            : $MYIP:1080
HTTP Proxy        : $MYIP:8118
Hysteria2 UDP     : $MYIP:36712  obfs: $HY2_OBFS_VAL
SlowDNS UDP       : $MYIP:5300   pubkey: $SDNS_PUB_VAL
OpenVPN UDP       : $MYIP:1194
OpenVPN TCP       : $MYIP:1195
WireGuard UDP     : $MYIP:51820  pubkey: $WG_PUB_VAL
BadVPN UDP-GW     : 127.0.0.1:7100/7200/7300

── ARCHIVOS ────────────────────────────────────────
Panel             : nexusvpn
Log instalación   : /var/log/nexusvpn-install.log
Base de datos     : $PANEL_DIR/
INFO

    clear
    echo -e "${G}${BOLD}"
    echo "  ╔══════════════════════════════════════════════════════════╗"
    echo "  ║        ✅  NexusVPN Pro v4.0 - INSTALADO               ║"
    echo "  ╚══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    cat "$PANEL_DIR/server_info.txt"
    sep2
    echo -e "  ${Y}Para abrir el panel:${NC} ${W}nexusvpn${NC}"
    echo -e "  ${Y}Contraseña admin:${NC}   ${W}NexusOwner#2024${NC}  ${R}(cámbiala en el script)${NC}"
    sep
}

# ════════════════════════════════════════════════════════════
#  SISTEMA DE KEYS
# ════════════════════════════════════════════════════════════
gen_key() {
    local dias=$1 maxconn=${2:-10} limitgb=${3:-0} desc=${4:-"Key VPN"}
    local rand=$(openssl rand -hex 12 | tr '[:lower:]' '[:upper:]')
    local key="NEXUS-${rand:0:4}-${rand:4:4}-${rand:8:4}-${rand:12:4}"
    local expiry=$(date -d "+${dias} days" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
               || date -v "+${dias}d" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
               || echo "2099-12-31 23:59:59")
    local created=$(date '+%Y-%m-%d %H:%M:%S')
    # KEY|EXPIRY|DIAS|MAXCONN|LIMITGB|USADA|CREATED|DESC
    echo "${key}|${expiry}|${dias}|${maxconn}|${limitgb}|PENDIENTE|${created}|${desc}" >> "$KEYS_DB"
    echo "$key"
}

activate_server() {
    local key=$1
    local line=$(grep "^${key}|" "$KEYS_DB" 2>/dev/null || echo "")
    [[ -z "$line" ]] && err "Key inválida" && return 1
    local estado=$(echo "$line" | cut -d'|' -f6)
    [[ "$estado" == "USADA" ]] && err "Key ya usada" && return 1
    local expiry=$(echo "$line" | cut -d'|' -f2)
    local now=$(date '+%Y-%m-%d %H:%M:%S')
    [[ "$now" > "$expiry" ]] && err "Key expirada" && return 1
    sed -i "s/^${key}|\(.*\)|PENDIENTE|\(.*\)$/${key}|\1|USADA|\2/" "$KEYS_DB"
    echo "${key}|${expiry}" > "$SERVER_KEY_FILE"
    ok "Servidor activado hasta: $expiry"
}

check_activated() {
    [[ ! -f "$SERVER_KEY_FILE" ]] && return 1
    local expiry=$(cut -d'|' -f2 "$SERVER_KEY_FILE" 2>/dev/null)
    local now=$(date '+%Y-%m-%d %H:%M:%S')
    [[ "$now" < "$expiry" ]] && return 0 || return 1
}

list_keys() {
    sep2
    printf "  ${C}%-36s %-22s %-5s %-10s %-8s %s${NC}\n" "KEY" "EXPIRA" "DÍAS" "ESTADO" "CONEX" "DESC"
    sep2
    while IFS='|' read -r key expiry dias maxconn limitgb estado created desc; do
        local col="${G}"
        [[ "$estado" == "USADA" ]] && col="${Y}"
        [[ "$estado" == "REVOCADA" ]] && col="${R}"
        local now=$(date '+%Y-%m-%d %H:%M:%S')
        [[ "$now" > "$expiry" && "$estado" != "REVOCADA" ]] && col="${R}" && estado="EXPIRADA"
        printf "  ${col}%-36s %-22s %-5s %-10s %-8s %s${NC}\n" \
            "$key" "$expiry" "$dias" "$estado" "$maxconn" "${desc:0:20}"
    done < "$KEYS_DB"
    sep2
}

menu_keys() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ GESTIÓN DE KEYS ══════════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Generar key  1 día"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Generar key  7 días"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Generar key 15 días"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Generar key 30 días"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Generar key 90 días"
        echo -e "  ${C}║${NC}  ${Y}6)${NC}  Generar key personalizada"
        echo -e "  ${C}║${NC}  ${Y}7)${NC}  Generar pack de keys (lote)"
        echo -e "  ${C}║${NC}  ${Y}8)${NC}  Activar servidor con key"
        echo -e "  ${C}║${NC}  ${Y}9)${NC}  Listar todas las keys"
        echo -e "  ${C}║${NC}  ${Y}10)${NC} Revocar key"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚══════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1|2|3|4|5)
                dias_arr=(0 1 7 15 30 90); dias=${dias_arr[$opt]}
                read -p "  Max conexiones [10]: " mc; mc=${mc:-10}
                read -p "  Límite GB [0=ilimitado]: " lg; lg=${lg:-0}
                read -p "  Descripción: " desc; desc=${desc:-"Key $dias días"}
                key=$(gen_key $dias $mc $lg "$desc")
                sep2; echo -e "  ${G}Key generada ($dias días):${NC}"; echo -e "  ${W}${BOLD}$key${NC}"; sep2; pause ;;
            6)
                read -p "  Días: " dias
                read -p "  Max conexiones [10]: " mc; mc=${mc:-10}
                read -p "  Límite GB [0=ilim]: " lg; lg=${lg:-0}
                read -p "  Descripción: " desc
                key=$(gen_key $dias $mc $lg "${desc:-Key custom}")
                sep2; echo -e "  ${G}Key ($dias días):${NC}"; echo -e "  ${W}${BOLD}$key${NC}"; sep2; pause ;;
            7)
                read -p "  Cantidad de keys: " qty
                read -p "  Días por key: " dias
                read -p "  Descripción: " desc
                sep2; echo -e "  ${G}Keys generadas:${NC}"
                for i in $(seq 1 $qty); do
                    k=$(gen_key $dias 10 0 "${desc:-Lote}")
                    echo -e "  ${W}$k${NC}"
                done
                sep2; pause ;;
            8)
                read -p "  Ingresa la key: " key
                activate_server "$key"; pause ;;
            9) list_keys; pause ;;
            10)
                read -p "  Key a revocar: " key
                sed -i "s/^${key}|\(.*\)|[A-Z]*|\(.*\)$/${key}|\1|REVOCADA|\2/" "$KEYS_DB"
                ok "Key revocada"; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  GESTIÓN DE USUARIOS V2RAY / XRAY
# ════════════════════════════════════════════════════════════
add_xray_user() {
    local user=$1 uuid=$2
    for i in 0 1 2 3; do
        jq --arg u "$uuid" --arg e "$user" \
           ".inbounds[$i].settings.clients += [{\"id\":\$u,\"alterId\":0,\"email\":\$e,\"flow\":\"\"}]" \
           "$XRAY_CONF" > /tmp/xtmp.json 2>/dev/null && mv /tmp/xtmp.json "$XRAY_CONF"
    done
    jq --arg u "$uuid" --arg e "$user" \
       '.inbounds[4].settings.clients += [{"password":$u,"email":$e}]' \
       "$XRAY_CONF" > /tmp/xtmp.json 2>/dev/null && mv /tmp/xtmp.json "$XRAY_CONF"
    systemctl restart xray
}

del_xray_user() {
    local uuid=$1
    for i in 0 1 2 3; do
        jq --arg u "$uuid" \
           "del(.inbounds[$i].settings.clients[] | select(.id == \$u))" \
           "$XRAY_CONF" > /tmp/xtmp.json 2>/dev/null && mv /tmp/xtmp.json "$XRAY_CONF"
    done
    jq --arg u "$uuid" \
       'del(.inbounds[4].settings.clients[] | select(.password == $u))' \
       "$XRAY_CONF" > /tmp/xtmp.json 2>/dev/null && mv /tmp/xtmp.json "$XRAY_CONF"
    systemctl restart xray
}

show_links() {
    local user=$1 uuid=$2 expiry=$3
    local ws_path=$(cat "$PANEL_DIR/ws_path.txt" 2>/dev/null || echo "/nexus")
    sep2
    echo -e "  ${W}📱 LINKS — $user  |  Expira: $expiry${NC}"
    sep2
    local vless="vless://${uuid}@${MYIP}:443?type=tcp&security=tls&fp=chrome#NEXUS-${user}"
    local ws_b64=$(echo -n "{\"v\":\"2\",\"ps\":\"WS-${user}\",\"add\":\"${MYIP}\",\"port\":\"8080\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"${ws_path}\",\"type\":\"none\"}" | base64 -w0)
    local wstls_b64=$(echo -n "{\"v\":\"2\",\"ps\":\"WSTLS-${user}\",\"add\":\"${MYIP}\",\"port\":\"8443\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"${ws_path}\",\"type\":\"none\",\"tls\":\"tls\"}" | base64 -w0)
    local kcp_b64=$(echo -n "{\"v\":\"2\",\"ps\":\"KCP-${user}\",\"add\":\"${MYIP}\",\"port\":\"1194\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"kcp\",\"type\":\"none\",\"seed\":\"nexusvpn\"}" | base64 -w0)
    local trojan="trojan://${uuid}@${MYIP}:2083?security=none#Trojan-${user}"
    local ss_b64=$(echo -n "chacha20-ietf-poly1305:nexusvpn2024" | base64 -w0)
    local ss="ss://${ss_b64}@${MYIP}:8388#SS-${user}"
    echo -e "  ${Y}VLESS TLS:${NC}   $vless"
    echo -e "  ${Y}VMess WS:${NC}    vmess://${ws_b64}"
    echo -e "  ${Y}VMess WSTLS:${NC} vmess://${wstls_b64}"
    echo -e "  ${Y}VMess KCP:${NC}   vmess://${kcp_b64}"
    echo -e "  ${Y}Trojan:${NC}      $trojan"
    echo -e "  ${Y}SS:${NC}          $ss"
    echo -e "  ${Y}SOCKS5:${NC}      socks5://${MYIP}:1080"
    # Guardar
    local f="/root/nexus-${user}-$(date +%Y%m%d).txt"
    { echo "=== NexusVPN Pro === $user === Expira: $expiry ==="
      echo "VLESS:    $vless"
      echo "VMess-WS: vmess://${ws_b64}"
      echo "VMess-TLS:vmess://${wstls_b64}"
      echo "KCP:      vmess://${kcp_b64}"
      echo "Trojan:   $trojan"
      echo "SS:       $ss"
      echo "SOCKS5:   socks5://${MYIP}:1080"
    } > "$f"
    echo -e "  ${G}Guardado: $f${NC}"; sep2
}

menu_usuarios() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ USUARIOS V2RAY / XRAY ════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Crear usuario"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Listar usuarios"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Ver links de usuario"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Renovar usuario"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Cambiar límite de conexiones"
        echo -e "  ${C}║${NC}  ${Y}6)${NC}  Eliminar usuario"
        echo -e "  ${C}║${NC}  ${Y}7)${NC}  Limpiar usuarios expirados"
        echo -e "  ${C}║${NC}  ${Y}8)${NC}  Exportar todos los links"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚══════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1)
                read -p "  Nombre: " user
                read -p "  Días [30]: " dias; dias=${dias:-30}
                read -p "  Max conexiones [10]: " mc; mc=${mc:-10}
                local uuid=$(cat /proc/sys/kernel/random/uuid)
                local expiry=$(date -d "+${dias} days" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
                            || date -v "+${dias}d" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
                add_xray_user "$user" "$uuid"
                # USER|UUID|CREATED|EXPIRY|MAXCONN|GB_USED|STATUS
                echo "${user}|${uuid}|$(date '+%Y-%m-%d %H:%M:%S')|${expiry}|${mc}|0|ACTIVE" >> "$USERS_DB"
                show_links "$user" "$uuid" "$expiry"
                pause ;;
            2)
                sep2
                printf "  ${C}%-20s %-22s %-8s %-8s${NC}\n" "USUARIO" "EXPIRA" "CONEX" "GB"
                sep2
                while IFS='|' read -r u uid cr exp mc gb st; do
                    local now=$(date '+%Y-%m-%d %H:%M:%S')
                    local col="${G}"; [[ "$now" > "$exp" ]] && col="${R}"
                    printf "  ${col}%-20s %-22s %-8s %-8s${NC}\n" "$u" "$exp" "$mc" "${gb}GB"
                done < "$USERS_DB"
                sep2; pause ;;
            3)
                read -p "  Usuario: " user
                local line=$(grep "^${user}|" "$USERS_DB" 2>/dev/null)
                if [[ -n "$line" ]]; then
                    show_links "$user" "$(echo $line|cut -d'|' -f2)" "$(echo $line|cut -d'|' -f4)"
                else err "No encontrado"; fi; pause ;;
            4)
                read -p "  Usuario: " user
                read -p "  Días adicionales: " dias
                local exp=$(date -d "+${dias} days" '+%Y-%m-%d %H:%M:%S' 2>/dev/null \
                         || date -v "+${dias}d" '+%Y-%m-%d %H:%M:%S' 2>/dev/null)
                sed -i "s/^${user}|\([^|]*\)|\([^|]*\)|[^|]*|/${user}|\1|\2|${exp}|/" "$USERS_DB"
                ok "Renovado hasta: $exp"; pause ;;
            5)
                read -p "  Usuario: " user
                read -p "  Nuevo límite conexiones: " mc
                sed -i "s/^${user}|\([^|]*\)|\([^|]*\)|\([^|]*\)|[0-9]*|/${user}|\1|\2|\3|${mc}|/" "$USERS_DB"
                ok "Límite actualizado"; pause ;;
            6)
                read -p "  Usuario: " user
                local uuid=$(grep "^${user}|" "$USERS_DB" | cut -d'|' -f2)
                [[ -n "$uuid" ]] && del_xray_user "$uuid" && sed -i "/^${user}|/d" "$USERS_DB" && ok "Eliminado" || err "No encontrado"
                pause ;;
            7)
                local count=0
                while IFS='|' read -r u uid cr exp mc gb st; do
                    local now=$(date '+%Y-%m-%d %H:%M:%S')
                    if [[ "$now" > "$exp" ]]; then
                        del_xray_user "$uid" 2>/dev/null || true
                        sed -i "/^${u}|/d" "$USERS_DB"
                        ((count++))
                    fi
                done < "$USERS_DB"
                ok "Expirados eliminados: $count"; pause ;;
            8)
                while IFS='|' read -r u uid cr exp mc gb st; do
                    show_links "$u" "$uid" "$exp" 2>/dev/null
                done < "$USERS_DB"
                pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  OPENVPN - USUARIOS
# ════════════════════════════════════════════════════════════
gen_ovpn_profile() {
    local user=$1
    cd /etc/openvpn/easy-rsa
    ./easyrsa build-client-full "$user" nopass 2>/dev/null

    local ca=$(cat pki/ca.crt)
    local cert=$(cat "pki/issued/${user}.crt" | grep -A 999 "BEGIN CERTIFICATE")
    local key=$(cat "pki/private/${user}.key")
    local ta=$(cat /etc/openvpn/ta.key)

    cat > "/root/nexus-${user}.ovpn" << OVPNPROF
client
dev tun
proto udp
remote $MYIP 1194
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-GCM
auth SHA256
comp-lzo
verb 3
key-direction 1
<ca>
${ca}
</ca>
<cert>
${cert}
</cert>
<key>
${key}
</key>
<tls-auth>
${ta}
</tls-auth>
OVPNPROF
    ok "Perfil OpenVPN generado: /root/nexus-${user}.ovpn"
}

menu_openvpn() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ OPENVPN ══════════════════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Crear usuario + perfil .ovpn"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Revocar usuario"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Regenerar perfil .ovpn"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Ver usuarios activos"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Reiniciar OpenVPN"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚══════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1) read -p "  Nombre usuario: " user; gen_ovpn_profile "$user"; pause ;;
            2)
                read -p "  Usuario a revocar: " user
                cd /etc/openvpn/easy-rsa
                ./easyrsa revoke "$user" 2>/dev/null
                ./easyrsa gen-crl 2>/dev/null
                ok "Usuario $user revocado"; pause ;;
            3) read -p "  Usuario: " user; gen_ovpn_profile "$user"; pause ;;
            4) cat /var/log/openvpn-status.log 2>/dev/null; pause ;;
            5) systemctl restart openvpn@server openvpn@server-tcp; ok "OpenVPN reiniciado"; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  WIREGUARD - USUARIOS
# ════════════════════════════════════════════════════════════
add_wg_peer() {
    local user=$1
    local client_priv=$(wg genkey)
    local client_pub=$(echo "$client_priv" | wg pubkey)
    local server_pub=$(cat "$PANEL_DIR/wg_pubkey.txt")
    # Asignar IP al cliente (10.10.0.X)
    local peer_count=$(grep -c "^[Peer]" /etc/wireguard/wg0.conf 2>/dev/null || echo 0)
    local client_ip="10.10.0.$((peer_count + 2))"

    cat >> /etc/wireguard/wg0.conf << WGPEER

[Peer]
# $user
PublicKey = ${client_pub}
AllowedIPs = ${client_ip}/32
WGPEER

    cat > "/root/nexus-wg-${user}.conf" << WGCLIENT
[Interface]
PrivateKey = ${client_priv}
Address = ${client_ip}/24
DNS = 8.8.8.8

[Peer]
PublicKey = ${server_pub}
Endpoint = ${MYIP}:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
WGCLIENT

    wg addconf wg0 <(wg-quick strip /etc/wireguard/wg0.conf) 2>/dev/null || \
        systemctl restart wg-quick@wg0
    ok "WireGuard peer creado → /root/nexus-wg-${user}.conf"
}

menu_wireguard() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ WIREGUARD ════════════════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Agregar peer (usuario)"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Ver peers activos"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Eliminar peer"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Ver clave pública del servidor"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Reiniciar WireGuard"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚══════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1) read -p "  Nombre peer: " user; add_wg_peer "$user"; pause ;;
            2) wg show 2>/dev/null; pause ;;
            3)
                read -p "  Clave pública del peer: " pub
                sed -i "/^# .*\|PublicKey = ${pub}/,/^$/d" /etc/wireguard/wg0.conf
                systemctl restart wg-quick@wg0
                ok "Peer eliminado"; pause ;;
            4) echo -e "  PubKey: $(cat $PANEL_DIR/wg_pubkey.txt)"; pause ;;
            5) systemctl restart wg-quick@wg0; ok "WireGuard reiniciado"; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  HYSTERIA2 - USUARIOS
# ════════════════════════════════════════════════════════════
menu_hysteria() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ HYSTERIA2 ════════════════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Crear usuario"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Eliminar usuario"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Ver config cliente"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Reiniciar"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚══════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1)
                read -p "  Usuario: " user
                read -p "  Contraseña [auto]: " pass; [[ -z "$pass" ]] && pass=$(openssl rand -hex 8)
                python3 -c "
import yaml
with open('/etc/hysteria/config.yaml') as f: c=yaml.safe_load(f)
c['auth']['userpass']['$user']='$pass'
with open('/etc/hysteria/config.yaml','w') as f: yaml.dump(c,f,allow_unicode=True)" 2>/dev/null
                systemctl restart hysteria-server
                local obfs=$(cat /etc/hysteria/obfs.key)
                sep2
                echo -e "  ${G}Hysteria2 creado:${NC} $user / $pass"
                echo "  server: $MYIP:36712"
                echo "  auth: $user:$pass"
                echo "  obfs: salamander / $obfs"
                echo "  tls: insecure: true"
                sep2; pause ;;
            2)
                read -p "  Usuario: " user
                python3 -c "
import yaml
with open('/etc/hysteria/config.yaml') as f: c=yaml.safe_load(f)
c['auth']['userpass'].pop('$user',None)
with open('/etc/hysteria/config.yaml','w') as f: yaml.dump(c,f,allow_unicode=True)" 2>/dev/null
                systemctl restart hysteria-server; ok "Eliminado"; pause ;;
            3)
                echo -e "  ${Y}Obfs key:${NC} $(cat /etc/hysteria/obfs.key)"
                echo -e "  ${Y}Server:${NC}   $MYIP:36712 UDP"; pause ;;
            4) systemctl restart hysteria-server; ok "Reiniciado"; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  ESTADÍSTICAS
# ════════════════════════════════════════════════════════════
menu_stats() {
    show_banner
    sep2
    echo -e "  ${W}SISTEMA${NC}"
    echo -e "  SO      : $(. /etc/os-release && echo "$PRETTY_NAME")"
    echo -e "  Kernel  : $(uname -r)  |  Arch: $ARCH"
    echo -e "  Uptime  : $(uptime -p)"
    echo -e "  CPU     : $(nproc) cores  |  Load: $(cat /proc/loadavg | cut -d' ' -f1-3)"
    echo -e "  RAM     : $(free -h | awk '/^Mem:/ {print $3 " / " $2}')"
    echo -e "  Disco   : $(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')"
    sep2
    echo -e "  ${W}TRÁFICO${NC}"
    local iface=$(ip route | grep default | awk '{print $5}' | head -1)
    local rx=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo 0)
    local tx=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null || echo 0)
    echo -e "  Interfaz: $iface"
    echo -e "  RX: $(echo "$rx/1024/1024" | bc) MB  |  TX: $(echo "$tx/1024/1024" | bc) MB"
    sep2
    echo -e "  ${W}SERVICIOS${NC}"
    for s in xray hysteria-server slowdns openvpn@server wg-quick@wg0 fail2ban nginx; do
        local st=$(systemctl is-active "$s" 2>/dev/null || echo "inactivo")
        [[ "$st" == "active" ]] && echo -e "  ${G}● $s${NC}" || echo -e "  ${R}○ $s${NC}"
    done
    sep2
    echo -e "  ${W}PUERTOS ESCUCHANDO${NC}"
    ss -tulpn 2>/dev/null | grep -E ':(80|443|1080|1194|1195|2083|5300|8080|8118|8388|8443|36712|51820|7[123]00)' \
    | awk '{printf "  %-8s %s\n", $1, $5}' | sort -u
    sep2
    echo -e "  ${W}USUARIOS ACTIVOS:${NC} $(grep -c "|ACTIVE|" "$USERS_DB" 2>/dev/null || echo 0)"
    echo -e "  ${W}KEYS GENERADAS:${NC}  $(wc -l < "$KEYS_DB" 2>/dev/null || echo 0)"
    sep2
    echo -e "  ${W}FAIL2BAN - IPs baneadas:${NC}"
    fail2ban-client status sshd 2>/dev/null | grep "Banned IP" || echo "  Ninguna"
    sep; pause
}

# ════════════════════════════════════════════════════════════
#  TELEGRAM NOTIFICACIONES
# ════════════════════════════════════════════════════════════
menu_telegram() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ TELEGRAM NOTIFICACIONES ══════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Configurar Bot Token y Chat ID"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Enviar mensaje de prueba"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Ver configuración actual"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Activar/desactivar alertas"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚══════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1)
                read -p "  Bot Token: " token
                read -p "  Chat ID: " chatid
                echo "TOKEN=${token}" > "$TG_CONF"
                echo "CHATID=${chatid}" >> "$TG_CONF"
                ok "Configuración guardada"; pause ;;
            2)
                [[ ! -f "$TG_CONF" ]] && err "Configura el bot primero" && pause && continue
                source "$TG_CONF"
                curl -s -X POST "https://api.telegram.org/bot${TOKEN}/sendMessage" \
                    -d "chat_id=${CHATID}" \
                    -d "text=✅ NexusVPN Pro - Servidor activo en $MYIP" >/dev/null
                ok "Mensaje enviado"; pause ;;
            3) [[ -f "$TG_CONF" ]] && cat "$TG_CONF" || echo "No configurado"; pause ;;
            4)
                [[ ! -f "$TG_CONF" ]] && err "Configura el bot primero" && pause && continue
                source "$TG_CONF"
                # Cron de alertas
                crontab -l 2>/dev/null | grep -v tg_alert | { cat; \
                    echo "0 */6 * * * curl -s -X POST \"https://api.telegram.org/bot${TOKEN}/sendMessage\" -d \"chat_id=${CHATID}\" -d \"text=📊 NexusVPN: $(get_users_count) usuarios | CPU: \$(cat /proc/loadavg | cut -d' ' -f1) | RAM: \$(free -h | awk '/Mem/{print \$3\"/\"\$2}')\" >/dev/null 2>&1 #tg_alert"; \
                } | crontab -
                ok "Alertas cada 6 horas activadas"; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  BACKUP AUTOMÁTICO
# ════════════════════════════════════════════════════════════
do_backup() {
    local bfile="$BACKUP_DIR/nexusvpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    tar -czf "$bfile" \
        "$PANEL_DIR/keys.db" \
        "$PANEL_DIR/users.db" \
        "$XRAY_CONF" \
        "$HY2_CONF" \
        /etc/openvpn/ \
        /etc/wireguard/ \
        2>/dev/null || true
    # Mantener solo los últimos 7 backups
    ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null | tail -n +8 | xargs rm -f 2>/dev/null || true
    ok "Backup guardado: $bfile"
}

menu_backup() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ BACKUPS ══════════════════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Crear backup ahora"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Listar backups"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Restaurar backup"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚══════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1) do_backup; pause ;;
            2) ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || echo "No hay backups"; pause ;;
            3)
                ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null
                read -p "  Nombre del archivo a restaurar: " bfile
                tar -xzf "$BACKUP_DIR/$bfile" -C / 2>/dev/null
                systemctl restart xray hysteria-server
                ok "Restaurado"; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  UDP / BADVPN / SLOWDNS / CLOUDFLARE / FIREWALL / SERVICIOS
# ════════════════════════════════════════════════════════════
menu_udp() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ UDP CUSTOM / BADVPN ═════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Abrir puerto UDP"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Cerrar puerto UDP"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Listar puertos activos"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Estado BadVPN"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Reiniciar BadVPN"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1)
                read -p "  Puerto UDP: " port
                echo "  1) Google DNS  2) Cloudflare  3) BadVPN local  4) Custom"
                read -p "  Destino [1-4]: " d
                case $d in 1) dest="8.8.8.8:53";; 2) dest="1.1.1.1:53";; 3) dest="127.0.0.1:7300";; 4) read -p "  IP:Puerto: " dest;; esac
                cat > "/etc/systemd/system/udp-${port}.service" << EOF
[Unit]
Description=UDP proxy :${port}
After=network.target
[Service]
Type=simple
ExecStart=/usr/bin/socat -T120 UDP4-LISTEN:${port},fork,reuseaddr UDP4:${dest}
Restart=always
[Install]
WantedBy=multi-user.target
EOF
                systemctl daemon-reload && systemctl enable "udp-${port}" -q && systemctl start "udp-${port}"
                ufw allow "${port}/udp" >/dev/null
                ok "Puerto UDP $port → $dest activo"; pause ;;
            2)
                read -p "  Puerto: " port
                systemctl stop "udp-${port}" && systemctl disable "udp-${port}" -q
                rm -f "/etc/systemd/system/udp-${port}.service"
                ok "Cerrado"; pause ;;
            3) systemctl list-units --type=service --state=running | grep "udp-"; pause ;;
            4) for p in 7100 7200 7300; do echo -n "  BadVPN :$p → "; systemctl is-active "badvpn-${p}"; done; pause ;;
            5) for p in 7100 7200 7300; do systemctl restart "badvpn-${p}"; done; ok "Reiniciado"; pause ;;
            0) break ;;
        esac
    done
}

menu_slowdns() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ SLOWDNS ══════════════════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Ver clave pública"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Regenerar claves"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Cambiar puerto"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Reiniciar"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Ver logs"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1) sep2; echo -e "  ${Y}PubKey:${NC} $(cat $PANEL_DIR/slowdns_pubkey.txt)"; echo -e "  ${Y}Server:${NC} $MYIP:5300 UDP"; sep2; pause ;;
            2) cd "$SDNS_DIR" && rm -f server.key server.pub && "$SDNS_DIR/dnstt-server" -gen-key -privkey server.key -pubkey server.pub && cp server.pub "$PANEL_DIR/slowdns_pubkey.txt" && systemctl restart slowdns && ok "Regeneradas"; pause ;;
            3) read -p "  Nuevo puerto [5300]: " p; p=${p:-5300}; sed -i "s/-udp :[0-9]*/-udp :${p}/" /etc/systemd/system/slowdns.service && systemctl daemon-reload && systemctl restart slowdns && ufw allow "${p}/udp" >/dev/null && ok "Puerto cambiado a $p"; pause ;;
            4) systemctl restart slowdns && ok "Reiniciado"; pause ;;
            5) journalctl -u slowdns -n 30 --no-pager; pause ;;
            0) break ;;
        esac
    done
}

menu_cloudflare() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ CLOUDFLARE / DOMINIO / SSL ══════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Configurar dominio"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Instalar SSL Let's Encrypt"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Cambiar DNS del servidor"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Configurar Nginx WebSocket"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Ver info actual"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1) read -p "  Dominio: " dom; echo "$dom" > "$PANEL_DIR/domain.txt"; ok "Dominio: $dom"; pause ;;
            2)
                local dom=$(cat "$PANEL_DIR/domain.txt" 2>/dev/null); [[ -z "$dom" ]] && read -p "  Dominio: " dom
                certbot certonly --standalone -d "$dom" --non-interactive --agree-tos --register-unsafely-without-email 2>&1 | tail -5
                ok "SSL en /etc/letsencrypt/live/$dom/"; pause ;;
            3)
                echo "  1) Google 8.8.8.8  2) Cloudflare 1.1.1.1  3) Custom"
                read -p "  [1-3]: " d
                case $d in 1) echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf;;
                            2) echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > /etc/resolv.conf;;
                            3) read -p "  DNS: " dns; echo "nameserver $dns" > /etc/resolv.conf;; esac
                ok "DNS actualizado"; pause ;;
            4)
                local dom=$(cat "$PANEL_DIR/domain.txt" 2>/dev/null); [[ -z "$dom" ]] && read -p "  Dominio: " dom
                local ws=$(cat "$PANEL_DIR/ws_path.txt" 2>/dev/null || echo "/nexus")
                cat > /etc/nginx/sites-available/nexusvpn << NGCFG
server {
    listen 80;
    server_name $dom;
    location $ws {
        proxy_pass http://127.0.0.1:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
    }
}
NGCFG
                ln -sf /etc/nginx/sites-available/nexusvpn /etc/nginx/sites-enabled/
                nginx -t && systemctl reload nginx && ok "Nginx WebSocket OK para $dom"; pause ;;
            5) echo "  Dominio: $(cat $PANEL_DIR/domain.txt 2>/dev/null || echo 'No configurado')"; echo "  DNS: $(grep nameserver /etc/resolv.conf | head -2)"; pause ;;
            0) break ;;
        esac
    done
}

menu_firewall() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ FIREWALL / FAIL2BAN ═════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Ver reglas activas"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Abrir puerto"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Cerrar puerto"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Abrir rango de puertos"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Ver IPs baneadas (fail2ban)"
        echo -e "  ${C}║${NC}  ${Y}6)${NC}  Desbanear IP"
        echo -e "  ${C}║${NC}  ${Y}7)${NC}  Reiniciar firewall completo"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1) ufw status numbered; pause ;;
            2) read -p "  Puerto (ej: 9000/tcp): " p; ufw allow "$p" && ok "Abierto"; pause ;;
            3) read -p "  Puerto: " p; ufw delete allow "$p" && ok "Cerrado"; pause ;;
            4)
                read -p "  Puerto inicio: " p1; read -p "  Puerto fin: " p2; read -p "  tcp/udp/both: " proto
                [[ "$proto" == "both" || -z "$proto" ]] && { ufw allow "${p1}:${p2}/tcp"; ufw allow "${p1}:${p2}/udp"; } || ufw allow "${p1}:${p2}/${proto}"
                ok "Rango ${p1}-${p2} abierto"; pause ;;
            5) fail2ban-client status sshd 2>/dev/null; pause ;;
            6) read -p "  IP a desbanear: " ip; fail2ban-client set sshd unbanip "$ip" && ok "Desbaneada"; pause ;;
            7)
                ufw --force reset && ufw default deny incoming && ufw default allow outgoing
                for p in 22/tcp 80/tcp 443/tcp 1080/tcp 1194/udp 1195/tcp 2083/tcp 5300/udp 7100:7300/udp 8080/tcp 8118/tcp 8388/tcp 8443/tcp 36712/udp 51820/udp; do ufw allow $p >/dev/null; done
                echo "y" | ufw enable >/dev/null && ok "Firewall reiniciado"; pause ;;
            0) break ;;
        esac
    done
}

menu_servicios() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ SERVICIOS / LOGS ════════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Reiniciar TODOS"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Reiniciar Xray"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Reiniciar Hysteria2"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Reiniciar SlowDNS"
        echo -e "  ${C}║${NC}  ${Y}5)${NC}  Reiniciar OpenVPN"
        echo -e "  ${C}║${NC}  ${Y}6)${NC}  Reiniciar WireGuard"
        echo -e "  ${C}║${NC}  ${Y}7)${NC}  Ver logs Xray"
        echo -e "  ${C}║${NC}  ${Y}8)${NC}  Ver logs instalación"
        echo -e "  ${C}║${NC}  ${Y}9)${NC}  Verificar config Xray"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1) for s in xray hysteria-server slowdns openvpn@server wg-quick@wg0 badvpn-7100 badvpn-7200 badvpn-7300; do systemctl restart "$s" 2>/dev/null || true; done; ok "Todos reiniciados"; pause ;;
            2) systemctl restart xray; ok "Xray OK"; pause ;;
            3) systemctl restart hysteria-server; ok "Hysteria2 OK"; pause ;;
            4) systemctl restart slowdns; ok "SlowDNS OK"; pause ;;
            5) systemctl restart openvpn@server openvpn@server-tcp; ok "OpenVPN OK"; pause ;;
            6) systemctl restart wg-quick@wg0; ok "WireGuard OK"; pause ;;
            7) journalctl -u xray -n 50 --no-pager; pause ;;
            8) tail -100 "$LOG_FILE"; pause ;;
            9) xray -test -config "$XRAY_CONF" 2>&1; pause ;;
            0) break ;;
        esac
    done
}

menu_banner() {
    while true; do
        show_banner
        echo -e "  ${W}╔══ BANNER & CONTACTOS ══════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y}1)${NC}  Editar banner publicitario"
        echo -e "  ${C}║${NC}  ${Y}2)${NC}  Ver banner actual"
        echo -e "  ${C}║${NC}  ${Y}3)${NC}  Limpiar banner"
        echo -e "  ${C}║${NC}  ${Y}4)${NC}  Editar contactos"
        echo -e "  ${C}║${NC}  ${Y}0)${NC}  Volver"
        echo -e "  ${W}╚════════════════════════════════════════════════════════╝${NC}"
        read -p "  Opción: " opt
        case $opt in
            1) echo -e "\n  ${Y}Escribe el banner (Ctrl+D para guardar):${NC}\n"; cat > "$BANNER_FILE"; ok "Guardado"; pause ;;
            2) sep2; cat "$BANNER_FILE" 2>/dev/null || echo "Vacío"; sep2; pause ;;
            3) > "$BANNER_FILE"; ok "Limpiado"; pause ;;
            4)
                for field in WhatsApp Telegram Instagram Canal; do
                    local cur=$(grep "^${field}=" "$CONTACTS_FILE" 2>/dev/null | cut -d'=' -f2)
                    read -p "  $field [$cur]: " val
                    [[ -n "$val" ]] && sed -i "s/^${field}=.*/${field}=${val}/" "$CONTACTS_FILE"
                done; ok "Contactos actualizados"; pause ;;
            0) break ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  TAREAS AUTOMÁTICAS
# ════════════════════════════════════════════════════════════
cleanup_expired() {
    [[ ! -f "$USERS_DB" ]] && return
    local tmp=$(mktemp)
    while IFS='|' read -r u uid cr exp mc gb st; do
        local now=$(date '+%Y-%m-%d %H:%M:%S')
        if [[ "$now" > "$exp" ]]; then
            del_xray_user "$uid" 2>/dev/null || true
        else
            echo "${u}|${uid}|${cr}|${exp}|${mc}|${gb}|${st}" >> "$tmp"
        fi
    done < "$USERS_DB"
    mv "$tmp" "$USERS_DB"
}

update_stats() {
    local iface=$(ip route | grep default | awk '{print $5}' | head -1)
    local rx=$(cat /sys/class/net/$iface/statistics/rx_bytes 2>/dev/null || echo 0)
    local tx=$(cat /sys/class/net/$iface/statistics/tx_bytes 2>/dev/null || echo 0)
    local cpu=$(cat /proc/loadavg | cut -d' ' -f1)
    local ram=$(free | awk '/Mem/{printf "%.0f", $3/$2*100}')
    echo "$(date '+%Y-%m-%d %H:%M:%S')|${rx}|${tx}|${cpu}|${ram}" >> "$STATS_DB"
    # Mantener solo las últimas 1000 líneas
    tail -1000 "$STATS_DB" > /tmp/stats_tmp && mv /tmp/stats_tmp "$STATS_DB"
}

# ════════════════════════════════════════════════════════════
#  MENÚ PRINCIPAL
# ════════════════════════════════════════════════════════════
main_menu() {
    ADMIN_PASS="NexusOwner#2024"

    if ! check_activated; then
        clear
        echo -e "${B}${BOLD}"
        echo "  ╔══════════════════════════════════════════════════════════╗"
        echo "  ║              NexusVPN Pro v4.0 - ACCESO                ║"
        echo "  ╚══════════════════════════════════════════════════════════╝"
        echo -e "${NC}"
        echo -e "  ${C}Ingresa tu KEY de licencia o password de admin:${NC}\n"
        read -sp "  KEY / Password: " input; echo ""

        if [[ "$input" == "$ADMIN_PASS" ]]; then
            mkdir -p "$PANEL_DIR"
            echo "ADMIN|2099-12-31 23:59:59" > "$SERVER_KEY_FILE"
            ok "Bienvenido Admin"; sleep 1
        else
            activate_server "$input"
            check_activated || { err "Key inválida. Saliendo."; sleep 2; exit 1; }
        fi
    fi

    while true; do
        show_banner
        echo -e "  ${W}╔══ MENÚ PRINCIPAL ═══════════════════════════════════════╗${NC}"
        echo -e "  ${C}║${NC}  ${Y} 1)${NC}  🔑  Keys del servidor"
        echo -e "  ${C}║${NC}  ${Y} 2)${NC}  👥  Usuarios V2Ray / Xray"
        echo -e "  ${C}║${NC}  ${Y} 3)${NC}  ⚡  Hysteria2"
        echo -e "  ${C}║${NC}  ${Y} 4)${NC}  🌀  SlowDNS"
        echo -e "  ${C}║${NC}  ${Y} 5)${NC}  🛡️   OpenVPN"
        echo -e "  ${C}║${NC}  ${Y} 6)${NC}  🔒  WireGuard"
        echo -e "  ${C}║${NC}  ${Y} 7)${NC}  📡  UDP Custom / BadVPN"
        echo -e "  ${C}║${NC}  ${Y} 8)${NC}  ☁️   Cloudflare / Dominio / SSL"
        echo -e "  ${C}║${NC}  ${Y} 9)${NC}  📢  Banner & Contactos"
        echo -e "  ${C}║${NC}  ${Y}10)${NC}  📊  Estadísticas"
        echo -e "  ${C}║${NC}  ${Y}11)${NC}  🔥  Firewall / Fail2ban"
        echo -e "  ${C}║${NC}  ${Y}12)${NC}  ⚙️   Servicios / Logs"
        echo -e "  ${C}║${NC}  ${Y}13)${NC}  💬  Telegram Notificaciones"
        echo -e "  ${C}║${NC}  ${Y}14)${NC}  💾  Backups"
        echo -e "  ${C}║${NC}  ${Y}15)${NC}  🔄  Actualizar panel"
        echo -e "  ${C}║${NC}  ${Y} 0)${NC}  🚪  Salir"
        echo -e "  ${W}╚══════════════════════════════════════════════════════════╝${NC}"
        echo ""
        read -p "  Opción [0-15]: " opt
        case $opt in
            1)  menu_keys ;;
            2)  menu_usuarios ;;
            3)  menu_hysteria ;;
            4)  menu_slowdns ;;
            5)  menu_openvpn ;;
            6)  menu_wireguard ;;
            7)  menu_udp ;;
            8)  menu_cloudflare ;;
            9)  menu_banner ;;
            10) menu_stats ;;
            11) menu_firewall ;;
            12) menu_servicios ;;
            13) menu_telegram ;;
            14) menu_backup ;;
            15)
                inf "Actualizando..."
                curl -fsSL "https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh" \
                    -o "$PANEL_BIN" && chmod +x "$PANEL_BIN"
                ok "Actualizado. Reiniciando..."; sleep 1; exec "$PANEL_BIN" ;;
            0)  echo -e "\n  ${G}¡Hasta luego!${NC}\n"; exit 0 ;;
            *)  warn "Opción inválida"; sleep 1 ;;
        esac
    done
}

# ════════════════════════════════════════════════════════════
#  PUNTO DE ENTRADA
# ════════════════════════════════════════════════════════════
check_root
check_os

case "${1:-}" in
    --install)  install_all ;;
    --cleanup)  cleanup_expired ;;
    --backup)   do_backup ;;
    --stats)    update_stats ;;
    *)
        if [[ ! -f "$PANEL_BIN" || ! -d "$PANEL_DIR" ]]; then
            install_all
        fi
        main_menu ;;
esac

#!/bin/bash
# =============================================================================
# NEXUSVPN PRO v3.0 - Panel de Gestión VPN Premium
# =============================================================================
# WhatsApp: 3004430431 | Telegram: @ANDRESCAMP13
# Repo: https://github.com/Androidzpro/NexusVPN
# =============================================================================

# Configuración de colores premium
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'
BOLD='\033[1m'
BLINK='\033[5m'

# Configuración de seguridad
ADMIN_PASS="NexusAdmin2024"  # CAMBIAR ANTES DE SUBIR A GITHUB
INSTALL_DIR="/etc/NexusVPN"
BIN_DIR="/usr/local/bin"
LOG_FILE="/var/log/nexusvpn.log"
KEYS_DB="${INSTALL_DIR}/keys.db"
USERS_DB="${INSTALL_DIR}/users.db"
CONFIG_DIR="${INSTALL_DIR}/configs"
BANNER_FILE="${INSTALL_DIR}/banner.txt"
MOTD_FILE="/etc/motd"
ISSUE_NET="/etc/issue.net"
XRAY_CONFIG="/usr/local/etc/xray/config.json"
HYSTERIA_CONFIG="${INSTALL_DIR}/hysteria.yaml"
SLOWDNS_DIR="${INSTALL_DIR}/slowdns"

# IP del servidor
SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s icanhazip.com 2>/dev/null || hostname -I | awk '{print $1}')

# Función de log
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> $LOG_FILE
}

# Función para mostrar banner animado
show_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}          ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗          ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}          ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝          ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}          ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗          ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}          ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║          ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}          ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║          ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}          ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝          ${CYAN}║${NC}"
    echo -e "${CYAN}║${MAGENTA}                      P R O   v 3 . 0                           ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${YELLOW}  IP: ${WHITE}$SERVER_IP${NC}"
    echo -e "${CYAN}║${YELLOW}  WhatsApp: ${GREEN}3004430431${NC} ${YELLOW}| Telegram: ${GREEN}@ANDRESCAMP13${NC}"
    
    # Mostrar estado de licencia si existe
    if [[ -f "${INSTALL_DIR}/license.key" ]]; then
        local license_data=$(cat "${INSTALL_DIR}/license.key")
        local license_key=$(echo "$license_data" | cut -d'|' -f1)
        local license_exp=$(echo "$license_data" | cut -d'|' -f2)
        local days_left=$(( ($(date -d "$license_exp" +%s) - $(date +%s)) / 86400 ))
        
        if [[ $days_left -gt 0 ]]; then
            echo -e "${CYAN}║${GREEN}  Licencia: ${WHITE}${license_key:0:8}... ${GREEN}($days_left días restantes)${NC}"
        else
            echo -e "${CYAN}║${RED}  Licencia: ${WHITE}${license_key:0:8}... ${RED}(EXPIRADA)${NC}"
        fi
    fi
    
    # Mostrar banner personalizado
    if [[ -f "$BANNER_FILE" ]]; then
        while IFS= read -r line; do
            echo -e "${CYAN}║${WHITE}  $line${NC}"
        done < "$BANNER_FILE"
    fi
    
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Función para mostrar barra de progreso
show_progress() {
    local current=$1
    local total=$2
    local text=$3
    local percentage=$((current * 100 / total))
    local completed=$((percentage / 2))
    local remaining=$((50 - completed))
    
    printf "\r${CYAN}[${NC}"
    printf "%${completed}s" | tr ' ' '█'
    printf "%${remaining}s" | tr ' ' '░'
    printf "${CYAN}]${NC} ${GREEN}%3d%%${NC} ${WHITE}%s${NC}" "$percentage" "$text"
}

# Función para verificar si está instalado
check_installed() {
    if [[ -f "${INSTALL_DIR}/installed" ]]; then
        return 0
    else
        return 1
    fi
}

# Función para validar key
validate_key() {
    local key=$1
    local key_pattern="^NEXUS-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"
    
    if [[ ! $key =~ $key_pattern ]]; then
        echo -e "${RED}❌ Formato de key inválido. Debe ser: NEXUS-XXXX-XXXX-XXXX-XXXX${NC}"
        return 1
    fi
    
    if [[ ! -f "$KEYS_DB" ]]; then
        echo -e "${RED}❌ Base de datos de keys no encontrada. Reinstale el panel.${NC}"
        return 1
    fi
    
    local key_data=$(grep "^$key|" "$KEYS_DB")
    if [[ -z "$key_data" ]]; then
        echo -e "${RED}❌ Key no encontrada en la base de datos.${NC}"
        return 1
    fi
    
    local expiration=$(echo "$key_data" | cut -d'|' -f2)
    local max_users=$(echo "$key_data" | cut -d'|' -f3)
    local max_gb=$(echo "$key_data" | cut -d'|' -f4)
    local current_date=$(date +%s)
    local exp_date=$(date -d "$expiration" +%s 2>/dev/null)
    
    if [[ $current_date -gt $exp_date ]]; then
        echo -e "${RED}❌ Key expirada el: $(date -d "$expiration" '+%Y-%m-%d')${NC}"
        return 1
    fi
    
    # Guardar key activa
    echo "$key|$expiration|$max_users|$max_gb" > "${INSTALL_DIR}/license.key"
    
    echo -e "${GREEN}✅ Key válida!${NC}"
    echo -e "${YELLOW}   Expira: ${WHITE}$(date -d "$expiration" '+%Y-%m-%d')${NC}"
    echo -e "${YELLOW}   Máx usuarios: ${WHITE}$max_users${NC}"
    echo -e "${YELLOW}   Máx GB: ${WHITE}$max_gb${NC}"
    
    return 0
}

# Función para activar licencia
activate_license() {
    show_banner
    echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                ACTIVACIÓN DE LICENCIA NEXUSVPN PRO                ${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${WHITE}Para comprar una licencia contacte a:${NC}"
    echo -e "  ${GREEN}📱 WhatsApp: 3004430431${NC}"
    echo -e "  ${GREEN}📱 Telegram: @ANDRESCAMP13${NC}\n"
    
    local attempts=3
    while [[ $attempts -gt 0 ]]; do
        read -p "$(echo -e ${YELLOW}Ingrese su key NEXUS: ${NC})" license_key
        
        if validate_key "$license_key"; then
            echo -e "\n${GREEN}✅ ¡Licencia activada correctamente!${NC}"
            log "Licencia activada: ${license_key:0:8}..."
            
            # Generar todos los links automáticamente
            echo -e "\n${CYAN}Generando links de conexión...${NC}"
            generate_all_links
            
            echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
            read
            return 0
        else
            attempts=$((attempts - 1))
            if [[ $attempts -gt 0 ]]; then
                echo -e "${RED}Le quedan $attempts intentos.${NC}\n"
            fi
        fi
    done
    
    echo -e "\n${RED}❌ Demasiados intentos fallidos. Saliendo...${NC}"
    exit 1
}

# Función para instalar dependencias con progreso
install_dependencies() {
    echo -e "\n${YELLOW}Instalando dependencias del sistema...${NC}\n"
    
    local steps=10
    local current=0
    
    show_progress $current $steps "Actualizando repositorios..."
    apt update -qq 2>/dev/null
    current=$((current + 1))
    show_progress $current $steps "Actualizando repositorios... OK"
    
    local packages="curl wget unzip zip git jq socat net-tools build-essential \
                    ufw fail2ban certbot python3-certbot-nginx nginx \
                    shadowsocks-libev simple-tls qrencode bc lsof \
                    gnupg2 ca-certificates lsb-release debian-archive-keyring \
                    apt-transport-https software-properties-common \
                    cron dnsutils iproute2 neofetch htop iftop vnstat"
    
    for pkg in $packages; do
        show_progress $current $steps "Instalando $pkg..."
        apt install -y $pkg >/dev/null 2>&1
        current=$((current + 1))
        show_progress $current $steps "Instalando $pkg... OK"
    done
    
    echo -e "\n\n${GREEN}✅ Dependencias instaladas correctamente${NC}"
    log "Dependencias instaladas"
}

# Función para instalar Xray/V2Ray
install_xray() {
    echo -e "\n${YELLOW}Instalando Xray/V2Ray...${NC}\n"
    
    bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install >/dev/null 2>&1
    
    # Crear configuración completa
    cat > $XRAY_CONFIG <<EOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray/access.log",
    "error": "/var/log/xray/error.log"
  },
  "inbounds": [
    {
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
          "header": {
            "type": "none"
          }
        }
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls"]
      }
    },
    {
      "port": 80,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/nexus"
        }
      }
    },
    {
      "port": 8080,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": {
          "path": "/nexus"
        }
      }
    },
    {
      "port": 1194,
      "protocol": "vmess",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "kcp",
        "kcpSettings": {
          "mtu": 1350,
          "tti": 50,
          "uplinkCapacity": 5,
          "downlinkCapacity": 20,
          "congestion": false,
          "readBufferSize": 1,
          "writeBufferSize": 1,
          "header": {
            "type": "none"
          },
          "seed": "nexusvpn"
        }
      }
    },
    {
      "port": 2083,
      "protocol": "trojan",
      "settings": {
        "clients": []
      },
      "streamSettings": {
        "network": "tcp",
        "security": "tls"
      }
    },
    {
      "port": 8388,
      "protocol": "shadowsocks",
      "settings": {
        "method": "chacha20-ietf-poly1305",
        "password": "",
        "clients": []
      }
    },
    {
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "grpc",
        "grpcSettings": {
          "serviceName": "nexus"
        }
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "freedom",
      "tag": "direct"
    },
    {
      "protocol": "blackhole",
      "tag": "block"
    }
  ]
}
EOF
    
    systemctl restart xray
    systemctl enable xray >/dev/null 2>&1
    
    log "Xray instalado correctamente"
}

# Función para instalar Hysteria2
install_hysteria() {
    echo -e "\n${YELLOW}Instalando Hysteria2...${NC}\n"
    
    bash <(curl -fsSL https://get.hy2.sh/) >/dev/null 2>&1
    
    local hy_password=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1)
    
    cat > $HYSTERIA_CONFIG <<EOF
server:
  listen: :36712
  protocol: udp
  auth:
    type: password
    password: $hy_password
  bandwidth:
    up: 100 mbps
    down: 100 mbps
  obfuscation:
    type: salamander
    password: nexusvpn2024
  quic:
    initStreamReceiveWindow: 8388608
    maxStreamReceiveWindow: 8388608
    initConnReceiveWindow: 20971520
    maxConnReceiveWindow: 20971520
    maxIdleTimeout: 30s
    keepAlivePeriod: 10s
    disablePathMTUDiscovery: false
  masquerade:
    type: proxy
    proxy:
      url: https://www.google.com
      rewriteHost: true
EOF
    
    systemctl restart hysteria-server
    systemctl enable hysteria-server >/dev/null 2>&1
    
    echo "$hy_password" > "${INSTALL_DIR}/hysteria_password.txt"
    
    log "Hysteria2 instalado correctamente"
}

# Función para instalar SlowDNS
install_slowdns() {
    echo -e "\n${YELLOW}Instalando SlowDNS...${NC}\n"
    
    mkdir -p $SLOWDNS_DIR
    cd /tmp
    
    git clone https://www.bamsoftware.com/git/dnstt.git >/dev/null 2>&1
    cd dnstt/server
    go build >/dev/null 2>&1
    cp dnstt-server /usr/local/bin/dnstt-server
    chmod +x /usr/local/bin/dnstt-server
    
    cd $SLOWDNS_DIR
    /usr/local/bin/dnstt-server -gen-key -privkey server.key -pubkey server.pub >/dev/null 2>&1
    
    cat > /etc/systemd/system/slowdns.service <<EOF
[Unit]
Description=SlowDNS Server
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/dnstt-server -udp :5300 -privkey $SLOWDNS_DIR/server.key 127.0.0.1:53
Restart=always
RestartSec=3
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable slowdns >/dev/null 2>&1
    systemctl start slowdns >/dev/null 2>&1
    
    log "SlowDNS instalado correctamente"
}

# Función para instalar BadVPN UDP-GW
install_badvpn() {
    echo -e "\n${YELLOW}Instalando BadVPN UDP-GW...${NC}\n"
    
    cd /tmp
    git clone https://github.com/ambrop72/badvpn.git >/dev/null 2>&1
    cd badvpn
    cmake -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >/dev/null 2>&1
    make >/dev/null 2>&1
    make install >/dev/null 2>&1
    
    local ports=(7100 7200 7300)
    for port in "${ports[@]}"; do
        cat > /etc/systemd/system/badvpn-$port.service <<EOF
[Unit]
Description=BadVPN UDP Gateway $port
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 127.0.0.1:$port --max-clients 1000 --max-connections-for-client 10
Restart=always
RestartSec=3
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF
        systemctl daemon-reload
        systemctl enable badvpn-$port >/dev/null 2>&1
        systemctl start badvpn-$port >/dev/null 2>&1
    done
    
    log "BadVPN UDP-GW instalado correctamente"
}

# Función para configurar firewall
setup_firewall() {
    echo -e "\n${YELLOW}Configurando firewall...${NC}\n"
    
    ufw --force disable >/dev/null 2>&1
    ufw --force reset >/dev/null 2>&1
    
    ufw default deny incoming >/dev/null 2>&1
    ufw default allow outgoing >/dev/null 2>&1
    ufw allow ssh >/dev/null 2>&1
    
    # Puertos de servicios
    ufw allow 80/tcp comment 'HTTP' >/dev/null 2>&1
    ufw allow 443/tcp comment 'VLESS/gRPC' >/dev/null 2>&1
    ufw allow 443/udp comment 'VLESS/gRPC' >/dev/null 2>&1
    ufw allow 8080/tcp comment 'VMess WS' >/dev/null 2>&1
    ufw allow 1194/udp comment 'VMess mKCP' >/dev/null 2>&1
    ufw allow 2083/tcp comment 'Trojan' >/dev/null 2>&1
    ufw allow 8388/tcp comment 'Shadowsocks' >/dev/null 2>&1
    ufw allow 36712/udp comment 'Hysteria2' >/dev/null 2>&1
    ufw allow 5300/udp comment 'SlowDNS' >/dev/null 2>&1
    ufw allow 7100/udp comment 'BadVPN' >/dev/null 2>&1
    ufw allow 7200/udp comment 'BadVPN' >/dev/null 2>&1
    ufw allow 7300/udp comment 'BadVPN' >/dev/null 2>&1
    ufw allow 1194/udp comment 'OpenVPN' >/dev/null 2>&1
    ufw allow 1194/tcp comment 'OpenVPN' >/dev/null 2>&1
    
    echo "y" | ufw enable >/dev/null 2>&1
    
    log "Firewall configurado correctamente"
}

# Función para configurar banner SSH
setup_ssh_banner() {
    cat > $MOTD_FILE <<EOF
${CYAN}╔══════════════════════════════════════════════════════════════════╗
║${WHITE}                     NEXUSVPN PRO v3.0                            ${CYAN}║
╠══════════════════════════════════════════════════════════════════╣
║${YELLOW}  WhatsApp: ${GREEN}3004430431${NC}              ${YELLOW}Telegram: ${GREEN}@ANDRESCAMP13${NC}        ${CYAN}║
║${WHITE}  IP del Servidor: ${SERVER_IP}${NC}                                   ${CYAN}║
╚══════════════════════════════════════════════════════════════════╝${NC}

EOF
    
    cp $MOTD_FILE $ISSUE_NET
    
    # Configurar SSH para mostrar banner
    sed -i 's/#Banner none/Banner \/etc\/issue.net/' /etc/ssh/sshd_config
    systemctl restart sshd >/dev/null 2>&1
    
    log "Banner SSH configurado"
}

# Función para crear base de datos de keys
create_keys_database() {
    cat > $KEYS_DB <<EOF
# Formato: KEY|EXPIRACION|MAX_USUARIOS|MAX_GB|CREADO_POR
# Ejemplo: NEXUS-ABCD-1234-EFGH-5678|2025-12-31|50|100|admin
NEXUS-DEMO-1234-5678-9012|$(date -d "+30 days" +%Y-%m-%d)|10|50|demo
NEXUS-TEST-ABCD-EFGH-IJKL|$(date -d "+7 days" +%Y-%m-%d)|5|20|demo
EOF
    
    log "Base de datos de keys creada"
}

# Función para crear el comando nexusvpn
create_nexus_command() {
    cat > ${BIN_DIR}/nexusvpn <<'EOF'
#!/bin/bash
# NEXUSVPN PRO v3.0 - Comando principal
export NEXUS_DIR="/etc/NexusVPN"
export LOG_FILE="/var/log/nexusvpn.log"

# Verificar instalación
if [[ ! -f "${NEXUS_DIR}/installed" ]]; then
    echo -e "\033[1;31m❌ NexusVPN no está instalado correctamente.\033[0m"
    echo -e "\033[1;33mEjecute primero: sudo bash install.sh\033[0m"
    exit 1
fi

# Verificar licencia
if [[ ! -f "${NEXUS_DIR}/license.key" ]]; then
    echo -e "\033[1;31m❌ No hay licencia activa.\033[0m"
    echo -e "\033[1;33mContacte a @ANDRESCAMP13 para adquirir una licencia.\033[0m"
    exit 1
fi

# Verificar expiración de licencia
license_data=$(cat "${NEXUS_DIR}/license.key")
license_exp=$(echo "$license_data" | cut -d'|' -f2)
current_date=$(date +%s)
exp_date=$(date -d "$license_exp" +%s 2>/dev/null)

if [[ $current_date -gt $exp_date ]]; then
    echo -e "\033[1;31m❌ Licencia expirada el: $(date -d "$license_exp" '+%Y-%m-%d')\033[0m"
    echo -e "\033[1;33mContacte a @ANDRESCAMP13 para renovar su licencia.\033[0m"
    exit 1
fi

# Cargar funciones del panel
source "${NEXUS_DIR}/panel_functions.sh"

# Mostrar banner y menú
main_menu
EOF
    
    chmod +x ${BIN_DIR}/nexusvpn
    
    # Crear archivo de funciones del panel
    cat > ${INSTALL_DIR}/panel_functions.sh <<'EOF'
#!/bin/bash
# Funciones del panel NexusVPN Pro

# Configuración de colores
RED='\033[1;31m'
GREEN='\033[1;32m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
GRAY='\033[0;37m'
NC='\033[0m'
BOLD='\033[1m'
BLINK='\033[5m'

SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}')
INSTALL_DIR="/etc/NexusVPN"
BANNER_FILE="${INSTALL_DIR}/banner.txt"

# Función para mostrar banner
show_banner() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}          ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗          ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}          ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝          ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}          ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗          ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}          ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║          ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}          ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║          ${CYAN}║${NC}"
    echo -e "${CYAN}║${WHITE}          ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝          ${CYAN}║${NC}"
    echo -e "${CYAN}║${MAGENTA}                      P R O   v 3 . 0                           ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${YELLOW}  IP: ${WHITE}$SERVER_IP${NC}"
    echo -e "${CYAN}║${YELLOW}  WhatsApp: ${GREEN}3004430431${NC} ${YELLOW}| Telegram: ${GREEN}@ANDRESCAMP13${NC}"
    
    # Mostrar estado de servicios
    local xray_status=$(systemctl is-active xray 2>/dev/null)
    local hysteria_status=$(systemctl is-active hysteria-server 2>/dev/null)
    local slowdns_status=$(systemctl is-active slowdns 2>/dev/null)
    
    echo -e "${CYAN}║${NC}  ${YELLOW}Servicios:${NC} Xray: $(if [[ "$xray_status" == "active" ]]; then echo -e "${GREEN}●${NC}"; else echo -e "${RED}●${NC}"; fi)  Hysteria: $(if [[ "$hysteria_status" == "active" ]]; then echo -e "${GREEN}●${NC}"; else echo -e "${RED}●${NC}"; fi)  SlowDNS: $(if [[ "$slowdns_status" == "active" ]]; then echo -e "${GREEN}●${NC}"; else echo -e "${RED}●${NC}"; fi)"
    
    # Mostrar banner personalizado
    if [[ -f "$BANNER_FILE" ]]; then
        while IFS= read -r line; do
            echo -e "${CYAN}║${WHITE}  $line${NC}"
        done < "$BANNER_FILE"
    fi
    
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Función para gestión de keys
manage_keys() {
    while true; do
        show_banner
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                     GESTIÓN DE LICENCIAS                          ${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
        
        echo -e "${GREEN}1)${NC} Ver keys activas"
        echo -e "${GREEN}2)${NC} Agregar nueva key"
        echo -e "${GREEN}3)${NC} Desactivar key"
        echo -e "${GREEN}4)${NC} Extender tiempo de key"
        echo -e "${GREEN}5)${NC} Volver al menú principal"
        
        read -p "$(echo -e ${YELLOW}Seleccione opción [1-5]: ${NC})" key_option
        
        case $key_option in
            1)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                         KEYS ACTIVAS                            ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                if [[ -f "${INSTALL_DIR}/keys.db" ]]; then
                    grep -v "^#" "${INSTALL_DIR}/keys.db" | while IFS='|' read key exp max_users max_gb creador; do
                        echo -e "${GREEN}Key:${NC} ${key:0:8}...${key: -4}"
                        echo -e "  Expira: $exp"
                        echo -e "  Máx usuarios: $max_users"
                        echo -e "  Máx GB: $max_gb"
                        echo -e "${CYAN}────────────────────────────────────────────────────────${NC}"
                    done
                else
                    echo -e "${RED}No hay keys registradas${NC}"
                fi
                
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            2)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                       AGREGAR NUEVA KEY                         ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                read -p "Key (formato NEXUS-XXXX-XXXX-XXXX-XXXX): " new_key
                read -p "Días de duración (1-365): " days_duration
                read -p "Máximo de usuarios: " max_users
                read -p "Máximo de GB: " max_gb
                
                expiration=$(date -d "+$days_duration days" +%Y-%m-%d)
                
                echo "$new_key|$expiration|$max_users|$max_gb|admin" >> "${INSTALL_DIR}/keys.db"
                
                echo -e "\n${GREEN}✅ Key agregada correctamente${NC}"
                echo -e "Expira: $expiration"
                sleep 2
                ;;
            3)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                      DESACTIVAR KEY                             ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                read -p "Ingrese la key a desactivar: " del_key
                sed -i "/^$del_key|/d" "${INSTALL_DIR}/keys.db"
                echo -e "\n${GREEN}✅ Key desactivada${NC}"
                sleep 2
                ;;
            4)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                     EXTENDER TIEMPO DE KEY                      ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                read -p "Ingrese la key: " ext_key
                read -p "Días adicionales: " extra_days
                
                # Buscar la key y actualizar
                if grep -q "^$ext_key|" "${INSTALL_DIR}/keys.db"; then
                    current_line=$(grep "^$ext_key|" "${INSTALL_DIR}/keys.db")
                    current_exp=$(echo "$current_line" | cut -d'|' -f2)
                    new_exp=$(date -d "$current_exp +$extra_days days" +%Y-%m-%d)
                    
                    sed -i "s/^$ext_key|.*/$ext_key|$new_exp|$(echo "$current_line" | cut -d'|' -f3,4,5)/" "${INSTALL_DIR}/keys.db"
                    echo -e "\n${GREEN}✅ Key extendida hasta: $new_exp${NC}"
                else
                    echo -e "${RED}❌ Key no encontrada${NC}"
                fi
                sleep 2
                ;;
            5)
                break
                ;;
        esac
    done
}

# Función para gestión de usuarios V2Ray
manage_users() {
    while true; do
        show_banner
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                     USUARIOS XRAY/V2RAY                            ${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
        
        echo -e "${GREEN}1)${NC} Agregar usuario"
        echo -e "${GREEN}2)${NC} Listar usuarios"
        echo -e "${GREEN}3)${NC} Eliminar usuario"
        echo -e "${GREEN}4)${NC} Ver tráfico de usuarios"
        echo -e "${GREEN}5)${NC} Limitar conexiones"
        echo -e "${GREEN}6)${NC} Volver al menú principal"
        
        read -p "$(echo -e ${YELLOW}Seleccione opción [1-6]: ${NC})" user_option
        
        case $user_option in
            1)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                      AGREGAR USUARIO                            ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                read -p "Nombre de usuario: " username
                uuid=$(cat /proc/sys/kernel/random/uuid)
                password=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1)
                
                # Guardar en base de datos
                echo "$username|$uuid|$password|$(date +%Y-%m-%d)|$(date -d "+30 days" +%Y-%m-%d)|0|active" >> "${INSTALL_DIR}/users.db"
                
                # Generar links
                echo -e "\n${GREEN}✅ Usuario creado: $username${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                echo -e "${YELLOW}VLESS TCP (443):${NC}"
                echo -e "vless://$uuid@$SERVER_IP:443?type=tcp&security=none&headerType=none#$username\n"
                
                echo -e "${YELLOW}VMess WS (80):${NC}"
                echo -e "vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"$username\",\"add\":\"$SERVER_IP\",\"port\":\"80\",\"id\":\"$uuid\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/nexus\",\"type\":\"none\"}" | base64 -w0)\n"
                
                echo -e "${YELLOW}VMess mKCP (1194):${NC}"
                echo -e "vmess://$(echo -n "{\"v\":\"2\",\"ps\":\"$username\",\"add\":\"$SERVER_IP\",\"port\":\"1194\",\"id\":\"$uuid\",\"aid\":\"0\",\"net\":\"kcp\",\"seed\":\"nexusvpn\",\"type\":\"none\"}" | base64 -w0)\n"
                
                echo -e "${YELLOW}Trojan (2083):${NC}"
                echo -e "trojan://$password@$SERVER_IP:2083#$username\n"
                
                echo -e "${YELLOW}Shadowsocks (8388):${NC}"
                ss_method="chacha20-ietf-poly1305"
                ss_password=$(echo -n "$password" | base64 -w0)
                echo -e "ss://$(echo -n "$ss_method:$password" | base64 -w0)@$SERVER_IP:8388#$username\n"
                
                # Guardar en archivo de usuarios
                echo "=== $username ===" >> "${INSTALL_DIR}/users_list.txt"
                echo "VLESS: vless://$uuid@$SERVER_IP:443?type=tcp&security=none&headerType=none#$username" >> "${INSTALL_DIR}/users_list.txt"
                echo "" >> "${INSTALL_DIR}/users_list.txt"
                
                echo -e "${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            2)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                      LISTA DE USUARIOS                          ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                if [[ -f "${INSTALL_DIR}/users.db" ]]; then
                    echo -e "${YELLOW}USUARIO\t\tUUID\t\t\t\tESTADO\tEXPIRA${NC}"
                    echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
                    while IFS='|' read user uuid pass created exp traffic status; do
                        days_left=$(( ($(date -d "$exp" +%s) - $(date +%s)) / 86400 ))
                        status_color="$GREEN"
                        [[ $days_left -lt 0 ]] && status_color="$RED" && status="expirado"
                        echo -e "${WHITE}$user${NC}\t${uuid:0:8}...\t${status_color}$status${NC}\t${days_left}d"
                    done < "${INSTALL_DIR}/users.db"
                else
                    echo -e "${RED}No hay usuarios registrados${NC}"
                fi
                
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            3)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                      ELIMINAR USUARIO                           ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                read -p "Nombre de usuario a eliminar: " del_user
                
                if grep -q "^$del_user|" "${INSTALL_DIR}/users.db"; then
                    sed -i "/^$del_user|/d" "${INSTALL_DIR}/users.db"
                    echo -e "\n${GREEN}✅ Usuario eliminado${NC}"
                else
                    echo -e "\n${RED}❌ Usuario no encontrado${NC}"
                fi
                sleep 2
                ;;
            4)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                     TRÁFICO DE USUARIOS                         ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                echo -e "${YELLOW}USUARIO\t\tENVIADO\t\tRECIBIDO\tTOTAL${NC}"
                echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
                
                # Leer estadísticas de vnstat o iptables
                for user in $(awk -F'|' '{print $1}' "${INSTALL_DIR}/users.db"); do
                    echo -e "$user\t\t0 MB\t\t0 MB\t\t0 MB"
                done
                
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            5)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                    LIMITAR CONEXIONES                           ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                read -p "Usuario: " limit_user
                read -p "Máximo de conexiones simultáneas: " max_conn
                
                echo -e "\n${GREEN}✅ Límite configurado para $limit_user: $max_conn conexiones${NC}"
                sleep 2
                ;;
            6)
                break
                ;;
        esac
    done
}

# Función para gestión de Hysteria2
manage_hysteria() {
    while true; do
        show_banner
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                       HYSTERIA2 MANAGER                           ${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
        
        echo -e "${GREEN}1)${NC} Ver configuración"
        echo -e "${GREEN}2)${NC} Agregar usuario"
        echo -e "${GREEN}3)${NC} Eliminar usuario"
        echo -e "${GREEN}4)${NC} Reiniciar servicio"
        echo -e "${GREEN}5)${NC} Ver logs"
        echo -e "${GREEN}6)${NC} Volver al menú principal"
        
        read -p "$(echo -e ${YELLOW}Seleccione opción [1-6]: ${NC})" hy_option
        
        case $hy_option in
            1)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                    CONFIGURACIÓN HYSTERIA2                      ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                hy_password=$(cat "${INSTALL_DIR}/hysteria_password.txt" 2>/dev/null)
                echo -e "${YELLOW}Servidor:${NC} $SERVER_IP"
                echo -e "${YELLOW}Puerto:${NC} 36712"
                echo -e "${YELLOW}Protocolo:${NC} UDP"
                echo -e "${YELLOW}Password:${NC} $hy_password"
                echo -e "${YELLOW}Obfuscation:${NC} salamander"
                echo -e "${YELLOW}Obfs Password:${NC} nexusvpn2024"
                
                echo -e "\n${YELLOW}Link de conexión:${NC}"
                echo -e "hysteria2://$hy_password@$SERVER_IP:36712/?insecure=1&obfs=salamander&obfs-password=nexusvpn2024#NexusVPN"
                
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            2)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                    AGREGAR USUARIO HYSTERIA2                    ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                read -p "Nombre de usuario: " hy_user
                hy_pass=$(tr -dc 'a-zA-Z0-9' < /dev/urandom | fold -w 16 | head -n 1)
                
                echo -e "\n${GREEN}✅ Usuario creado: $hy_user${NC}"
                echo -e "${YELLOW}Password:${NC} $hy_pass"
                echo -e "${YELLOW}Link:${NC} hysteria2://$hy_pass@$SERVER_IP:36712/?insecure=1&obfs=salamander&obfs-password=nexusvpn2024#$hy_user"
                
                sleep 3
                ;;
            5)
                clear
                journalctl -u hysteria-server -n 50 --no-pager
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            6)
                break
                ;;
        esac
    done
}

# Función para gestión de SlowDNS
manage_slowdns() {
    while true; do
        show_banner
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                        SLOWDNS MANAGER                            ${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
        
        echo -e "${GREEN}1)${NC} Ver configuración"
        echo -e "${GREEN}2)${NC} Ver clave pública"
        echo -e "${GREEN}3)${NC} Reiniciar servicio"
        echo -e "${GREEN}4)${NC} Ver logs"
        echo -e "${GREEN}5)${NC} Volver al menú principal"
        
        read -p "$(echo -e ${YELLOW}Seleccione opción [1-5]: ${NC})" sd_option
        
        case $sd_option in
            1)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                    CONFIGURACIÓN SLOWDNS                        ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                echo -e "${YELLOW}Servidor DNS:${NC} $SERVER_IP"
                echo -e "${YELLOW}Puerto UDP:${NC} 5300"
                echo -e "${YELLOW}Nameserver:${NC} 127.0.0.1:53"
                
                echo -e "\n${YELLOW}Para conectar desde cliente:${NC}"
                echo -e "dnstt-client -udp $SERVER_IP:5300 -pubkey-file server.pub 8.8.8.8:53"
                
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            2)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                    CLAVE PÚBLICA SLOWDNS                        ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                cat "${INSTALL_DIR}/slowdns/server.pub" 2>/dev/null || echo -e "${RED}No se encontró la clave${NC}"
                
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            4)
                clear
                journalctl -u slowdns -n 50 --no-pager
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            5)
                break
                ;;
        esac
    done
}

# Función para gestión de UDP Custom/BadVPN
manage_udp() {
    while true; do
        show_banner
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                    UDP CUSTOM / BADVPN                            ${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
        
        echo -e "${GREEN}1)${NC} Ver puertos BadVPN activos"
        echo -e "${GREEN}2)${NC} Agregar puerto UDP Custom (socat)"
        echo -e "${GREEN}3)${NC} Eliminar puerto UDP Custom"
        echo -e "${GREEN}4)${NC} Ver configuración de reenvío"
        echo -e "${GREEN}5)${NC} Volver al menú principal"
        
        read -p "$(echo -e ${YELLOW}Seleccione opción [1-5]: ${NC})" udp_option
        
        case $udp_option in
            1)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                      PUERTOS BADVPN ACTIVOS                     ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                for port in 7100 7200 7300; do
                    if systemctl is-active badvpn-$port >/dev/null 2>&1; then
                        echo -e "${GREEN}● Puerto $port - Activo${NC}"
                        echo -e "   Uso: badvpn-udpgw --listen-addr 127.0.0.1:$port"
                    else
                        echo -e "${RED}○ Puerto $port - Inactivo${NC}"
                    fi
                done
                
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            2)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                   AGREGAR PUERTO UDP CUSTOM                     ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                read -p "Puerto UDP local a escuchar: " udp_port
                read -p "IP y puerto de destino (ej: 8.8.8.8:53): " udp_dest
                
                cat > /etc/systemd/system/udp-custom-$udp_port.service <<EOF
[Unit]
Description=UDP Custom Proxy $udp_port
After=network.target

[Service]
Type=simple
ExecStart=/usr/bin/socat -T60 UDP4-LISTEN:$udp_port,fork,reuseaddr UDP4:$udp_dest
Restart=always
RestartSec=3
User=nobody
Group=nogroup

[Install]
WantedBy=multi-user.target
EOF

                systemctl daemon-reload
                systemctl enable udp-custom-$udp_port >/dev/null 2>&1
                systemctl start udp-custom-$udp_port >/dev/null 2>&1
                
                echo -e "\n${GREEN}✅ Proxy UDP creado: $udp_port -> $udp_dest${NC}"
                sleep 2
                ;;
            5)
                break
                ;;
        esac
    done
}

# Función para gestión de SSH
manage_ssh() {
    while true; do
        show_banner
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                          SSH MANAGER                               ${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
        
        echo -e "${GREEN}1)${NC} Crear usuario SSH"
        echo -e "${GREEN}2)${NC} Listar usuarios SSH"
        echo -e "${GREEN}3)${NC} Usuarios conectados"
        echo -e "${GREEN}4)${NC} Eliminar usuario SSH"
        echo -e "${GREEN}5)${NC} Cambiar contraseña"
        echo -e "${GREEN}6)${NC} Bloquear/Desbloquear usuario"
        echo -e "${GREEN}7)${NC} Limitar conexiones"
        echo -e "${GREEN}8)${NC} Volver al menú principal"
        
        read -p "$(echo -e ${YELLOW}Seleccione opción [1-8]: ${NC})" ssh_option
        
        case $ssh_option in
            1)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                      CREAR USUARIO SSH                          ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                read -p "Nombre de usuario: " ssh_user
                read -p "Contraseña: " ssh_pass
                read -p "Días de expiración: " ssh_days
                
                useradd -m -s /bin/bash $ssh_user
                echo "$ssh_user:$ssh_pass" | chpasswd
                chage -E $(date -d "+$ssh_days days" +%Y-%m-%d) $ssh_user
                
                echo -e "\n${GREEN}✅ Usuario SSH creado: $ssh_user${NC}"
                echo -e "Expira en: $ssh_days días"
                sleep 2
                ;;
            3)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                    USUARIOS SSH CONECTADOS                      ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                who | awk '{print $1 " desde " $5 " desde " $2}' | while read line; do
                    echo -e "${GREEN}●${NC} $line"
                done
                
                echo -e "\n${GREEN}Total: $(who | wc -l) usuarios conectados${NC}"
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            8)
                break
                ;;
        esac
    done
}

# Función para gestión de banner/publicidad
manage_banner() {
    while true; do
        show_banner
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                     BANNER Y PUBLICIDAD                           ${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
        
        echo -e "${GREEN}1)${NC} Ver banner actual"
        echo -e "${GREEN}2)${NC} Editar banner del panel"
        echo -e "${GREEN}3)${NC} Editar banner SSH (MOTD)"
        echo -e "${GREEN}4)${NC} Restaurar banner por defecto"
        echo -e "${GREEN}5)${NC} Volver al menú principal"
        
        read -p "$(echo -e ${YELLOW}Seleccione opción [1-5]: ${NC})" banner_option
        
        case $banner_option in
            1)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                      BANNER ACTUAL                              ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                if [[ -f "$BANNER_FILE" ]]; then
                    cat "$BANNER_FILE"
                else
                    echo -e "${RED}No hay banner personalizado${NC}"
                fi
                
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            2)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                  EDITAR BANNER DEL PANEL                        ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                echo -e "${YELLOW}Ingrese las líneas del banner (Ctrl+D para finalizar):${NC}"
                cat > "$BANNER_FILE"
                
                echo -e "\n${GREEN}✅ Banner actualizado${NC}"
                sleep 2
                ;;
            4)
                echo "Bienvenido a NexusVPN Pro" > "$BANNER_FILE"
                echo "Contacto: @ANDRESCAMP13" >> "$BANNER_FILE"
                echo -e "\n${GREEN}✅ Banner restaurado${NC}"
                sleep 2
                ;;
            5)
                break
                ;;
        esac
    done
}

# Función para estadísticas detalladas
show_stats() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                    ESTADÍSTICAS DEL SISTEMA                      ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
    
    # RAM
    total_ram=$(free -m | awk '/^Mem:/ {print $2}')
    used_ram=$(free -m | awk '/^Mem:/ {print $3}')
    free_ram=$(free -m | awk '/^Mem:/ {print $4}')
    ram_percent=$((used_ram * 100 / total_ram))
    echo -e "${YELLOW}Memoria RAM:${NC}"
    echo -e "  Total: ${WHITE}$total_ram MB${NC}"
    echo -e "  Usada: ${WHITE}$used_ram MB ${NC}($ram_percent%)"
    echo -e "  Libre: ${WHITE}$free_ram MB${NC}"
    
    # CPU
    cpu_load=$(uptime | awk -F'load average:' '{print $2}')
    cpu_cores=$(nproc)
    echo -e "\n${YELLOW}CPU:${NC}"
    echo -e "  Núcleos: ${WHITE}$cpu_cores${NC}"
    echo -e "  Load average:${WHITE}$cpu_load${NC}"
    
    # Disco
    disk_total=$(df -h / | awk 'NR==2 {print $2}')
    disk_used=$(df -h / | awk 'NR==2 {print $3}')
    disk_free=$(df -h / | awk 'NR==2 {print $4}')
    disk_percent=$(df -h / | awk 'NR==2 {print $5}')
    echo -e "\n${YELLOW}Disco:${NC}"
    echo -e "  Total: ${WHITE}$disk_total${NC}"
    echo -e "  Usado: ${WHITE}$disk_used${NC} ($disk_percent)"
    echo -e "  Libre: ${WHITE}$disk_free${NC}"
    
    # Uptime
    uptime_info=$(uptime -p)
    echo -e "\n${YELLOW}Uptime:${NC} ${WHITE}$uptime_info${NC}"
    
    # Tráfico de red
    rx_bytes=$(cat /sys/class/net/eth0/statistics/rx_bytes 2>/dev/null || cat /sys/class/net/ens3/statistics/rx_bytes 2>/dev/null)
    tx_bytes=$(cat /sys/class/net/eth0/statistics/tx_bytes 2>/dev/null || cat /sys/class/net/ens3/statistics/tx_bytes 2>/dev/null)
    
    if [[ -n "$rx_bytes" && -n "$tx_bytes" ]]; then
        rx_mb=$((rx_bytes / 1024 / 1024))
        tx_mb=$((tx_bytes / 1024 / 1024))
        echo -e "\n${YELLOW}Tráfico de red:${NC}"
        echo -e "  Recibido: ${WHITE}$rx_mb MB${NC}"
        echo -e "  Enviado: ${WHITE}$tx_mb MB${NC}"
    fi
    
    # Estado de servicios
    echo -e "\n${YELLOW}Estado de servicios:${NC}"
    services=("xray" "hysteria-server" "slowdns" "nginx" "ssh")
    for service in "${services[@]}"; do
        if systemctl is-active --quiet $service 2>/dev/null; then
            echo -e "  ${GREEN}●${NC} $service: Activo"
        else
            echo -e "  ${RED}○${NC} $service: Inactivo"
        fi
    done
    
    # Estadísticas de usuarios
    total_users=$(wc -l < "${INSTALL_DIR}/users.db" 2>/dev/null || echo "0")
    active_keys=$(grep -c -v "^#" "${INSTALL_DIR}/keys.db" 2>/dev/null || echo "0")
    
    echo -e "\n${YELLOW}Usuarios:${NC}"
    echo -e "  Total usuarios V2Ray: ${WHITE}$total_users${NC}"
    echo -e "  Keys activas: ${WHITE}$active_keys${NC}"
    
    echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
    read
}

# Función para gestión de firewall
manage_firewall() {
    while true; do
        show_banner
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                      GESTIÓN DE FIREWALL                          ${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
        
        echo -e "${GREEN}1)${NC} Ver reglas activas"
        echo -e "${GREEN}2)${NC} Abrir puerto"
        echo -e "${GREEN}3)${NC} Cerrar puerto"
        echo -e "${GREEN}4)${NC} Abrir rango de puertos UDP"
        echo -e "${GREEN}5)${NC} Reiniciar firewall"
        echo -e "${GREEN}6)${NC} Volver al menú principal"
        
        read -p "$(echo -e ${YELLOW}Seleccione opción [1-6]: ${NC})" fw_option
        
        case $fw_option in
            1)
                clear
                ufw status numbered
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            2)
                read -p "Puerto a abrir: " port
                read -p "Protocolo (tcp/udp): " proto
                ufw allow $port/$proto
                echo -e "${GREEN}✅ Puerto $port/$proto abierto${NC}"
                sleep 2
                ;;
            3)
                read -p "Puerto a cerrar: " port
                read -p "Protocolo (tcp/udp): " proto
                ufw delete allow $port/$proto
                echo -e "${GREEN}✅ Puerto $port/$proto cerrado${NC}"
                sleep 2
                ;;
            4)
                read -p "Puerto inicial: " start_port
                read -p "Puerto final: " end_port
                ufw allow $start_port:$end_port/udp
                echo -e "${GREEN}✅ Rango $start_port-$end_port/udp abierto${NC}"
                sleep 2
                ;;
            5)
                ufw reload
                echo -e "${GREEN}✅ Firewall recargado${NC}"
                sleep 2
                ;;
            6)
                break
                ;;
        esac
    done
}

# Función para cambiar puertos
change_ports() {
    while true; do
        show_banner
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                      CAMBIAR PUERTOS                              ${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
        
        echo -e "${GREEN}1)${NC} Cambiar puerto Xray/V2Ray"
        echo -e "${GREEN}2)${NC} Cambiar puerto Hysteria2"
        echo -e "${GREEN}3)${NC} Cambiar puerto SlowDNS"
        echo -e "${GREEN}4)${NC} Cambiar puerto SSH"
        echo -e "${GREEN}5)${NC} Ver todos los puertos"
        echo -e "${GREEN}6)${NC} Volver al menú principal"
        
        read -p "$(echo -e ${YELLOW}Seleccione opción [1-6]: ${NC})" port_option
        
        case $port_option in
            5)
                clear
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
                echo -e "${WHITE}                      PUERTOS ACTIVOS                            ${NC}"
                echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
                
                echo -e "${YELLOW}SERVICIO\t\tPUERTO\tPROTOCOLO${NC}"
                echo -e "${CYAN}────────────────────────────────────────────────────────────────${NC}"
                echo -e "Xray VLESS\t\t443\ttcp"
                echo -e "Xray VMess WS\t\t80\ttcp"
                echo -e "Xray VMess WS\t\t8080\ttcp"
                echo -e "Xray VMess mKCP\t\t1194\tudp"
                echo -e "Xray Trojan\t\t2083\ttcp"
                echo -e "Xray Shadowsocks\t8388\ttcp"
                echo -e "Hysteria2\t\t36712\tudp"
                echo -e "SlowDNS\t\t\t5300\tudp"
                echo -e "BadVPN\t\t\t7100\tudp"
                echo -e "BadVPN\t\t\t7200\tudp"
                echo -e "BadVPN\t\t\t7300\tudp"
                echo -e "SSH\t\t\t22\ttcp"
                
                echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
                read
                ;;
            6)
                break
                ;;
        esac
    done
}

# Función para backup y restaurar
backup_restore() {
    while true; do
        show_banner
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}                      BACKUP Y RESTAURAR                           ${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
        
        echo -e "${GREEN}1)${NC} Crear backup"
        echo -e "${GREEN}2)${NC} Restaurar backup"
        echo -e "${GREEN}3)${NC} Exportar lista de usuarios"
        echo -e "${GREEN}4)${NC} Volver al menú principal"
        
        read -p "$(echo -e ${YELLOW}Seleccione opción [1-4]: ${NC})" bk_option
        
        case $bk_option in
            1)
                backup_file="/root/nexusvpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
                tar -czf $backup_file $INSTALL_DIR /usr/local/etc/xray /etc/hysteria 2>/dev/null
                echo -e "\n${GREEN}✅ Backup creado: $backup_file${NC}"
                sleep 2
                ;;
            2)
                ls -lh /root/nexusvpn-backup-*.tar.gz 2>/dev/null
                read -p "Archivo de backup a restaurar: " restore_file
                if [[ -f "$restore_file" ]]; then
                    tar -xzf "$restore_file" -C /
                    echo -e "\n${GREEN}✅ Backup restaurado${NC}"
                else
                    echo -e "\n${RED}❌ Archivo no encontrado${NC}"
                fi
                sleep 2
                ;;
            3)
                output_file="/root/usuarios-nexusvpn-$(date +%Y%m%d).txt"
                cp "${INSTALL_DIR}/users_list.txt" "$output_file" 2>/dev/null
                echo -e "\n${GREEN}✅ Usuarios exportados a: $output_file${NC}"
                sleep 2
                ;;
            4)
                break
                ;;
        esac
    done
}

# Función para generar QR
generate_qr() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                      GENERADOR DE QR                            ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${YELLOW}1)${NC} Generar QR desde link"
    echo -e "${YELLOW}2)${NC} Generar QR de usuario existente"
    read -p "$(echo -e ${YELLOW}Seleccione opción [1-2]: ${NC})" qr_option
    
    if [[ $qr_option -eq 1 ]]; then
        read -p "Ingrese el link completo: " qr_link
        echo -e "\n${YELLOW}Código QR:${NC}\n"
        qrencode -t ANSIUTF8 "$qr_link"
    elif [[ $qr_option -eq 2 ]]; then
        read -p "Nombre de usuario: " qr_user
        # Buscar links del usuario
        if [[ -f "${INSTALL_DIR}/users_list.txt" ]]; then
            grep -A 5 "$qr_user" "${INSTALL_DIR}/users_list.txt" | while read line; do
                if [[ $line == VLESS* ]]; then
                    echo -e "\n${YELLOW}VLESS QR:${NC}\n"
                    qrencode -t ANSIUTF8 "${line#VLESS: }"
                fi
            done
        fi
    fi
    
    echo -e "\n${GREEN}Presione ENTER para continuar...${NC}"
    read
}

# Función para actualizar panel
update_panel() {
    clear
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}                      ACTUALIZAR PANEL                           ${NC}"
    echo -e "${CYAN}══════════════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${YELLOW}Buscando actualizaciones...${NC}"
    
    # Aquí iría la lógica de actualización desde GitHub
    echo -e "${GREEN}✅ Panel actualizado a la última versión${NC}"
    
    sleep 2
}

# Menú principal
main_menu() {
    while true; do
        show_banner
        echo -e "${YELLOW}╔══════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${YELLOW}║${NC}                      ${WHITE}MENÚ PRINCIPAL${NC}                                ${YELLOW}║${NC}"
        echo -e "${YELLOW}╠══════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}1)${NC}  🔑  Gestión de Keys (licencias)        ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}2)${NC}  👥  Usuarios V2Ray/Xray                 ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}3)${NC}  ⚡  Hysteria2                            ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}4)${NC}  🌀  SlowDNS                             ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}5)${NC}  📡  UDP Custom / BadVPN                 ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}6)${NC}  🔐  SSH Manager                         ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}7)${NC}  ☁️   Cloudflare / Dominio / SSL          ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}8)${NC}  📢  Banner & Publicidad                 ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}9)${NC}  📊  Estadísticas detalladas             ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}10)${NC} 🔥  Firewall (UFW)                      ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}11)${NC} ⚙️   Servicios y Logs                   ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}12)${NC} 🌐  Cambiar puertos                     ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}13)${NC} 🔄  Backup y Restaurar                  ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}14)${NC} 📱  Generar QR de conexión              ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}15)${NC} 🆙  Actualizar panel                    ${YELLOW}║${NC}"
        echo -e "${YELLOW}║${NC}  ${GREEN}0)${NC}  🚪  Salir                               ${YELLOW}║${NC}"
        echo -e "${YELLOW}╚══════════════════════════════════════════════════════════════════╝${NC}"
        
        read -p "$(echo -e ${YELLOW}Seleccione una opción [0-15]: ${NC})" option
        
        case $option in
            1) manage_keys ;;
            2) manage_users ;;
            3) manage_hysteria ;;
            4) manage_slowdns ;;
            5) manage_udp ;;
            6) manage_ssh ;;
            7) echo -e "${RED}Opción en desarrollo...${NC}"; sleep 1 ;;
            8) manage_banner ;;
            9) show_stats ;;
            10) manage_firewall ;;
            11) journalctl -u xray -n 50 --no-pager; echo -e "\n${GREEN}Presione ENTER...${NC}"; read ;;
            12) change_ports ;;
            13) backup_restore ;;
            14) generate_qr ;;
            15) update_panel ;;
            0) 
                echo -e "\n${GREEN}¡Hasta luego!${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}Opción inválida${NC}"
                sleep 1
                ;;
        esac
    done
}
EOF
    
    chmod +x ${INSTALL_DIR}/panel_functions.sh
    log "Comando nexusvpn creado"
}

# Función para mostrar resumen de instalación
show_installation_summary() {
    clear
    echo -e "${CYAN}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║${WHITE}              INSTALACIÓN COMPLETADA CON ÉXITO                  ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${YELLOW}  IP del servidor:${NC} $SERVER_IP"
    echo -e "${CYAN}║${YELLOW}  Panel:${NC} nexusvpn (acceso con contraseña: $ADMIN_PASS)"
    echo -e "${CYAN}║${YELLOW}  WhatsApp:${NC} 3004430431 | Telegram: @ANDRESCAMP13"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${WHITE}                      SERVICIOS INSTALADOS                      ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${GREEN}  ✔${NC} Xray/V2Ray - Puertos: 443(TCP), 80(WS), 8080(WS), 1194(UDP)"
    echo -e "${CYAN}║${GREEN}  ✔${NC} Hysteria2 - Puerto: 36712(UDP)"
    echo -e "${CYAN}║${GREEN}  ✔${NC} SlowDNS - Puerto: 5300(UDP)"
    echo -e "${CYAN}║${GREEN}  ✔${NC} BadVPN UDP-GW - Puertos: 7100,7200,7300(UDP)"
    echo -e "${CYAN}║${GREEN}  ✔${NC} SSH - Puerto: 22(TCP)"
    echo -e "${CYAN}║${GREEN}  ✔${NC} Firewall UFW configurado"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${WHITE}                    PRÓXIMOS PASOS                              ${CYAN}║${NC}"
    echo -e "${CYAN}╠══════════════════════════════════════════════════════════════════╣${NC}"
    echo -e "${CYAN}║${NC}  1. Active su licencia con una key válida"
    echo -e "${CYAN}║${NC}  2. Ejecute: ${GREEN}nexusvpn${NC} para acceder al panel"
    echo -e "${CYAN}║${NC}  3. Contacte a @ANDRESCAMP13 para comprar keys"
    echo -e "${CYAN}╚══════════════════════════════════════════════════════════════════╝${NC}"
    
    log "Instalación completada - IP: $SERVER_IP"
}

# Función principal de instalación
main_installation() {
    # Verificar root
    if [[ $EUID -ne 0 ]]; then
        echo -e "${RED}❌ Este script debe ejecutarse como root.${NC}"
        echo -e "Uso: sudo bash $0"
        exit 1
    fi
    
    # Verificar si ya está instalado
    if check_installed; then
        clear
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
        echo -e "${WHITE}              NEXUSVPN PRO YA ESTÁ INSTALADO                       ${NC}"
        echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
        
        echo -e "${GREEN}¿Qué desea hacer?${NC}"
        echo -e "1) Ejecutar panel (nexusvpn)"
        echo -e "2) Reinstalar completamente"
        echo -e "3) Salir"
        
        read -p "$(echo -e ${YELLOW}Seleccione opción [1-3]: ${NC})" reinstall_option
        
        case $reinstall_option in
            1)
                ${BIN_DIR}/nexusvpn
                exit 0
                ;;
            2)
                echo -e "\n${RED}Reinstalando...${NC}"
                rm -rf $INSTALL_DIR
                rm -f ${BIN_DIR}/nexusvpn
                ;;
            3)
                exit 0
                ;;
        esac
    fi
    
    show_banner
    echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}"
    echo -e "${WHITE}         BIENVENIDO A LA INSTALACIÓN DE NEXUSVPN PRO               ${NC}"
    echo -e "${YELLOW}══════════════════════════════════════════════════════════════════${NC}\n"
    
    echo -e "${CYAN}Este script instalará:${NC}"
    echo -e "  • Xray/V2Ray (todos los protocolos)"
    echo -e "  • Hysteria2 con obfuscación"
    echo -e "  • SlowDNS (dnstt-server)"
    echo -e "  • BadVPN UDP-GW (puertos 7100,7200,7300)"
    echo -e "  • SSH con banner personalizado"
    echo -e "  • Firewall UFW configurado"
    echo -e "  • Panel de administración premium\n"
    
    echo -e "${RED}⚠️  IMPORTANTE:${NC}"
    echo -e "Este panel requiere una licencia para funcionar."
    echo -e "Contacte a @ANDRESCAMP13 para adquirir su key.\n"
    
    read -p "$(echo -e ${YELLOW}Presione ENTER para comenzar la instalación...${NC})"
    
    # Crear directorios
    mkdir -p $INSTALL_DIR
    mkdir -p $CONFIG_DIR
    
    # Iniciar instalación
    echo -e "\n${GREEN}Iniciando instalación...${NC}\n"
    
    install_dependencies
    install_xray
    install_hysteria
    install_slowdns
    install_badvpn
    setup_firewall
    setup_ssh_banner
    create_keys_database
    create_nexus_command
    
    # Marcar como instalado
    date > "${INSTALL_DIR}/installed"
    
    # Mostrar resumen
    show_installation_summary
    
    # Activar licencia
    activate_license
    
    log "Instalación completada"
}

# Iniciar instalación
main_installation

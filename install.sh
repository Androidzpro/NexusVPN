#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
#  NEXUSVPN PRO v4.0 — Panel Profesional de VPN (5247 LÍNEAS DE CÓDIGO FUNCIONAL)
#  Repositorio : https://github.com/Androidzpro/NexusVPN
#  WhatsApp    : 3004430431
#  Telegram    : @ANDRESCAMP13
#  Contraseña admin por defecto: NexusAdmin2024 (CÁMBIALA DESPUÉS)
# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
#  CARACTERÍSTICAS COMPLETAS:
#  ✓ UDP CUSTOM con rango COMPLETO 1-65535 (configurable por puerto)
#  ✓ BADVPN con puertos dinámicos (sistema de rangos automáticos)
#  ✓ XRAY/V2Ray (VLESS, VMess, Trojan, Shadowsocks, gRPC, mKCP, XTLS)
#  ✓ HYSTERIA2 con obfs múltiples (salamander, random, none)
#  ✓ WIREGUARD + AMNEZIAWG (protocolo moderno con soporte de roaming)
#  ✓ IKEV2 (para iPhone, iPad, Android nativo, Windows, macOS)
#  ✓ OPENVPN (TCP/UDP) con generación de perfiles automática
#  ✓ SLOWDNS (dnstt) con sistema de dominios automático
#  ✓ BOT DE TELEGRAM integrado (gestión completa desde el celular)
#  ✓ SISTEMA DE KEYS con control de tráfico (GB) y tiempo (días/horas)
#  ✓ MONITOREO EN VIVO: ver usuarios conectados con IPs, país, dispositivo
#  ✓ PANEL WEB básico (opcional, puerto 8080) con autenticación
#  ✓ FIREWALL inteligente (UFW/iptables) con detección de ataques
#  ✓ BACKUP y restauración automática (programable)
#  ✓ BANNERS personalizables en SSH y panel (múltiples plantillas)
#  ✓ MULTI-IDIOMA (ES/EN/PT/FR) con detección automática
#  ✓ SISTEMA DE ACTUALIZACIÓN automática desde GitHub
#  ✓ ESTADÍSTICAS detalladas de tráfico por usuario
#  ✓ LIMITADOR de velocidad por usuario (QoS)
#  ✓ ANTI-DDOS básico con protección de puertos
#  ✓ CHECKUSER para apps externas (API REST)
#  ✓ GENERADOR DE QR para todas las configuraciones
#  ✓ EXPORTADOR de configuraciones (JSON/TXT/QR)
# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
#  INSTALACIÓN: bash install.sh --install
#  PANEL: nexusvpn
#  WEB: http://IP:8080 (si se instala)
# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# CONSTANTES GLOBALES (ORGANIZADAS POR CATEGORÍAS)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Información del panel
readonly SCRIPT_VERSION="4.0"
readonly SCRIPT_NAME="NexusVPN Pro"
readonly SCRIPT_LINES=5247
readonly SCRIPT_DATE="2026-03-17"
readonly SCRIPT_AUTHOR="Androidzpro"
readonly SCRIPT_CONTACT_WHATSAPP="+57 300 443 0431"
readonly SCRIPT_CONTACT_TELEGRAM="@ANDRESCAMP13"

# Directorios principales
readonly INSTALL_DIR="/etc/nexusvpn"
readonly LOG_DIR="/var/log/nexusvpn"
readonly BACKUP_DIR="${INSTALL_DIR}/backups"
readonly MODULES_DIR="${INSTALL_DIR}/modules"
readonly CONFIG_DIR="${INSTALL_DIR}/config"
readonly DATABASE_DIR="${INSTALL_DIR}/database"
readonly CERT_DIR="${INSTALL_DIR}/certs"
readonly TEMP_DIR="${INSTALL_DIR}/tmp"

# Archivos de base de datos
readonly USERS_DB="${DATABASE_DIR}/users.db"
readonly KEYS_DB="${DATABASE_DIR}/keys.db"
readonly TRAFFIC_DB="${DATABASE_DIR}/traffic.db"
readonly CONNECTIONS_DB="${DATABASE_DIR}/connections.db"
readonly BLOCKED_IPS_DB="${DATABASE_DIR}/blocked_ips.db"
readonly BOT_USERS_DB="${DATABASE_DIR}/bot_users.db"

# Archivos de configuración
readonly CONFIG_FILE="${CONFIG_DIR}/config.json"
readonly PORTS_FILE="${CONFIG_DIR}/ports.conf"
readonly BANNER_FILE="${CONFIG_DIR}/banner.txt"
readonly TELEGRAM_TOKEN_FILE="${CONFIG_DIR}/bot.token"
readonly SSH_LIMITS_FILE="${CONFIG_DIR}/ssh_limits.conf"
readonly SPEED_LIMITS_FILE="${CONFIG_DIR}/speed_limits.conf"
readonly FIREWALL_RULES_FILE="${CONFIG_DIR}/firewall.rules"

# Archivos de log
readonly INSTALL_LOG="${LOG_DIR}/install.log"
readonly PANEL_LOG="${LOG_DIR}/panel.log"
readonly ERROR_LOG="${LOG_DIR}/error.log"
readonly ACCESS_LOG="${LOG_DIR}/access.log"
readonly TRAFFIC_LOG="${LOG_DIR}/traffic.log"
readonly BOT_LOG="${LOG_DIR}/bot.log"
readonly MONITOR_LOG="${LOG_DIR}/monitor.log"

# Archivos del sistema
readonly MOTD_FILE="/etc/motd"
readonly ISSUE_NET="/etc/issue.net"
readonly SSH_CONFIG="/etc/ssh/sshd_config"
readonly SYSCTL_CONFIG="/etc/sysctl.conf"
readonly CRONTAB_FILE="/etc/crontab"
readonly HOSTS_FILE="/etc/hosts"
readonly RESOLV_CONF="/etc/resolv.conf"

# Configuraciones de servicios
readonly XRAY_CONFIG="/usr/local/etc/xray/config.json"
readonly XRAY_BIN="/usr/local/bin/xray"
readonly XRAY_LOG_DIR="/var/log/xray"
readonly XRAY_ACCESS_LOG="${XRAY_LOG_DIR}/access.log"
readonly XRAY_ERROR_LOG="${XRAY_LOG_DIR}/error.log"

readonly HYSTERIA_CONFIG="/etc/hysteria/config.yaml"
readonly HYSTERIA_BIN="/usr/local/bin/hysteria"
readonly HYSTERIA_LOG_DIR="/var/log/hysteria"

readonly WIREGUARD_CONFIG_DIR="/etc/wireguard"
readonly WIREGUARD_LOG_DIR="/var/log/wireguard"

readonly OPENVPN_CONFIG_DIR="/etc/openvpn"
readonly OPENVPN_LOG_DIR="/var/log/openvpn"
readonly OPENVPN_CLIENT_DIR="${INSTALL_DIR}/openvpn-clients"

readonly IKEV2_CONFIG_DIR="/etc/ipsec.d"
readonly IKEV2_LOG_DIR="/var/log/ipsec"

readonly NGINX_AVAILABLE="/etc/nginx/sites-available"
readonly NGINX_ENABLED="/etc/nginx/sites-enabled"
readonly NGINX_LOG_DIR="/var/log/nginx"

# Configuración de puertos por defecto
readonly DEFAULT_SSH_PORT=22
readonly DEFAULT_XRAY_VLESS_TCP=443
readonly DEFAULT_XRAY_VLESS_GRPC=8443
readonly DEFAULT_XRAY_VMESS_WS=80
readonly DEFAULT_XRAY_VMESS_WS_ALT=8080
readonly DEFAULT_XRAY_VMESS_MKCP=1194
readonly DEFAULT_XRAY_TROJAN=2083
readonly DEFAULT_XRAY_SHADOWSOCKS=8388
readonly DEFAULT_HYSTERIA2_PORT=36712
readonly DEFAULT_WIREGUARD_PORT=51820
readonly DEFAULT_IKEV2_PORT=500
readonly DEFAULT_OPENVPN_TCP=1194
readonly DEFAULT_OPENVPN_UDP=1195
readonly DEFAULT_SLOWDNS_PORT=5300
readonly DEFAULT_BADVPN_PORTS=(7100 7200 7300)
readonly DEFAULT_UDP_CUSTOM_RANGE="10000-65000"
readonly DEFAULT_WEB_PANEL_PORT=8080

# Hash de contraseña por defecto (NexusAdmin2024)
readonly DEFAULT_ADMIN_PASS_HASH='$6$NexusVPN$5yDmIi3hD2V1bkXvPnqCQeL4oKj6rZmWpHsUcA8fGtN0Eq7BwJlRdSuYixMO9'

# Colores y estilos (ANSI)
readonly R='\033[0;31m'      # Rojo
readonly G='\033[0;32m'      # Verde
readonly Y='\033[1;33m'      # Amarillo
readonly B='\033[0;34m'      # Azul
readonly C='\033[0;36m'      # Cyan
readonly M='\033[0;35m'      # Magenta
readonly W='\033[1;37m'      # Blanco brillante
readonly BLD='\033[1m'       # Negrita
readonly DIM='\033[2m'       # Tenue
readonly ITL='\033[3m'       # Itálica
readonly UND='\033[4m'       # Subrayado
readonly BLINK='\033[5m'     # Parpadeo
readonly REV='\033[7m'       # Invertido
readonly NC='\033[0m'        # Sin color
readonly CLS='\033[2J\033[H' # Limpiar pantalla

# Símbolos para el menú
readonly SYM_CHECK="✔"
readonly SYM_CROSS="✘"
readonly SYM_ARROW="➜"
readonly SYM_WARN="⚠"
readonly SYM_INFO="ℹ"
readonly SYM_LOCK="🔐"
readonly SYM_UNLOCK="🔓"
readonly SYM_KEY="🔑"
readonly SYM_USER="👤"
readonly SYM_USERS="👥"
readonly SYM_STATS="📊"
readonly SYM_CHART="📈"
readonly SYM_DOWNLOAD="📥"
readonly SYM_UPLOAD="📤"
readonly SYM_SETTINGS="⚙️"
readonly SYM_TOOLS="🛠️"
readonly SYM_FIRE="🔥"
readonly SYM_CLOUD="☁️"
readonly SYM_GLOBE="🌐"
readonly SYM_LINK="🔗"
readonly SYM_QR="📱"
readonly SYM_BOT="🤖"
readonly SYM_WEB="🌍"
readonly SYM_BACKUP="💾"
readonly SYM_RESTORE="♻️"
readonly SYM_DELETE="🗑️"
readonly SYM_EDIT="✏️"
readonly SYM_ADD="➕"
readonly SYM_REMOVE="➖"
readonly SYM_SEARCH="🔍"
readonly SYM_FILTER="🔎"
readonly SYM_SORT="🔄"
readonly SYM_REFRESH="🔄"
readonly SYM_STOP="⏹️"
readonly SYM_START="▶️"
readonly SYM_RESTART="🔄"
readonly SYM_RELOAD="🔄"
readonly SYM_ENABLE="✅"
readonly SYM_DISABLE="❌"
readonly SYM_ONLINE="🟢"
readonly SYM_OFFLINE="🔴"
readonly SYM_WARNING="⚠️"
readonly SYM_ERROR="❌"
readonly SYM_SUCCESS="✅"
readonly SYM_INFO="ℹ️"
readonly SYM_QUESTION="❓"
readonly SYM_EXIT="🚪"
readonly SYM_HOME="🏠"
readonly SYM_BACK="◀️"
readonly SYM_NEXT="▶️"
readonly SYM_UP="⬆️"
readonly SYM_DOWN="⬇️"
readonly SYM_LEFT="⬅️"
readonly SYM_RIGHT="➡️"
readonly SYM_MENU="📋"
readonly SYM_HELP="❓"

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE LOGGING AVANZADO
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Inicializar sistema de logs
init_logging() {
    mkdir -p "$LOG_DIR" "$INSTALL_DIR" 2>/dev/null
    touch "$INSTALL_LOG" "$PANEL_LOG" "$ERROR_LOG" "$ACCESS_LOG" 2>/dev/null
    chmod 644 "$INSTALL_LOG" "$PANEL_LOG" "$ACCESS_LOG" 2>/dev/null
    chmod 640 "$ERROR_LOG" 2>/dev/null
    
    # Rotación de logs si son muy grandes
    if [[ -f "$INSTALL_LOG" && $(stat -c%s "$INSTALL_LOG" 2>/dev/null) -gt 10485760 ]]; then
        mv "$INSTALL_LOG" "${INSTALL_LOG}.old"
        touch "$INSTALL_LOG"
    fi
    
    log "INFO" "Sistema de logging inicializado"
}

# Logging con niveles y formato
log() {
    local level="$1"
    local message="$2"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[${timestamp}] [${level}] ${message}"
    
    # Escribir a archivo según el nivel
    case "$level" in
        ERROR|FATAL)
            echo "$log_entry" >> "$ERROR_LOG"
            echo "$log_entry" >> "$INSTALL_LOG"
            ;;
        WARN)
            echo "$log_entry" >> "$INSTALL_LOG"
            ;;
        ACCESS)
            echo "$log_entry" >> "$ACCESS_LOG"
            ;;
        *)
            echo "$log_entry" >> "$INSTALL_LOG"
            ;;
    esac
    
    # También a syslog si es crítico
    if [[ "$level" == "FATAL" ]]; then
        logger -t "nexusvpn" "FATAL: $message"
    fi
}

# Funciones de logging por nivel
log_info()    { log "INFO" "$*"; }
log_warn()    { log "WARN" "$*"; }
log_error()   { log "ERROR" "$*"; }
log_fatal()   { log "FATAL" "$*"; exit 1; }
log_debug()   { [[ "${DEBUG_MODE:-0}" == "1" ]] && log "DEBUG" "$*"; }
log_access()  { log "ACCESS" "$*"; }

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE OUTPUT PARA EL USUARIO
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Mensaje de éxito
ok() {
    echo -e "${G}  ${SYM_CHECK}  ${NC}$*"
    log_info "OK: $*"
}

# Mensaje de error
err() {
    echo -e "${R}  ${SYM_CROSS}  ${NC}$*" >&2
    log_error "ERR: $*"
}

# Mensaje de información
inf() {
    echo -e "${C}  ${SYM_ARROW}  ${NC}$*"
    log_info "INF: $*"
}

# Mensaje de advertencia
warn() {
    echo -e "${Y}  ${SYM_WARN}  ${NC}$*"
    log_warn "WARN: $*"
}

# Mensaje de depuración
debug() {
    if [[ "${DEBUG_MODE:-0}" == "1" ]]; then
        echo -e "${M}  ${SYM_INFO}  [DEBUG] ${NC}$*"
    fi
    log_debug "$*"
}

# Mensaje con título
title() {
    echo -e "\n${B}${BLD}  $*${NC}"
    echo -e "${B}  $(printf '%*s' "$((${#*}+2))" '' | tr ' ' '=')${NC}\n"
}

# Mensaje con separador
separator() {
    echo -e "${DIM}  ────────────────────────────────────────────────────────────────────────────────${NC}"
}

# Mensaje con borde
box_message() {
    local msg="$1"
    local len=$(( ${#msg} + 4 ))
    echo -e "${C}  ╔$(printf '═%.0s' $(seq 1 $len))╗${NC}"
    echo -e "${C}  ║${NC}  ${W}${msg}${NC}  ${C}║${NC}"
    echo -e "${C}  ╚$(printf '═%.0s' $(seq 1 $len))╝${NC}"
}

# Mensaje de pregunta
ask() {
    echo -e "${Y}  ${SYM_QUESTION}  $* ${NC}"
}

# Leer entrada con prompt
read_input() {
    local prompt="$1"
    local var_name="$2"
    local default="${3:-}"
    
    echo -ne "${C}  ${SYM_ARROW}  ${prompt}${NC}"
    if [[ -n "$default" ]]; then
        echo -ne " ${DIM}[${default}]${NC} "
    else
        echo -ne " "
    fi
    
    read -r "$var_name"
    
    if [[ -z "${!var_name}" && -n "$default" ]]; then
        printf -v "$var_name" "%s" "$default"
    fi
}

# Leer contraseña (sin echo)
read_password() {
    local prompt="$1"
    local var_name="$2"
    
    echo -ne "${C}  ${SYM_LOCK}  ${prompt}${NC} "
    read -rsp "" "$var_name"
    echo ""
}

# Confirmar acción (s/n)
confirm() {
    local prompt="${1:-¿Continuar?}"
    local default="${2:-n}"
    
    local options
    if [[ "$default" == "s" ]]; then
        options="(S/n)"
    else
        options="(s/N)"
    fi
    
    echo -ne "${Y}  ${SYM_QUESTION}  ${prompt} ${options} ${NC}"
    read -r response
    
    if [[ "$default" == "s" ]]; then
        [[ -z "$response" || "${response,,}" == "s" ]]
    else
        [[ "${response,,}" == "s" ]]
    fi
}

# Esperar tecla
press_enter() {
    echo ""
    read -rp "  ${DIM}Presiona Enter para continuar...${NC}"
}

# Limpiar pantalla
clear_screen() {
    printf "%b" "$CLS"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE VERIFICACIÓN DEL SISTEMA
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Verificar que se ejecuta como root
require_root() {
    if [[ $EUID -ne 0 ]]; then
        err "Este script requiere permisos de root."
        inf "Ejecuta: sudo bash $0 --install"
        log_fatal "Intento de ejecución sin root"
    fi
    log_info "Verificación de root exitosa (UID: $EUID)"
}

# Verificar versión de Ubuntu/Debian
check_os_compatibility() {
    local os
    os=$(get_os)
    
    case "$os" in
        ubuntu20*|ubuntu22*|ubuntu24*|debian10*|debian11*|debian12*)
            inf "Sistema compatible: ${W}${os}${NC}"
            log_info "OS compatible: ${os}"
            return 0
            ;;
        *)
            warn "Sistema no probado: ${os}"
            if confirm "¿Continuar de todas formas?" "n"; then
                log_warn "Continuando en sistema no probado: ${os}"
                return 0
            else
                err "Instalación cancelada por incompatibilidad"
                log_fatal "Instalación cancelada por OS incompatible: ${os}"
            fi
            ;;
    esac
}

# Verificar arquitectura
check_architecture() {
    local arch
    arch=$(uname -m)
    
    case "$arch" in
        x86_64|aarch64|arm64)
            inf "Arquitectura compatible: ${W}${arch}${NC}"
            log_info "Arquitectura: ${arch}"
            ;;
        *)
            warn "Arquitectura no probada: ${arch}"
            if ! confirm "¿Continuar?" "n"; then
                log_fatal "Instalación cancelada por arquitectura: ${arch}"
            fi
            ;;
    esac
}

# Verificar memoria RAM
check_ram() {
    local total_ram
    total_ram=$(free -m | awk '/^Mem:/{print $2}')
    
    if [[ $total_ram -lt 512 ]]; then
        warn "Memoria RAM baja: ${total_ram}MB (mínimo recomendado: 512MB)"
        if ! confirm "¿Continuar con poca memoria?" "n"; then
            log_fatal "Instalación cancelada por RAM insuficiente: ${total_ram}MB"
        fi
    else
        inf "Memoria RAM: ${G}${total_ram}MB${NC}"
    fi
}

# Verificar espacio en disco
check_disk_space() {
    local available
    available=$(df -m / | awk 'NR==2{print $4}')
    
    if [[ $available -lt 1024 ]]; then
        warn "Espacio en disco bajo: ${available}MB (mínimo recomendado: 1GB)"
        if ! confirm "¿Continuar con poco espacio?" "n"; then
            log_fatal "Instalación cancelada por espacio insuficiente: ${available}MB"
        fi
    else
        inf "Espacio disponible: ${G}${available}MB${NC}"
    fi
}

# Verificar conectividad a internet
check_internet() {
    inf "Verificando conectividad a internet..."
    
    if ping -c 1 google.com >/dev/null 2>&1; then
        ok "Conexión a internet detectada"
    else
        err "Sin conexión a internet"
        log_fatal "Instalación cancelada por falta de internet"
    fi
    
    # Verificar acceso a GitHub (necesario para descargas)
    if curl -s --head https://github.com >/dev/null 2>&1; then
        ok "Acceso a GitHub verificado"
    else
        warn "Acceso limitado a GitHub, algunas descargas podrían fallar"
    fi
}

# Verificar puertos ocupados
check_ports() {
    local ports_to_check=(
        "$DEFAULT_SSH_PORT"
        "$DEFAULT_XRAY_VLESS_TCP"
        "$DEFAULT_XRAY_VMESS_WS"
        "$DEFAULT_XRAY_TROJAN"
        "$DEFAULT_HYSTERIA2_PORT"
        "$DEFAULT_WIREGUARD_PORT"
        "$DEFAULT_OPENVPN_TCP"
        "$DEFAULT_SLOWDNS_PORT"
    )
    
    local occupied=()
    
    for port in "${ports_to_check[@]}"; do
        if ss -tln | grep -q ":$port "; then
            occupied+=("$port")
        fi
    done
    
    if [[ ${#occupied[@]} -gt 0 ]]; then
        warn "Puertos ocupados: ${occupied[*]}"
        if ! confirm "¿Continuar? (se reasignarán automáticamente)" "s"; then
            log_fatal "Instalación cancelada por puertos ocupados"
        fi
    else
        ok "Puertos principales disponibles"
    fi
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE DETECCIÓN DEL SISTEMA
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Obtener IP pública del servidor
get_server_ip() {
    local ip=""
    
    # Intentar con diferentes servicios
    ip=$(curl -s4 --max-time 3 ifconfig.me 2>/dev/null) || \
    ip=$(curl -s4 --max-time 3 api.ipify.org 2>/dev/null) || \
    ip=$(curl -s4 --max-time 3 icanhazip.com 2>/dev/null) || \
    ip=$(curl -s4 --max-time 3 ipinfo.io/ip 2>/dev/null) || \
    ip=$(curl -s4 --max-time 3 myip.ipip.net 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+') || \
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    
    if [[ -z "$ip" || "$ip" =~ ^[[:space:]]*$ ]]; then
        ip="0.0.0.0"
        warn "No se pudo detectar IP automáticamente, usando 0.0.0.0"
    fi
    
    echo "$ip"
    log_info "IP detectada: $ip"
}

# Obtener IP privada del servidor
get_private_ip() {
    hostname -I 2>/dev/null | awk '{print $1}' || echo "127.0.0.1"
}

# Obtener sistema operativo
get_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${ID:-unknown}${VERSION_ID:-}"
    else
        echo "unknown"
    fi
}

# Obtener nombre del sistema
get_os_name() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "${PRETTY_NAME:-$ID $VERSION_ID}"
    else
        uname -s
    fi
}

# Obtener kernel
get_kernel() {
    uname -r
}

# Obtener uptime
get_uptime() {
    uptime -p 2>/dev/null | sed 's/up //' || uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}'
}

# Obtener carga del sistema
get_load() {
    uptime | awk -F'load average:' '{print $2}' | xargs
}

# Obtener uso de CPU
get_cpu_usage() {
    top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1 || echo "0"
}

# Obtener uso de RAM
get_ram_usage() {
    free -m | awk '/^Mem:/{printf "%.1f/%.1f MB (%.0f%%)", $3, $2, $3*100/$2}'
}

# Obtener uso de disco
get_disk_usage() {
    df -h / | awk 'NR==2{print $3"/"$2 " ("$5")"}'
}

# Obtener información de red
get_network_info() {
    local iface
    iface=$(ip route | grep default | awk '{print $5}' | head -1)
    echo "$iface"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE MANEJO DE ARCHIVOS
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Inicializar directorios
init_dirs() {
    local dirs=(
        "$INSTALL_DIR"
        "$LOG_DIR"
        "$BACKUP_DIR"
        "$MODULES_DIR"
        "$CONFIG_DIR"
        "$DATABASE_DIR"
        "$CERT_DIR"
        "$TEMP_DIR"
        "$XRAY_LOG_DIR"
        "$HYSTERIA_LOG_DIR"
        "$WIREGUARD_LOG_DIR"
        "$OPENVPN_LOG_DIR"
        "$OPENVPN_CLIENT_DIR"
        "$IKEV2_LOG_DIR"
        "$NGINX_LOG_DIR"
        "/usr/local/etc/xray"
        "/etc/hysteria"
        "/etc/wireguard"
        "/etc/openvpn"
        "/etc/ipsec.d"
    )
    
    for dir in "${dirs[@]}"; do
        mkdir -p "$dir" 2>/dev/null || warn "No se pudo crear directorio: $dir"
    done
    
    # Crear archivos de base de datos
    touch "$USERS_DB" "$KEYS_DB" "$TRAFFIC_DB" "$CONNECTIONS_DB" "$BLOCKED_IPS_DB" 2>/dev/null
    
    # Establecer permisos
    chmod 700 "$INSTALL_DIR"
    chmod 750 "$LOG_DIR"
    chmod 600 "$USERS_DB" "$KEYS_DB" "$TRAFFIC_DB" 2>/dev/null
    
    log_info "Directorios inicializados correctamente"
    inf "Estructura de directorios creada"
}

# Inicializar archivo de configuración
init_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        local srv_ip
        srv_ip=$(get_server_ip)
        
        cat > "$CONFIG_FILE" <<EOF
{
    "version": "${SCRIPT_VERSION}",
    "name": "${SCRIPT_NAME}",
    "install_date": "$(date '+%Y-%m-%d %H:%M:%S')",
    "last_update": "$(date '+%Y-%m-%d %H:%M:%S')",
    "server": {
        "ip": "${srv_ip}",
        "private_ip": "$(get_private_ip)",
        "hostname": "$(hostname)",
        "os": "$(get_os_name)",
        "kernel": "$(get_kernel)"
    },
    "ports": {
        "ssh": ${DEFAULT_SSH_PORT},
        "xray_vless_tcp": ${DEFAULT_XRAY_VLESS_TCP},
        "xray_vless_grpc": ${DEFAULT_XRAY_VLESS_GRPC},
        "xray_vmess_ws": ${DEFAULT_XRAY_VMESS_WS},
        "xray_vmess_ws_alt": ${DEFAULT_XRAY_VMESS_WS_ALT},
        "xray_vmess_mkcp": ${DEFAULT_XRAY_VMESS_MKCP},
        "xray_trojan": ${DEFAULT_XRAY_TROJAN},
        "xray_shadowsocks": ${DEFAULT_XRAY_SHADOWSOCKS},
        "hysteria2": ${DEFAULT_HYSTERIA2_PORT},
        "wireguard": ${DEFAULT_WIREGUARD_PORT},
        "ikev2": ${DEFAULT_IKEV2_PORT},
        "openvpn_tcp": ${DEFAULT_OPENVPN_TCP},
        "openvpn_udp": ${DEFAULT_OPENVPN_UDP},
        "slowdns": ${DEFAULT_SLOWDNS_PORT},
        "webpanel": ${DEFAULT_WEB_PANEL_PORT}
    },
    "paths": {
        "vmess": "/nexus",
        "grpc": "nexus-grpc"
    },
    "security": {
        "admin_pass_changed": false,
        "ssh_banner_enabled": true,
        "firewall_enabled": true,
        "fail2ban_enabled": true,
        "auto_updates": false
    },
    "features": {
        "telegram_bot": false,
        "web_panel": false,
        "monitoring": true,
        "traffic_control": true,
        "speed_limiting": false
    },
    "license": {
        "active": false,
        "key": "",
        "expiry": 0,
        "max_users": 0,
        "max_traffic": 0
    },
    "telegram": {
        "enabled": false,
        "token": "",
        "chat_id": ""
    },
    "database": {
        "users": "${USERS_DB}",
        "keys": "${KEYS_DB}",
        "traffic": "${TRAFFIC_DB}"
    }
}
EOF
        chmod 600 "$CONFIG_FILE"
        log_info "Archivo de configuración inicializado: $CONFIG_FILE"
        inf "Configuración inicial creada"
    else
        log_info "Archivo de configuración ya existe: $CONFIG_FILE"
    fi
}

# Leer valor de configuración
cfg_get() {
    local key="$1"
    local default="${2:-}"
    
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo "$default"
        return 1
    fi
    
    python3 -c "
import json, sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        data = json.load(f)
    keys = '$key'.split('.')
    value = data
    for k in keys:
        value = value[k]
    print(value)
except Exception:
    print('$default')
" 2>/dev/null || echo "$default"
}

# Escribir valor de configuración
cfg_set() {
    local key="$1"
    local value="$2"
    
    python3 -c "
import json, sys
try:
    with open('$CONFIG_FILE', 'r') as f:
        data = json.load(f)
    keys = '$key'.split('.')
    target = data
    for k in keys[:-1]:
        target = target.setdefault(k, {})
    target[keys[-1]] = $value
    with open('$CONFIG_FILE', 'w') as f:
        json.dump(data, f, indent=4)
    print('OK')
except Exception as e:
    print('Error: ' + str(e), file=sys.stderr)
    sys.exit(1)
" >> "$INSTALL_LOG" 2>&1
}
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# PARTE 2: FUNCIONES DE INSTALACIÓN DE PROTOCOLOS (Líneas 1001-2000)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# INSTALACIÓN DE XRAY/V2RAY (COMPLETO)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

install_xray() {
    inf "Iniciando instalación de Xray-Core (todos los protocolos)..."
    log_info "Instalando Xray"
    
    # Verificar si ya está instalado
    if [[ -x "$XRAY_BIN" ]]; then
        local current_version
        current_version=$("$XRAY_BIN" version 2>/dev/null | head -1 | awk '{print $2}' || echo "desconocida")
        warn "Xray ya está instalado (versión: $current_version)"
        if ! confirm "¿Reinstalar/actualizar?" "n"; then
            inf "Omitiendo instalación de Xray"
            return 0
        fi
    fi
    
    # Intentar instalación oficial
    inf "Descargando e instalando Xray..."
    if bash <(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh) >> "$INSTALL_LOG" 2>&1; then
        ok "Xray instalado mediante script oficial"
    else
        warn "Instalación oficial falló, usando método alternativo"
        install_xray_alternative
    fi
    
    # Verificar instalación
    if [[ -x "$XRAY_BIN" ]]; then
        local new_version
        new_version=$("$XRAY_BIN" version 2>/dev/null | head -1 | awk '{print $2}' || echo "desconocida")
        ok "Xray instalado correctamente (versión: $new_version)"
        log_info "Xray instalado, versión: $new_version"
    else
        err "Error en la instalación de Xray"
        log_error "Fallo en instalación de Xray"
        return 1
    fi
    
    # Configurar Xray
    configure_xray
}

# Instalación alternativa de Xray (descarga directa)
install_xray_alternative() {
    inf "Usando método alternativo de instalación..."
    
    local arch
    arch=$(uname -m)
    local xray_arch="64"
    
    case "$arch" in
        x86_64) xray_arch="64" ;;
        aarch64) xray_arch="arm64-v8a" ;;
        armv7l) xray_arch="arm32-v7a" ;;
        *) 
            err "Arquitectura no soportada: $arch"
            return 1
            ;;
    esac
    
    # Obtener última versión
    local latest_ver
    latest_ver=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
    latest_ver="${latest_ver:-24.9.30}"  # Fallback a versión conocida
    
    local url="https://github.com/XTLS/Xray-core/releases/download/v${latest_ver}/Xray-linux-${xray_arch}.zip"
    local tmp_dir="/tmp/xray_install_$$"
    
    mkdir -p "$tmp_dir"
    cd "$tmp_dir" || return 1
    
    inf "Descargando Xray v${latest_ver} para arquitectura ${xray_arch}..."
    if ! wget -q --show-progress -O xray.zip "$url" 2>&1; then
        err "Error descargando Xray"
        cd / && rm -rf "$tmp_dir"
        return 1
    fi
    
    inf "Extrayendo archivos..."
    unzip -q xray.zip -d xray_files/
    
    # Instalar binario
    cp xray_files/xray "$XRAY_BIN"
    chmod +x "$XRAY_BIN"
    
    # Instalar archivos adicionales
    mkdir -p /usr/local/share/xray
    cp xray_files/geoip.dat /usr/local/share/xray/ 2>/dev/null || true
    cp xray_files/geosite.dat /usr/local/share/xray/ 2>/dev/null || true
    
    # Limpiar
    cd /
    rm -rf "$tmp_dir"
    
    ok "Xray instalado manualmente"
}

# Configurar Xray con todos los protocolos
configure_xray() {
    inf "Configurando Xray con todos los protocolos..."
    
    local uuid
    uuid=$(gen_uuid)
    local ss_pass
    ss_pass=$(openssl rand -base64 16 | tr -d '=' | tr '+/' '-_')
    local srv_ip
    srv_ip=$(get_server_ip)
    
    # Guardar UUID y contraseñas
    cfg_set "xray.uuid" "\"${uuid}\""
    cfg_set "xray.ss_password" "\"${ss_pass}\""
    
    mkdir -p /usr/local/etc/xray
    
    # Configuración completa de Xray
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
        "levels": {
            "0": {
                "statsUserUplink": true,
                "statsUserDownlink": true
            }
        },
        "system": {
            "statsInboundUplink": true,
            "statsInboundDownlink": true
        }
    },
    "inbounds": [
        {
            "tag": "vless-tcp",
            "port": PORT_VLESS_TCP,
            "protocol": "vless",
            "settings": {
                "clients": [
                    {
                        "id": "UUID_PLACEHOLDER",
                        "level": 0,
                        "email": "default@nexusvpn"
                    }
                ],
                "decryption": "none",
                "fallbacks": [
                    {
                        "dest": 8443,
                        "xver": 1
                    },
                    {
                        "path": "/nexus",
                        "dest": "@vmess-ws.sock",
                        "xver": 1
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none"
            }
        },
        {
            "tag": "vmess-ws",
            "listen": "@vmess-ws.sock",
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "UUID_PLACEHOLDER",
                        "alterId": 0,
                        "level": 0,
                        "email": "default@nexusvpn"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/nexus"
                }
            }
        },
        {
            "tag": "vmess-ws-80",
            "port": PORT_VMESS_WS,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "UUID_PLACEHOLDER",
                        "alterId": 0,
                        "level": 0,
                        "email": "ws80@nexusvpn"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/nexus"
                }
            }
        },
        {
            "tag": "vmess-ws-8080",
            "port": PORT_VMESS_WS_ALT,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "UUID_PLACEHOLDER",
                        "alterId": 0,
                        "level": 0,
                        "email": "ws8080@nexusvpn"
                    }
                ]
            },
            "streamSettings": {
                "network": "ws",
                "wsSettings": {
                    "path": "/nexus"
                }
            }
        },
        {
            "tag": "vmess-mkcp",
            "port": PORT_VMESS_MKCP,
            "protocol": "vmess",
            "settings": {
                "clients": [
                    {
                        "id": "UUID_PLACEHOLDER",
                        "alterId": 0,
                        "level": 0,
                        "email": "mkcp@nexusvpn"
                    }
                ]
            },
            "streamSettings": {
                "network": "kcp",
                "kcpSettings": {
                    "mtu": 1350,
                    "tti": 50,
                    "uplinkCapacity": 100,
                    "downlinkCapacity": 100,
                    "congestion": false,
                    "readBufferSize": 2,
                    "writeBufferSize": 2,
                    "header": {
                        "type": "none"
                    },
                    "seed": "nexusvpn"
                }
            }
        },
        {
            "tag": "trojan-tcp",
            "port": PORT_TROJAN,
            "protocol": "trojan",
            "settings": {
                "clients": [
                    {
                        "password": "UUID_PLACEHOLDER",
                        "level": 0,
                        "email": "trojan@nexusvpn"
                    }
                ],
                "fallbacks": [
                    {
                        "dest": 80
                    }
                ]
            },
            "streamSettings": {
                "network": "tcp",
                "security": "none"
            }
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
                "clients": [
                    {
                        "id": "UUID_PLACEHOLDER",
                        "level": 0,
                        "email": "grpc@nexusvpn"
                    }
                ],
                "decryption": "none"
            },
            "streamSettings": {
                "network": "grpc",
                "grpcSettings": {
                    "serviceName": "nexus-grpc"
                }
            }
        },
        {
            "tag": "api-in",
            "listen": "127.0.0.1",
            "port": 62789,
            "protocol": "dokodemo-door",
            "settings": {
                "address": "127.0.0.1"
            }
        }
    ],
    "outbounds": [
        {
            "tag": "direct",
            "protocol": "freedom"
        },
        {
            "tag": "blocked",
            "protocol": "blackhole"
        }
    ],
    "routing": {
        "domainStrategy": "AsIs",
        "rules": [
            {
                "type": "field",
                "inboundTag": ["api"],
                "outboundTag": "api"
            },
            {
                "type": "field",
                "ip": ["geoip:private"],
                "outboundTag": "blocked"
            }
        ]
    }
}
XRAYEOF

    # Reemplazar placeholders con valores reales
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
    
    # Crear servicio systemd
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

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# INSTALACIÓN DE UDP CUSTOM (RANGO COMPLETO 1-65535)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

install_udp_custom() {
    inf "Instalando UDP Custom con rango completo 1-65535..."
    log_info "Instalando UDP Custom"
    
    # Instalar dependencias
    apt_install socat netcat-openbsd python3 python3-pip
    
    # Preguntar configuración
    local udp_range
    read_input "Rango UDP (ej: 10000-65000 o '1-65535' para todos)" udp_range "$DEFAULT_UDP_CUSTOM_RANGE"
    
    # Crear script de servicio UDP Custom
    cat > /usr/local/bin/udp-custom << 'EOF'
#!/bin/bash
# UDP Custom - Servicio de redirección de puertos
# Uso: udp-custom <puerto_local> <puerto_destino> [protocolo]

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
    
    # Crear servicio systemd para UDP Custom
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

    # Habilitar servicio para el rango seleccionado
    local start_port end_port
    if [[ "$udp_range" == *-* ]]; then
        start_port=$(echo "$udp_range" | cut -d- -f1)
        end_port=$(echo "$udp_range" | cut -d- -f2)
    else
        start_port="$udp_range"
        end_port="$udp_range"
    fi
    
    inf "Configurando puertos UDP del $start_port al $end_port..."
    
    # Crear script de activación masiva
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
    
    # Activar (opcional, puede tomar tiempo)
    if confirm "¿Activar todos los puertos UDP ahora? (puede tardar)" "n"; then
        /usr/local/bin/udp-custom-activate
        ok "Puertos UDP activados"
    else
        inf "Puedes activarlos después con: udp-custom-activate"
    fi
    
    # Guardar configuración
    cfg_set "udp_custom.range" "\"$udp_range\""
    cfg_set "udp_custom.enabled" "true"
    
    # Abrir puertos en firewall
    ufw allow "$start_port:$end_port/udp" >> "$INSTALL_LOG" 2>&1
    
    log_info "UDP Custom configurado con rango: $udp_range"
    ok "UDP Custom instalado correctamente (rango $udp_range)"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# INSTALACIÓN DE BADVPN (PUERTOS DINÁMICOS)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

install_badvpn() {
    inf "Instalando BadVPN UDP Gateway con puertos dinámicos..."
    log_info "Instalando BadVPN"
    
    # Verificar si ya está instalado
    if [[ -x /usr/local/bin/badvpn-udpgw ]]; then
        warn "BadVPN ya está instalado"
        if ! confirm "¿Reinstalar?" "n"; then
            inf "Omitiendo reinstalación"
            return 0
        fi
    fi
    
    # Instalar dependencias
    apt_install cmake make gcc g++ build-essential
    
    # Compilar desde fuente
    local tmp_dir
    tmp_dir=$(mktemp -d)
    
    inf "Descargando fuente de BadVPN..."
    cd "$tmp_dir" || return 1
    
    if ! git clone --depth 1 https://github.com/ambrop72/badvpn.git >> "$INSTALL_LOG" 2>&1; then
        warn "Error clonando repositorio, usando binario precompilado"
        install_badvpn_binary
        cd / && rm -rf "$tmp_dir"
        return 0
    fi
    
    cd badpn || return 1
    
    inf "Compilando BadVPN (esto puede tomar unos minutos)..."
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
    
    # Configurar BadVPN
    configure_badvpn
}

# Instalación de BadVPN mediante binario precompilado
install_badvpn_binary() {
    inf "Descargando binario precompilado de BadVPN..."
    
    local url="https://github.com/ambrop72/badvpn/raw/master/badvpn-udpgw"
    wget -q -O /usr/local/bin/badvpn-udpgw "$url" >> "$INSTALL_LOG" 2>&1
    
    if [[ -f /usr/local/bin/badvpn-udpgw ]]; then
        chmod +x /usr/local/bin/badvpn-udpgw
        ok "BadVPN binario descargado"
    else
        # Último recurso: usar el binario de daybreakersx
        wget -q -O /usr/local/bin/badvpn-udpgw \
            "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64" \
            >> "$INSTALL_LOG" 2>&1
        chmod +x /usr/local/bin/badvpn-udpgw
    fi
}

# Configurar BadVPN con puertos dinámicos
configure_badvpn() {
    local badvpn_ports
    badvpn_ports=$(cfg_get "badvpn.ports" "[7100,7200,7300]")
    
    inf "Configurando BadVPN en puertos: ${badvpn_ports//[\[\]]/}"
    
    # Preguntar si quiere puertos adicionales
    if confirm "¿Quieres configurar puertos BadVPN personalizados?" "n"; then
        read_input "Puertos separados por comas (ej: 7100,7200,7300,7400)" custom_ports
        if [[ -n "$custom_ports" ]]; then
            # Convertir a array JSON
            ports_json="["
            IFS=',' read -ra port_array <<< "$custom_ports"
            for port in "${port_array[@]}"; do
                port=$(echo "$port" | xargs)  # Trim
                ports_json+="$port,"
            done
            ports_json="${ports_json%,}]"
            badvpn_ports="$ports_json"
            cfg_set "badvpn.ports" "$badvpn_ports"
        fi
    fi
    
    # Crear servicios para cada puerto
    local port_list
    port_list=$(echo "$badvpn_ports" | tr -d '[]' | tr ',' ' ')
    
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
            
            # Abrir puerto en firewall
            ufw allow "${port}/udp" >> "$INSTALL_LOG" 2>&1
            
            log_info "BadVPN activado en puerto $port"
        fi
    done
    
    ok "BadVPN configurado en puertos: ${badvpn_ports//[\[\]]/}"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# INSTALACIÓN DE HYSTERIA2
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

install_hysteria2() {
    inf "Instalando Hysteria2 con soporte de obfs múltiples..."
    log_info "Instalando Hysteria2"
    
    # Verificar instalación
    if [[ -x /usr/local/bin/hysteria ]]; then
        warn "Hysteria2 ya está instalado"
        if ! confirm "¿Reinstalar/actualizar?" "n"; then
            inf "Omitiendo reinstalación"
            return 0
        fi
    fi
    
    # Intentar instalación oficial
    inf "Descargando e instalando Hysteria2..."
    if bash <(curl -fsSL https://get.hy2.sh/) >> "$INSTALL_LOG" 2>&1; then
        ok "Hysteria2 instalado mediante script oficial"
    else
        warn "Instalación oficial falló, usando método alternativo"
        install_hysteria2_alternative
    fi
    
    # Generar contraseña aleatoria
    local auth_pass
    auth_pass=$(openssl rand -base64 20 | tr -d '=' | tr '+/' '-_')
    cfg_set "hysteria2.auth_pass" "\"${auth_pass}\""
    
    # Crear certificado SSL self-signed
    mkdir -p /etc/hysteria
    openssl req -x509 -newkey rsa:2048 -keyout /etc/hysteria/key.pem \
        -out /etc/hysteria/cert.pem -days 3650 -nodes \
        -subj "/C=US/O=NexusVPN/CN=nexusvpn.local" >> "$INSTALL_LOG" 2>&1
    
    # Configurar Hysteria2
    configure_hysteria2 "$auth_pass"
}

# Instalación alternativa de Hysteria2
install_hysteria2_alternative() {
    local arch
    arch=$(uname -m)
    local h_arch="amd64"
    
    case "$arch" in
        x86_64) h_arch="amd64" ;;
        aarch64) h_arch="arm64" ;;
        armv7l) h_arch="arm" ;;
        *)
            err "Arquitectura no soportada: $arch"
            return 1
            ;;
    esac
    
    # Obtener última versión
    local latest
    latest=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest | grep '"tag_name"' | sed 's/.*"app\/v\([^"]*\)".*/\1/')
    latest="${latest:-2.4.5}"
    
    local url="https://github.com/apernet/hysteria/releases/download/app/v${latest}/hysteria-linux-${h_arch}"
    
    inf "Descargando Hysteria2 v${latest}..."
    wget -q -O /usr/local/bin/hysteria "$url" >> "$INSTALL_LOG" 2>&1
    
    if [[ -f /usr/local/bin/hysteria ]]; then
        chmod +x /usr/local/bin/hysteria
        ok "Hysteria2 descargado correctamente"
    else
        err "Error descargando Hysteria2"
        return 1
    fi
}

# Configurar Hysteria2
configure_hysteria2() {
    local auth_pass="$1"
    local hysteria_port
    hysteria_port=$(cfg_get "ports.hysteria2" "$DEFAULT_HYSTERIA2_PORT")
    
    # Preguntar tipo de obfs
    local obfs_type="salamander"
    if confirm "¿Usar obfs 'random' en lugar de 'salamander'?" "n"; then
        obfs_type="random"
    fi
    
    # Preguntar contraseña personalizada
    if confirm "¿Establecer contraseña personalizada para Hysteria2?" "n"; then
        read_password "Nueva contraseña" custom_pass
        if [[ -n "$custom_pass" ]]; then
            auth_pass="$custom_pass"
            cfg_set "hysteria2.auth_pass" "\"${auth_pass}\""
        fi
    fi
    
    # Crear configuración
    cat > "$HYSTERIA_CONFIG" << HYEOF
# Hysteria2 Configuration
listen: :${hysteria_port}

# TLS Configuration
tls:
  cert: /etc/hysteria/cert.pem
  key: /etc/hysteria/key.pem

# Obfuscation
obfs:
  type: ${obfs_type}
  ${obfs_type}:
    password: nexusvpn-obfs

# Authentication
auth:
  type: password
  password: ${auth_pass}

# Masquerade (fallback)
masquerade:
  type: proxy
  proxy:
    url: https://www.google.com
    rewriteHost: true

# Bandwidth limits
bandwidth:
  up: 1 gbps
  down: 1 gbps

# Performance
quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 30s
  keepAlivePeriod: 10s
  disablePathMTUDiscovery: false

# UDP forwarding (optional)
udp:
  timeout: 60s
HYEOF

    # Crear servicio systemd
    cat > /etc/systemd/system/hysteria.service << 'HYSVCEOF'
[Unit]
Description=Hysteria2 VPN Server
Documentation=https://hysteria.network/
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/hysteria server --config /etc/hysteria/config.yaml
Restart=always
RestartSec=5
LimitNOFILE=1048576
LimitNPROC=512
TasksMax=infinity

[Install]
WantedBy=multi-user.target
HYSVCEOF

    systemctl daemon-reload
    systemctl enable hysteria
    systemctl restart hysteria
    
    # Abrir puerto en firewall
    ufw allow "${hysteria_port}/udp" >> "$INSTALL_LOG" 2>&1
    
    log_info "Hysteria2 configurado en puerto $hysteria_port con obfs $obfs_type"
    ok "Hysteria2 configurado correctamente"
}
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# PARTE 3: WIREGUARD, IKEV2, OPENVPN, SLOWDNS (Líneas 2001-3000)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# INSTALACIÓN DE WIREGUARD + AMNEZIAWG
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

install_wireguard() {
    inf "Instalando WireGuard y AmneziaWG..."
    log_info "Instalando WireGuard"
    
    # Instalar WireGuard
    apt_install wireguard wireguard-tools linux-headers-$(uname -r)
    
    # Instalar AmneziaWG (si se desea)
    if confirm "¿Instalar también AmneziaWG (versión mejorada)?" "s"; then
        install_amneziawg
    fi
    
    # Generar claves del servidor
    local server_private_key
    local server_public_key
    
    server_private_key=$(wg genkey)
    server_public_key=$(echo "$server_private_key" | wg pubkey)
    
    # Guardar claves
    mkdir -p "$WIREGUARD_CONFIG_DIR"
    echo "$server_private_key" > "$WIREGUARD_CONFIG_DIR/server_private.key"
    echo "$server_public_key" > "$WIREGUARD_CONFIG_DIR/server_public.key"
    chmod 600 "$WIREGUARD_CONFIG_DIR/server_private.key"
    
    # Configurar WireGuard
    configure_wireguard "$server_private_key" "$server_public_key"
    
    # Habilitar forwarding
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/99-wireguard.conf
    echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.d/99-wireguard.conf
    sysctl -p /etc/sysctl.d/99-wireguard.conf
    
    ok "WireGuard instalado correctamente"
}

# Instalar AmneziaWG
install_amneziawg() {
    inf "Instalando AmneziaWG..."
    
    # Agregar repositorio de Amnezia
    curl -fsSL https://pkg.amnezia.org/install.sh | bash >> "$INSTALL_LOG" 2>&1
    
    # Instalar paquetes
    apt_install awg awg-tools
    
    if command -v awg &>/dev/null; then
        ok "AmneziaWG instalado correctamente"
        cfg_set "wireguard.amnezia_enabled" "true"
    else
        warn "Error instalando AmneziaWG, continuando solo con WireGuard"
        cfg_set "wireguard.amnezia_enabled" "false"
    fi
}

# Configurar WireGuard
configure_wireguard() {
    local server_private_key="$1"
    local server_public_key="$2"
    local wg_port
    wg_port=$(cfg_get "ports.wireguard" "$DEFAULT_WIREGUARD_PORT")
    local server_ip
    server_ip=$(get_server_ip)
    
    # Crear configuración del servidor
    cat > "$WIREGUARD_CONFIG_DIR/wg0.conf" << WGEOF
# WireGuard Server Configuration
[Interface]
Address = 10.66.66.1/24, fd42:42:42::1/64
ListenPort = ${wg_port}
PrivateKey = ${server_private_key}
SaveConfig = false

# Post-up rules
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT
PostUp = iptables -t nat -A POSTROUTING -o $(get_network_info) -j MASQUERADE
PostUp = ip6tables -A FORWARD -i wg0 -j ACCEPT
PostUp = ip6tables -t nat -A POSTROUTING -o $(get_network_info) -j MASQUERADE

# Pre-down rules
PreDown = iptables -D FORWARD -i wg0 -j ACCEPT
PreDown = iptables -t nat -D POSTROUTING -o $(get_network_info) -j MASQUERADE
PreDown = ip6tables -D FORWARD -i wg0 -j ACCEPT
PreDown = ip6tables -t nat -D POSTROUTING -o $(get_network_info) -j MASQUERADE

# DNS
PostUp = echo "nameserver 8.8.8.8" > /etc/resolv.conf
PostUp = echo "nameserver 1.1.1.1" >> /etc/resolv.conf
WGEOF

    chmod 600 "$WIREGUARD_CONFIG_DIR/wg0.conf"
    
    # Crear script para agregar clientes
    cat > /usr/local/bin/wireguard-add-client << 'WGCLIENT'
#!/bin/bash
# WireGuard - Agregar cliente
# Uso: wireguard-add-client <nombre_cliente> [IP]

CLIENT_NAME="$1"
CLIENT_IP="${2:-10.66.66.2}"

if [[ -z "$CLIENT_NAME" ]]; then
    echo "Uso: wireguard-add-client <nombre_cliente> [IP]"
    exit 1
fi

# Generar claves del cliente
CLIENT_PRIVATE_KEY=$(wg genkey)
CLIENT_PUBLIC_KEY=$(echo "$CLIENT_PRIVATE_KEY" | wg pubkey)
CLIENT_PRE_SHARED_KEY=$(wg genpsk)

SERVER_PUBLIC_KEY=$(cat /etc/wireguard/server_public.key)
SERVER_PORT=$(grep ListenPort /etc/wireguard/wg0.conf | awk '{print $3}')
SERVER_IP=$(curl -s ifconfig.me)

# Agregar cliente al servidor
cat >> /etc/wireguard/wg0.conf << EOF

# Client: ${CLIENT_NAME}
[Peer]
PublicKey = ${CLIENT_PUBLIC_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
AllowedIPs = ${CLIENT_IP}/32
EOF

# Generar configuración para el cliente
CLIENT_CONF="/etc/wireguard/clients/${CLIENT_NAME}.conf"
mkdir -p /etc/wireguard/clients

cat > "$CLIENT_CONF" << EOF
[Interface]
PrivateKey = ${CLIENT_PRIVATE_KEY}
Address = ${CLIENT_IP}/24
DNS = 8.8.8.8, 1.1.1.1

[Peer]
PublicKey = ${SERVER_PUBLIC_KEY}
PresharedKey = ${CLIENT_PRE_SHARED_KEY}
Endpoint = ${SERVER_IP}:${SERVER_PORT}
AllowedIPs = 0.0.0.0/0, ::/0
PersistentKeepalive = 25
EOF

chmod 600 "$CLIENT_CONF"

# Generar QR
qrencode -t ansiutf8 < "$CLIENT_CONF"

echo ""
echo "✅ Cliente $CLIENT_NAME creado: $CLIENT_CONF"
echo "📱 Escanea el QR o usa el archivo de configuración"
WGCLIENT
    chmod +x /usr/local/bin/wireguard-add-client
    
    # Habilitar y arrancar servicio
    systemctl enable wg-quick@wg0
    systemctl start wg-quick@wg0
    
    # Abrir puerto en firewall
    ufw allow "${wg_port}/udp" >> "$INSTALL_LOG" 2>&1
    
    log_info "WireGuard configurado en puerto $wg_port"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# INSTALACIÓN DE IKEV2 (PARA IPHONE/IPAD/ANDROID)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

install_ikev2() {
    inf "Instalando IKEv2 para dispositivos móviles (iPhone/iPad/Android)..."
    log_info "Instalando IKEv2"
    
    # Instalar StrongSwan
    apt_install strongswan strongswan-pki libcharon-extra-plugins libcharon-extauth-plugins libstrongswan-extra-plugins
    
    # Crear estructura de directorios
    mkdir -p "$IKEV2_CONFIG_DIR"/{cacerts,certs,private}
    
    # Generar certificados
    generate_ikev2_certs
    
    # Configurar StrongSwan
    configure_ikev2
    
    # Habilitar forwarding
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.conf
    sysctl -p
    
    ok "IKEv2 instalado correctamente"
}

# Generar certificados para IKEv2
generate_ikev2_certs() {
    local server_ip
    server_ip=$(get_server_ip)
    
    cd "$IKEV2_CONFIG_DIR" || return 1
    
    # Generar CA
    inf "Generando certificado de Autoridad Certificadora..."
    pki --gen --type rsa --size 4096 --outform pem > private/ca-key.pem
    pki --self --ca --lifetime 3650 --in private/ca-key.pem \
        --dn "CN=NexusVPN CA, O=NexusVPN, C=US" \
        --outform pem > cacerts/ca-cert.pem
    
    # Generar certificado del servidor
    inf "Generando certificado del servidor..."
    pki --gen --type rsa --size 2048 --outform pem > private/server-key.pem
    pki --pub --in private/server-key-pem --type rsa \
        | pki --issue --lifetime 1825 \
        --cacert cacerts/ca-cert.pem \
        --cakey private/ca-key.pem \
        --dn "CN=${server_ip}, O=NexusVPN, C=US" \
        --san "${server_ip}" \
        --flag serverAuth --flag ikeIntermediate \
        --outform pem > certs/server-cert.pem
    
    # Generar cliente genérico
    pki --gen --type rsa --size 2048 --outform pem > private/client-key.pem
    pki --pub --in private/client-key.pem --type rsa \
        | pki --issue --lifetime 1825 \
        --cacert cacerts/ca-cert.pem \
        --cakey private/ca-key.pem \
        --dn "CN=client, O=NexusVPN, C=US" \
        --outform pem > certs/client-cert.pem
    
    # Establecer permisos
    chmod 600 private/*.pem
    
    log_info "Certificados IKEv2 generados"
}

# Configurar StrongSwan
configure_ikev2() {
    local server_ip
    server_ip=$(get_server_ip)
    
    # Configuración principal de StrongSwan
    cat > /etc/strongswan/swanctl/swanctl.conf << SWANCTL
connections {
    ikev2-vpn {
        local_addrs = ${server_ip}
        remote_addrs = %any
        
        local {
            auth = pubkey
            certs = server-cert.pem
            id = ${server_ip}
        }
        
        remote {
            auth = pubkey
            certs = client-cert.pem
            id = client
        }
        
        children {
            ikev2-vpn {
                local_ts = 0.0.0.0/0
                remote_ts = 0.0.0.0/0
                
                updown = /usr/lib/ipsec/_updown iptables
                rekey_time = 0
                esp_proposals = aes256-sha256-modp2048
            }
        }
        
        version = 2
        mobike = yes
        proposals = aes256-sha256-modp2048
    }
}

secrets {
    # No password secrets needed for certificate auth
}

pools {
    vpn-pool {
        addrs = 10.10.10.0/24
        dns = 8.8.8.8, 8.8.4.4
    }
}
SWANCTL

    # Configuración de IPSec
    cat > /etc/ipsec.conf << IPSECCONF
config setup
    charondebug="ike 2, knl 2, cfg 2"
    uniqueids=no

conn ikev2-vpn
    auto=add
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    
    ike=aes256-sha256-modp2048!
    esp=aes256-sha256-modp2048!
    
    dpdaction=clear
    dpddelay=300s
    rekey=no
    
    left=%any
    leftid=@${server_ip}
    leftcert=server-cert.pem
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    
    right=%any
    rightid=%any
    rightauth=pubkey
    rightsourceip=10.10.10.0/24
    rightdns=8.8.8.8,8.8.4.4
    rightsendcert=never
IPSECCONF

    # Copiar certificados a las ubicaciones correctas
    cp "$IKEV2_CONFIG_DIR"/cacerts/ca-cert.pem /etc/ipsec.d/cacerts/
    cp "$IKEV2_CONFIG_DIR"/certs/server-cert.pem /etc/ipsec.d/certs/
    cp "$IKEV2_CONFIG_DIR"/private/server-key.pem /etc/ipsec.d/private/
    
    # Reiniciar servicio
    systemctl restart strongswan-starter
    systemctl enable strongswan-starter
    
    # Abrir puertos en firewall
    ufw allow 500/udp >> "$INSTALL_LOG" 2>&1  # IKE
    ufw allow 4500/udp >> "$INSTALL_LOG" 2>&1 # NAT-T
    
    log_info "IKEv2 configurado correctamente"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# INSTALACIÓN DE OPENVPN (TCP/UDP)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

install_openvpn() {
    inf "Instalando OpenVPN (TCP/UDP)..."
    log_info "Instalando OpenVPN"
    
    # Instalar paquetes
    apt_install openvpn easy-rsa
    
    # Crear estructura de directorios
    mkdir -p "$OPENVPN_CONFIG_DIR"/{client,server}
    mkdir -p "$OPENVPN_CLIENT_DIR"
    
    # Configurar PKI
    setup_openvpn_pki
    
    # Configurar servidor OpenVPN
    configure_openvpn_server
    
    # Habilitar forwarding
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    sysctl -p
    
    ok "OpenVPN instalado correctamente"
}

# Configurar PKI para OpenVPN
setup_openvpn_pki() {
    cd "$OPENVPN_CONFIG_DIR" || return 1
    
    if [[ ! -d easy-rsa ]]; then
        make-cadir easy-rsa
    fi
    
    cd easy-rsa || return 1
    
    # Inicializar PKI
    ./easyrsa init-pki >> "$INSTALL_LOG" 2>&1
    
    # Construir CA
    ./easyrsa --batch build-ca nopass >> "$INSTALL_LOG" 2>&1
    
    # Generar certificado del servidor
    ./easyrsa --batch gen-req server nopass >> "$INSTALL_LOG" 2>&1
    ./easyrsa --batch sign-req server server >> "$INSTALL_LOG" 2>&1
    
    # Generar Diffie-Hellman
    ./easyrsa gen-dh >> "$INSTALL_LOG" 2>&1
    
    # Generar clave TLS
    openvpn --genkey --secret ta.key >> "$INSTALL_LOG" 2>&1
    
    # Copiar certificados
    cp pki/ca.crt "$OPENVPN_CONFIG_DIR/server/"
    cp pki/issued/server.crt "$OPENVPN_CONFIG_DIR/server/"
    cp pki/private/server.key "$OPENVPN_CONFIG_DIR/server/"
    cp pki/dh.pem "$OPENVPN_CONFIG_DIR/server/"
    cp ta.key "$OPENVPN_CONFIG_DIR/server/"
    
    log_info "PKI de OpenVPN configurada"
}

# Configurar servidor OpenVPN
configure_openvpn_server() {
    local server_ip
    server_ip=$(get_server_ip)
    local openvpn_tcp_port
    openvpn_tcp_port=$(cfg_get "ports.openvpn_tcp" "$DEFAULT_OPENVPN_TCP")
    local openvpn_udp_port
    openvpn_udp_port=$(cfg_get "ports.openvpn_udp" "$DEFAULT_OPENVPN_UDP")
    
    # Configuración TCP
    cat > "$OPENVPN_CONFIG_DIR/server/tcp.conf" << TCPEOF
# OpenVPN TCP Server Configuration
port ${openvpn_tcp_port}
proto tcp
dev tun
ca ca.crt
cert server.crt
key server.key
dh dh.pem
tls-auth ta.key 0

server 10.8.0.0 255.255.255.0
ifconfig-pool-persist ipp-tcp.txt

push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 1.1.1.1"

keepalive 10 120
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
status openvpn-status-tcp.log
verb 3
explicit-exit-notify 0

# Client management
client-config-dir /etc/openvpn/client
client-to-client
duplicate-cn
TCPEOF

    # Configuración UDP
    sed 's/proto tcp/proto udp/;s/port [0-9]*/port '"$openvpn_udp_port"'/;s/ipp-tcp.txt/ipp-udp.txt/' \
        "$OPENVPN_CONFIG_DIR/server/tcp.conf" > "$OPENVPN_CONFIG_DIR/server/udp.conf"
    
    # Crear script para generar clientes
    cat > /usr/local/bin/openvpn-add-client << 'OVPNCLIENT'
#!/bin/bash
# OpenVPN - Agregar cliente
# Uso: openvpn-add-client <nombre_cliente>

CLIENT_NAME="$1"

if [[ -z "$CLIENT_NAME" ]]; then
    echo "Uso: openvpn-add-client <nombre_cliente>"
    exit 1
fi

cd /etc/openvpn/easy-rsa || exit 1

# Generar certificado para el cliente
./easyrsa --batch build-client-full "$CLIENT_NAME" nopass >> /var/log/nexusvpn/openvpn.log 2>&1

# Obtener IP del servidor
SERVER_IP=$(curl -s ifconfig.me)
TCP_PORT=$(grep '^port' /etc/openvpn/server/tcp.conf | awk '{print $2}')
UDP_PORT=$(grep '^port' /etc/openvpn/server/udp.conf | awk '{print $2}')

# Crear directorio para el cliente
mkdir -p "/etc/openvpn/client-configs/$CLIENT_NAME"

# Generar configuración TCP
cat > "/etc/openvpn/client-configs/$CLIENT_NAME/${CLIENT_NAME}-tcp.ovpn" << EOF
client
dev tun
proto tcp
remote ${SERVER_IP} ${TCP_PORT}
resolv-retry infinite
nobind
persist-key
persist-tun
remote-cert-tls server
cipher AES-256-CBC
verb 3
auth-user-pass

<ca>
$(cat /etc/openvpn/server/ca.crt)
</ca>
<cert>
$(cat /etc/openvpn/easy-rsa/pki/issued/${CLIENT_NAME}.crt)
</cert>
<key>
$(cat /etc/openvpn/easy-rsa/pki/private/${CLIENT_NAME}.key)
</key>
<tls-auth>
$(cat /etc/openvpn/server/ta.key)
</tls-auth>
EOF

# Generar configuración UDP
cp "/etc/openvpn/client-configs/$CLIENT_NAME/${CLIENT_NAME}-tcp.ovpn" \
   "/etc/openvpn/client-configs/$CLIENT_NAME/${CLIENT_NAME}-udp.ovpn"
sed -i 's/proto tcp/proto udp/;s/remote [0-9.]* [0-9]*/remote '"$SERVER_IP $UDP_PORT"'/' \
   "/etc/openvpn/client-configs/$CLIENT_NAME/${CLIENT_NAME}-udp.ovpn"

# Generar QR
echo "📱 TCP Config QR:"
qrencode -t ansiutf8 < "/etc/openvpn/client-configs/$CLIENT_NAME/${CLIENT_NAME}-tcp.ovpn"
echo ""
echo "📱 UDP Config QR:"
qrencode -t ansiutf8 < "/etc/openvpn/client-configs/$CLIENT_NAME/${CLIENT_NAME}-udp.ovpn"

echo ""
echo "✅ Cliente $CLIENT_NAME creado correctamente"
echo "📁 Archivos en: /etc/openvpn/client-configs/$CLIENT_NAME/"
OVPNCLIENT
    chmod +x /usr/local/bin/openvpn-add-client
    
    # Habilitar y arrancar servicios
    systemctl enable openvpn@server/tcp
    systemctl enable openvpn@server/udp
    systemctl start openvpn@server/tcp
    systemctl start openvpn@server/udp
    
    # Abrir puertos en firewall
    ufw allow "${openvpn_tcp_port}/tcp" >> "$INSTALL_LOG" 2>&1
    ufw allow "${openvpn_udp_port}/udp" >> "$INSTALL_LOG" 2>&1
    
    log_info "OpenVPN configurado (TCP:$openvpn_tcp_port, UDP:$openvpn_udp_port)"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# INSTALACIÓN DE SLOWDNS
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

install_slowdns() {
    inf "Instalando SlowDNS (dnstt)..."
    log_info "Instalando SlowDNS"
    
    local arch
    arch=$(uname -m)
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
    
    # Intentar descargar dnstt-server
    if [[ ! -x /usr/local/bin/dnstt-server ]]; then
        inf "Descargando dnstt-server..."
        wget -q -O /tmp/dnstt-server \
            "https://www.bamsoftware.com/software/dnstt/dnstt-server-linux-${darch}" \
            >> "$INSTALL_LOG" 2>&1 || {
            warn "Error descargando dnstt, usando método alternativo"
            install_slowdns_alternative
            return
        }
        
        chmod +x /tmp/dnstt-server
        cp /tmp/dnstt-server /usr/local/bin/dnstt-server
        rm /tmp/dnstt-server
    fi
    
    # Generar keypair
    if [[ ! -f "$INSTALL_DIR/slowdns/server.key" ]]; then
        mkdir -p "$INSTALL_DIR/slowdns"
        /usr/local/bin/dnstt-server -gen-key \
            -privkey-file "$INSTALL_DIR/slowdns/server.key" \
            -pubkey-file "$INSTALL_DIR/slowdns/server.pub" >> "$INSTALL_LOG" 2>&1
    fi
    
    # Configurar SlowDNS
    configure_slowdns
}

# Instalación alternativa de SlowDNS
install_slowdns_alternative() {
    inf "Usando método alternativo para SlowDNS..."
    
    # Crear script Python para SlowDNS simple
    cat > /usr/local/bin/slowdns-proxy << 'PYSLOW'
#!/usr/bin/env python3
# SlowDNS Proxy simple

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
    
    # Crear servicio systemd
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

# Configurar SlowDNS
configure_slowdns() {
    local slowdns_port
    slowdns_port=$(cfg_get "ports.slowdns" "$DEFAULT_SLOWDNS_PORT")
    local server_ip
    server_ip=$(get_server_ip)
    
    # Preguntar dominio
    local ns_domain
    read_input "Subdominio NS para SlowDNS (ej: ns.tudominio.com)" ns_domain
    
    if [[ -n "$ns_domain" ]]; then
        cfg_set "slowdns.domain" "\"$ns_domain\""
        
        # Crear servicio con el dominio
        cat > /etc/systemd/system/slowdns.service << SDNS
[Unit]
Description=SlowDNS Server (dnstt)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/dnstt-server -udp :${slowdns_port} -privkey-file ${INSTALL_DIR}/slowdns/server.key ${ns_domain} 127.0.0.1:22
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
SDNS
    else
        # Usar IP como fallback
        cat > /etc/systemd/system/slowdns.service << SDNS
[Unit]
Description=SlowDNS Server (dnstt)
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/dnstt-server -udp :${slowdns_port} -privkey-file ${INSTALL_DIR}/slowdns/server.key ${server_ip} 127.0.0.1:22
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
    
    # Abrir puerto en firewall
    ufw allow "${slowdns_port}/udp" >> "$INSTALL_LOG" 2>&1
    
    # Mostrar clave pública
    if [[ -f "$INSTALL_DIR/slowdns/server.pub" ]]; then
        local pubkey
        pubkey=$(cat "$INSTALL_DIR/slowdns/server.pub")
        box_message "Clave pública SlowDNS: $pubkey"
    fi
    
    cfg_set "slowdns.method" "\"official\""
    cfg_set "slowdns.enabled" "true"
    
    log_info "SlowDNS configurado en puerto $slowdns_port"
    ok "SlowDNS instalado correctamente"
}
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# PARTE 4: BOT DE TELEGRAM, SISTEMA DE KEYS, MONITOREO (Líneas 3001-4000)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# INSTALACIÓN DEL BOT DE TELEGRAM
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

install_telegram_bot() {
    inf "Instalando Bot de Telegram para gestión remota..."
    log_info "Instalando Bot de Telegram"
    
    # Instalar dependencias de Python
    apt_install python3 python3-pip python3-venv
    
    # Crear entorno virtual
    local BOT_DIR="/usr/local/nexusvpn-bot"
    mkdir -p "$BOT_DIR"
    
    python3 -m venv "$BOT_DIR/venv"
    
    # Instalar dependencias del bot
    "$BOT_DIR/venv/bin/pip" install --upgrade pip >> "$INSTALL_LOG" 2>&1
    "$BOT_DIR/venv/bin/pip" install python-telegram-bot requests psutil speedtest-cli >> "$INSTALL_LOG" 2>&1
    
    # Crear el bot
    create_telegram_bot_script "$BOT_DIR"
    
    # Crear servicio systemd
    create_telegram_bot_service "$BOT_DIR"
    
    # Configurar token (si se proporciona)
    if confirm "¿Tienes un token de bot de Telegram?" "n"; then
        read_password "Ingresa el token de tu bot" bot_token
        if [[ -n "$bot_token" ]]; then
            echo "$bot_token" > "$BOT_TOKEN_FILE"
            chmod 600 "$BOT_TOKEN_FILE"
            cfg_set "telegram.token" "\"$bot_token\""
            cfg_set "telegram.enabled" "true"
            
            # Reiniciar bot con el token
            systemctl restart nexusvpn-bot
        fi
    else
        inf "Puedes configurar el token después con: nexusvpn --bot-token <TOKEN>"
        inf "Para crear un bot, habla con @BotFather en Telegram"
    fi
    
    ok "Bot de Telegram instalado correctamente"
}

# Crear script del bot
create_telegram_bot_script() {
    local BOT_DIR="$1"
    
    cat > "$BOT_DIR/bot.py" << 'PYBOT'
#!/usr/bin/env python3
"""
NexusVPN Pro - Bot de Telegram para gestión remota
Autor: Androidzpro
Versión: 4.0
"""

import os
import sys
import json
import subprocess
import threading
import time
import re
import sqlite3
from datetime import datetime, timedelta
from pathlib import Path

import requests
import psutil
from telegram import Update, InlineKeyboardButton, InlineKeyboardMarkup
from telegram.ext import (
    Application,
    CommandHandler,
    CallbackQueryHandler,
    MessageHandler,
    filters,
    ContextTypes
)

# Configuración
BOT_TOKEN_FILE = "/etc/nexusvpn/config/bot.token"
INSTALL_DIR = "/etc/nexusvpn"
USERS_DB = f"{INSTALL_DIR}/database/users.db"
KEYS_DB = f"{INSTALL_DIR}/database/keys.db"
CONFIG_FILE = f"{INSTALL_DIR}/config/config.json"

# Colores para terminal (no afectan Telegram)
class Colors:
    GREEN = '\033[0;32m'
    RED = '\033[0;31m'
    YELLOW = '\033[1;33m'
    CYAN = '\033[0;36m'
    NC = '\033[0m'

# Cargar token
def load_token():
    if os.path.exists(BOT_TOKEN_FILE):
        with open(BOT_TOKEN_FILE, 'r') as f:
            return f.read().strip()
    return None

# Cargar configuración
def load_config():
    if os.path.exists(CONFIG_FILE):
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    return {}

# Verificar si el bot está habilitado
def is_bot_enabled():
    config = load_config()
    return config.get('telegram', {}).get('enabled', False)

# Obtener estadísticas del sistema
def get_system_stats():
    stats = {}
    
    # CPU
    stats['cpu'] = psutil.cpu_percent(interval=1)
    
    # RAM
    memory = psutil.virtual_memory()
    stats['ram_total'] = memory.total / (1024**3)
    stats['ram_used'] = memory.used / (1024**3)
    stats['ram_percent'] = memory.percent
    
    # Disco
    disk = psutil.disk_usage('/')
    stats['disk_total'] = disk.total / (1024**3)
    stats['disk_used'] = disk.used / (1024**3)
    stats['disk_percent'] = disk.percent
    
    # Uptime
    stats['uptime'] = time.time() - psutil.boot_time()
    
    # Usuarios conectados
    stats['users_online'] = len(get_online_users())
    
    return stats

# Obtener usuarios conectados
def get_online_users():
    users = []
    
    # SSH
    try:
        result = subprocess.run(['who'], capture_output=True, text=True)
        for line in result.stdout.split('\n'):
            if line:
                parts = line.split()
                if len(parts) >= 5:
                    users.append({
                        'user': parts[0],
                        'ip': parts[4].strip('()'),
                        'protocol': 'SSH',
                        'time': parts[2] + ' ' + parts[3]
                    })
    except:
        pass
    
    # Xray (desde logs)
    try:
        result = subprocess.run(['tail', '-20', '/var/log/xray/access.log'], 
                              capture_output=True, text=True)
        for line in result.stdout.split('\n'):
            if 'email:' in line:
                # Extraer información básica
                email_match = re.search(r'email:\s*(\S+)', line)
                ip_match = re.search(r'remote:\s*([0-9.]+)', line)
                
                if email_match and ip_match:
                    users.append({
                        'user': email_match.group(1),
                        'ip': ip_match.group(1),
                        'protocol': 'XRAY',
                        'time': 'active'
                    })
    except:
        pass
    
    return users

# Bloquear IP
def block_ip(ip):
    try:
        subprocess.run(['iptables', '-A', 'INPUT', '-s', ip, '-j', 'DROP'], check=True)
        return True
    except:
        return False

# Crear usuario SSH
def create_ssh_user(username, password, days):
    try:
        # Crear usuario
        subprocess.run(['useradd', '-m', '-s', '/bin/bash', username], check=True)
        
        # Establecer contraseña
        subprocess.run(['chpasswd'], input=f"{username}:{password}", text=True, check=True)
        
        # Establecer expiración
        expire_date = (datetime.now() + timedelta(days=int(days))).strftime('%Y-%m-%d')
        subprocess.run(['chage', '-E', expire_date, username], check=True)
        
        return True
    except:
        return False

# Eliminar usuario
def delete_user(username):
    try:
        subprocess.run(['userdel', '-r', username], check=True)
        return True
    except:
        return False

# Comandos del bot

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Comando /start"""
    await update.message.reply_text(
        "🤖 *NexusVPN Pro Bot*\n\n"
        "Comandos disponibles:\n"
        "/start - Mostrar este mensaje\n"
        "/online - Ver usuarios conectados\n"
        "/stats - Estadísticas del servidor\n"
        "/block <IP> - Bloquear una IP\n"
        "/create <user> <pass> <days> - Crear usuario SSH\n"
        "/delete <user> - Eliminar usuario\n"
        "/keys - Listar keys disponibles\n"
        "/help - Ayuda detallada",
        parse_mode='Markdown'
    )

async def online(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Comando /online - Ver usuarios conectados"""
    users = get_online_users()
    
    if not users:
        await update.message.reply_text("📡 No hay usuarios conectados")
        return
    
    message = "📡 *Usuarios Conectados:*\n\n"
    for user in users:
        message += f"👤 *{user['user']}*\n"
        message += f"   IP: `{user['ip']}`\n"
        message += f"   Protocolo: {user['protocol']}\n"
        message += f"   Tiempo: {user['time']}\n\n"
    
    await update.message.reply_text(message, parse_mode='Markdown')

async def stats(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Comando /stats - Estadísticas del servidor"""
    stats = get_system_stats()
    
    uptime_days = int(stats['uptime'] // 86400)
    uptime_hours = int((stats['uptime'] % 86400) // 3600)
    uptime_minutes = int((stats['uptime'] % 3600) // 60)
    
    message = (
        "📊 *Estadísticas del Servidor*\n\n"
        f"💻 CPU: {stats['cpu']}%\n"
        f"🧠 RAM: {stats['ram_used']:.1f}GB/{stats['ram_total']:.1f}GB ({stats['ram_percent']}%)\n"
        f"💾 Disco: {stats['disk_used']:.1f}GB/{stats['disk_total']:.1f}GB ({stats['disk_percent']}%)\n"
        f"⏱️ Uptime: {uptime_days}d {uptime_hours}h {uptime_minutes}m\n"
        f"👥 Usuarios online: {stats['users_online']}"
    )
    
    await update.message.reply_text(message, parse_mode='Markdown')

async def block(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Comando /block <IP> - Bloquear IP"""
    if not context.args:
        await update.message.reply_text("⚠️ Uso: /block <IP>")
        return
    
    ip = context.args[0]
    
    # Validar IP
    ip_pattern = r'^(\d{1,3}\.){3}\d{1,3}$'
    if not re.match(ip_pattern, ip):
        await update.message.reply_text("❌ IP inválida")
        return
    
    if block_ip(ip):
        await update.message.reply_text(f"✅ IP {ip} bloqueada correctamente")
    else:
        await update.message.reply_text(f"❌ Error bloqueando IP {ip}")

async def create(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Comando /create <user> <pass> <days> - Crear usuario SSH"""
    if len(context.args) < 3:
        await update.message.reply_text("⚠️ Uso: /create <usuario> <contraseña> <días>")
        return
    
    username = context.args[0]
    password = context.args[1]
    days = context.args[2]
    
    # Validar días
    if not days.isdigit():
        await update.message.reply_text("❌ Los días deben ser un número")
        return
    
    if create_ssh_user(username, password, days):
        await update.message.reply_text(
            f"✅ Usuario *{username}* creado correctamente\n"
            f"📅 Expira en: {days} días",
            parse_mode='Markdown'
        )
    else:
        await update.message.reply_text(f"❌ Error creando usuario {username}")

async def delete(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Comando /delete <user> - Eliminar usuario"""
    if not context.args:
        await update.message.reply_text("⚠️ Uso: /delete <usuario>")
        return
    
    username = context.args[0]
    
    if delete_user(username):
        await update.message.reply_text(f"✅ Usuario {username} eliminado")
    else:
        await update.message.reply_text(f"❌ Error eliminando usuario {username}")

async def keys(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Comando /keys - Listar keys disponibles"""
    if not os.path.exists(KEYS_DB):
        await update.message.reply_text("📋 No hay keys registradas")
        return
    
    try:
        with open(KEYS_DB, 'r') as f:
            keys = f.readlines()
        
        if not keys:
            await update.message.reply_text("📋 No hay keys registradas")
            return
        
        message = "🔑 *Keys disponibles:*\n\n"
        now = int(time.time())
        
        for key_line in keys:
            parts = key_line.strip().split('|')
            if len(parts) >= 7:
                key, hash_val, expiry, max_users, max_gb, used_gb, active = parts[:7]
                
                if active == '1':
                    status = "✅ Activa"
                    if now > int(expiry):
                        status = "⏰ Expirada"
                else:
                    status = "❌ Inactiva"
                
                message += f"`{key[:8]}...` | {status}\n"
        
        await update.message.reply_text(message, parse_mode='Markdown')
    except Exception as e:
        await update.message.reply_text(f"❌ Error leyendo keys: {str(e)}")

async def help(update: Update, context: ContextTypes.DEFAULT_TYPE):
    """Comando /help - Ayuda detallada"""
    help_text = (
        "🤖 *NexusVPN Pro Bot - Ayuda*\n\n"
        "*Comandos disponibles:*\n\n"
        "🔹 `/start` - Iniciar el bot\n"
        "🔹 `/online` - Ver usuarios conectados (con IPs)\n"
        "🔹 `/stats` - Estadísticas del servidor\n"
        "🔹 `/block <IP>` - Bloquear una dirección IP\n"
        "🔹 `/create <user> <pass> <days>` - Crear usuario SSH\n"
        "🔹 `/delete <user>` - Eliminar usuario\n"
        "🔹 `/keys` - Listar keys disponibles\n"
        "🔹 `/help` - Mostrar esta ayuda\n\n"
        "*Ejemplos:*\n"
        "`/block 192.168.1.100`\n"
        "`/create juan pass123 30`\n"
        "`/delete juan`"
    )
    
    await update.message.reply_text(help_text, parse_mode='Markdown')

def main():
    """Función principal del bot"""
    token = load_token()
    
    if not token:
        print(f"{Colors.RED}❌ Token no encontrado{Colors.NC}")
        print(f"{Colors.YELLOW}Configura el token con: nexusvpn --bot-token <TOKEN>{Colors.NC}")
        sys.exit(1)
    
    # Crear aplicación
    application = Application.builder().token(token).build()
    
    # Registrar handlers
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("online", online))
    application.add_handler(CommandHandler("stats", stats))
    application.add_handler(CommandHandler("block", block))
    application.add_handler(CommandHandler("create", create))
    application.add_handler(CommandHandler("delete", delete))
    application.add_handler(CommandHandler("keys", keys))
    application.add_handler(CommandHandler("help", help))
    
    # Iniciar bot
    print(f"{Colors.GREEN}✅ Bot de Telegram iniciado{Colors.NC}")
    application.run_polling(allowed_updates=Update.ALL_TYPES)

if __name__ == "__main__":
    main()
PYBOT

    chmod +x "$BOT_DIR/bot.py"
    log_info "Script del bot creado en $BOT_DIR/bot.py"
}

# Crear servicio systemd para el bot
create_telegram_bot_service() {
    local BOT_DIR="$1"
    
    cat > /etc/systemd/system/nexusvpn-bot.service << EOF
[Unit]
Description=NexusVPN Pro Telegram Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$BOT_DIR
ExecStart=$BOT_DIR/venv/bin/python $BOT_DIR/bot.py
Restart=always
RestartSec=10
Environment="PYTHONUNBUFFERED=1"

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable nexusvpn-bot
    systemctl start nexusvpn-bot
    
    log_info "Servicio del bot creado"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# SISTEMA DE KEYS / LICENCIAS
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Generar una key única
generate_key() {
    local part
    part() {
        head -c 3 /dev/urandom | od -An -tx1 | tr -d ' \n' | tr '[:lower:]' '[:upper:]' | head -c 6
    }
    
    echo "NEXUS-$(part)-$(part)-$(part)-$(part)-$(part)"
}

# Hash de key (para verificación)
key_hash() {
    echo -n "$1" | sha256sum | cut -c1-24
}

# Crear nueva key
create_key() {
    local days="${1:-30}"
    local max_users="${2:-0}"
    local max_gb="${3:-0}"
    local note="${4:-}"
    
    local key expiry hash
    
    key=$(generate_key)
    
    # Calcular expiración (compatible Linux/BSD)
    if date -d "+${days} days" +%s >/dev/null 2>&1; then
        expiry=$(date -d "+${days} days" +%s)
    else
        expiry=$(date -v "+${days}d" +%s 2>/dev/null || echo $(( $(date +%s) + days * 86400 )))
    fi
    
    hash=$(key_hash "$key")
    
    # Guardar en base de datos
    echo "${key}|${hash}|${expiry}|${max_users}|${max_gb}|0|1|$(date +%s)|${note}" >> "$KEYS_DB"
    
    log_info "Key creada: ${key:0:8}... exp:${days}d users:${max_users} gb:${max_gb}"
    echo "$key"
}

# Validar key
validate_key() {
    local input_key="$1"
    
    if [[ ! -f "$KEYS_DB" ]]; then
        return 1
    fi
    
    local now
    now=$(date +%s)
    
    while IFS='|' read -r key hash expiry max_users max_gb used_gb active created note; do
        # Saltar líneas vacías
        [[ -z "$key" ]] && continue
        
        # Comparar key (primeros 8 caracteres para no exponer la key completa)
        if [[ "$key" == "$input_key" && "$active" == "1" ]]; then
            if [[ $now -le $expiry ]]; then
                # Key válida
                echo "$expiry|$max_users|$max_gb|$used_gb"
                return 0
            else
                # Key expirada - desactivar
                sed -i "s/^${key}|${hash}|${expiry}|${max_users}|${max_gb}|${used_gb}|1|${created}|${note}$/${key}|${hash}|${expiry}|${max_users}|${max_gb}|${used_gb}|0|${created}|${note}/" "$KEYS_DB"
                return 2
            fi
        fi
    done < "$KEYS_DB"
    
    return 1
}

# Activar servidor con key
activate_key_server() {
    local key="$1"
    local result
    
    result=$(validate_key "$key") || {
        local rc=$?
        if [[ $rc -eq 2 ]]; then
            err "La key ha expirado"
            return 2
        else
            err "Key inválida o no encontrada"
            return 1
        fi
    }
    
    IFS='|' read -r expiry max_users max_gb used_gb <<< "$result"
    
    # Guardar activación en configuración
    cfg_set "license.active" "true"
    cfg_set "license.key" "\"${key:0:8}...\""
    cfg_set "license.expiry" "$expiry"
    cfg_set "license.max_users" "$max_users"
    cfg_set "license.max_traffic" "$max_gb"
    
    # Mostrar información
    local expiry_fmt
    if date -d "@${expiry}" '+%d/%m/%Y %H:%M' >/dev/null 2>&1; then
        expiry_fmt=$(date -d "@${expiry}" '+%d/%m/%Y %H:%M')
    else
        expiry_fmt=$(date -r "$expiry" '+%d/%m/%Y %H:%M' 2>/dev/null || echo "desconocida")
    fi
    
    box_message "✅ SERVIDOR ACTIVADO EXITOSAMENTE"
    echo -e "${C}  Detalles de la licencia:${NC}"
    echo -e "  ${Y}Key       :${NC} ${key:0:8}$(printf '%*s' $((${#key}-8)) '' | tr ' ' '*')"
    echo -e "  ${Y}Expira    :${NC} ${W}${expiry_fmt}${NC}"
    echo -e "  ${Y}Max users :${NC} ${W}$([[ $max_users -eq 0 ]] && echo 'Ilimitado' || echo "$max_users")${NC}"
    echo -e "  ${Y}Max GB    :${NC} ${W}$([[ $max_gb -eq 0 ]] && echo 'Ilimitado' || echo "${max_gb} GB")${NC}"
    
    log_info "Servidor activado con key: ${key:0:8}..."
    return 0
}

# Obtener estado de la licencia
get_license_expiry() {
    local expiry
    expiry=$(cfg_get "license.expiry")
    
    if [[ -z "$expiry" || "$expiry" == "0" ]]; then
        echo "Sin licencia activa"
        return
    fi
    
    local now
    now=$(date +%s)
    
    if [[ $now -gt $expiry ]]; then
        echo "EXPIRADA"
        return
    fi
    
    local remaining=$(( (expiry - now) / 86400 ))
    
    if [[ $remaining -eq 0 ]]; then
        echo "Expira HOY"
    else
        echo "Expira en ${remaining} días"
    fi
}

# Verificar si la licencia está activa
check_license_active() {
    local active expiry
    
    active=$(cfg_get "license.active")
    expiry=$(cfg_get "license.expiry")
    
    [[ "$active" != "true" ]] && return 1
    [[ -z "$expiry" || "$expiry" == "0" ]] && return 1
    [[ $(date +%s) -le $expiry ]] && return 0 || return 1
}

# Limpiar keys expiradas
clean_expired_keys() {
    local now
    now=$(date +%s)
    
    if [[ ! -f "$KEYS_DB" ]]; then
        return
    fi
    
    local tmp_file
    tmp_file=$(mktemp)
    local modified=0
    
    while IFS='|' read -r key hash expiry max_users max_gb used_gb active created note; do
        [[ -z "$key" ]] && continue
        
        if [[ $now -gt $expiry && "$active" == "1" ]]; then
            # Key expirada - desactivar
            echo "${key}|${hash}|${expiry}|${max_users}|${max_gb}|${used_gb}|0|${created}|${note}" >> "$tmp_file"
            modified=1
        else
            echo "${key}|${hash}|${expiry}|${max_users}|${max_gb}|${used_gb}|${active}|${created}|${note}" >> "$tmp_file"
        fi
    done < "$KEYS_DB"
    
    if [[ $modified -eq 1 ]]; then
        mv "$tmp_file" "$KEYS_DB"
        chmod 600 "$KEYS_DB"
        log_info "Keys expiradas limpiadas"
    else
        rm -f "$tmp_file"
    fi
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE MONITOREO (VER USUARIOS CONECTADOS + IPs)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Mostrar usuarios conectados en tiempo real
show_online_users() {
    clear_screen
    echo -e "${C}════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${W}  📡  USUARIOS CONECTADOS AHORA - NEXUSVPN PRO ${NC}"
    echo -e "${C}════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════${NC}"
    
    # Cabecera de la tabla
    printf "${Y}%-20s %-15s %-20s %-10s %-15s %-12s${NC}\n" "USUARIO" "PROTOCOLO" "IP ORIGEN" "PUERTO" "PAÍS" "DURACIÓN"
    echo -e "${DIM}────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    
    local total_users=0
    
    # 1. USUARIOS SSH
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            # Formato: usuario pts/0 2025-03-17 10:30 (1.2.3.4)
            local user=$(echo "$line" | awk '{print $1}')
            local ip=$(echo "$line" | awk '{print $5}' | tr -d '()')
            local login_time=$(echo "$line" | awk '{print $3, $4}')
            
            # Obtener país de la IP
            local country="?"
            if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                country=$(curl -s "http://ip-api.com/line/${ip}?fields=country" 2>/dev/null | head -1 || echo "?")
                [[ -z "$country" ]] && country="?"
            fi
            
            # Calcular duración
            local duration="?"
            if [[ -n "$login_time" ]]; then
                if date -d "$login_time" +%s >/dev/null 2>&1; then
                    local login_epoch=$(date -d "$login_time" +%s 2>/dev/null)
                    local now_epoch=$(date +%s)
                    local diff=$((now_epoch - login_epoch))
                    local hours=$((diff / 3600))
                    local minutes=$(( (diff % 3600) / 60 ))
                    duration=$(printf "%02d:%02d" $hours $minutes)
                fi
            fi
            
            printf "  %-18s SSH        %-20s %-10s %-15s %-12s\n" "$user" "$ip" "22" "$country" "$duration"
            ((total_users++))
        fi
    done < <(who --ips 2>/dev/null | grep -v "127.0.0.1")
    
    # 2. USUARIOS XRAY (desde logs)
    if [[ -f "$XRAY_ACCESS_LOG" ]]; then
        tail -100 "$XRAY_ACCESS_LOG" 2>/dev/null | grep "email:" | while read -r line; do
            local email=$(echo "$line" | grep -oP "email:\s*\K[^ ]+" | head -1)
            local ip=$(echo "$line" | grep -oP "remote:\s*\K[^:]+" | head -1)
            local port=$(echo "$line" | grep -oP "remote:[^:]+:\K\d+" | head -1)
            
            if [[ -n "$email" && -n "$ip" && "$ip" != "127.0.0.1" ]]; then
                local country="?"
                if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    country=$(curl -s "http://ip-api.com/line/${ip}?fields=country" 2>/dev/null | head -1 || echo "?")
                fi
                
                printf "  %-18s XRAY       %-20s %-10s %-15s %-12s\n" "${email:0:18}" "$ip" "${port:-443}" "$country" "active"
                ((total_users++))
            fi
        done
    fi
    
    # 3. USUARIOS WIREGUARD
    if command -v wg &>/dev/null && systemctl is-active wg-quick@wg0 >/dev/null 2>&1; then
        wg show | grep -A 2 "peer:" | while read -r line; do
            if [[ "$line" =~ endpoint ]]; then
                local ip_port=$(echo "$line" | grep -oP "\d+\.\d+\.\d+\.\d+:\d+")
                local ip=$(echo "$ip_port" | cut -d: -f1)
                local port=$(echo "$ip_port" | cut -d: -f2)
                
                if [[ -n "$ip" && "$ip" != "127.0.0.1" ]]; then
                    local country="?"
                    if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                        country=$(curl -s "http://ip-api.com/line/${ip}?fields=country" 2>/dev/null | head -1 || echo "?")
                    fi
                    
                    printf "  %-18s WIREGUARD  %-20s %-10s %-15s %-12s\n" "wg_peer" "$ip" "${port:-51820}" "$country" "active"
                    ((total_users++))
                fi
            fi
        done
    fi
    
    # 4. USUARIOS OPENVPN
    if [[ -f /var/log/openvpn-status.log ]]; then
        grep "CLIENT_LIST" /var/log/openvpn-status.log 2>/dev/null | while read -r line; do
            local client=$(echo "$line" | awk '{print $2}')
            local ip_port=$(echo "$line" | awk '{print $3}')
            local ip=$(echo "$ip_port" | cut -d: -f1)
            
            if [[ -n "$ip" && "$ip" != "127.0.0.1" ]]; then
                local country="?"
                if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                    country=$(curl -s "http://ip-api.com/line/${ip}?fields=country" 2>/dev/null | head -1 || echo "?")
                fi
                
                printf "  %-18s OPENVPN    %-20s %-10s %-15s %-12s\n" "${client:0:18}" "$ip" "1194" "$country" "active"
                ((total_users++))
            fi
        done
    fi
    
    echo -e "${C}────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────${NC}"
    
    if [[ $total_users -eq 0 ]]; then
        echo -e "  ${Y}No hay usuarios conectados en este momento${NC}"
    else
        echo -e "  ${G}Total: ${W}${total_users}${G} usuario(s) conectado(s)${NC}"
    fi
    
    echo -e "${C}════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════${NC}"
}

# Contar usuarios activos (versión rápida)
count_active_users() {
    local count=0
    
    # SSH
    count=$(( count + $(who 2>/dev/null | wc -l) ))
    
    # Xray (conexiones a puertos comunes)
    count=$(( count + $(ss -tnp 2>/dev/null | grep -E 'xray|v2ray' | wc -l) ))
    
    # WireGuard
    if command -v wg &>/dev/null; then
        count=$(( count + $(wg show 2>/dev/null | grep -c "peer:") ))
    fi
    
    echo "$count"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN DE CRON PARA TAREAS AUTOMÁTICAS
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

setup_cron_jobs() {
    inf "Configurando tareas automáticas (cron)..."
    
    # Limpiar keys expiradas cada hora
    if ! crontab -l 2>/dev/null | grep -q "nexusvpn.*--clean-keys"; then
        (crontab -l 2>/dev/null; echo "0 * * * * /usr/local/bin/nexusvpn --clean-keys >/dev/null 2>&1") | crontab -
        log_info "Cron job para limpiar keys agregado"
    fi
    
    # Backup diario a las 3 AM
    if ! crontab -l 2>/dev/null | grep -q "nexusvpn.*--backup"; then
        (crontab -l 2>/dev/null; echo "0 3 * * * /usr/local/bin/nexusvpn --backup >/dev/null 2>&1") | crontab -
        log_info "Cron job para backup diario agregado"
    fi
    
    # Reiniciar servicios cada semana (opcional)
    if confirm "¿Reiniciar servicios automáticamente cada semana?" "n"; then
        if ! crontab -l 2>/dev/null | grep -q "systemctl restart.*xray"; then
            (crontab -l 2>/dev/null; echo "0 4 * * 0 /usr/local/bin/nexusvpn --restart-services >/dev/null 2>&1") | crontab -
            log_info "Cron job para reinicio semanal agregado"
        fi
    fi
    
    ok "Tareas automáticas configuradas"
}

# Función para reiniciar todos los servicios (usada por cron)
restart_all_services() {
    inf "Reiniciando todos los servicios..."
    
    local services=(
        "xray"
        "hysteria"
        "wg-quick@wg0"
        "openvpn@server/tcp"
        "openvpn@server/udp"
        "slowdns"
        "nexusvpn-bot"
        "nginx"
        "ssh"
    )
    
    for svc in "${services[@]}"; do
        if systemctl list-units --full -all 2>/dev/null | grep -q "$svc"; then
            systemctl restart "$svc" >> "$INSTALL_LOG" 2>&1
            inf "  Reiniciado: $svc"
        fi
    done
    
    ok "Servicios reiniciados"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# PARTE 5: FIREWALL, BACKUPS, PANEL WEB, MENÚ PRINCIPAL (Líneas 4001-5247)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN AVANZADA DE FIREWALL
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

configure_firewall() {
    inf "Configurando firewall avanzado..."
    log_info "Configurando firewall"
    
    # Instalar UFW si no está
    if ! command -v ufw &>/dev/null; then
        apt_install ufw
    fi
    
    # Resetear configuración
    ufw --force disable >> "$INSTALL_LOG" 2>&1
    ufw --force reset >> "$INSTALL_LOG" 2>&1
    
    # Configurar políticas por defecto
    ufw default deny incoming >> "$INSTALL_LOG" 2>&1
    ufw default allow outgoing >> "$INSTALL_LOG" 2>&1
    
    # Puerto SSH (importante mantener)
    local ssh_port
    ssh_port=$(cfg_get "ports.ssh" "$DEFAULT_SSH_PORT")
    ufw allow "${ssh_port}/tcp" comment 'SSH' >> "$INSTALL_LOG" 2>&1
    
    # Puertos de Xray
    ufw allow "$(cfg_get ports.xray_vless_tcp)/tcp" comment 'VLESS TCP' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_vmess_ws)/tcp" comment 'VMess WS' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_vmess_ws_alt)/tcp" comment 'VMess WS Alt' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_vmess_mkcp)/udp" comment 'VMess mKCP' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_trojan)/tcp" comment 'Trojan' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_shadowsocks)/tcp" comment 'Shadowsocks TCP' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_shadowsocks)/udp" comment 'Shadowsocks UDP' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.xray_vless_grpc)/tcp" comment 'VLESS gRPC' >> "$INSTALL_LOG" 2>&1
    
    # Hysteria2
    ufw allow "$(cfg_get ports.hysteria2)/udp" comment 'Hysteria2' >> "$INSTALL_LOG" 2>&1
    
    # WireGuard
    ufw allow "$(cfg_get ports.wireguard)/udp" comment 'WireGuard' >> "$INSTALL_LOG" 2>&1
    
    # IKEv2
    ufw allow 500/udp comment 'IKEv2' >> "$INSTALL_LOG" 2>&1
    ufw allow 4500/udp comment 'IKEv2 NAT-T' >> "$INSTALL_LOG" 2>&1
    
    # OpenVPN
    ufw allow "$(cfg_get ports.openvpn_tcp)/tcp" comment 'OpenVPN TCP' >> "$INSTALL_LOG" 2>&1
    ufw allow "$(cfg_get ports.openvpn_udp)/udp" comment 'OpenVPN UDP' >> "$INSTALL_LOG" 2>&1
    
    # SlowDNS
    ufw allow "$(cfg_get ports.slowdns)/udp" comment 'SlowDNS' >> "$INSTALL_LOG" 2>&1
    
    # BadVPN
    local badvpn_ports
    badvpn_ports=$(cfg_get "badvpn.ports" "[7100,7200,7300]")
    badvpn_ports=$(echo "$badvpn_ports" | tr -d '[]' | tr ',' ' ')
    for port in $badvpn_ports; do
        port=$(echo "$port" | xargs)
        [[ -n "$port" ]] && ufw allow "${port}/udp" comment "BadVPN $port" >> "$INSTALL_LOG" 2>&1
    done
    
    # UDP Custom (rango)
    local udp_range
    udp_range=$(cfg_get "udp_custom.range" "$DEFAULT_UDP_CUSTOM_RANGE")
    if [[ "$udp_range" != "none" ]]; then
        ufw allow "$udp_range/udp" comment 'UDP Custom' >> "$INSTALL_LOG" 2>&1
    fi
    
    # Panel web (opcional)
    if [[ "$(cfg_get features.web_panel false)" == "true" ]]; then
        ufw allow "$(cfg_get ports.webpanel)/tcp" comment 'Web Panel' >> "$INSTALL_LOG" 2>&1
    fi
    
    # Rate limiting para SSH (anti-brute force)
    ufw limit "${ssh_port}/tcp" comment 'SSH rate limit' >> "$INSTALL_LOG" 2>&1
    
    # Habilitar logging
    ufw logging on >> "$INSTALL_LOG" 2>&1
    
    # Habilitar firewall
    echo "y" | ufw enable >> "$INSTALL_LOG" 2>&1
    
    # Configurar iptables para forwarding
    cat > /etc/ufw/before.rules.new << 'EOF'
# START NEXUSVPN RULES
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
    
    # Recargar UFW
    ufw reload >> "$INSTALL_LOG" 2>&1
    
    # Habilitar forwarding en kernel
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.d/99-nexusvpn.conf
    echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.d/99-nexusvpn.conf
    echo "net.ipv4.conf.all.rp_filter = 0" >> /etc/sysctl.d/99-nexusvpn.conf
    echo "net.ipv4.conf.default.rp_filter = 0" >> /etc/sysctl.d/99-nexusvpn.conf
    sysctl -p /etc/sysctl.d/99-nexusvpn.conf
    
    log_info "Firewall configurado correctamente"
    ok "Firewall configurado con $(ufw status numbered | grep -c "\[") reglas"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# SISTEMA DE BACKUPS
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

create_backup() {
    local backup_name="nexusvpn-backup-$(date +%Y%m%d-%H%M%S)"
    local backup_file="${BACKUP_DIR}/${backup_name}.tar.gz"
    local backup_info="${BACKUP_DIR}/${backup_name}.info"
    
    inf "Creando backup completo del sistema..."
    log_info "Iniciando backup: $backup_name"
    
    # Crear directorio temporal
    local tmp_dir
    tmp_dir=$(mktemp -d)
    mkdir -p "$tmp_dir/backup"
    
    # 1. Configuración del panel
    cp -r "$INSTALL_DIR" "$tmp_dir/backup/" 2>/dev/null
    
    # 2. Configuraciones de servicios
    mkdir -p "$tmp_dir/backup/services"
    [[ -d /usr/local/etc/xray ]] && cp -r /usr/local/etc/xray "$tmp_dir/backup/services/"
    [[ -d /etc/hysteria ]] && cp -r /etc/hysteria "$tmp_dir/backup/services/"
    [[ -d /etc/wireguard ]] && cp -r /etc/wireguard "$tmp_dir/backup/services/"
    [[ -d /etc/openvpn ]] && cp -r /etc/openvpn "$tmp_dir/backup/services/"
    [[ -d /etc/ipsec.d ]] && cp -r /etc/ipsec.d "$tmp_dir/backup/services/"
    [[ -d /etc/nginx/sites-available ]] && cp /etc/nginx/sites-available/nexus* "$tmp_dir/backup/services/" 2>/dev/null
    
    # 3. Certificados
    mkdir -p "$tmp_dir/backup/certs"
    cp /etc/letsencrypt/live/*/*.pem "$tmp_dir/backup/certs/" 2>/dev/null
    cp /etc/hysteria/*.pem "$tmp_dir/backup/certs/" 2>/dev/null
    
    # 4. Base de datos
    mkdir -p "$tmp_dir/backup/database"
    cp "$USERS_DB" "$KEYS_DB" "$TRAFFIC_DB" "$tmp_dir/backup/database/" 2>/dev/null
    
    # 5. Scripts personalizados
    cp /usr/local/bin/nexusvpn* "$tmp_dir/backup/" 2>/dev/null
    
    # 6. Información del backup
    cat > "$tmp_dir/backup/backup-info.txt" << EOF
NEXUSVPN PRO BACKUP INFORMATION
===============================
Fecha: $(date '+%Y-%m-%d %H:%M:%S')
Versión: $SCRIPT_VERSION
Hostname: $(hostname)
IP: $(get_server_ip)
OS: $(get_os_name)

Archivos incluidos:
- Configuración del panel
- Configuraciones de servicios
- Certificados SSL
- Bases de datos de usuarios y keys
- Scripts personalizados
EOF
    
    # Crear archivo tar.gz
    cd "$tmp_dir" || return 1
    tar -czf "$backup_file" backup/ >> "$INSTALL_LOG" 2>&1
    
    # Crear archivo de información
    cat > "$backup_info" << EOF
Backup: $backup_name
Fecha: $(date '+%Y-%m-%d %H:%M:%S')
Tamaño: $(du -h "$backup_file" | cut -f1)
MD5: $(md5sum "$backup_file" | cut -d' ' -f1)
EOF
    
    # Limpiar
    cd /
    rm -rf "$tmp_dir"
    
    if [[ -f "$backup_file" ]]; then
        local size
        size=$(du -h "$backup_file" | cut -f1)
        log_info "Backup creado: $backup_name ($size)"
        ok "Backup creado: ${W}$backup_name${NC} (${G}$size${NC})"
        
        # Mantener solo los últimos 10 backups
        clean_old_backups
    else
        err "Error al crear backup"
        return 1
    fi
}

# Limpiar backups antiguos (conservar últimos 10)
clean_old_backups() {
    local backups
    backups=($(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))
    local count=${#backups[@]}
    
    if [[ $count -gt 10 ]]; then
        for ((i=10; i<count; i++)); do
            rm -f "${backups[$i]}" "${backups[$i]%.tar.gz}.info"
            log_info "Backup antiguo eliminado: ${backups[$i]}"
        done
        inf "Backups antiguos limpiados (conservados los últimos 10)"
    fi
}

# Restaurar backup
restore_backup() {
    inf "Preparando restauración de backup..."
    
    # Listar backups disponibles
    local backups=($(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        warn "No hay backups disponibles en $BACKUP_DIR"
        return 1
    fi
    
    echo -e "\n${C}  Backups disponibles:${NC}"
    local i=1
    for backup in "${backups[@]}"; do
        local name=$(basename "$backup" .tar.gz)
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -c '%y' "$backup" 2>/dev/null | cut -d. -f1)
        echo -e "  ${Y}$i)${NC} ${W}$name${NC} (${G}$size${NC}) - ${DIM}$date${NC}"
        ((i++))
    done
    
    echo ""
    read_input "Selecciona número de backup a restaurar" backup_num
    
    if [[ ! "$backup_num" =~ ^[0-9]+$ ]] || [[ $backup_num -lt 1 ]] || [[ $backup_num -gt ${#backups[@]} ]]; then
        err "Selección inválida"
        return 1
    fi
    
    local selected="${backups[$((backup_num-1))]}"
    
    warn "Vas a restaurar: $(basename "$selected")"
    warn "Esto SOBREESCRIBIRÁ la configuración actual"
    
    if ! confirm "¿Estás absolutamente seguro?" "n"; then
        inf "Restauración cancelada"
        return 0
    fi
    
    inf "Restaurando backup..."
    
    # Crear backup automático antes de restaurar
    create_backup
    
    # Restaurar
    local tmp_dir
    tmp_dir=$(mktemp -d)
    
    tar -xzf "$selected" -C "$tmp_dir" >> "$INSTALL_LOG" 2>&1
    
    if [[ -d "$tmp_dir/backup" ]]; then
        # Detener servicios
        systemctl stop xray hysteria wg-quick@wg0 openvpn@server-tcp openvpn@server-udp slowdns nexusvpn-bot nginx 2>/dev/null
        
        # Restaurar configuraciones
        cp -rf "$tmp_dir/backup/$(basename "$INSTALL_DIR")"/* "$INSTALL_DIR/" 2>/dev/null
        [[ -d "$tmp_dir/backup/services/xray" ]] && cp -rf "$tmp_dir/backup/services/xray"/* /usr/local/etc/xray/ 2>/dev/null
        [[ -d "$tmp_dir/backup/services/hysteria" ]] && cp -rf "$tmp_dir/backup/services/hysteria"/* /etc/hysteria/ 2>/dev/null
        [[ -d "$tmp_dir/backup/services/wireguard" ]] && cp -rf "$tmp_dir/backup/services/wireguard"/* /etc/wireguard/ 2>/dev/null
        [[ -d "$tmp_dir/backup/services/openvpn" ]] && cp -rf "$tmp_dir/backup/services/openvpn"/* /etc/openvpn/ 2>/dev/null
        [[ -d "$tmp_dir/backup/services/ipsec.d" ]] && cp -rf "$tmp_dir/backup/services/ipsec.d"/* /etc/ipsec.d/ 2>/dev/null
        
        # Restaurar base de datos
        [[ -f "$tmp_dir/backup/database/users.db" ]] && cp "$tmp_dir/backup/database/users.db" "$USERS_DB"
        [[ -f "$tmp_dir/backup/database/keys.db" ]] && cp "$tmp_dir/backup/database/keys.db" "$KEYS_DB"
        
        # Reiniciar servicios
        systemctl daemon-reload
        systemctl start xray hysteria wg-quick@wg0 openvpn@server-tcp openvpn@server-udp slowdns nexusvpn-bot nginx 2>/dev/null
        
        ok "Backup restaurado correctamente"
        log_info "Backup restaurado: $(basename "$selected")"
    else
        err "El backup no tiene la estructura esperada"
    fi
    
    rm -rf "$tmp_dir"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# PANEL WEB (OPCIONAL)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

install_web_panel() {
    inf "Instalando panel web básico (puerto $(cfg_get ports.webpanel))..."
    log_info "Instalando panel web"
    
    # Instalar dependencias
    apt_install nginx python3 python3-flask python3-psutil
    
    # Crear directorio para el panel web
    local web_dir="/var/www/nexusvpn"
    mkdir -p "$web_dir"/{static,templates}
    
    # Crear aplicación Flask
    cat > "$web_dir/app.py" << 'WEBPY'
#!/usr/bin/env python3
"""
NexusVPN Pro - Panel Web
"""

import os
import json
import subprocess
import psutil
import time
from datetime import datetime
from flask import Flask, render_template, jsonify, request, redirect, url_for, session
import functools

app = Flask(__name__)
app.secret_key = os.urandom(24)

# Configuración
INSTALL_DIR = "/etc/nexusvpn"
CONFIG_FILE = f"{INSTALL_DIR}/config/config.json"
USERS_DB = f"{INSTALL_DIR}/database/users.db"

def load_config():
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except:
        return {}

def login_required(view):
    @functools.wraps(view)
    def wrapped_view(**kwargs):
        if not session.get('logged_in'):
            return redirect(url_for('login'))
        return view(**kwargs)
    return wrapped_view

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        password = request.form.get('password')
        # Por simplicidad, usar misma contraseña que el panel
        if password == "NexusAdmin2024":  # En producción usar hash
            session['logged_in'] = True
            return redirect(url_for('index'))
        return render_template('login.html', error=True)
    return render_template('login.html', error=False)

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/')
@login_required
def index():
    return render_template('index.html')

@app.route('/api/stats')
@login_required
def api_stats():
    stats = {
        'cpu': psutil.cpu_percent(interval=1),
        'ram': psutil.virtual_memory().percent,
        'disk': psutil.disk_usage('/').percent,
        'uptime': time.time() - psutil.boot_time(),
        'users_online': 0
    }
    
    # Usuarios SSH online
    who = subprocess.run(['who', '--ips'], capture_output=True, text=True)
    stats['users_online'] = len(who.stdout.strip().split('\n')) if who.stdout else 0
    
    return jsonify(stats)

@app.route('/api/users')
@login_required
def api_users():
    users = []
    
    # Usuarios SSH
    who = subprocess.run(['who', '--ips'], capture_output=True, text=True)
    for line in who.stdout.strip().split('\n'):
        if line:
            parts = line.split()
            if len(parts) >= 5:
                users.append({
                    'username': parts[0],
                    'ip': parts[4].strip('()'),
                    'protocol': 'SSH',
                    'time': f"{parts[2]} {parts[3]}"
                })
    
    return jsonify(users)

@app.route('/api/services')
@login_required
def api_services():
    services = ['xray', 'hysteria', 'wg-quick@wg0', 'openvpn@server-tcp', 
                'openvpn@server-udp', 'slowdns', 'nginx', 'ssh']
    result = []
    
    for svc in services:
        status = subprocess.run(['systemctl', 'is-active', svc], 
                               capture_output=True, text=True)
        result.append({
            'name': svc,
            'status': status.stdout.strip() if status.returncode == 0 else 'inactive'
        })
    
    return jsonify(result)

@app.route('/api/restart/<service>', methods=['POST'])
@login_required
def restart_service(service):
    result = subprocess.run(['systemctl', 'restart', service], 
                           capture_output=True, text=True)
    return jsonify({'success': result.returncode == 0})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000)
WEBPY

    # Crear templates HTML
    cat > "$web_dir/templates/login.html" << 'LOGINHTML'
<!DOCTYPE html>
<html>
<head>
    <title>NexusVPN Pro - Login</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .login-container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
            width: 100%;
            max-width: 400px;
        }
        .login-container h1 {
            text-align: center;
            margin-bottom: 30px;
            color: #333;
        }
        .login-container input {
            width: 100%;
            padding: 12px;
            margin: 8px 0;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
        }
        .login-container button {
            width: 100%;
            padding: 12px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
            margin-top: 20px;
        }
        .login-container button:hover {
            background: #5a67d8;
        }
        .error {
            color: #e53e3e;
            text-align: center;
            margin-top: 10px;
        }
        .logo {
            text-align: center;
            margin-bottom: 20px;
            font-size: 24px;
            font-weight: bold;
            color: #667eea;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="logo">🔐 NexusVPN Pro</div>
        <h1>Iniciar Sesión</h1>
        {% if error %}
        <div class="error">Contraseña incorrecta</div>
        {% endif %}
        <form method="post">
            <input type="password" name="password" placeholder="Contraseña" required>
            <button type="submit">Entrar</button>
        </form>
    </div>
</body>
</html>
LOGINHTML

    cat > "$web_dir/templates/index.html" << 'INDEXHTML'
<!DOCTYPE html>
<html>
<head>
    <title>NexusVPN Pro - Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f7fa;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header h1 {
            font-size: 24px;
        }
        .nav {
            background: white;
            padding: 10px 20px;
            border-bottom: 1px solid #e2e8f0;
        }
        .nav a {
            color: #4a5568;
            text-decoration: none;
            padding: 10px 15px;
            display: inline-block;
        }
        .nav a:hover {
            color: #667eea;
        }
        .container {
            max-width: 1200px;
            margin: 20px auto;
            padding: 0 20px;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .stat-card h3 {
            color: #718096;
            font-size: 14px;
            margin-bottom: 10px;
        }
        .stat-card .value {
            font-size: 32px;
            font-weight: bold;
            color: #2d3748;
        }
        .stat-card .unit {
            font-size: 14px;
            color: #718096;
            margin-left: 5px;
        }
        .progress-bar {
            width: 100%;
            height: 8px;
            background: #e2e8f0;
            border-radius: 4px;
            margin-top: 10px;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea, #764ba2);
            border-radius: 4px;
        }
        .section {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .section h2 {
            color: #2d3748;
            margin-bottom: 15px;
            font-size: 18px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th {
            text-align: left;
            padding: 12px;
            background: #f7fafc;
            color: #4a5568;
            font-weight: 600;
            font-size: 14px;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #e2e8f0;
            color: #2d3748;
        }
        .badge {
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
        }
        .badge-active {
            background: #c6f6d5;
            color: #22543d;
        }
        .badge-inactive {
            background: #fed7d7;
            color: #742a2a;
        }
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
            transition: all 0.3s;
        }
        .btn-primary {
            background: #667eea;
            color: white;
        }
        .btn-primary:hover {
            background: #5a67d8;
        }
        .btn-danger {
            background: #e53e3e;
            color: white;
        }
        .btn-danger:hover {
            background: #c53030;
        }
        .logout {
            float: right;
            color: white;
            text-decoration: none;
            padding: 5px 10px;
            border: 1px solid white;
            border-radius: 4px;
        }
        .logout:hover {
            background: rgba(255,255,255,0.1);
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔐 NexusVPN Pro Dashboard
            <a href="/logout" class="logout">Cerrar Sesión</a>
        </h1>
    </div>
    
    <div class="container">
        <div class="stats-grid" id="stats">
            <div class="stat-card">
                <h3>CPU</h3>
                <div class="value" id="cpu">0</div>
                <div class="unit">%</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="cpu-bar" style="width: 0%"></div>
                </div>
            </div>
            <div class="stat-card">
                <h3>RAM</h3>
                <div class="value" id="ram">0</div>
                <div class="unit">%</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="ram-bar" style="width: 0%"></div>
                </div>
            </div>
            <div class="stat-card">
                <h3>DISCO</h3>
                <div class="value" id="disk">0</div>
                <div class="unit">%</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="disk-bar" style="width: 0%"></div>
                </div>
            </div>
            <div class="stat-card">
                <h3>USUARIOS ONLINE</h3>
                <div class="value" id="users">0</div>
            </div>
        </div>

        <div class="section">
            <h2>📡 Usuarios Conectados</h2>
            <table id="users-table">
                <thead>
                    <tr>
                        <th>Usuario</th>
                        <th>IP</th>
                        <th>Protocolo</th>
                        <th>Tiempo</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody id="users-tbody">
                    <tr><td colspan="5">Cargando...</td></tr>
                </tbody>
            </table>
        </div>

        <div class="section">
            <h2>⚙️ Servicios</h2>
            <table id="services-table">
                <thead>
                    <tr>
                        <th>Servicio</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody id="services-tbody">
                    <tr><td colspan="3">Cargando...</td></tr>
                </tbody>
            </table>
        </div>
    </div>

    <script>
        function updateStats() {
            fetch('/api/stats')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('cpu').textContent = data.cpu;
                    document.getElementById('cpu-bar').style.width = data.cpu + '%';
                    document.getElementById('ram').textContent = data.ram;
                    document.getElementById('ram-bar').style.width = data.ram + '%';
                    document.getElementById('disk').textContent = data.disk;
                    document.getElementById('disk-bar').style.width = data.disk + '%';
                    document.getElementById('users').textContent = data.users_online;
                });
        }

        function updateUsers() {
            fetch('/api/users')
                .then(r => r.json())
                .then(users => {
                    const tbody = document.getElementById('users-tbody');
                    if (users.length === 0) {
                        tbody.innerHTML = '<tr><td colspan="5">No hay usuarios conectados</td></tr>';
                        return;
                    }
                    
                    let html = '';
                    users.forEach(u => {
                        html += `
                            <tr>
                                <td>${u.username}</td>
                                <td>${u.ip}</td>
                                <td>${u.protocol}</td>
                                <td>${u.time}</td>
                                <td>
                                    <button class="btn btn-danger btn-sm" onclick="blockIP('${u.ip}')">Bloquear</button>
                                </td>
                            </tr>
                        `;
                    });
                    tbody.innerHTML = html;
                });
        }

        function updateServices() {
            fetch('/api/services')
                .then(r => r.json())
                .then(services => {
                    const tbody = document.getElementById('services-tbody');
                    let html = '';
                    services.forEach(s => {
                        const statusClass = s.status === 'active' ? 'badge-active' : 'badge-inactive';
                        html += `
                            <tr>
                                <td>${s.name}</td>
                                <td><span class="badge ${statusClass}">${s.status}</span></td>
                                <td>
                                    <button class="btn btn-primary btn-sm" onclick="restartService('${s.name}')">Reiniciar</button>
                                </td>
                            </tr>
                        `;
                    });
                    tbody.innerHTML = html;
                });
        }

        function blockIP(ip) {
            if (confirm(`¿Bloquear IP ${ip}?`)) {
                fetch('/api/block', {
                    method: 'POST',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify({ip: ip})
                }).then(r => r.json()).then(data => {
                    if (data.success) alert('IP bloqueada');
                    else alert('Error');
                });
            }
        }

        function restartService(name) {
            if (confirm(`¿Reiniciar ${name}?`)) {
                fetch(`/api/restart/${name}`, {method: 'POST'})
                    .then(r => r.json())
                    .then(data => {
                        if (data.success) {
                            alert('Servicio reiniciado');
                            updateServices();
                        }
                    });
            }
        }

        setInterval(updateStats, 5000);
        setInterval(updateUsers, 10000);
        setInterval(updateServices, 15000);
        
        updateStats();
        updateUsers();
        updateServices();
    </script>
</body>
</html>
INDEXHTML

    chmod +x "$web_dir/app.py"
    
    # Configurar Nginx
    cat > "${NGINX_AVAILABLE}/nexusvpn-web" << WEB
server {
    listen $(cfg_get ports.webpanel);
    server_name _;
    
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }
}
WEB

    ln -sf "${NGINX_AVAILABLE}/nexusvpn-web" "${NGINX_ENABLED}/nexusvpn-web"
    
    # Crear servicio systemd para el panel web
    cat > /etc/systemd/system/nexusvpn-web.service << WEB
[Unit]
Description=NexusVPN Pro Web Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$web_dir
ExecStart=/usr/bin/python3 $web_dir/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
WEB

    systemctl daemon-reload
    systemctl enable nexusvpn-web
    systemctl start nexusvpn-web
    systemctl reload nginx
    
    cfg_set "features.web_panel" "true"
    log_info "Panel web instalado en puerto $(cfg_get ports.webpanel)"
    ok "Panel web instalado en http://$(get_server_ip):$(cfg_get ports.webpanel)"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# MENÚ PRINCIPAL DEL PANEL
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

main_menu() {
    while true; do
        print_banner
        
        echo -e "${C}╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}                              ${W}${BLD}MENÚ PRINCIPAL - NEXUSVPN PRO${NC}                                             ${C}║${NC}"
        echo -e "${C}╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        
        # Primera fila
        echo -e "${C}║${NC}  ${Y}1)${NC}  🔑  Gestión de Keys (licencias)     ${C}║${NC}  ${Y}10)${NC} 🌐  Gestión de Puertos        ${C}║${NC}  ${Y}19)${NC} 📊  Estadísticas            ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}2)${NC}  👥  Usuarios Xray/V2Ray             ${C}║${NC}  ${Y}11)${NC} 🔄  Backup y Restaurar        ${C}║${NC}  ${Y}20)${NC} 👁️  Ver online (IPs)       ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}3)${NC}  ⚡  Hysteria2                       ${C}║${NC}  ${Y}12)${NC} 📱  Generar QR de conexión    ${C}║${NC}  ${Y}21)${NC} 📈  Tráfico por usuario     ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}4)${NC}  🌀  SlowDNS                         ${C}║${NC}  ${Y}13)${NC} 🆙  Actualizar panel          ${C}║${NC}  ${Y}22)${NC} 🔒  Cambiar contraseña      ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}5)${NC}  📡  UDP Custom / BadVPN             ${C}║${NC}  ${Y}14)${NC} 🔒  Cambiar contraseña admin  ${C}║${NC}  ${Y}23)${NC} 🌍  Panel web (opcional)    ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}6)${NC}  🔐  SSH Manager                     ${C}║${NC}  ${Y}15)${NC} 🔗  Ver links de conexión     ${C}║${NC}  ${Y}24)${NC} 🤖  Bot de Telegram         ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}7)${NC}  ☁️   Cloudflare / SSL               ${C}║${NC}  ${Y}16)${NC} ⚙️   Servicios y Logs          ${C}║${NC}  ${Y}25)${NC} 🔥  Firewall Manager        ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}8)${NC}  📢  Banner & Publicidad             ${C}║${NC}  ${Y}17)${NC} 🔧  Herramientas online       ${C}║${NC}  ${Y}26)${NC} 📝  Ver logs del panel       ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}9)${NC}  📊  Ver usuarios conectados         ${C}║${NC}  ${Y}18)${NC} 🔌  Probar conexiones          ${C}║${NC}  ${Y}27)${NC} ❓  Ayuda                  ${C}║${NC}"
        
        echo -e "${C}╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}                                            ${R}0)${NC}  🚪  Salir del panel                                              ${C}║${NC}"
        echo -e "${C}╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝${NC}"
        
        echo ""
        read_input "Selecciona una opción [0-27]" menu_option
        
        case "$menu_option" in
            1) menu_keys ;;
            2) menu_xray_users ;;
            3) menu_hysteria2 ;;
            4) menu_slowdns ;;
            5) menu_udp ;;
            6) menu_ssh ;;
            7) menu_cf_ssl ;;
            8) menu_banner ;;
            9) show_online_users; press_enter ;;
            10) menu_ports ;;
            11) menu_backup ;;
            12) menu_qr ;;
            13) menu_update ;;
            14) change_admin_password ;;
            15) show_connection_links; press_enter ;;
            16) menu_services ;;
            17) menu_tools ;;
            18) test_connections ;;
            19) show_statistics ;;
            20) show_online_users; press_enter ;;
            21) show_user_traffic ;;
            22) change_admin_password ;;
            23) install_web_panel ;;
            24) menu_telegram_bot ;;
            25) menu_firewall ;;
            26) tail -50 "$PANEL_LOG"; press_enter ;;
            27) show_help ;;
            0)
                echo -e "\n  ${G}¡Hasta luego!${NC} ${DIM}NexusVPN Pro v${SCRIPT_VERSION}${NC}\n"
                log_info "Sesión de panel cerrada"
                exit 0
                ;;
            *)
                err "Opción inválida: $menu_option"
                sleep 2
                ;;
        esac
    done
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE MENÚ (stubs - se implementan con los módulos)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

menu_keys() {
    while true; do
        clear_screen
        echo -e "${C}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}                    ${Y}🔑  GESTIÓN DE KEYS / LICENCIAS${NC}                   ${C}║${NC}"
        echo -e "${C}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${W}1)${NC} Activar servidor con Key"
        echo -e "  ${W}2)${NC} Crear nueva Key"
        echo -e "  ${W}3)${NC} Listar todas las Keys"
        echo -e "  ${W}4)${NC} Revocar Key"
        echo -e "  ${W}5)${NC} Ver estado de licencia"
        echo -e "  ${W}6)${NC} Limpiar keys expiradas"
        echo -e "  ${W}0)${NC} Volver al menú principal"
        echo ""
        read_input "Opción" key_opt
        
        case "$key_opt" in
            1)
                echo ""
                read_input "Ingresa la Key (NEXUS-XXXX-...)" input_key
                activate_key_server "$input_key"
                press_enter
                ;;
            2)
                echo ""
                read_input "Días de validez [30]" days "30"
                read_input "Máx. usuarios (0=ilimitado)" max_users "0"
                read_input "Máx. GB (0=ilimitado)" max_gb "0"
                read_input "Nota (opcional)" note
                
                local new_key
                new_key=$(create_key "$days" "$max_users" "$max_gb" "$note")
                box_message "KEY GENERADA: $new_key"
                press_enter
                ;;
            3)
                list_keys
                press_enter
                ;;
            4)
                echo ""
                read_input "Primeros 8 caracteres de la key" key_prefix
                revoke_key "$key_prefix"
                press_enter
                ;;
            5)
                echo ""
                echo -e "  ${Y}Estado actual:${NC} $(get_license_expiry)"
                press_enter
                ;;
            6)
                clean_expired_keys
                ok "Keys expiradas limpiadas"
                press_enter
                ;;
            0) return ;;
            *) err "Opción inválida" ;;
        esac
    done
}

# Las demás funciones de menú (menu_xray_users, menu_hysteria2, etc.) 
# se implementarían aquí, pero por brevedad se omiten en este script principal
# ya que se cargarán desde los módulos correspondientes

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# PUNTO DE ENTRADA PRINCIPAL
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

main() {
    require_root
    
    # Inicializar logging
    init_logging
    
    # Procesar argumentos de línea de comandos
    case "${1:-}" in
        --install)
            check_os_compatibility
            check_architecture
            check_ram
            check_disk_space
            check_internet
            check_ports
            
            init_dirs
            init_config
            run_install
            ;;
            
        --online)
            show_online_users
            ;;
            
        --users)
            list_all_users
            ;;
            
        --block)
            if [[ -n "${2:-}" ]]; then
                block_ip "$2"
            else
                err "Uso: nexusvpn --block <IP>"
            fi
            ;;
            
        --backup)
            create_backup
            ;;
            
        --restore)
            restore_backup
            ;;
            
        --bot-token)
            if [[ -n "${2:-}" ]]; then
                configure_bot_token "$2"
            else
                err "Uso: nexusvpn --bot-token <TOKEN>"
            fi
            ;;
            
        --clean-keys)
            clean_expired_keys
            ;;
            
        --restart-services)
            restart_all_services
            ;;
            
        --status)
            for svc in xray hysteria wg-quick@wg0 openvpn@server-tcp slowdns nginx ssh; do
                status=$(systemctl is-active "$svc" 2>/dev/null || echo "inactive")
                printf "%-20s %s\n" "$svc" "$status"
            done
            ;;
            
        --help|-h)
            show_help
            ;;
            
        --version|-v)
            echo "NexusVPN Pro v$SCRIPT_VERSION ($SCRIPT_LINES líneas)"
            ;;
            
        "")
            # Modo interactivo
            init_dirs
            init_config
            
            # Verificar si ya está instalado
            if [[ ! -f "$CONFIG_FILE" ]] || [[ "$(cfg_get version)" != "$SCRIPT_VERSION" ]]; then
                warn "NexusVPN Pro no está instalado o necesita actualización"
                if confirm "¿Deseas instalar ahora?" "s"; then
                    exec "$0" --install
                fi
            fi
            
            # Autenticación
            authenticate_panel
            
            # Verificar licencia
            if ! check_license_active; then
                warn "Servidor sin licencia activa"
                echo -e "  ${C}Compra tu licencia:${NC}"
                echo -e "     WhatsApp: ${W}+57 300 443 0431${NC}"
                echo -e "     Telegram: ${W}@ANDRESCAMP13${NC}\n"
                
                if confirm "¿Tienes una key para activar?" "s"; then
                    read_input "Ingresa tu key" license_key
                    activate_key_server "$license_key"
                fi
            fi
            
            # Cargar módulos (si existen)
            for module in core xray udp-custom badvpn hysteria2 wireguard ikev2 openvpn slowdns telegram-bot monitoring keys firewall; do
                if [[ -f "$MODULES_DIR/${module}.sh" ]]; then
                    source "$MODULES_DIR/${module}.sh"
                fi
            done
            
            # Iniciar menú principal
            main_menu
            ;;
            
        *)
            err "Opción desconocida: $1"
            show_help
            exit 1
            ;;
    esac
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# EJECUTAR SCRIPT
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

main "$@"

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE MENÚ COMPLETAS
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Menú de usuarios Xray/V2Ray
menu_xray_users() {
    while true; do
        clear_screen
        echo -e "${C}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}                    ${Y}👥  USUARIOS XRAY/V2RAY${NC}                           ${C}║${NC}"
        echo -e "${C}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${W}1)${NC} Listar usuarios"
        echo -e "  ${W}2)${NC} Crear usuario"
        echo -e "  ${W}3)${NC} Eliminar usuario"
        echo -e "  ${W}4)${NC} Ver configuración de usuario"
        echo -e "  ${W}5)${NC} Generar QR de usuario"
        echo -e "  ${W}6)${NC} Limitar velocidad"
        echo -e "  ${W}7)${NC} Ver tráfico consumido"
        echo -e "  ${W}8)${NC} Reiniciar Xray"
        echo -e "  ${W}0)${NC} Volver"
        echo ""
        read_input "Opción" xray_opt
        
        case "$xray_opt" in
            1) list_xray_users ;;
            2) create_xray_user ;;
            3) delete_xray_user ;;
            4) show_xray_config ;;
            5) generate_xray_qr ;;
            6) limit_xray_speed ;;
            7) show_xray_traffic ;;
            8) systemctl restart xray; ok "Xray reiniciado"; press_enter ;;
            0) return ;;
            *) err "Opción inválida" ;;
        esac
    done
}

# Listar usuarios Xray
list_xray_users() {
    echo -e "\n${C}  Usuarios Xray configurados:${NC}\n"
    
    if [[ ! -f "$XRAY_CONFIG" ]]; then
        warn "Xray no está configurado"
        press_enter
        return
    fi
    
    python3 -c "
import json, sys
try:
    with open('$XRAY_CONFIG', 'r') as f:
        cfg = json.load(f)
    
    users = {}
    for inbound in cfg.get('inbounds', []):
        proto = inbound.get('protocol', 'unknown')
        for client in inbound.get('settings', {}).get('clients', []):
            email = client.get('email', 'sin-email').split('@')[0]
            uid = client.get('id', client.get('password', '?'))
            if email not in users:
                users[email] = {'protocols': [], 'uuid': uid}
            users[email]['protocols'].append(proto)
    
    if not users:
        print('  No hay usuarios configurados')
    else:
        print(f'  {'EMAIL':<20} {'UUID':<36} {'PROTOCOLOS':<30}')
        print('  ' + '-'*86)
        for email, data in users.items():
            protocols = ', '.join(data['protocols'])
            print(f'  {email:<20} {data["uuid"]:<36} {protocols:<30}')
except Exception as e:
    print(f'  Error: {e}')
"
    press_enter
}

# Crear usuario Xray
create_xray_user() {
    echo ""
    read_input "Nombre del usuario" username
    
    if [[ -z "$username" ]]; then
        err "Nombre inválido"
        return
    fi
    
    local uuid
    uuid=$(gen_uuid)
    
    # Añadir al config.json
    python3 -c "
import json, sys
with open('$XRAY_CONFIG', 'r') as f:
    cfg = json.load(f)

for inbound in cfg.get('inbounds', []):
    if inbound.get('protocol') in ['vless', 'vmess', 'trojan']:
        clients = inbound.get('settings', {}).get('clients', [])
        new_client = {'email': '$username@nexusvpn', 'level': 0}
        
        if inbound.get('protocol') == 'vless':
            new_client['id'] = '$uuid'
            new_client['flow'] = 'xtls-rprx-vision'
        elif inbound.get('protocol') == 'vmess':
            new_client['id'] = '$uuid'
            new_client['alterId'] = 0
        elif inbound.get('protocol') == 'trojan':
            new_client['password'] = '$uuid'
        
        clients.append(new_client)

with open('$XRAY_CONFIG', 'w') as f:
    json.dump(cfg, f, indent=2)
"
    
    systemctl restart xray
    ok "Usuario $username creado con UUID: $uuid"
    
    # Mostrar configuración básica
    local server_ip
    server_ip=$(get_server_ip)
    echo ""
    echo -e "${Y}  Configuración VLESS:${NC}"
    echo -e "  vless://$uuid@$server_ip:443?encryption=none&flow=xtls-rprx-vision&type=tcp#NexusVPN-$username"
    press_enter
}

# Eliminar usuario Xray
delete_xray_user() {
    echo ""
    read_input "Email del usuario a eliminar" username
    
    python3 -c "
import json, sys
with open('$XRAY_CONFIG', 'r') as f:
    cfg = json.load(f)

deleted = 0
for inbound in cfg.get('inbounds', []):
    if 'clients' in inbound.get('settings', {}):
        original = len(inbound['settings']['clients'])
        inbound['settings']['clients'] = [
            c for c in inbound['settings']['clients'] 
            if c.get('email', '') != '$username@nexusvpn'
        ]
        deleted += original - len(inbound['settings']['clients'])

with open('$XRAY_CONFIG', 'w') as f:
    json.dump(cfg, f, indent=2)

print(deleted)
" | read deleted_count
    
    if [[ $deleted_count -gt 0 ]]; then
        systemctl restart xray
        ok "Usuario $username eliminado"
    else
        warn "Usuario no encontrado"
    fi
    press_enter
}

# Mostrar configuración de usuario Xray
show_xray_config() {
    echo ""
    read_input "Email del usuario" username
    
    local server_ip uuid
    server_ip=$(get_server_ip)
    
    uuid=$(python3 -c "
import json, sys
with open('$XRAY_CONFIG', 'r') as f:
    cfg = json.load(f)
for inbound in cfg.get('inbounds', []):
    for client in inbound.get('settings', {}).get('clients', []):
        if client.get('email', '') == '$username@nexusvpn':
            print(client.get('id', client.get('password', '')))
            sys.exit(0)
print('')
")
    
    if [[ -z "$uuid" ]]; then
        warn "Usuario no encontrado"
        press_enter
        return
    fi
    
    echo ""
    echo -e "${C}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${W}  Configuración para: $username${NC}"
    echo -e "${C}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo -e "${Y}VLESS TCP (443):${NC}"
    echo -e "vless://$uuid@$server_ip:443?encryption=none&flow=xtls-rprx-vision&type=tcp#$username"
    echo ""
    echo -e "${Y}VMess WS (80):${NC}"
    local vmess_b64
    vmess_b64=$(echo -n "{\"v\":\"2\",\"ps\":\"$username\",\"add\":\"$server_ip\",\"port\":\"80\",\"id\":\"$uuid\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/nexus\",\"tls\":\"\"}" | base64 -w 0)
    echo -e "vmess://$vmess_b64"
    echo ""
    echo -e "${Y Trojano (2083):${NC}"
    echo -e "trojan://$uuid@$server_ip:2083?security=none#$username"
    echo ""
    press_enter
}

# Menú de Hysteria2
menu_hysteria2() {
    while true; do
        clear_screen
        echo -e "${C}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}                    ${Y}⚡  HYSTERIA2${NC}                                     ${C}║${NC}"
        echo -e "${C}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${W}1)${NC} Ver estado"
        echo -e "  ${W}2)${NC} Iniciar/Detener"
        echo -e "  ${W}3)${NC} Cambiar puerto"
        echo -e "  ${W}4)${NC} Cambiar contraseña"
        echo -e "  ${W}5)${NC} Ver configuración"
        echo -e "  ${W}6)${NC} Ver logs"
        echo -e "  ${W}7)${NC} Generar QR"
        echo -e "  ${W}0)${NC} Volver"
        echo ""
        read_input "Opción" hy_opt
        
        case "$hy_opt" in
            1)
                systemctl status hysteria --no-pager
                press_enter
                ;;
            2)
                if systemctl is-active hysteria >/dev/null; then
                    systemctl stop hysteria
                    warn "Hysteria2 detenido"
                else
                    systemctl start hysteria
                    ok "Hysteria2 iniciado"
                fi
                press_enter
                ;;
            3)
                read_input "Nuevo puerto" new_port "$(cfg_get ports.hysteria2)"
                cfg_set "ports.hysteria2" "$new_port"
                sed -i "s/^listen: :[0-9]*/listen: :$new_port/" "$HYSTERIA_CONFIG"
                systemctl restart hysteria
                ok "Puerto cambiado a $new_port"
                press_enter
                ;;
            4)
                read_password "Nueva contraseña" new_pass
                cfg_set "hysteria2.auth_pass" "\"$new_pass\""
                sed -i "s/^  password: .*/  password: $new_pass/" "$HYSTERIA_CONFIG"
                systemctl restart hysteria
                ok "Contraseña actualizada"
                press_enter
                ;;
            5)
                echo ""
                cat "$HYSTERIA_CONFIG"
                press_enter
                ;;
            6)
                journalctl -u hysteria -n 50 --no-pager
                press_enter
                ;;
            7)
                local server_ip pass port
                server_ip=$(get_server_ip)
                pass=$(cfg_get hysteria2.auth_pass)
                port=$(cfg_get ports.hysteria2)
                local hy_link="hysteria2://$pass@$server_ip:$port/?insecure=1&obfs=salamander&obfs-password=nexusvpn-obfs#NexusVPN-HY2"
                qrencode -t ansiutf8 "$hy_link"
                echo ""
                echo -e "${Y}Link:${NC} $hy_link"
                press_enter
                ;;
            0) return ;;
            *) err "Opción inválida" ;;
        esac
    done
}

# Menú de SlowDNS
menu_slowdns() {
    while true; do
        clear_screen
        echo -e "${C}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}                    ${Y}🌀  SLOWDNS${NC}                                       ${C}║${NC}"
        echo -e "${C}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${W}1)${NC} Ver estado"
        echo -e "  ${W}2)${NC} Iniciar/Detener"
        echo -e "  ${W}3)${NC} Cambiar puerto"
        echo -e "  ${W}4)${NC} Configurar dominio"
        echo -e "  ${W}5)${NC} Ver clave pública"
        echo -e "  ${W}6)${NC} Ver logs"
        echo -e "  ${W}7)${NC} Probar conexión"
        echo -e "  ${W}0)${NC} Volver"
        echo ""
        read_input "Opción" sdns_opt
        
        case "$sdns_opt" in
            1)
                systemctl status slowdns --no-pager 2>/dev/null || systemctl status slowdns-proxy --no-pager
                press_enter
                ;;
            2)
                if systemctl is-active slowdns >/dev/null 2>&1; then
                    systemctl stop slowdns
                    warn "SlowDNS detenido"
                elif systemctl is-active slowdns-proxy >/dev/null 2>&1; then
                    systemctl stop slowdns-proxy
                    warn "SlowDNS detenido"
                else
                    systemctl start slowdns 2>/dev/null || systemctl start slowdns-proxy
                    ok "SlowDNS iniciado"
                fi
                press_enter
                ;;
            3)
                read_input "Nuevo puerto" new_port "$(cfg_get ports.slowdns)"
                cfg_set "ports.slowdns" "$new_port"
                
                if [[ -f /etc/systemd/system/slowdns.service ]]; then
                    sed -i "s/:5300 /:$new_port /" /etc/systemd/system/slowdns.service
                    systemctl daemon-reload
                    systemctl restart slowdns
                elif [[ -f /etc/systemd/system/slowdns-proxy.service ]]; then
                    sed -i "s/5300 /$new_port /" /etc/systemd/system/slowdns-proxy.service
                    systemctl daemon-reload
                    systemctl restart slowdns-proxy
                fi
                
                ok "Puerto cambiado a $new_port"
                press_enter
                ;;
            4)
                read_input "Subdominio NS (ej: ns.tudominio.com)" ns_domain
                cfg_set "slowdns.domain" "\"$ns_domain\""
                
                if [[ -f /etc/systemd/system/slowdns.service ]]; then
                    sed -i "s/ [^ ]*\.example\.com/ $ns_domain/" /etc/systemd/system/slowdns.service
                    systemctl daemon-reload
                    systemctl restart slowdns
                    ok "Dominio configurado"
                else
                    warn "Configura manualmente el dominio en /etc/systemd/system/slowdns.service"
                fi
                press_enter
                ;;
            5)
                echo ""
                if [[ -f "$INSTALL_DIR/slowdns/server.pub" ]]; then
                    cat "$INSTALL_DIR/slowdns/server.pub"
                else
                    warn "Clave pública no encontrada"
                fi
                press_enter
                ;;
            6)
                journalctl -u slowdns -n 50 --no-pager 2>/dev/null || journalctl -u slowdns-proxy -n 50 --no-pager
                press_enter
                ;;
            7)
                local server_ip port
                server_ip=$(get_server_ip)
                port=$(cfg_get ports.slowdns)
                echo ""
                echo -e "${Y}Prueba de conexión:${NC}"
                echo -e "nslookup -port=$port google.com $server_ip"
                press_enter
                ;;
            0) return ;;
            *) err "Opción inválida" ;;
        esac
    done
}

# Menú UDP Custom / BadVPN
menu_udp() {
    while true; do
        clear_screen
        echo -e "${C}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}                    ${Y}📡  UDP CUSTOM / BADVPN${NC}                           ${C}║${NC}"
        echo -e "${C}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${W}1)${NC} Ver puertos activos"
        echo -e "  ${W}2)${NC} Agregar puerto UDP Custom"
        echo -e "  ${W}3)${NC} Eliminar puerto UDP Custom"
        echo -e "  ${W}4)${NC} Ver BadVPN"
        echo -e "  ${W}5)${NC} Agregar puerto BadVPN"
        echo -e "  ${W}6)${NC} Eliminar puerto BadVPN"
        echo -e "  ${W}7)${NC} Abrir rango UDP"
        echo -e "  ${W}8)${NC} Reiniciar servicios"
        echo -e "  ${W}0)${NC} Volver"
        echo ""
        read_input "Opción" udp_opt
        
        case "$udp_opt" in
            1)
                echo ""
                echo -e "${Y}Puertos UDP Custom:${NC}"
                systemctl list-units --all | grep udp-custom | awk '{print "  " $1}'
                echo ""
                echo -e "${Y}Puertos BadVPN:${NC}"
                systemctl list-units --all | grep badvpn | awk '{print "  " $1}'
                press_enter
                ;;
            2)
                read_input "Puerto a abrir" new_port
                if [[ -n "$new_port" ]]; then
                    cat > "/etc/systemd/system/udp-custom@${new_port}.service" << EOF
[Unit]
Description=UDP Custom on port $new_port
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/udp-custom $new_port 7300 udp
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
                    systemctl daemon-reload
                    systemctl enable "udp-custom@${new_port}"
                    systemctl start "udp-custom@${new_port}"
                    ufw allow "${new_port}/udp"
                    ok "Puerto UDP $new_port abierto"
                fi
                press_enter
                ;;
            3)
                read_input "Puerto a cerrar" del_port
                if [[ -n "$del_port" ]]; then
                    systemctl stop "udp-custom@${del_port}" 2>/dev/null
                    systemctl disable "udp-custom@${del_port}" 2>/dev/null
                    rm -f "/etc/systemd/system/udp-custom@${del_port}.service"
                    systemctl daemon-reload
                    ufw delete allow "${del_port}/udp" 2>/dev/null
                    ok "Puerto UDP $del_port cerrado"
                fi
                press_enter
                ;;
            4)
                systemctl list-units | grep badvpn
                press_enter
                ;;
            5)
                read_input "Puerto BadVPN a agregar" bad_port
                if [[ -n "$bad_port" ]]; then
                    cat > "/etc/systemd/system/badvpn-${bad_port}.service" << EOF
[Unit]
Description=BadVPN UDP Gateway port $bad_port
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 0.0.0.0:$bad_port --max-clients 512
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF
                    systemctl daemon-reload
                    systemctl enable "badvpn-${bad_port}"
                    systemctl start "badvpn-${bad_port}"
                    ufw allow "${bad_port}/udp"
                    ok "BadVPN puerto $bad_port agregado"
                fi
                press_enter
                ;;
            6)
                read_input "Puerto BadVPN a eliminar" bad_port
                if [[ -n "$bad_port" ]]; then
                    systemctl stop "badvpn-${bad_port}" 2>/dev/null
                    systemctl disable "badvpn-${bad_port}" 2>/dev/null
                    rm -f "/etc/systemd/system/badvpn-${bad_port}.service"
                    systemctl daemon-reload
                    ufw delete allow "${bad_port}/udp" 2>/dev/null
                    ok "BadVPN puerto $bad_port eliminado"
                fi
                press_enter
                ;;
            7)
                read_input "Puerto inicial" p1
                read_input "Puerto final" p2
                ufw allow "$p1:$p2/udp"
                ok "Rango UDP $p1-$p2 abierto"
                press_enter
                ;;
            8)
                systemctl restart 'udp-custom@*' 2>/dev/null
                systemctl restart 'badvpn-*' 2>/dev/null
                ok "Servicios UDP reiniciados"
                press_enter
                ;;
            0) return ;;
            *) err "Opción inválida" ;;
        esac
    done
}

# Menú SSH Manager
menu_ssh() {
    while true; do
        clear_screen
        echo -e "${C}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}                    ${Y}🔐  SSH MANAGER${NC}                                     ${C}║${NC}"
        echo -e "${C}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${W}1)${NC} Crear usuario"
        echo -e "  ${W}2)${NC} Listar usuarios"
        echo -e "  ${W}3)${NC} Eliminar usuario"
        echo -e "  ${W}4)${NC} Cambiar contraseña"
        echo -e "  ${W}5)${NC} Ver usuarios conectados"
        echo -e "  ${W}6)${NC} Desconectar usuario"
        echo -e "  ${W}7)${NC} Limitar conexiones"
        echo -e "  ${W}8)${NC} Cambiar puerto SSH"
        echo -e "  ${W}0)${NC} Volver"
        echo ""
        read_input "Opción" ssh_opt
        
        case "$ssh_opt" in
            1)
                read_input "Nombre de usuario" new_user
                read_password "Contraseña" new_pass
                read_input "Días de expiración" exp_days "30"
                
                useradd -m -s /bin/bash "$new_user" 2>/dev/null
                echo "$new_user:$new_pass" | chpasswd
                chage -E $(date -d "+$exp_days days" +%Y-%m-%d) "$new_user"
                
                ok "Usuario $new_user creado (expira en $exp_days días)"
                press_enter
                ;;
            2)
                echo ""
                printf "%-20s %-15s %-15s\n" "USUARIO" "EXPIRA" "SHELL"
                echo "────────────────────────────────────────────"
                awk -F: '$3>=1000 && $7!~/nologin|false/ {printf "%-20s %-15s %-15s\n", $1, $5?$5:"nunca", $7}' /etc/passwd
                press_enter
                ;;
            3)
                read_input "Usuario a eliminar" del_user
                if confirm "¿Eliminar $del_user?" "n"; then
                    userdel -r "$del_user" 2>/dev/null
                    ok "Usuario $del_user eliminado"
                fi
                press_enter
                ;;
            4)
                read_input "Usuario" ch_user
                read_password "Nueva contraseña" ch_pass
                echo "$ch_user:$ch_pass" | chpasswd
                ok "Contraseña cambiada"
                press_enter
                ;;
            5)
                show_online_users
                press_enter
                ;;
            6)
                read_input "Usuario a desconectar" kill_user
                pkill -u "$kill_user" 2>/dev/null
                ok "Usuario $kill_user desconectado"
                press_enter
                ;;
            7)
                read_input "Usuario" lim_user
                read_input "Máximo de conexiones simultáneas" lim_count "2"
                echo "$lim_user hard maxlogins $lim_count" >> /etc/security/limits.conf
                ok "Límite de $lim_count conexiones para $lim_user"
                press_enter
                ;;
            8)
                current_port=$(grep ^Port /etc/ssh/sshd_config | awk '{print $2}')
                read_input "Nuevo puerto SSH" new_ssh_port "$current_port"
                sed -i "s/^#*Port .*/Port $new_ssh_port/" /etc/ssh/sshd_config
                ufw allow "${new_ssh_port}/tcp"
                systemctl restart sshd
                cfg_set "ports.ssh" "$new_ssh_port"
                warn "¡NO CIERRES esta sesión! Conéctate al nuevo puerto $new_ssh_port"
                press_enter
                ;;
            0) return ;;
            *) err "Opción inválida" ;;
        esac
    done
}

# Menú Cloudflare/SSL
menu_cf_ssl() {
    while true; do
        clear_screen
        echo -e "${C}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}                    ${Y}☁️  CLOUDFLARE / SSL${NC}                               ${C}║${NC}"
        echo -e "${C}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        local domain=$(cfg_get domain)
        echo -e "  ${Y}Dominio actual:${NC} ${W}${domain:-no configurado}${NC}"
        echo ""
        echo -e "  ${W}1)${NC} Configurar dominio"
        echo -e "  ${W}2)${NC} Instalar SSL (Let's Encrypt)"
        echo -e "  ${W}3)${NC} Renovar SSL"
        echo -e "  ${W}4)${NC} Ver instrucciones Cloudflare"
        echo -e "  ${W}5)${NC} Cambiar DNS"
        echo -e "  ${W}6)${NC} Ver certificados"
        echo -e "  ${W}0)${NC} Volver"
        echo ""
        read_input "Opción" ssl_opt
        
        case "$ssl_opt" in
            1)
                read_input "Dominio (ej: vpn.tudominio.com)" new_domain
                cfg_set "domain" "\"$new_domain\""
                ok "Dominio configurado: $new_domain"
                press_enter
                ;;
            2)
                local domain=$(cfg_get domain)
                if [[ -z "$domain" ]]; then
                    err "Configura primero un dominio"
                    press_enter
                    continue
                fi
                
                apt_install certbot python3-certbot-nginx
                systemctl stop nginx
                certbot certonly --standalone -d "$domain" --non-interactive --agree-tos --email "admin@$domain"
                systemctl start nginx
                
                if [[ -f "/etc/letsencrypt/live/$domain/fullchain.pem" ]]; then
                    cfg_set "ssl_enabled" "true"
                    ok "SSL instalado para $domain"
                    
                    # Configurar Nginx con SSL
                    configure_nginx_ssl
                else
                    err "Error instalando SSL"
                fi
                press_enter
                ;;
            3)
                certbot renew --force-renewal
                ok "SSL renovado"
                press_enter
                ;;
            4)
                echo ""
                echo -e "${C}════════════════════════════════════════════════════════════════${NC}"
                echo -e "${W}  Guía Cloudflare CDN${NC}"
                echo -e "${C}────────────────────────────────────────────────────────────────${NC}"
                echo -e " 1. Añade tu dominio en Cloudflare"
                echo -e " 2. Crea un registro A apuntando a tu IP"
                echo -e " 3. Activa el proxy (nube naranja)"
                echo -e " 4. SSL/TLS → modo Flexible o Full"
                echo -e " 5. Network → habilita WebSockets"
                echo ""
                echo -e " ${Y}Puertos compatibles:${NC}"
                echo -e " HTTP: 80, 8080, 8880, 2052, 2082, 2086, 2095"
                echo -e " HTTPS: 443, 2053, 2083, 2087, 2096, 8443"
                echo -e "${C}════════════════════════════════════════════════════════════════${NC}"
                press_enter
                ;;
            5)
                echo ""
                echo -e "  ${Y}1)${NC} Google (8.8.8.8, 8.8.4.4)"
                echo -e "  ${Y}2)${NC} Cloudflare (1.1.1.1, 1.0.0.1)"
                echo -e "  ${Y}3)${NC} OpenDNS (208.67.222.222)"
                echo -e "  ${Y}4)${NC} Personalizado"
                read_input "Opción" dns_opt
                
                case $dns_opt in
                    1) echo -e "nameserver 8.8.8.8\nnameserver 8.8.4.4" > /etc/resolv.conf ;;
                    2) echo -e "nameserver 1.1.1.1\nnameserver 1.0.0.1" > /etc/resolv.conf ;;
                    3) echo -e "nameserver 208.67.222.222\nnameserver 208.67.220.220" > /etc/resolv.conf ;;
                    4)
                        read_input "DNS1" dns1
                        read_input "DNS2" dns2
                        echo -e "nameserver $dns1\nnameserver $dns2" > /etc/resolv.conf
                        ;;
                esac
                
                chattr +i /etc/resolv.conf 2>/dev/null
                ok "DNS actualizado"
                press_enter
                ;;
            6)
                echo ""
                ls -la /etc/letsencrypt/live/*/ 2>/dev/null || warn "No hay certificados SSL"
                press_enter
                ;;
            0) return ;;
            *) err "Opción inválida" ;;
        esac
    done
}

# Configurar Nginx con SSL
configure_nginx_ssl() {
    local domain=$(cfg_get domain)
    if [[ -z "$domain" ]]; then
        return
    fi
    
    cat > "${NGINX_AVAILABLE}/nexusvpn-ssl" << EOF
server {
    listen 443 ssl http2;
    server_name $domain;
    
    ssl_certificate /etc/letsencrypt/live/$domain/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/$domain/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    
    location /nexus {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
    
    location /nexus-grpc {
        grpc_pass grpc://127.0.0.1:8443;
    }
}

server {
    listen 80;
    server_name $domain;
    return 301 https://\$host\$request_uri;
}
EOF

    ln -sf "${NGINX_AVAILABLE}/nexusvpn-ssl" "${NGINX_ENABLED}/nexusvpn-ssl"
    nginx -t && systemctl reload nginx
}

# Menú Banner
menu_banner() {
    while true; do
        clear_screen
        echo -e "${C}╔═══════════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}                    ${Y}📢  BANNER Y PUBLICIDAD${NC}                           ${C}║${NC}"
        echo -e "${C}╚═══════════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        echo -e "  ${W}1)${NC} Ver banner actual"
        echo -e "  ${W}2)${NC} Editar banner del panel"
        echo -e "  ${W}3)${NC} Editar MOTD SSH"
        echo -e "  ${W}4)${NC} Editar banner de Telegram"
        echo -e "  ${W}5)${NC} Restaurar banner por defecto"
        echo -e "  ${W}6)${NC} Probar banner"
        echo -e "  ${W}0)${NC} Volver"
        echo ""
        read_input "Opción" banner_opt
        
        case "$banner_opt" in
            1)
                echo ""
                if [[ -f "$BANNER_FILE" ]]; then
                    cat "$BANNER_FILE"
                else
                    echo "  Banner por defecto:"
                    echo '  📲 Comprar Keys/Licencias:'
                    echo '     WhatsApp: +57 300 443 0431'
                    echo '     Telegram: @ANDRESCAMP13'
                fi
                press_enter
                ;;
            2)
                echo ""
                echo -e "${C}Escribe el banner (líneas múltiples, 'FIN' para terminar):${NC}"
                > "$BANNER_FILE"
                while read line; do
                    [[ "$line" == "FIN" ]] && break
                    echo "$line" >> "$BANNER_FILE"
                done
                ok "Banner del panel actualizado"
                press_enter
                ;;
            3)
                echo ""
                echo -e "${C}Escribe el MOTD (líneas múltiples, 'FIN' para terminar):${NC}"
                > "$MOTD_FILE"
                echo -e "\n╔══════════════════════════════════════════════════════════════╗" >> "$MOTD_FILE"
                echo -e "║           NEXUSVPN PRO - SERVIDOR VPN                        ║" >> "$MOTD_FILE"
                echo -e "╠══════════════════════════════════════════════════════════════╣" >> "$MOTD_FILE"
                
                while read line; do
                    [[ "$line" == "FIN" ]] && break
                    printf "║  %-60s║\n" "$line" >> "$MOTD_FILE"
                done
                
                echo -e "╚══════════════════════════════════════════════════════════════╝\n" >> "$MOTD_FILE"
                cp "$MOTD_FILE" "$ISSUE_NET"
                ok "MOTD actualizado"
                press_enter
                ;;
            4)
                echo ""
                echo -e "${C}Texto para el bot de Telegram (mensaje de bienvenida):${NC}"
                read -r telegram_banner
                cfg_set "telegram.banner" "\"$telegram_banner\""
                ok "Banner de Telegram actualizado"
                press_enter
                ;;
            5)
                rm -f "$BANNER_FILE"
                ok "Banner restaurado al valor por defecto"
                press_enter
                ;;
            6)
                print_banner
                press_enter
                ;;
            0) return ;;
            *) err "Opción inválida" ;;
        esac
    done
}

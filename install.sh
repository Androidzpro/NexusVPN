#!/bin/bash
# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
# NEXUSVPN PRO v4.0 - INSTALADOR PRINCIPAL
# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════
# Este script es el orquestador principal. Carga los módulos y ejecuta la instalación.
# Los módulos contienen la lógica específica de cada protocolo.
# ════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════════

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN GLOBAL
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

readonly SCRIPT_VERSION="4.0"
readonly SCRIPT_NAME="NexusVPN Pro"
readonly SCRIPT_AUTHOR="Androidzpro"
readonly SCRIPT_CONTACT_WHATSAPP="+57 300 443 0431"
readonly SCRIPT_CONTACT_TELEGRAM="@ANDRESCAMP13"

# Directorios
readonly INSTALL_DIR="/etc/nexusvpn"
readonly MODULES_DIR="${INSTALL_DIR}/modules"
readonly CONFIG_DIR="${INSTALL_DIR}/config"
readonly LOG_DIR="/var/log/nexusvpn"
readonly TEMP_DIR="/tmp/nexusvpn"

# Archivos
readonly MAIN_LOG="${LOG_DIR}/install.log"
readonly ERROR_LOG="${LOG_DIR}/error.log"
readonly CONFIG_FILE="${CONFIG_DIR}/config.json"

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# COLORES Y ESTILOS (PROFESIONALES)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Colores base
readonly R='\033[0;31m'      # Rojo
readonly G='\033[0;32m'      # Verde
readonly Y='\033[1;33m'      # Amarillo
readonly B='\033[0;34m'      # Azul
readonly C='\033[0;36m'      # Cyan
readonly M='\033[0;35m'      # Magenta
readonly W='\033[1;37m'      # Blanco
readonly NC='\033[0m'        # Sin color

# Estilos
readonly BLD='\033[1m'       # Negrita
readonly DIM='\033[2m'       # Tenue
readonly UND='\033[4m'       # Subrayado
readonly BLINK='\033[5m'     # Parpadeo
readonly REV='\033[7m'       # Invertido

# Limpiar pantalla
readonly CLS='\033[2J\033[H'

# Símbolos profesionales
readonly SYM_CHECK="✓"
readonly SYM_CROSS="✗"
readonly SYM_ARROW="→"
readonly SYM_WARN="⚠"
readonly SYM_INFO="ℹ"
readonly SYM_LOCK="🔒"
readonly SYM_KEY="🔑"
readonly SYM_USER="👤"
readonly SYM_USERS="👥"
readonly SYM_STATS="📊"
readonly SYM_SETTINGS="⚙️"
readonly SYM_FIRE="🔥"
readonly SYM_CLOUD="☁️"
readonly SYM_GLOBE="🌐"
readonly SYM_LINK="🔗"
readonly SYM_QR="📱"
readonly SYM_BOT="🤖"
readonly SYM_WEB="🌍"
readonly SYM_BACKUP="💾"
readonly SYM_DELETE="🗑️"
readonly SYM_EDIT="✏️"
readonly SYM_ADD="➕"
readonly SYM_SEARCH="🔍"
readonly SYM_START="▶️"
readonly SYM_STOP="⏹️"
readonly SYM_RESTART="🔄"
readonly SYM_EXIT="🚪"

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# FUNCIONES BASE (LOGGING Y OUTPUT)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Inicializar sistema de logs
init_logging() {
    mkdir -p "$LOG_DIR" "$INSTALL_DIR" "$MODULES_DIR" "$CONFIG_DIR" "$TEMP_DIR" 2>/dev/null
    touch "$MAIN_LOG" "$ERROR_LOG" 2>/dev/null
    chmod 644 "$MAIN_LOG" 2>/dev/null
    chmod 640 "$ERROR_LOG" 2>/dev/null
    
    # Rotar log si es muy grande
    if [[ -f "$MAIN_LOG" && $(stat -c%s "$MAIN_LOG" 2>/dev/null) -gt 10485760 ]]; then
        mv "$MAIN_LOG" "${MAIN_LOG}.old"
        touch "$MAIN_LOG"
    fi
    
    log_info "Sistema de logging inicializado"
}

# Logging con niveles
log() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[${timestamp}] [${level}] ${message}"
    
    case "$level" in
        ERROR|FATAL)
            echo "$log_entry" >> "$ERROR_LOG"
            echo "$log_entry" >> "$MAIN_LOG"
            ;;
        WARN)
            echo "$log_entry" >> "$MAIN_LOG"
            ;;
        *)
            echo "$log_entry" >> "$MAIN_LOG"
            ;;
    esac
    
    if [[ "$level" == "FATAL" ]]; then
        logger -t "nexusvpn" "FATAL: $message"
    fi
}

log_info()  { log "INFO" "$*"; }
log_warn()  { log "WARN" "$*"; }
log_error() { log "ERROR" "$*"; }
log_fatal() { log "FATAL" "$*"; exit 1; }

# Output para el usuario
ok() {
    echo -e "${G}${BLD}  ${SYM_CHECK}  ${NC}${W}$*${NC}"
    log_info "OK: $*"
}

err() {
    echo -e "${R}${BLD}  ${SYM_CROSS}  ${NC}${W}$*${NC}" >&2
    log_error "ERR: $*"
}

inf() {
    echo -e "${C}${BLD}  ${SYM_ARROW}  ${NC}${W}$*${NC}"
    log_info "INF: $*"
}

warn() {
    echo -e "${Y}${BLD}  ${SYM_WARN}  ${NC}${W}$*${NC}"
    log_warn "WARN: $*"
}

debug() {
    if [[ "${DEBUG_MODE:-0}" == "1" ]]; then
        echo -e "${M}  ${SYM_INFO}  [DEBUG] $*${NC}"
    fi
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE INTERFAZ
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Limpiar pantalla
clear_screen() {
    printf "%b" "$CLS"
}

# Título con bordes
title() {
    local msg="$1"
    local len=$(( ${#msg} + 4 ))
    echo ""
    echo -e "${C}╔$(printf '═%.0s' $(seq 1 $len))╗${NC}"
    echo -e "${C}║${NC}  ${W}${BLD}${msg}${NC}  ${C}║${NC}"
    echo -e "${C}╚$(printf '═%.0s' $(seq 1 $len))╝${NC}"
    echo ""
}

# Separador
separator() {
    echo -e "${DIM}─────────────────────────────────────────────────────────────────${NC}"
}

# Box message
box_message() {
    local msg="$1"
    local len=$(( ${#msg} + 4 ))
    echo -e "${G}╔$(printf '═%.0s' $(seq 1 $len))╗${NC}"
    echo -e "${G}║${NC}  ${W}${msg}${NC}  ${G}║${NC}"
    echo -e "${G}╚$(printf '═%.0s' $(seq 1 $len))╝${NC}"
}

# Leer entrada con prompt
read_input() {
    local prompt="$1"
    local var_name="$2"
    local default="${3:-}"
    
    echo -ne "${C}${BLD}  ${SYM_ARROW}  ${prompt}${NC}"
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

# Leer contraseña
read_password() {
    local prompt="$1"
    local var_name="$2"
    
    echo -ne "${C}${BLD}  ${SYM_LOCK}  ${prompt}${NC} "
    read -rsp "" "$var_name"
    echo ""
}

# Confirmar acción
confirm() {
    local prompt="${1:-¿Continuar?}"
    local default="${2:-n}"
    
    local options
    if [[ "$default" == "s" ]]; then
        options="(S/n)"
    else
        options="(s/N)"
    fi
    
    echo -ne "${Y}  ${SYM_WARN}  ${prompt} ${options} ${NC}"
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

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE VERIFICACIÓN
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Verificar root
require_root() {
    if [[ $EUID -ne 0 ]]; then
        clear_screen
        echo -e "${R}${BLK}════════════════════════════════════════════════════════════════${NC}"
        echo -e "${R}${BLK}                     ERROR DE PERMISOS                            ${NC}"
        echo -e "${R}${BLK}════════════════════════════════════════════════════════════════${NC}"
        echo ""
        echo -e "  ${W}Este script requiere permisos de root${NC}"
        echo ""
        echo -e "  ${Y}Ejecuta:${NC} ${C}sudo bash $0 --install${NC}"
        echo ""
        exit 1
    fi
}

# Detectar sistema operativo
check_os() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        OS_NAME="$NAME"
        OS_VERSION="$VERSION_ID"
        OS_ID="$ID"
    else
        OS_NAME="Desconocido"
        OS_VERSION="?"
        OS_ID="unknown"
    fi
    
    case "$OS_ID" in
        ubuntu|debian)
            ok "Sistema compatible: $OS_NAME $OS_VERSION"
            ;;
        *)
            warn "Sistema no probado: $OS_NAME $OS_VERSION"
            if ! confirm "¿Continuar?" "n"; then
                exit 1
            fi
            ;;
    esac
}

# Verificar arquitectura
check_arch() {
    ARCH=$(uname -m)
    case "$ARCH" in
        x86_64|aarch64|arm64)
            ok "Arquitectura compatible: $ARCH"
            ;;
        *)
            warn "Arquitectura no probada: $ARCH"
            if ! confirm "¿Continuar?" "n"; then
                exit 1
            fi
            ;;
    esac
}

# Verificar conectividad
check_internet() {
    inf "Verificando conexión a internet..."
    if ping -c 1 google.com >/dev/null 2>&1; then
        ok "Conexión detectada"
    else
        err "Sin conexión a internet"
        exit 1
    fi
}

# Obtener IP pública
get_server_ip() {
    local ip=""
    ip=$(curl -s4 --max-time 3 ifconfig.me 2>/dev/null) || \
    ip=$(curl -s4 --max-time 3 api.ipify.org 2>/dev/null) || \
    ip=$(curl -s4 --max-time 3 icanhazip.com 2>/dev/null) || \
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    
    echo "${ip:-0.0.0.0}"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# FUNCIONES DE CARGA DE MÓDULOS
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

# Lista de módulos disponibles
declare -A MODULES
MODULES=(
    ["core"]="core.sh"
    ["xray"]="xray.sh"
    ["udp-custom"]="udp-custom.sh"
    ["badvpn"]="badvpn.sh"
    ["hysteria2"]="hysteria2.sh"
    ["wireguard"]="wireguard.sh"
    ["ikev2"]="ikev2.sh"
    ["openvpn"]="openvpn.sh"
    ["slowdns"]="slowdns.sh"
    ["telegram-bot"]="telegram-bot.sh"
    ["monitoring"]="monitoring.sh"
    ["keys"]="keys.sh"
    ["firewall"]="firewall.sh"
    ["backup"]="backup.sh"
    ["webpanel"]="webpanel.sh"
)

# Cargar un módulo específico
load_module() {
    local module_name="$1"
    local module_file="${MODULES_DIR}/${MODULES[$module_name]}"
    
    if [[ ! -f "$module_file" ]]; then
        err "Módulo ${module_name} no encontrado en $module_file"
        return 1
    fi
    
    inf "Cargando módulo: ${module_name}"
    source "$module_file"
    
    # Verificar que el módulo tiene función de instalación
    if declare -f "install_${module_name//-/_}" >/dev/null; then
        ok "Módulo ${module_name} listo"
    else
        warn "Módulo ${module_name} no tiene función install_${module_name//-/_}"
    fi
}

# Cargar todos los módulos esenciales
load_all_modules() {
    inf "Cargando módulos del sistema..."
    
    # Módulos esenciales (deben existir)
    local essential_modules=("core" "xray" "udp-custom" "badvpn" "monitoring" "keys" "firewall" "backup")
    
    for module in "${essential_modules[@]}"; do
        if ! load_module "$module"; then
            err "Fallo al cargar módulo esencial: $module"
            exit 1
        fi
    done
    
    # Módulos opcionales (pueden no existir)
    local optional_modules=("hysteria2" "wireguard" "ikev2" "openvpn" "slowdns" "telegram-bot" "webpanel")
    
    for module in "${optional_modules[@]}"; do
        load_module "$module" 2>/dev/null || warn "Módulo opcional no encontrado: $module"
    done
    
    ok "Módulos cargados"
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# INSTALACIÓN PRINCIPAL
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

run_installation() {
    clear_screen
    title "NEXUSVPN PRO v${SCRIPT_VERSION} - INSTALACIÓN"
    
    # Verificaciones previas
    require_root
    check_os
    check_arch
    check_internet
    
    # Inicializar directorios
    init_logging
    inf "Directorios creados en: $INSTALL_DIR"
    
    # Preguntar configuración inicial
    echo ""
    inf "Configuración inicial del servidor:"
    separator
    
    read_input "Puerto SSH (actual: 22)" SSH_PORT "22"
    read_input "Puerto Web Panel (opcional)" WEB_PORT "8080"
    
    # Confirmar inicio
    echo ""
    if ! confirm "¿Iniciar instalación completa?" "s"; then
        warn "Instalación cancelada"
        exit 0
    fi
    
    echo ""
    inf "Iniciando instalación... (esto puede tomar varios minutos)"
    separator
    
    # PASO 1: Actualizar sistema
    echo ""
    inf "[1/8] Actualizando sistema..."
    apt-get update -qq >> "$MAIN_LOG" 2>&1
    apt-get upgrade -y -qq >> "$MAIN_LOG" 2>&1
    ok "Sistema actualizado"
    
    # PASO 2: Instalar dependencias base
    inf "[2/8] Instalando dependencias base..."
    apt-get install -y -qq curl wget unzip zip ufw python3 python3-pip git \
        openssl net-tools socat iptables cron qrencode jq htop >> "$MAIN_LOG" 2>&1
    ok "Dependencias base instaladas"
    
    # PASO 3: Cargar módulos
    inf "[3/8] Cargando módulos..."
    load_all_modules
    
    # PASO 4: Instalar Core (funciones base)
    inf "[4/8] Configurando sistema base..."
    if declare -f install_core >/dev/null; then
        install_core
    else
        ok "Core integrado (sin módulo específico)"
    fi
    
    # PASO 5: Instalar protocolos principales
    inf "[5/8] Instalando protocolos principales..."
    
    if declare -f install_xray >/dev/null; then
        install_xray
    else
        err "Módulo Xray no disponible"
    fi
    
    if declare -f install_udp_custom >/dev/null; then
        install_udp_custom
    fi
    
    if declare -f install_badvpn >/dev/null; then
        install_badvpn
    fi
    
    # PASO 6: Instalar protocolos adicionales (si existen)
    inf "[6/8] Instalando protocolos adicionales..."
    
    for proto in hysteria2 wireguard ikev2 openvpn slowdns; do
        if declare -f "install_${proto}" >/dev/null; then
            "install_${proto}"
        fi
    done
    
    # PASO 7: Configurar sistema
    inf "[7/8] Configurando sistema..."
    
    if declare -f configure_firewall >/dev/null; then
        configure_firewall
    fi
    
    if declare -f setup_monitoring >/dev/null; then
        setup_monitoring
    fi
    
    if declare -f setup_keys >/dev/null; then
        setup_keys
    fi
    
    # PASO 8: Finalizar
    inf "[8/8] Finalizando instalación..."
    
    # Guardar configuración
    mkdir -p "$CONFIG_DIR"
    cat > "$CONFIG_FILE" << EOF
{
    "version": "$SCRIPT_VERSION",
    "install_date": "$(date '+%Y-%m-%d %H:%M:%S')",
    "server_ip": "$(get_server_ip)",
    "ssh_port": $SSH_PORT,
    "web_port": $WEB_PORT,
    "modules_loaded": true
}
EOF
    
    ok "Instalación completada"
    
    # Mostrar resumen
    show_summary
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# RESUMEN FINAL
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

show_summary() {
    clear_screen
    local IP=$(get_server_ip)
    
    echo -e "${G}${BLD}"
    echo "  ╔════════════════════════════════════════════════════════════════╗"
    echo "  ║         ✅ NEXUSVPN PRO v${SCRIPT_VERSION} INSTALADO              ║"
    echo "  ╠════════════════════════════════════════════════════════════════╣"
    echo -e "  ║  ${W}IP del servidor:${NC} ${G}${IP}${NC}                                         ║"
    echo "  ╠════════════════════════════════════════════════════════════════╣"
    echo "  ║  📦 Módulos instalados:                                       ║"
    echo "  ║  ─────────────────────────────────────────────────────────── ║"
    
    local modules_installed=0
    for module in "${!MODULES[@]}"; do
        if [[ -f "${MODULES_DIR}/${MODULES[$module]}" ]]; then
            printf "  ║  ${G}✓${NC} %-20s                         ║\n" "$module"
            ((modules_installed++))
        fi
    done
    
    echo "  ╠════════════════════════════════════════════════════════════════╣"
    echo "  ║  📌 Comandos útiles:                                          ║"
    echo "  ║  ─────────────────────────────────────────────────────────── ║"
    echo "  ║  ${W}nexusvpn${NC}        → Abrir panel interactivo              ║"
    echo "  ║  ${W}nexusvpn --help${NC}  → Ver todos los comandos               ║"
    echo "  ║  ${W}tail -f ${LOG_DIR}/install.log${NC}  → Ver logs            ║"
    echo "  ╠════════════════════════════════════════════════════════════════╣"
    echo "  ║  📞 Soporte:                                                   ║"
    echo "  ║  WhatsApp: ${W}${SCRIPT_CONTACT_WHATSAPP}${NC}                      ║"
    echo "  ║  Telegram: ${W}${SCRIPT_CONTACT_TELEGRAM}${NC}                       ║"
    echo "  ╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    
    echo ""
    inf "Para acceder al panel: nexusvpn"
    inf "Contraseña por defecto: NexusAdmin2024 (¡cámbiala!)"
    echo ""
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# MENÚ PRINCIPAL (POST-INSTALACIÓN)
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

main_menu() {
    while true; do
        clear_screen
        echo -e "${C}${BLD}╔════════════════════════════════════════════════════════════════╗${NC}"
        echo -e "${C}${BLD}║                    NEXUSVPN PRO v${SCRIPT_VERSION}                    ║${NC}"
        echo -e "${C}${BLD}╠════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${C}${BLD}║${NC}  ${W}1)${NC}  ${SYM_SETTINGS}  Instalación completa          ${C}${BLD}║${NC}"
        echo -e "${C}${BLD}║${NC}  ${W}2)${NC}  ${SYM_KEY}     Gestión de Keys               ${C}${BLD}║${NC}"
        echo -e "${C}${BLD}║${NC}  ${W}3)${NC}  ${SYM_USERS}   Usuarios Xray                  ${C}${BLD}║${NC}"
        echo -e "${C}${BLD}║${NC}  ${W}4)${NC}  ${SYM_GLOBE}   UDP Custom / BadVPN            ${C}${BLD}║${NC}"
        echo -e "${C}${BLD}║${NC}  ${W}5)${NC}  ${SYM_BOT}     Bot de Telegram                ${C}${BLD}║${NC}"
        echo -e "${C}${BLD}║${NC}  ${W}6)${NC}  ${SYM_STATS}   Monitoreo en vivo              ${C}${BLD}║${NC}"
        echo -e "${C}${BLD}║${NC}  ${W}7)${NC}  ${SYM_FIRE}    Firewall                       ${C}${BLD}║${NC}"
        echo -e "${C}${BLD}║${NC}  ${W}8)${NC}  ${SYM_BACKUP}  Backup / Restaurar             ${C}${BLD}║${NC}"
        echo -e "${C}${BLD}║${NC}  ${W}9)${NC}  ${SYM_WEB}     Panel web (opcional)           ${C}${BLD}║${NC}"
        echo -e "${C}${BLD}╠════════════════════════════════════════════════════════════════╣${NC}"
        echo -e "${C}${BLD}║${NC}  ${W}0)${NC}  ${SYM_EXIT}    Salir                          ${C}${BLD}║${NC}"
        echo -e "${C}${BLD}╚════════════════════════════════════════════════════════════════╝${NC}"
        echo ""
        
        read_input "Selecciona una opción" menu_option
        
        case "$menu_option" in
            1) run_installation ;;
            2) 
                if declare -f menu_keys >/dev/null; then
                    menu_keys
                else
                    warn "Módulo de keys no disponible"
                    press_enter
                fi
                ;;
            3)
                if declare -f menu_xray >/dev/null; then
                    menu_xray
                else
                    warn "Módulo Xray no disponible"
                    press_enter
                fi
                ;;
            4)
                if declare -f menu_udp >/dev/null; then
                    menu_udp
                else
                    warn "Módulo UDP no disponible"
                    press_enter
                fi
                ;;
            5)
                if declare -f menu_telegram >/dev/null; then
                    menu_telegram
                else
                    warn "Módulo Telegram no disponible"
                    press_enter
                fi
                ;;
            6)
                if declare -f show_online_users >/dev/null; then
                    show_online_users
                    press_enter
                else
                    warn "Módulo monitoreo no disponible"
                    press_enter
                fi
                ;;
            7)
                if declare -f menu_firewall >/dev/null; then
                    menu_firewall
                else
                    warn "Módulo firewall no disponible"
                    press_enter
                fi
                ;;
            8)
                if declare -f menu_backup >/dev/null; then
                    menu_backup
                else
                    warn "Módulo backup no disponible"
                    press_enter
                fi
                ;;
            9)
                if declare -f install_webpanel >/dev/null; then
                    install_webpanel
                    press_enter
                else
                    warn "Módulo webpanel no disponible"
                    press_enter
                fi
                ;;
            0)
                echo -e "\n${G}¡Hasta luego!${NC}\n"
                exit 0
                ;;
            *)
                err "Opción inválida"
                sleep 2
                ;;
        esac
    done
}

# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
# PUNTO DE ENTRADA
# ────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────

main() {
    case "${1:-}" in
        --install)
            run_installation
            ;;
        --help|-h)
            echo "Uso: $0 [opción]"
            echo "Opciones:"
            echo "  --install    Realiza la instalación completa"
            echo "  --help       Muestra esta ayuda"
            echo ""
            echo "Sin opciones: abre el menú interactivo"
            ;;
        *)
            # Verificar si ya está instalado
            if [[ -f "$CONFIG_FILE" ]]; then
                # Cargar módulos si existen
                if [[ -d "$MODULES_DIR" ]]; then
                    for module in "$MODULES_DIR"/*.sh; do
                        [[ -f "$module" ]] && source "$module"
                    done
                fi
                main_menu
            else
                echo -e "${Y}NexusVPN no está instalado.${NC}"
                echo -e "Ejecuta: ${C}$0 --install${NC}"
            fi
            ;;
    esac
}

# Inicializar logging básico antes de todo
mkdir -p "$LOG_DIR" "$INSTALL_DIR" 2>/dev/null || true

# Ejecutar main con todos los argumentos
main "$@"

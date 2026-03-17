#!/bin/bash
# NEXUSVPN PRO v4.0 - INSTALADOR INTELIGENTE
# Un solo comando: bash <(curl -s https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh) --install

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# ─────────────────────────────────────────────────────────────────────────────
# CONFIGURACIÓN
# ─────────────────────────────────────────────────────────────────────────────
readonly VERSION="4.0"
readonly REPO="https://raw.githubusercontent.com/Androidzpro/NexusVPN/main"
readonly INSTALL_DIR="/etc/nexusvpn"
readonly MODULES_DIR="${INSTALL_DIR}/modules"
readonly LOG_FILE="/tmp/nexusvpn-install.log"

# Colores
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'; NC='\033[0m'
BLD='\033[1m'; DIM='\033[2m'

# Símbolos
CHECK="✓"; CROSS="✗"; ARROW="→"; WARN="⚠"

# ─────────────────────────────────────────────────────────────────────────────
# FUNCIONES BASE
# ─────────────────────────────────────────────────────────────────────────────
log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"; }
ok() { echo -e "${G}${CHECK}${NC} $1"; log "OK: $1"; }
err() { echo -e "${R}${CROSS}${NC} $1" >&2; log "ERROR: $1"; }
inf() { echo -e "${C}${ARROW}${NC} $1"; log "INFO: $1"; }
warn() { echo -e "${Y}${WARN}${NC} $1"; log "WARN: $1"; }

# ─────────────────────────────────────────────────────────────────────────────
# VERIFICACIÓN DE ROOT
# ─────────────────────────────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo -e "${R}${CROSS} Ejecuta como root: sudo bash $0 --install${NC}"
    exit 1
fi

# ─────────────────────────────────────────────────────────────────────────────
# FUNCIÓN PARA DESCARGAR MÓDULOS
# ─────────────────────────────────────────────────────────────────────────────
download_modules() {
    inf "Creando estructura de directorios..."
    mkdir -p "$MODULES_DIR"
    
    inf "Descargando módulos desde GitHub..."
    
    # Lista de todos los módulos necesarios
    local modules=(
        "core.sh"
        "xray.sh"
        "udp-custom.sh"
        "badvpn.sh"
        "hysteria2.sh"
        "wireguard.sh"
        "ikev2.sh"
        "openvpn.sh"
        "slowdns.sh"
        "telegram-bot.sh"
        "monitoring.sh"
        "keys.sh"
        "firewall.sh"
        "backup.sh"
        "webpanel.sh"
    )
    
    local success=0
    local failed=0
    
    for module in "${modules[@]}"; do
        echo -ne "  ${DIM}Descargando ${module}...${NC}"
        
        if wget -q -O "${MODULES_DIR}/${module}" "${REPO}/modules/${module}" 2>>"$LOG_FILE"; then
            echo -e "\r  ${G}${CHECK}${NC} ${module}"
            chmod +x "${MODULES_DIR}/${module}"
            ((success++))
        else
            echo -e "\r  ${R}${CROSS}${NC} ${module} ${DIM}(opcional)${NC}"
            ((failed++))
        fi
    done
    
    echo ""
    ok "Módulos descargados: ${G}${success} correctos${NC}, ${Y}${failed} opcionales${NC}"
}

# ─────────────────────────────────────────────────────────────────────────────
# FUNCIÓN PARA CARGAR MÓDULOS
# ─────────────────────────────────────────────────────────────────────────────
load_modules() {
    inf "Cargando módulos del sistema..."
    
    local loaded=0
    for module in "$MODULES_DIR"/*.sh; do
        if [[ -f "$module" ]]; then
            source "$module"
            ((loaded++))
        fi
    done
    
    ok "Módulos cargados: ${loaded}"
}

# ─────────────────────────────────────────────────────────────────────────────
# INSTALACIÓN PRINCIPAL
# ─────────────────────────────────────────────────────────────────────────────
run_install() {
    clear
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  ${BLD}NEXUSVPN PRO v${VERSION} - INSTALADOR AUTOMÁTICO${NC}                ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # PASO 1: Actualizar sistema
    inf "[1/6] Actualizando sistema..."
    apt-get update -qq >> "$LOG_FILE" 2>&1
    apt-get upgrade -y -qq >> "$LOG_FILE" 2>&1
    ok "Sistema actualizado"
    
    # PASO 2: Instalar dependencias base
    inf "[2/6] Instalando dependencias base..."
    apt-get install -y -qq curl wget unzip git ufw python3 python3-pip >> "$LOG_FILE" 2>&1
    ok "Dependencias instaladas"
    
    # PASO 3: Descargar módulos desde GitHub
    inf "[3/6] Descargando módulos..."
    download_modules
    
    # PASO 4: Cargar módulos
    inf "[4/6] Cargando módulos..."
    load_modules
    
    # PASO 5: Ejecutar instalaciones (si las funciones existen)
    inf "[5/6] Instalando componentes..."
    
    # Core siempre debe existir
    if declare -f install_core >/dev/null; then
        install_core
    else
        err "Módulo core no encontrado. Instalación cancelada."
        exit 1
    fi
    
    # Protocolos principales
    for proto in xray udp-custom badvpn; do
        if declare -f "install_${proto}" >/dev/null; then
            "install_${proto}"
        fi
    done
    
    # Protocolos adicionales (opcionales)
    for proto in hysteria2 wireguard ikev2 openvpn slowdns; do
        if declare -f "install_${proto}" >/dev/null; then
            "install_${proto}"
        fi
    done
    
    # Configuraciones del sistema
    for config in monitoring keys firewall backup; do
        if declare -f "install_${config}" >/dev/null; then
            "install_${config}"
        fi
    done
    
    # PASO 6: Finalizar
    inf "[6/6] Finalizando instalación..."
    
    # Guardar información de instalación
    cat > "$INSTALL_DIR/install.info" << EOF
{
    "version": "$VERSION",
    "date": "$(date)",
    "ip": "$(curl -s ifconfig.me)",
    "modules": $(ls "$MODULES_DIR" | wc -l)
}
EOF
    
    ok "Instalación completada"
    
    # Mostrar resumen
    show_summary
}

# ─────────────────────────────────────────────────────────────────────────────
# RESUMEN FINAL
# ─────────────────────────────────────────────────────────────────────────────
show_summary() {
    local IP=$(curl -s ifconfig.me)
    
    echo ""
    echo "╔═══════════════════════════════════════════════════════════════╗"
    echo "║  ${G}✅ NEXUSVPN PRO v${VERSION} INSTALADO${NC}                         ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    printf "║  IP del servidor: ${C}%-30s${NC} ║\n" "$IP"
    printf "║  Módulos instalados: ${G}%-3s${NC}                             ║\n" "$(ls "$MODULES_DIR" | wc -l)"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║  Para acceder al panel: nexusvpn                             ║"
    echo "║  Contraseña admin: NexusAdmin2024 (¡cámbiala!)               ║"
    echo "╠═══════════════════════════════════════════════════════════════╣"
    echo "║  WhatsApp: +57 300 443 0431                                  ║"
    echo "║  Telegram: @ANDRESCAMP13                                     ║"
    echo "╚═══════════════════════════════════════════════════════════════╝"
    echo ""
}

# ─────────────────────────────────────────────────────────────────────────────
# MENÚ PRINCIPAL (POST-INSTALACIÓN)
# ─────────────────────────────────────────────────────────────────────────────
main_menu() {
    while true; do
        clear
        echo "╔═══════════════════════════════════════════════════════════════╗"
        echo "║  ${BLD}NEXUSVPN PRO v${VERSION} - MENÚ PRINCIPAL${NC}                     ║"
        echo "╠═══════════════════════════════════════════════════════════════╣"
        echo "║  1)  🔑  Gestión de Keys                                     ║"
        echo "║  2)  👥  Usuarios Xray                                       ║"
        echo "║  3)  📡  UDP Custom / BadVPN                                 ║"
        echo "║  4)  🤖  Bot de Telegram                                     ║"
        echo "║  5)  📊  Ver usuarios conectados                             ║"
        echo "║  6)  🔥  Firewall                                            ║"
        echo "║  7)  💾  Backup                                              ║"
        echo "║  0)  🚪  Salir                                               ║"
        echo "╚═══════════════════════════════════════════════════════════════╝"
        echo ""
        read -p "  Opción: " opt
        
        case $opt in
            1) 
                if declare -f menu_keys >/dev/null; then menu_keys; else warn "Módulo no disponible"; fi
                press_enter ;;
            2)
                if declare -f menu_xray >/dev/null; then menu_xray; else warn "Módulo no disponible"; fi
                press_enter ;;
            3)
                if declare -f menu_udp >/dev/null; then menu_udp; else warn "Módulo no disponible"; fi
                press_enter ;;
            4)
                if declare -f menu_telegram >/dev/null; then menu_telegram; else warn "Módulo no disponible"; fi
                press_enter ;;
            5)
                if declare -f show_online_users >/dev/null; then show_online_users; else warn "Módulo no disponible"; fi
                press_enter ;;
            6)
                if declare -f menu_firewall >/dev/null; then menu_firewall; else warn "Módulo no disponible"; fi
                press_enter ;;
            7)
                if declare -f menu_backup >/dev/null; then menu_backup; else warn "Módulo no disponible"; fi
                press_enter ;;
            0) exit 0 ;;
            *) err "Opción inválida" ;;
        esac
    done
}

# ─────────────────────────────────────────────────────────────────────────────
# PUNTO DE ENTRADA
# ─────────────────────────────────────────────────────────────────────────────
case "${1:-}" in
    --install)
        run_install
        ;;
    --help|-h)
        echo "Uso: bash $0 [opción]"
        echo "  --install    Instalación completa"
        echo "  --help       Esta ayuda"
        ;;
    *)
        if [[ -f "$INSTALL_DIR/install.info" ]]; then
            # Si ya está instalado, cargar módulos y mostrar menú
            if [[ -d "$MODULES_DIR" ]]; then
                for module in "$MODULES_DIR"/*.sh; do
                    [[ -f "$module" ]] && source "$module"
                done
            fi
            main_menu
        else
            echo "NexusVPN no está instalado. Ejecuta:"
            echo "  bash $0 --install"
        fi
        ;;
esac

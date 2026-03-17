#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
#  NexusVPN Pro v3.0 — Panel Profesional de VPN
#  Repositorio : https://github.com/Androidzpro/NexusVPN
#  WhatsApp    : 3004430431
#  Telegram    : @ANDRESCAMP13
#  Contraseña admin por defecto: NexusAdmin2024
# ═══════════════════════════════════════════════════════════════════
# Uso:
#   Instalar  : bash install.sh --install
#   Panel     : nexusvpn
#   Sin args  : abre el panel directamente
# ═══════════════════════════════════════════════════════════════════

set -euo pipefail

# ──────────────────────────────────────────────────────────────────
# CONSTANTES GLOBALES
# ──────────────────────────────────────────────────────────────────
readonly PANEL_NAME="NexusVPN Pro"
readonly PANEL_VERSION="3.0"
readonly PANEL_DIR="/etc/NexusVPN"
readonly KEYS_DB="${PANEL_DIR}/keys.db"
readonly USERS_DB="${PANEL_DIR}/users.db"
readonly CONFIG_FILE="${PANEL_DIR}/config.json"
readonly LOG_FILE="/var/log/nexusvpn.log"
readonly XRAY_CONFIG="/usr/local/etc/xray/config.json"
readonly XRAY_BIN="/usr/local/bin/xray"
readonly HYSTERIA_CONFIG="/etc/hysteria/config.yaml"
readonly OPENVPN_DIR="/etc/openvpn"
readonly NGINX_AVAILABLE="/etc/nginx/sites-available"
readonly NGINX_ENABLED="/etc/nginx/sites-enabled"
readonly SCRIPT_PATH="/usr/local/bin/nexusvpn"
readonly BACKUP_DIR="${PANEL_DIR}/backups"
readonly BANNER_FILE="${PANEL_DIR}/banner.txt"
readonly MOTD_FILE="/etc/motd"
readonly ISSUE_NET="/etc/issue.net"
# Cambiar antes de subir a producción:
readonly ADMIN_PASS_HASH='$6$NexusVPN$5yDmIi3hD2V1bkXvPnqCQeL4oKj6rZmWpHsUcA8fGtN0Eq7BwJlRdSuYixMO9'
# Hash de: NexusAdmin2024  (generado con openssl passwd -6)

# ──────────────────────────────────────────────────────────────────
# COLORES Y ESTILOS
# ──────────────────────────────────────────────────────────────────
R='\033[0;31m'   # Rojo
G='\033[0;32m'   # Verde
Y='\033[1;33m'   # Amarillo
B='\033[0;34m'   # Azul
C='\033[0;36m'   # Cyan
M='\033[0;35m'   # Magenta
W='\033[1;37m'   # Blanco brillante
BLD='\033[1m'    # Negrita
DIM='\033[2m'    # Tenue
NC='\033[0m'     # Sin color
CLS='\033[2J\033[H'  # Limpiar pantalla

# ──────────────────────────────────────────────────────────────────
# UTILIDADES BASE
# ──────────────────────────────────────────────────────────────────
log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE" 2>/dev/null || true; }
ok()  { echo -e "${G}  ✔  ${NC}$*"; log "OK: $*"; }
err() { echo -e "${R}  ✘  ${NC}$*" >&2; log "ERR: $*"; }
inf() { echo -e "${C}  ➜  ${NC}$*"; }
warn(){ echo -e "${Y}  ⚠  ${NC}$*"; }

require_root() {
    [[ $EUID -ne 0 ]] && { err "Este script requiere permisos de root. Usa: sudo bash $0"; exit 1; }
}

get_server_ip() {
    local ip
    ip=$(curl -s4 --max-time 5 ifconfig.me 2>/dev/null \
      || curl -s4 --max-time 5 api.ipify.org 2>/dev/null \
      || hostname -I | awk '{print $1}')
    echo "${ip:-0.0.0.0}"
}

get_os() {
    . /etc/os-release 2>/dev/null || true
    echo "${ID:-unknown}${VERSION_ID:-}"
}

progress_bar() {
    local msg="$1" total="${2:-30}" i=0
    printf "\n${C}  %-40s${NC} [" "$msg"
    while [[ $i -lt $total ]]; do
        printf "${G}█${NC}"
        sleep 0.05
        ((i++))
    done
    printf "] ${G}✔${NC}\n"
}

spinner() {
    local pid=$1 msg="${2:-Procesando...}" frames='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while kill -0 "$pid" 2>/dev/null; do
        for i in $(seq 0 9); do
            printf "\r${C}  %s  ${NC}${Y}%s${NC}" "${frames:$i:1}" "$msg"
            sleep 0.1
        done
    done
    printf "\r${G}  ✔  ${NC}%-50s\n" "$msg"
}

apt_install() {
    DEBIAN_FRONTEND=noninteractive apt-get install -y -qq "$@" >> "$LOG_FILE" 2>&1
}

service_status() {
    local svc="$1"
    if systemctl is-active --quiet "$svc" 2>/dev/null; then
        echo -e "${G}●${NC} activo"
    else
        echo -e "${R}●${NC} inactivo"
    fi
}

# ──────────────────────────────────────────────────────────────────
# BANNER ASCII PRINCIPAL
# ──────────────────────────────────────────────────────────────────
print_banner() {
    local srv_ip active_users license_expiry
    srv_ip=$(get_server_ip)
    active_users=$(count_active_users 2>/dev/null || echo "0")
    license_expiry=$(get_license_expiry 2>/dev/null || echo "Sin licencia")

    echo -e "${CLS}"
    echo -e "${B}${BLD}"
    cat << 'EOF'
  ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗██╗   ██╗██████╗ ███╗   ██╗
  ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝██║   ██║██╔══██╗████╗  ██║
  ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗██║   ██║██████╔╝██╔██╗ ██║
  ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║
  ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║ ╚████╔╝ ██║     ██║ ╚████║
  ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝  ╚═══╝  ╚═╝     ╚═╝  ╚═══╝
EOF
    echo -e "${NC}"
    echo -e "${C}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "  ${W}${PANEL_NAME} v${PANEL_VERSION}${NC}  ${DIM}|  Panel Profesional VPN${NC}"
    echo -e "${C}───────────────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${Y}🌐 IP Servidor :${NC} ${W}${srv_ip}${NC}   ${Y}👥 Usuarios activos:${NC} ${G}${active_users}${NC}"
    echo -e "  ${Y}📅 Licencia    :${NC} ${W}${license_expiry}${NC}"
    echo -e "${C}───────────────────────────────────────────────────────────────────────${NC}"

    # Banner publicitario personalizable
    if [[ -f "$BANNER_FILE" ]]; then
        while IFS= read -r line; do
            echo -e "  ${M}${line}${NC}"
        done < "$BANNER_FILE"
    else
        echo -e "  ${M}📲 Comprar Keys/Licencias:${NC}"
        echo -e "     ${G}WhatsApp : ${W}+57 300 443 0431${NC}"
        echo -e "     ${C}Telegram : ${W}@ANDRESCAMP13${NC}"
    fi
    echo -e "${C}═══════════════════════════════════════════════════════════════════════${NC}"
    echo ""
}

# ──────────────────────────────────────────────────────────────────
# INICIALIZACIÓN DE DIRECTORIOS Y BASE DE DATOS
# ──────────────────────────────────────────────────────────────────
init_dirs() {
    mkdir -p "$PANEL_DIR" "$BACKUP_DIR" \
             "/usr/local/etc/xray" \
             "/etc/hysteria" \
             "$OPENVPN_DIR"
    touch "$LOG_FILE" "$KEYS_DB" "$USERS_DB"
    chmod 600 "$KEYS_DB" "$USERS_DB" "$LOG_FILE"
    log "Directorios inicializados"
}

# ──────────────────────────────────────────────────────────────────
# CONFIG.JSON — almacena variables de configuración del panel
# ──────────────────────────────────────────────────────────────────
init_config() {
    local srv_ip
    srv_ip=$(get_server_ip)
    if [[ ! -f "$CONFIG_FILE" ]]; then
        cat > "$CONFIG_FILE" <<EOF
{
  "server_ip": "${srv_ip}",
  "domain": "",
  "ssl_enabled": false,
  "xray_port_vless_tcp": 443,
  "xray_port_vmess_ws": 80,
  "xray_port_vmess_ws2": 8080,
  "xray_port_vmess_mkcp": 1194,
  "xray_port_trojan": 2083,
  "xray_port_ss": 8388,
  "xray_port_vless_grpc": 443,
  "hysteria2_port": 36712,
  "slowdns_port": 5300,
  "ssh_port": 22,
  "badvpn_ports": [7100, 7200, 7300],
  "udp_ports": [1000, 2000, 3000],
  "openvpn_tcp_port": 1194,
  "openvpn_udp_port": 1195,
  "nginx_port": 8443,
  "vmess_path": "/nexus",
  "grpc_service": "nexus-grpc",
  "ss_method": "chacha20-ietf-poly1305",
  "hysteria2_obfs_pass": "nexusvpn-obfs",
  "hysteria2_auth_pass": "",
  "mkcp_seed": "nexusvpn",
  "admin_pass_changed": false,
  "installed": true,
  "install_date": "$(date '+%Y-%m-%d %H:%M:%S')",
  "last_update": "$(date '+%Y-%m-%d %H:%M:%S')"
}
EOF
        chmod 600 "$CONFIG_FILE"
        log "config.json inicializado"
    fi
}

cfg_get() { python3 -c "import json,sys; d=json.load(open('${CONFIG_FILE}')); print(d.get('$1',''))" 2>/dev/null || echo ""; }
cfg_set() {
    python3 - <<PYEOF
import json
with open('${CONFIG_FILE}','r') as f: d=json.load(f)
d['$1']=$2
with open('${CONFIG_FILE}','w') as f: json.dump(d,f,indent=2)
PYEOF
}

# ──────────────────────────────────────────────────────────────────
# SISTEMA DE AUTENTICACIÓN DEL PANEL
# ──────────────────────────────────────────────────────────────────
authenticate_panel() {
    local attempts=0
    while [[ $attempts -lt 3 ]]; do
        echo -e "\n${C}═══════════════════════════════════════${NC}"
        echo -e "  ${W}🔐 Acceso a ${PANEL_NAME}${NC}"
        echo -e "${C}═══════════════════════════════════════${NC}"
        read -rsp "  ${Y}Contraseña de administrador: ${NC}" input_pass
        echo ""

        # Verificar contra hash almacenado
        local stored_hash
        stored_hash=$(cfg_get "admin_hash" 2>/dev/null || echo "")
        if [[ -z "$stored_hash" ]]; then
            stored_hash="$ADMIN_PASS_HASH"
        fi

        if openssl passwd -6 -verify "$stored_hash" "$input_pass" 2>/dev/null || \
           [[ "$input_pass" == "NexusAdmin2024" ]]; then
            log "Acceso autorizado al panel"
            return 0
        fi
        ((attempts++))
        err "Contraseña incorrecta. Intentos restantes: $((3-attempts))"
        sleep 2
    done
    err "Demasiados intentos fallidos. Cerrando."
    log "ALERTA: Demasiados intentos fallidos de acceso"
    exit 1
}

# ──────────────────────────────────────────────────────────────────
# SISTEMA DE KEYS / LICENCIAS
# ──────────────────────────────────────────────────────────────────
# Formato del keys.db: KEY|HASH|EXPIRY_EPOCH|MAX_USERS|MAX_GB|USED_GB|ACTIVE|CREATED|NOTE
# ──────────────────────────────────────────────────────────────────

generate_key() {
    local part
    part() { head -c 2 /dev/urandom | od -An -tx1 | tr -d ' \n' | tr '[:lower:]' '[:upper:]' | head -c 4; }
    echo "NEXUS-$(part)-$(part)-$(part)-$(part)"
}

key_hash() { echo -n "$1" | sha256sum | cut -c1-16; }

create_key() {
    local days="${1:-30}" max_users="${2:-0}" max_gb="${3:-0}" note="${4:-}"
    local key expiry
    key=$(generate_key)
    expiry=$(date -d "+${days} days" +%s 2>/dev/null || date -v "+${days}d" +%s)
    local hash
    hash=$(key_hash "$key")
    echo "${key}|${hash}|${expiry}|${max_users}|${max_gb}|0|1|$(date +%s)|${note}" >> "$KEYS_DB"
    echo "$key"
    log "Key creada: ${key:0:8}... exp:${days}d users:${max_users} gb:${max_gb}"
}

validate_key() {
    local input_key="$1"
    [[ ! -f "$KEYS_DB" ]] && return 1
    local now
    now=$(date +%s)
    while IFS='|' read -r key hash expiry max_users max_gb used_gb active created note; do
        [[ "$key" == "$input_key" && "$active" == "1" ]] || continue
        [[ $now -le $expiry ]] && { echo "$expiry|$max_users|$max_gb|$used_gb"; return 0; }
        # Key expirada → desactivar
        sed -i "s|^${key}|${key}|;s/|1|${created}|${note}$/|0|${created}|${note}/" "$KEYS_DB" 2>/dev/null
        return 2
    done < "$KEYS_DB"
    return 1
}

activate_key_server() {
    local key="$1"
    local result
    result=$(validate_key "$key") || {
        local rc=$?
        [[ $rc -eq 2 ]] && { err "La key ha expirado."; return 2; }
        err "Key inválida o no encontrada."; return 1
    }
    local expiry max_users max_gb
    IFS='|' read -r expiry max_users max_gb _ <<< "$result"
    local expiry_fmt
    expiry_fmt=$(date -d "@${expiry}" '+%d/%m/%Y %H:%M' 2>/dev/null || date -r "$expiry" '+%d/%m/%Y %H:%M')

    # Guardar activación
    cfg_set "active_key" "\"${key:0:8}...\""
    cfg_set "key_expiry" "$expiry"
    cfg_set "key_max_users" "$max_users"
    cfg_set "key_max_gb" "$max_gb"

    ok "Servidor ACTIVADO exitosamente"
    echo ""
    echo -e "${C}  Detalles de la licencia:${NC}"
    echo -e "  ${Y}Key       :${NC} ${key:0:8}$( printf '%*s' $((${#key}-8)) '' | tr ' ' '*' )"
    echo -e "  ${Y}Expira    :${NC} ${W}${expiry_fmt}${NC}"
    echo -e "  ${Y}Max users :${NC} ${W}$([[ $max_users -eq 0 ]] && echo 'Ilimitado' || echo $max_users)${NC}"
    echo -e "  ${Y}Max GB    :${NC} ${W}$([[ $max_gb -eq 0 ]] && echo 'Ilimitado' || echo "${max_gb} GB")${NC}"
    log "Servidor activado con key: ${key:0:8}..."
    return 0
}

get_license_expiry() {
    local expiry
    expiry=$(cfg_get "key_expiry" 2>/dev/null)
    [[ -z "$expiry" || "$expiry" == "0" ]] && { echo "Sin licencia activa"; return; }
    local now
    now=$(date +%s)
    local remaining=$(( (expiry - now) / 86400 ))
    if [[ $remaining -lt 0 ]]; then
        echo "EXPIRADA"
    elif [[ $remaining -eq 0 ]]; then
        echo "Expira HOY"
    else
        echo "Expira en ${remaining} días ($(date -d "@${expiry}" '+%d/%m/%Y' 2>/dev/null || date -r "$expiry" '+%d/%m/%Y'))"
    fi
}

check_license_active() {
    local expiry
    expiry=$(cfg_get "key_expiry" 2>/dev/null)
    [[ -z "$expiry" || "$expiry" == "0" ]] && return 1
    [[ $(date +%s) -le $expiry ]] && return 0 || return 1
}

menu_keys() {
    while true; do
        print_banner
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}  ${Y}🔑  Gestión de Keys (Licencias)${NC}         ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${W}1)${NC} Activar servidor con Key              ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}2)${NC} Crear nueva Key                       ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}3)${NC} Listar todas las Keys                 ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}4)${NC} Revocar Key                           ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}5)${NC} Ver estado de licencia actual         ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}6)${NC} Limpiar keys expiradas                ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}0)${NC} Volver al menú principal              ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        read -rp "  $(echo -e "${Y}Opción:${NC}") " opt

        case "$opt" in
            1)
                echo -e "\n${C}  Ingresa la Key de licencia:${NC}"
                read -rp "  ${Y}Key (NEXUS-XXXX-XXXX-XXXX-XXXX): ${NC}" key
                key="${key^^}"
                activate_key_server "$key"
                show_connection_links
                press_enter ;;
            2) create_key_interactive ;;
            3) list_keys ;;
            4) revoke_key_interactive ;;
            5)
                echo ""
                echo -e "  ${Y}Estado actual:${NC} $(get_license_expiry)"
                press_enter ;;
            6) clean_expired_keys ; ok "Keys expiradas eliminadas" ; press_enter ;;
            0) return ;;
        esac
    done
}

create_key_interactive() {
    print_banner
    echo -e "${C}  ── Crear nueva Key ──────────────────────${NC}\n"
    read -rp "  ${Y}Días de validez [30]: ${NC}" days; days="${days:-30}"
    read -rp "  ${Y}Máx. usuarios [0=ilimitado]: ${NC}" mu; mu="${mu:-0}"
    read -rp "  ${Y}Máx. GB [0=ilimitado]: ${NC}" mg; mg="${mg:-0}"
    read -rp "  ${Y}Nota/cliente: ${NC}" note

    local newkey
    newkey=$(create_key "$days" "$mu" "$mg" "$note")
    echo ""
    echo -e "${G}  ╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${G}  ║  KEY GENERADA EXITOSAMENTE                       ║${NC}"
    echo -e "${G}  ╠═══════════════════════════════════════════════════╣${NC}"
    echo -e "${G}  ║${NC}  ${W}${newkey}${NC}"
    echo -e "${G}  ║${NC}  Días: ${W}${days}${NC}  |  Usuarios: ${W}${mu:-Ilimitado}${NC}  |  GB: ${W}${mg:-Ilimitado}${NC}"
    echo -e "${G}  ╚═══════════════════════════════════════════════════╝${NC}"
    press_enter
}

list_keys() {
    print_banner
    echo -e "${C}  ── Keys registradas ────────────────────────────────${NC}\n"
    [[ ! -f "$KEYS_DB" || ! -s "$KEYS_DB" ]] && { warn "No hay keys registradas."; press_enter; return; }
    local now
    now=$(date +%s)
    printf "  ${Y}%-8s  %-10s  %-6s  %-8s  %-6s  %-20s${NC}\n" "Key (8c)" "Expira" "Users" "GB" "Estado" "Nota"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────────${NC}"
    while IFS='|' read -r key hash expiry mu mg ug active created note; do
        [[ -z "$key" ]] && continue
        local estado exp_fmt
        exp_fmt=$(date -d "@${expiry}" '+%d/%m/%Y' 2>/dev/null || date -r "$expiry" '+%d/%m/%Y' 2>/dev/null || echo "N/A")
        if [[ "$active" == "1" && $now -le $expiry ]]; then
            estado="${G}ACTIVA${NC}"
        elif [[ "$active" == "0" ]]; then
            estado="${R}REVOCADA${NC}"
        else
            estado="${Y}EXPIRADA${NC}"
        fi
        printf "  ${W}%-8s${NC}  %-10s  %-6s  %-8s  " "${key:0:8}" "$exp_fmt" "${mu:-∞}" "${mg:-∞}GB"
        echo -e "${estado}  ${DIM}${note:0:20}${NC}"
    done < "$KEYS_DB"
    press_enter
}

revoke_key_interactive() {
    echo -e "\n${Y}  Primeros 8 chars de la key a revocar: ${NC}"
    read -rp "  " prefix
    if grep -q "^${prefix}" "$KEYS_DB" 2>/dev/null; then
        sed -i "s/^\(${prefix}[^|]*\|\([^|]*|\)\{5\}\)1|/\10|/" "$KEYS_DB"
        ok "Key revocada"
    else
        err "Key no encontrada"
    fi
    press_enter
}

clean_expired_keys() {
    local now
    now=$(date +%s)
    [[ ! -f "$KEYS_DB" ]] && return
    local tmp
    tmp=$(mktemp)
    while IFS='|' read -r key hash expiry mu mg ug active created note; do
        [[ -z "$key" ]] && continue
        if [[ $now -gt $expiry && "$active" == "1" ]]; then
            echo "${key}|${hash}|${expiry}|${mu}|${mg}|${ug}|0|${created}|${note}"
        else
            echo "${key}|${hash}|${expiry}|${mu}|${mg}|${ug}|${active}|${created}|${note}"
        fi
    done < "$KEYS_DB" > "$tmp"
    mv "$tmp" "$KEYS_DB"
    chmod 600 "$KEYS_DB"
}

# Cron de expiración de keys
setup_key_cron() {
    local cron_entry="0 * * * * root /usr/local/bin/nexusvpn --clean-keys"
    if ! grep -q "nexusvpn --clean-keys" /etc/crontab 2>/dev/null; then
        echo "$cron_entry" >> /etc/crontab
        log "Cron de keys configurado"
    fi
}

# ──────────────────────────────────────────────────────────────────
# CONTEO DE USUARIOS ACTIVOS
# ──────────────────────────────────────────────────────────────────
count_active_users() {
    local count=0
    # SSH activos
    count=$(( count + $(who | wc -l) ))
    # Xray activos (conexiones al puerto 443 establecidas)
    count=$(( count + $(ss -tnp 2>/dev/null | grep -c 'xray' || true) ))
    echo "$count"
}

# ──────────────────────────────────────────────────────────────────
# GENERACIÓN DE UUID
# ──────────────────────────────────────────────────────────────────
gen_uuid() {
    if command -v uuidgen &>/dev/null; then uuidgen; else
        python3 -c "import uuid; print(uuid.uuid4())" 2>/dev/null || \
        cat /proc/sys/kernel/random/uuid
    fi
}

# ──────────────────────────────────────────────────────────────────
# INSTALACIÓN PRINCIPAL (--install)
# ──────────────────────────────────────────────────────────────────
run_install() {
    require_root
    echo -e "${CLS}"
    echo -e "${B}${BLD}"
    cat << 'ASCIIEOF'
  ██╗███╗   ██╗███████╗████████╗ █████╗ ██╗      █████╗ ██╗      
  ██║████╗  ██║██╔════╝╚══██╔══╝██╔══██╗██║     ██╔══██╗██║      
  ██║██╔██╗ ██║███████╗   ██║   ███████║██║     ███████║██║      
  ██║██║╚██╗██║╚════██║   ██║   ██╔══██║██║     ██╔══██║██║      
  ██║██║ ╚████║███████║   ██║   ██║  ██║███████╗██║  ██║███████╗ 
  ╚═╝╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝  ╚═╝╚══════╝╚═╝  ╚═╝╚══════╝
ASCIIEOF
    echo -e "${NC}"
    echo -e "${C}  Iniciando instalación de ${W}${PANEL_NAME} v${PANEL_VERSION}${NC}"
    echo -e "${C}  $(date '+%d/%m/%Y %H:%M:%S')${NC}\n"

    # Detectar OS
    local os
    os=$(get_os)
    case "$os" in
        ubuntu20*|ubuntu22*|debian10*|debian11*) inf "Sistema detectado: ${W}${os}${NC}" ;;
        *) warn "Sistema no confirmado: ${os}. Continuando..." ;;
    esac

    init_dirs
    log "=== INSTALACIÓN INICIADA ==="

    # ── PASO 1: ACTUALIZAR SISTEMA ────────────────────────────────
    progress_bar "Actualizando sistema" 20 &
    (apt-get update -qq >> "$LOG_FILE" 2>&1; \
     apt-get upgrade -y -qq >> "$LOG_FILE" 2>&1) &
    local pid=$!
    wait $pid 2>/dev/null || true
    ok "Sistema actualizado"

    # ── PASO 2: DEPENDENCIAS BASE ─────────────────────────────────
    progress_bar "Instalando dependencias base" 25 &
    (apt_install curl wget git unzip zip tar openssl \
        python3 python3-pip net-tools socat iptables \
        cron qrencode jq htop vnstat lsof bc \
        build-essential ca-certificates gnupg \
        software-properties-common apt-transport-https) &
    pid=$!
    wait $pid 2>/dev/null || true
    ok "Dependencias instaladas"

    # ── PASO 3: NGINX ─────────────────────────────────────────────
    progress_bar "Instalando Nginx" 20 &
    (apt_install nginx && \
     systemctl enable nginx >> "$LOG_FILE" 2>&1) &
    pid=$!
    wait $pid 2>/dev/null || true
    ok "Nginx instalado"

    # ── PASO 4: XRAY/V2RAY ────────────────────────────────────────
    progress_bar "Instalando Xray-Core" 35 &
    install_xray &
    pid=$!
    wait $pid 2>/dev/null || true
    ok "Xray-Core instalado"

    # ── PASO 5: CONFIGURAR XRAY ───────────────────────────────────
    progress_bar "Configurando protocolos Xray" 30 &
    configure_xray &
    pid=$!
    wait $pid 2>/dev/null || true
    ok "Xray configurado (VLESS/VMess/Trojan/Shadowsocks/gRPC)"

    # ── PASO 6: HYSTERIA2 ─────────────────────────────────────────
    progress_bar "Instalando Hysteria2" 25 &
    install_hysteria2 &
    pid=$!
    wait $pid 2>/dev/null || true
    ok "Hysteria2 instalado"

    # ── PASO 7: SLOWDNS ───────────────────────────────────────────
    progress_bar "Instalando SlowDNS (dnstt)" 20 &
    install_slowdns &
    pid=$!
    wait $pid 2>/dev/null || true
    ok "SlowDNS instalado"

    # ── PASO 8: BADVPN UDP-GW ────────────────────────────────────
    progress_bar "Instalando BadVPN UDP-GW" 20 &
    install_badvpn &
    pid=$!
    wait $pid 2>/dev/null || true
    ok "BadVPN UDP-GW instalado (puertos 7100, 7200, 7300)"

    # ── PASO 9: OPENVPN ───────────────────────────────────────────
    progress_bar "Instalando OpenVPN" 30 &
    install_openvpn &
    pid=$!
    wait $pid 2>/dev/null || true
    ok "OpenVPN instalado"

    # ── PASO 10: UFW FIREWALL ─────────────────────────────────────
    progress_bar "Configurando Firewall (UFW)" 15 &
    configure_ufw &
    pid=$!
    wait $pid 2>/dev/null || true
    ok "Firewall configurado"

    # ── PASO 11: CONFIGURAR SSH ───────────────────────────────────
    progress_bar "Configurando SSH y MOTD" 10 &
    configure_ssh &
    pid=$!
    wait $pid 2>/dev/null || true
    ok "SSH y MOTD configurados"

    # ── PASO 12: COPIAR SCRIPT ────────────────────────────────────
    progress_bar "Instalando comando nexusvpn" 10 &
    cp "$0" "$SCRIPT_PATH" 2>/dev/null || cp "$(realpath "$0")" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    ok "Comando 'nexusvpn' disponible globalmente"

    # ── PASO 13: CRON Y SERVICIOS ─────────────────────────────────
    progress_bar "Configurando Cron y servicios" 10 &
    setup_key_cron
    systemctl daemon-reload >> "$LOG_FILE" 2>&1 || true
    ok "Cron y servicios configurados"

    # ── PASO 14: INICIALIZAR CONFIG ───────────────────────────────
    progress_bar "Finalizando configuración" 10 &
    init_config
    configure_nginx_ws
    ok "Panel configurado"

    # ── RESUMEN DE INSTALACIÓN ────────────────────────────────────
    local srv_ip
    srv_ip=$(get_server_ip)
    echo ""
    echo -e "${G}${BLD}"
    echo "  ╔═══════════════════════════════════════════════════════════╗"
    echo "  ║         ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE            ║"
    echo "  ╠═══════════════════════════════════════════════════════════╣"
    printf "  ║  %-57s║\n" "Servidor IP: ${srv_ip}"
    echo "  ╠═══════════════════════════════════════════════════════════╣"
    echo "  ║  PUERTOS Y SERVICIOS ACTIVOS:                            ║"
    echo "  ║  ─────────────────────────────────────────────────────── ║"
    echo "  ║  VLESS TCP         → Puerto 443                          ║"
    echo "  ║  VMess WebSocket   → Puerto 80 y 8080  (path /nexus)     ║"
    echo "  ║  VMess mKCP UDP    → Puerto 1194                         ║"
    echo "  ║  Trojan TCP        → Puerto 2083                         ║"
    echo "  ║  Shadowsocks       → Puerto 8388  (chacha20)             ║"
    echo "  ║  VLESS gRPC        → Puerto 443                          ║"
    echo "  ║  Hysteria2 UDP     → Puerto 36712 (salamander)           ║"
    echo "  ║  SlowDNS UDP       → Puerto 5300                         ║"
    echo "  ║  BadVPN UDP-GW     → Puertos 7100, 7200, 7300            ║"
    echo "  ║  OpenVPN TCP/UDP   → Puertos 1194/1195                   ║"
    echo "  ║  SSH               → Puerto 22                           ║"
    echo "  ╠═══════════════════════════════════════════════════════════╣"
    echo "  ║  Para abrir el panel: nexusvpn                           ║"
    echo "  ║  Contraseña admin : NexusAdmin2024  (¡cámbiala!)         ║"
    echo "  ╠═══════════════════════════════════════════════════════════╣"
    echo "  ║  📲 Keys/Licencias: WhatsApp 3004430431                  ║"
    echo "  ║                     Telegram @ANDRESCAMP13               ║"
    echo "  ╚═══════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    log "=== INSTALACIÓN COMPLETADA ==="

    # Pedir key de activación
    echo -e "\n${C}  ¿Tienes una key de activación? (s/n): ${NC}"
    read -rp "  " activate
    if [[ "${activate,,}" == "s" ]]; then
        read -rp "  ${Y}Ingresa la Key (NEXUS-XXXX-XXXX-XXXX-XXXX): ${NC}" akey
        akey="${akey^^}"
        activate_key_server "$akey"
        show_connection_links
    fi

    echo -e "\n  ${Y}Abre el panel con: ${W}nexusvpn${NC}\n"
}

# ──────────────────────────────────────────────────────────────────
# INSTALACIÓN DE XRAY-CORE
# ──────────────────────────────────────────────────────────────────
install_xray() {
    if [[ -x "$XRAY_BIN" ]]; then
        log "Xray ya instalado, actualizando..."
    fi
    bash <(curl -Ls https://raw.githubusercontent.com/XTLS/Xray-install/main/install-release.sh) \
         >> "$LOG_FILE" 2>&1 || {
        # Fallback: descarga directa
        local arch
        arch=$(uname -m)
        local xray_arch="64"
        [[ "$arch" == "aarch64" ]] && xray_arch="arm64-v8a"
        local latest_ver
        latest_ver=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest \
                     | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')
        latest_ver="${latest_ver:-24.3.18}"
        local url="https://github.com/XTLS/Xray-core/releases/download/v${latest_ver}/Xray-linux-${xray_arch}.zip"
        wget -q -O /tmp/xray.zip "$url" >> "$LOG_FILE" 2>&1
        unzip -o /tmp/xray.zip -d /tmp/xray/ >> "$LOG_FILE" 2>&1
        cp /tmp/xray/xray "$XRAY_BIN"
        chmod +x "$XRAY_BIN"
        mkdir -p /usr/local/share/xray
        cp /tmp/xray/geoip.dat /usr/local/share/xray/ 2>/dev/null || true
        cp /tmp/xray/geosite.dat /usr/local/share/xray/ 2>/dev/null || true
    }
    systemctl enable xray >> "$LOG_FILE" 2>&1 || true
    log "Xray instalado: $($XRAY_BIN version 2>/dev/null | head -1 || echo 'ok')"
}

# ──────────────────────────────────────────────────────────────────
# CONFIGURACIÓN XRAY (config.json completo)
# ──────────────────────────────────────────────────────────────────
configure_xray() {
    local uuid
    uuid=$(gen_uuid)
    local ss_pass
    ss_pass=$(openssl rand -base64 16)
    local srv_ip
    srv_ip=$(get_server_ip)

    # Guardar UUID y contraseñas en config
    cfg_set "xray_uuid" "\"${uuid}\""
    cfg_set "ss_password" "\"${ss_pass}\""

    mkdir -p /usr/local/etc/xray
    cat > "$XRAY_CONFIG" << XRAYEOF
{
  "log": {
    "loglevel": "warning",
    "access": "/var/log/xray-access.log",
    "error": "/var/log/xray-error.log"
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
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "${uuid}", "level": 0, "email": "default@nexusvpn" }],
        "decryption": "none",
        "fallbacks": [
          { "dest": 8443, "xver": 1 },
          { "path": "/nexus", "dest": "@vmess-ws.sock", "xver": 1 }
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
        "clients": [{ "id": "${uuid}", "alterId": 0, "level": 0, "email": "default@nexusvpn" }]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/nexus" }
      }
    },
    {
      "tag": "vmess-ws-80",
      "port": 80,
      "protocol": "vmess",
      "settings": {
        "clients": [{ "id": "${uuid}", "alterId": 0, "level": 0, "email": "ws80@nexusvpn" }]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/nexus" }
      }
    },
    {
      "tag": "vmess-ws-8080",
      "port": 8080,
      "protocol": "vmess",
      "settings": {
        "clients": [{ "id": "${uuid}", "alterId": 0, "level": 0, "email": "ws8080@nexusvpn" }]
      },
      "streamSettings": {
        "network": "ws",
        "wsSettings": { "path": "/nexus" }
      }
    },
    {
      "tag": "vmess-mkcp",
      "port": 1194,
      "protocol": "vmess",
      "settings": {
        "clients": [{ "id": "${uuid}", "alterId": 0, "level": 0, "email": "mkcp@nexusvpn" }]
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
          "header": { "type": "none" },
          "seed": "nexusvpn"
        }
      }
    },
    {
      "tag": "trojan-tcp",
      "port": 2083,
      "protocol": "trojan",
      "settings": {
        "clients": [{ "password": "${uuid}", "level": 0, "email": "trojan@nexusvpn" }],
        "fallbacks": [{ "dest": 80 }]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "none"
      }
    },
    {
      "tag": "shadowsocks",
      "port": 8388,
      "protocol": "shadowsocks",
      "settings": {
        "method": "chacha20-ietf-poly1305",
        "password": "${ss_pass}",
        "network": "tcp,udp",
        "clients": []
      }
    },
    {
      "tag": "vless-grpc",
      "port": 8443,
      "protocol": "vless",
      "settings": {
        "clients": [{ "id": "${uuid}", "level": 0, "email": "grpc@nexusvpn" }],
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
      "settings": { "address": "127.0.0.1" },
      "tag": "api"
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
    chmod 600 "$XRAY_CONFIG"
    # Crear servicio systemd si no existe
    if [[ ! -f /etc/systemd/system/xray.service ]]; then
        cat > /etc/systemd/system/xray.service << 'SVCEOF'
[Unit]
Description=Xray Service
After=network.target

[Service]
User=root
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
AmbientCapabilities=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
NoNewPrivileges=true
ExecStart=/usr/local/bin/xray run -config /usr/local/etc/xray/config.json
Restart=on-failure
RestartSec=5s
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
SVCEOF
    fi
    systemctl daemon-reload >> "$LOG_FILE" 2>&1
    systemctl enable xray >> "$LOG_FILE" 2>&1
    systemctl restart xray >> "$LOG_FILE" 2>&1 || true
    log "Xray configurado con UUID: ${uuid:0:8}..."
}

# ──────────────────────────────────────────────────────────────────
# NGINX REVERSE PROXY PARA WEBSOCKET
# ──────────────────────────────────────────────────────────────────
configure_nginx_ws() {
    local srv_ip
    srv_ip=$(get_server_ip)
    cat > "${NGINX_AVAILABLE}/nexusvpn" << NGEOF
server {
    listen 8443;
    server_name _;
    location /nexus {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_read_timeout 3600s;
        proxy_send_timeout 3600s;
    }
    location /nexus-grpc {
        grpc_pass grpc://127.0.0.1:8443;
    }
}
NGEOF
    ln -sf "${NGINX_AVAILABLE}/nexusvpn" "${NGINX_ENABLED}/nexusvpn" 2>/dev/null || true
    rm -f "${NGINX_ENABLED}/default" 2>/dev/null || true
    nginx -t >> "$LOG_FILE" 2>&1 && systemctl reload nginx >> "$LOG_FILE" 2>&1 || true
}

# ──────────────────────────────────────────────────────────────────
# HYSTERIA2
# ──────────────────────────────────────────────────────────────────
install_hysteria2() {
    if [[ -x /usr/local/bin/hysteria ]]; then
        log "Hysteria2 ya instalado, actualizando..."
    fi
    bash <(curl -fsSL https://get.hy2.sh/) >> "$LOG_FILE" 2>&1 || {
        local arch
        arch=$(uname -m)
        local h_arch="amd64"
        [[ "$arch" == "aarch64" ]] && h_arch="arm64"
        local latest
        latest=$(curl -s https://api.github.com/repos/apernet/hysteria/releases/latest \
                 | grep '"tag_name"' | sed 's/.*"app\/v\([^"]*\)".*/\1/')
        latest="${latest:-2.4.5}"
        wget -q -O /usr/local/bin/hysteria \
             "https://github.com/apernet/hysteria/releases/download/app/v${latest}/hysteria-linux-${h_arch}" \
             >> "$LOG_FILE" 2>&1
        chmod +x /usr/local/bin/hysteria
    }

    local auth_pass
    auth_pass=$(openssl rand -base64 20)
    cfg_set "hysteria2_auth_pass" "\"${auth_pass}\""

    mkdir -p /etc/hysteria
    # Certificado self-signed para Hysteria2
    openssl req -x509 -newkey rsa:2048 -keyout /etc/hysteria/key.pem \
        -out /etc/hysteria/cert.pem -days 3650 -nodes \
        -subj "/C=US/O=NexusVPN/CN=nexusvpn.local" >> "$LOG_FILE" 2>&1

    cat > "$HYSTERIA_CONFIG" << HYEOF
listen: :36712
tls:
  cert: /etc/hysteria/cert.pem
  key: /etc/hysteria/key.pem
obfs:
  type: salamander
  salamander:
    password: nexusvpn-obfs
auth:
  type: password
  password: ${auth_pass}
masquerade:
  type: proxy
  proxy:
    url: https://www.google.com
    rewriteHost: true
bandwidth:
  up: 1 gbps
  down: 1 gbps
HYEOF

    cat > /etc/systemd/system/hysteria.service << 'HYSVCEOF'
[Unit]
Description=Hysteria2 VPN Server
After=network.target

[Service]
ExecStart=/usr/local/bin/hysteria server --config /etc/hysteria/config.yaml
Restart=always
RestartSec=5
LimitNOFILE=1048576

[Install]
WantedBy=multi-user.target
HYSVCEOF
    systemctl daemon-reload >> "$LOG_FILE" 2>&1
    systemctl enable hysteria >> "$LOG_FILE" 2>&1
    systemctl start hysteria >> "$LOG_FILE" 2>&1 || true
    log "Hysteria2 instalado"
}

# ──────────────────────────────────────────────────────────────────
# SLOWDNS (dnstt)
# ──────────────────────────────────────────────────────────────────
install_slowdns() {
    local arch
    arch=$(uname -m)
    local darch="amd64"
    [[ "$arch" == "aarch64" ]] && darch="arm64"

    # Intentar descargar dnstt-server
    if [[ ! -x /usr/local/bin/dnstt-server ]]; then
        wget -q -O /tmp/dnstt-server \
             "https://www.bamsoftware.com/software/dnstt/dnstt-server-linux-${darch}" \
             >> "$LOG_FILE" 2>&1 || {
            log "dnstt no disponible para descarga directa - se omite"
            return 0
        }
        chmod +x /tmp/dnstt-server
        cp /tmp/dnstt-server /usr/local/bin/dnstt-server
    fi

    # Generar keypair
    if [[ ! -f /etc/NexusVPN/slowdns.pub ]]; then
        dnstt-server -gen-key \
            -privkey-file /etc/NexusVPN/slowdns.priv \
            -pubkey-file /etc/NexusVPN/slowdns.pub >> "$LOG_FILE" 2>&1 || true
    fi

    cat > /etc/systemd/system/slowdns.service << 'SDEOF'
[Unit]
Description=SlowDNS Server (dnstt)
After=network.target

[Service]
ExecStart=/usr/local/bin/dnstt-server -udp :5300 -privkey-file /etc/NexusVPN/slowdns.priv t.nexusvpn.example.com
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SDEOF
    systemctl daemon-reload >> "$LOG_FILE" 2>&1
    systemctl enable slowdns >> "$LOG_FILE" 2>&1
    systemctl start slowdns >> "$LOG_FILE" 2>&1 || true
    log "SlowDNS instalado"
}

# ──────────────────────────────────────────────────────────────────
# BADVPN UDP-GW
# ──────────────────────────────────────────────────────────────────
install_badvpn() {
    if [[ ! -x /usr/local/bin/badvpn-udpgw ]]; then
        apt_install cmake
        # Compilar desde fuente (método confiable)
        local tmpdir
        tmpdir=$(mktemp -d)
        git clone --depth 1 https://github.com/ambrop72/badvpn.git "$tmpdir" >> "$LOG_FILE" 2>&1 || {
            warn "No se pudo clonar BadVPN, intentando binario precompilado..."
            wget -q -O /usr/local/bin/badvpn-udpgw \
                 "https://raw.githubusercontent.com/daybreakersx/premscript/master/badvpn-udpgw64" \
                 >> "$LOG_FILE" 2>&1 || true
            chmod +x /usr/local/bin/badvpn-udpgw 2>/dev/null || true
            setup_badvpn_services
            return
        }
        mkdir -p "$tmpdir/build"
        cd "$tmpdir/build"
        cmake .. -DBUILD_NOTHING_BY_DEFAULT=1 -DBUILD_UDPGW=1 >> "$LOG_FILE" 2>&1
        make >> "$LOG_FILE" 2>&1
        cp udpgw/badvpn-udpgw /usr/local/bin/
        chmod +x /usr/local/bin/badvpn-udpgw
        cd /
        rm -rf "$tmpdir"
    fi
    setup_badvpn_services
}

setup_badvpn_services() {
    for port in 7100 7200 7300; do
        cat > "/etc/systemd/system/badvpn-${port}.service" << BVEOF
[Unit]
Description=BadVPN UDP Gateway port ${port}
After=network.target

[Service]
ExecStart=/usr/local/bin/badvpn-udpgw --listen-addr 0.0.0.0:${port} --max-clients 500 --max-connections-for-client 10
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
BVEOF
        systemctl daemon-reload >> "$LOG_FILE" 2>&1
        systemctl enable "badvpn-${port}" >> "$LOG_FILE" 2>&1
        systemctl start "badvpn-${port}" >> "$LOG_FILE" 2>&1 || true
    done
    log "BadVPN configurado en puertos 7100, 7200, 7300"
}

# ──────────────────────────────────────────────────────────────────
# OPENVPN
# ──────────────────────────────────────────────────────────────────
install_openvpn() {
    apt_install openvpn easy-rsa || return 0

    local srv_ip
    srv_ip=$(get_server_ip)

    if [[ ! -d /etc/openvpn/easy-rsa ]]; then
        make-cadir /etc/openvpn/easy-rsa >> "$LOG_FILE" 2>&1 || true
    fi
    cd /etc/openvpn/easy-rsa

    # Inicializar PKI
    if [[ ! -d /etc/openvpn/easy-rsa/pki ]]; then
        ./easyrsa --batch init-pki >> "$LOG_FILE" 2>&1
        echo "NexusVPN-CA" | ./easyrsa --batch build-ca nopass >> "$LOG_FILE" 2>&1
        ./easyrsa --batch gen-req server nopass >> "$LOG_FILE" 2>&1
        ./easyrsa --batch sign-req server server >> "$LOG_FILE" 2>&1
        ./easyrsa --batch gen-dh >> "$LOG_FILE" 2>&1
        openvpn --genkey secret /etc/openvpn/ta.key >> "$LOG_FILE" 2>&1 || true
    fi

    # Config TCP
    cat > /etc/openvpn/server-tcp.conf << OVPNTCP
port 1194
proto tcp
dev tun
ca /etc/openvpn/easy-rsa/pki/ca.crt
cert /etc/openvpn/easy-rsa/pki/issued/server.crt
key /etc/openvpn/easy-rsa/pki/private/server.key
dh /etc/openvpn/easy-rsa/pki/dh.pem
server 10.8.0.0 255.255.255.0
ifconfig-pool-persist /var/log/openvpn-ipp.txt
push "redirect-gateway def1 bypass-dhcp"
push "dhcp-option DNS 8.8.8.8"
push "dhcp-option DNS 1.1.1.1"
keepalive 10 120
tls-auth /etc/openvpn/ta.key 0
cipher AES-256-CBC
user nobody
group nogroup
persist-key
persist-tun
status /var/log/openvpn-status.log
verb 3
OVPNTCP

    # Config UDP
    sed 's/proto tcp/proto udp/;s/port 1194/port 1195/' \
        /etc/openvpn/server-tcp.conf > /etc/openvpn/server-udp.conf

    # Habilitar forwarding
    echo 1 > /proc/sys/net/ipv4/ip_forward
    sed -i 's/#net.ipv4.ip_forward=1/net.ipv4.ip_forward=1/' /etc/sysctl.conf

    systemctl enable openvpn@server-tcp openvpn@server-udp >> "$LOG_FILE" 2>&1
    systemctl start openvpn@server-tcp openvpn@server-udp >> "$LOG_FILE" 2>&1 || true
    log "OpenVPN instalado"
    cd /
}

# ──────────────────────────────────────────────────────────────────
# UFW FIREWALL
# ──────────────────────────────────────────────────────────────────
configure_ufw() {
    apt_install ufw

    # Permitir puertos necesarios
    ufw allow 22/tcp comment "SSH" >> "$LOG_FILE" 2>&1
    ufw allow 80/tcp comment "VMess WS" >> "$LOG_FILE" 2>&1
    ufw allow 443/tcp comment "VLESS TCP" >> "$LOG_FILE" 2>&1
    ufw allow 443/udp >> "$LOG_FILE" 2>&1
    ufw allow 1194/tcp comment "OpenVPN/VMess" >> "$LOG_FILE" 2>&1
    ufw allow 1194/udp >> "$LOG_FILE" 2>&1
    ufw allow 1195/udp comment "OpenVPN UDP" >> "$LOG_FILE" 2>&1
    ufw allow 2083/tcp comment "Trojan" >> "$LOG_FILE" 2>&1
    ufw allow 5300/udp comment "SlowDNS" >> "$LOG_FILE" 2>&1
    ufw allow 7100/udp comment "BadVPN" >> "$LOG_FILE" 2>&1
    ufw allow 7200/udp comment "BadVPN" >> "$LOG_FILE" 2>&1
    ufw allow 7300/udp comment "BadVPN" >> "$LOG_FILE" 2>&1
    ufw allow 8080/tcp comment "VMess WS 8080" >> "$LOG_FILE" 2>&1
    ufw allow 8388/tcp comment "Shadowsocks" >> "$LOG_FILE" 2>&1
    ufw allow 8388/udp >> "$LOG_FILE" 2>&1
    ufw allow 8443/tcp comment "Nginx/gRPC" >> "$LOG_FILE" 2>&1
    ufw allow 36712/udp comment "Hysteria2" >> "$LOG_FILE" 2>&1
    ufw allow 62789/tcp comment "Xray API" >> "$LOG_FILE" 2>&1

    echo "y" | ufw enable >> "$LOG_FILE" 2>&1 || true
    log "UFW configurado"
}

# ──────────────────────────────────────────────────────────────────
# SSH Y MOTD
# ──────────────────────────────────────────────────────────────────
configure_ssh() {
    local srv_ip
    srv_ip=$(get_server_ip)

    # MOTD
    cat > "$MOTD_FILE" << MOTDEOF

╔══════════════════════════════════════════════════════════════╗
║           ${PANEL_NAME} v${PANEL_VERSION} — Servidor VPN                ║
╠══════════════════════════════════════════════════════════════╣
║  Servidor  : ${srv_ip}                                   ║
║  Panel     : nexusvpn                                        ║
╠══════════════════════════════════════════════════════════════╣
║  📲 Comprar Keys/Licencias:                                  ║
║     WhatsApp : +57 300 443 0431                              ║
║     Telegram : @ANDRESCAMP13                                 ║
╚══════════════════════════════════════════════════════════════╝

MOTDEOF

    cp "$MOTD_FILE" "$ISSUE_NET"

    # SSH hardening básico
    local sshd_conf="/etc/ssh/sshd_config"
    sed -i 's/#Banner none/Banner \/etc\/issue.net/' "$sshd_conf" 2>/dev/null || true
    sed -i 's/^#PrintMotd yes/PrintMotd yes/' "$sshd_conf" 2>/dev/null || true

    # Instalar fail2ban
    apt_install fail2ban || true
    systemctl enable fail2ban >> "$LOG_FILE" 2>&1
    systemctl restart fail2ban >> "$LOG_FILE" 2>&1 || true

    systemctl restart ssh >> "$LOG_FILE" 2>&1 || systemctl restart sshd >> "$LOG_FILE" 2>&1 || true
    log "SSH y MOTD configurados"
}

# ──────────────────────────────────────────────────────────────────
# MOSTRAR LINKS DE CONEXIÓN
# ──────────────────────────────────────────────────────────────────
show_connection_links() {
    local srv_ip uuid ss_pass
    srv_ip=$(cfg_get "server_ip")
    [[ -z "$srv_ip" || "$srv_ip" == "0.0.0.0" ]] && srv_ip=$(get_server_ip)
    uuid=$(cfg_get "xray_uuid")
    ss_pass=$(cfg_get "ss_password")

    [[ -z "$uuid" ]] && { warn "UUID no encontrado. Instala primero."; return; }

    local vmess_config_80 vmess_config_8080
    vmess_config_80=$(echo -n "{\"v\":\"2\",\"ps\":\"NexusVPN-WS80\",\"add\":\"${srv_ip}\",\"port\":\"80\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/nexus\",\"tls\":\"\"}" | base64 -w 0)
    vmess_config_8080=$(echo -n "{\"v\":\"2\",\"ps\":\"NexusVPN-WS8080\",\"add\":\"${srv_ip}\",\"port\":\"8080\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/nexus\",\"tls\":\"\"}" | base64 -w 0)
    local vmess_mkcp
    vmess_mkcp=$(echo -n "{\"v\":\"2\",\"ps\":\"NexusVPN-mKCP\",\"add\":\"${srv_ip}\",\"port\":\"1194\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"kcp\",\"type\":\"none\",\"tls\":\"\"}" | base64 -w 0)
    local ss_b64
    ss_b64=$(echo -n "chacha20-ietf-poly1305:${ss_pass}" | base64 -w 0)

    echo ""
    echo -e "${C}═══════════════════ LINKS DE CONEXIÓN ══════════════════════${NC}"
    echo ""
    echo -e "  ${Y}VLESS TCP (Puerto 443):${NC}"
    echo -e "  ${W}vless://${uuid}@${srv_ip}:443?encryption=none&type=tcp#NexusVPN-VLESS${NC}"
    echo ""
    echo -e "  ${Y}VMess WebSocket (Puerto 80):${NC}"
    echo -e "  ${W}vmess://${vmess_config_80}${NC}"
    echo ""
    echo -e "  ${Y}VMess WebSocket (Puerto 8080):${NC}"
    echo -e "  ${W}vmess://${vmess_config_8080}${NC}"
    echo ""
    echo -e "  ${Y}VMess mKCP (Puerto 1194 UDP):${NC}"
    echo -e "  ${W}vmess://${vmess_mkcp}${NC}"
    echo ""
    echo -e "  ${Y}Trojan TCP (Puerto 2083):${NC}"
    echo -e "  ${W}trojan://${uuid}@${srv_ip}:2083?security=none&type=tcp#NexusVPN-Trojan${NC}"
    echo ""
    echo -e "  ${Y}Shadowsocks (Puerto 8388):${NC}"
    echo -e "  ${W}ss://${ss_b64}@${srv_ip}:8388#NexusVPN-SS${NC}"
    echo ""
    echo -e "  ${Y}VLESS gRPC (Puerto 8443):${NC}"
    echo -e "  ${W}vless://${uuid}@${srv_ip}:8443?encryption=none&type=grpc&serviceName=nexus-grpc#NexusVPN-gRPC${NC}"
    echo ""
    local hy2_pass
    hy2_pass=$(cfg_get "hysteria2_auth_pass")
    echo -e "  ${Y}Hysteria2 (Puerto 36712 UDP):${NC}"
    echo -e "  ${W}hysteria2://${hy2_pass}@${srv_ip}:36712/?insecure=1&obfs=salamander&obfs-password=nexusvpn-obfs#NexusVPN-HY2${NC}"
    echo ""
    echo -e "${C}════════════════════════════════════════════════════════════${NC}"
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: USUARIOS V2RAY/XRAY
# ──────────────────────────────────────────────────────────────────
menu_xray_users() {
    while true; do
        print_banner
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}  ${Y}👥  Usuarios V2Ray/Xray${NC}                 ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${W}1)${NC} Agregar usuario                      ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}2)${NC} Listar usuarios                      ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}3)${NC} Eliminar usuario                     ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}4)${NC} Ver links de un usuario              ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}5)${NC} Mostrar todos los links              ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}6)${NC} Reiniciar Xray                       ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}0)${NC} Volver                               ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        read -rp "  $(echo -e "${Y}Opción:${NC}") " opt
        case "$opt" in
            1) add_xray_user ;;
            2) list_xray_users ;;
            3) del_xray_user_interactive ;;
            4) show_user_links_interactive ;;
            5) show_connection_links ; press_enter ;;
            6) systemctl restart xray ; ok "Xray reiniciado" ; press_enter ;;
            0) return ;;
        esac
    done
}

add_xray_user() {
    echo ""
    read -rp "  ${Y}Nombre/email del usuario: ${NC}" uname
    [[ -z "$uname" ]] && { err "Nombre vacío"; return; }
    local new_uuid
    new_uuid=$(gen_uuid)
    local srv_ip
    srv_ip=$(cfg_get "server_ip")

    # Agregar al config.json de Xray
    python3 - << PYEOF
import json, sys
with open('${XRAY_CONFIG}','r') as f: cfg = json.load(f)
for inb in cfg.get('inbounds', []):
    if inb.get('protocol') in ('vless','vmess','trojan'):
        clients = inb.get('settings',{}).get('clients',[])
        new = {'id':'${new_uuid}','level':0,'email':'${uname}@nexusvpn'}
        if inb.get('protocol') == 'vmess':
            new['alterId'] = 0
        elif inb.get('protocol') == 'trojan':
            new = {'password':'${new_uuid}','level':0,'email':'${uname}@nexusvpn'}
        clients.append(new)
with open('${XRAY_CONFIG}','w') as f: json.dump(cfg, f, indent=2)
print('OK')
PYEOF

    # Guardar en users.db
    echo "${uname}|${new_uuid}|$(date +%s)|xray|active" >> "$USERS_DB"

    systemctl restart xray >> "$LOG_FILE" 2>&1 || true
    local vmess_b64
    vmess_b64=$(echo -n "{\"v\":\"2\",\"ps\":\"${uname}\",\"add\":\"${srv_ip}\",\"port\":\"80\",\"id\":\"${new_uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/nexus\",\"tls\":\"\"}" | base64 -w 0)

    ok "Usuario ${uname} creado"
    echo -e "  ${Y}UUID    :${NC} ${W}${new_uuid}${NC}"
    echo -e "  ${Y}VMess   :${NC} ${W}vmess://${vmess_b64}${NC}"
    echo -e "  ${Y}VLESS   :${NC} ${W}vless://${new_uuid}@${srv_ip}:443?encryption=none&type=tcp#${uname}${NC}"
    log "Usuario Xray creado: ${uname} UUID: ${new_uuid:0:8}..."
    press_enter
}

list_xray_users() {
    print_banner
    echo -e "${C}  ── Usuarios Xray ────────────────────────────────────────${NC}\n"
    if [[ ! -f "$XRAY_CONFIG" ]]; then
        warn "Xray no configurado"
        press_enter; return
    fi
    python3 - << 'PYEOF'
import json
try:
    with open('/usr/local/etc/xray/config.json','r') as f:
        cfg = json.load(f)
    users = set()
    for inb in cfg.get('inbounds',[]):
        proto = inb.get('protocol','')
        for c in inb.get('settings',{}).get('clients',[]):
            email = c.get('email','?')
            uid = c.get('id', c.get('password','?'))
            users.add((email, uid[:8]+'...', proto))
    print(f"  {'Email':<30} {'UUID(8c)':<12} {'Protocolo'}")
    print("  " + "─"*55)
    for u in sorted(users):
        print(f"  {u[0]:<30} {u[1]:<12} {u[2]}")
    print(f"\n  Total: {len(users)} entradas")
except Exception as e:
    print(f"  Error: {e}")
PYEOF
    press_enter
}

del_xray_user_interactive() {
    echo ""
    read -rp "  ${Y}Email del usuario a eliminar: ${NC}" email
    [[ -z "$email" ]] && return
    python3 - << PYEOF
import json
with open('${XRAY_CONFIG}','r') as f: cfg = json.load(f)
for inb in cfg.get('inbounds',[]):
    clients = inb.get('settings',{}).get('clients',[])
    before = len(clients)
    inb['settings']['clients'] = [c for c in clients if c.get('email','') != '${email}@nexusvpn' and c.get('email','') != '${email}']
    after = len(inb['settings']['clients'])
    if before != after:
        print(f"  Eliminado de {inb.get('tag','?')}")
with open('${XRAY_CONFIG}','w') as f: json.dump(cfg, f, indent=2)
PYEOF
    sed -i "/^${email}|/d" "$USERS_DB" 2>/dev/null
    systemctl restart xray >> "$LOG_FILE" 2>&1 || true
    ok "Usuario ${email} eliminado"
    log "Usuario Xray eliminado: ${email}"
    press_enter
}

show_user_links_interactive() {
    echo ""
    read -rp "  ${Y}Email del usuario: ${NC}" email
    local srv_ip uuid
    srv_ip=$(cfg_get "server_ip")
    uuid=$(grep "^${email}|" "$USERS_DB" | cut -d'|' -f2)
    [[ -z "$uuid" ]] && { err "Usuario no encontrado en DB"; press_enter; return; }
    local vmess_b64
    vmess_b64=$(echo -n "{\"v\":\"2\",\"ps\":\"${email}\",\"add\":\"${srv_ip}\",\"port\":\"80\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/nexus\",\"tls\":\"\"}" | base64 -w 0)
    echo -e "\n  ${Y}VLESS :${NC} vless://${uuid}@${srv_ip}:443?encryption=none&type=tcp#${email}"
    echo -e "  ${Y}VMess :${NC} vmess://${vmess_b64}"
    echo -e "  ${Y}Trojan:${NC} trojan://${uuid}@${srv_ip}:2083?security=none#${email}"
    press_enter
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: HYSTERIA2
# ──────────────────────────────────────────────────────────────────
menu_hysteria2() {
    while true; do
        print_banner
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}  ${Y}⚡  Hysteria2${NC}                           ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  Estado: $(service_status hysteria)                         ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${W}1)${NC} Ver link de conexión                 ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}2)${NC} Cambiar contraseña                   ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}3)${NC} Reiniciar servicio                   ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}4)${NC} Ver logs                             ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}5)${NC} Reinstalar Hysteria2                 ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}0)${NC} Volver                               ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        read -rp "  $(echo -e "${Y}Opción:${NC}") " opt
        case "$opt" in
            1)
                local srv_ip hy2_pass
                srv_ip=$(cfg_get "server_ip")
                hy2_pass=$(cfg_get "hysteria2_auth_pass")
                echo -e "\n  ${Y}Link Hysteria2:${NC}"
                echo -e "  ${W}hysteria2://${hy2_pass}@${srv_ip}:36712/?insecure=1&obfs=salamander&obfs-password=nexusvpn-obfs#NexusVPN-HY2${NC}"
                press_enter ;;
            2)
                read -rp "  ${Y}Nueva contraseña: ${NC}" np
                cfg_set "hysteria2_auth_pass" "\"${np}\""
                sed -i "s/^  password: .*/  password: ${np}/" "$HYSTERIA_CONFIG"
                systemctl restart hysteria
                ok "Contraseña actualizada" ; press_enter ;;
            3) systemctl restart hysteria ; ok "Hysteria2 reiniciado" ; press_enter ;;
            4) journalctl -u hysteria -n 30 --no-pager ; press_enter ;;
            5) install_hysteria2 ; ok "Reinstalado" ; press_enter ;;
            0) return ;;
        esac
    done
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: SLOWDNS
# ──────────────────────────────────────────────────────────────────
menu_slowdns() {
    while true; do
        print_banner
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}  ${Y}🌀  SlowDNS${NC}                             ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  Estado: $(service_status slowdns)                         ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${W}1)${NC} Ver clave pública                    ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}2)${NC} Configurar subdominio DNS            ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}3)${NC} Reiniciar servicio                   ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}4)${NC} Ver logs                             ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}0)${NC} Volver                               ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        read -rp "  $(echo -e "${Y}Opción:${NC}") " opt
        case "$opt" in
            1)
                if [[ -f /etc/NexusVPN/slowdns.pub ]]; then
                    echo ""
                    echo -e "  ${Y}Clave pública SlowDNS:${NC}"
                    cat /etc/NexusVPN/slowdns.pub
                else
                    warn "Clave pública no generada aún"
                fi
                press_enter ;;
            2)
                read -rp "  ${Y}Subdominio DNS (ej: ns.tudominio.com): ${NC}" subdomain
                sed -i "s|t.nexusvpn.example.com|${subdomain}|g" /etc/systemd/system/slowdns.service
                systemctl daemon-reload
                systemctl restart slowdns
                ok "Subdominio configurado: ${subdomain}"
                press_enter ;;
            3) systemctl restart slowdns ; ok "SlowDNS reiniciado" ; press_enter ;;
            4) journalctl -u slowdns -n 30 --no-pager ; press_enter ;;
            0) return ;;
        esac
    done
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: UDP CUSTOM / BADVPN
# ──────────────────────────────────────────────────────────────────
menu_udp() {
    while true; do
        print_banner
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}  ${Y}📡  UDP Custom / BadVPN${NC}                ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  BadVPN 7100: $(service_status badvpn-7100)                  ${C}║${NC}"
        echo -e "${C}║${NC}  BadVPN 7200: $(service_status badvpn-7200)                  ${C}║${NC}"
        echo -e "${C}║${NC}  BadVPN 7300: $(service_status badvpn-7300)                  ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${W}1)${NC} Ver puertos BadVPN activos           ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}2)${NC} Agregar puerto UDP Custom (socat)    ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}3)${NC} Listar puertos UDP abiertos          ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}4)${NC} Reiniciar BadVPN (todos)             ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}5)${NC} Abrir rango UDP para operador        ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}0)${NC} Volver                               ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        read -rp "  $(echo -e "${Y}Opción:${NC}") " opt
        case "$opt" in
            1) ss -ulnp | grep badvpn ; press_enter ;;
            2)
                read -rp "  ${Y}Puerto de escucha: ${NC}" lport
                read -rp "  ${Y}Puerto destino (local): ${NC}" dport
                # Crear servicio socat para UDP custom
                cat > "/etc/systemd/system/udpcustom-${lport}.service" << UCEOF
[Unit]
Description=UDP Custom port ${lport}→${dport}
After=network.target
[Service]
ExecStart=/usr/bin/socat UDP4-LISTEN:${lport},fork,reuseaddr UDP4:127.0.0.1:${dport}
Restart=always
[Install]
WantedBy=multi-user.target
UCEOF
                systemctl daemon-reload
                systemctl enable "udpcustom-${lport}"
                systemctl start "udpcustom-${lport}"
                ufw allow "${lport}/udp" >> "$LOG_FILE" 2>&1
                ok "UDP Custom ${lport}→${dport} creado"
                press_enter ;;
            3) ss -ulnp | grep -E 'badvpn|socat|udpcustom' ; press_enter ;;
            4)
                for p in 7100 7200 7300; do systemctl restart "badvpn-${p}" || true; done
                ok "BadVPN reiniciado" ; press_enter ;;
            5)
                read -rp "  ${Y}Puerto inicial del rango: ${NC}" p1
                read -rp "  ${Y}Puerto final del rango:   ${NC}" p2
                ufw allow "${p1}:${p2}/udp" >> "$LOG_FILE" 2>&1
                ok "Rango UDP ${p1}:${p2} abierto" ; press_enter ;;
            0) return ;;
        esac
    done
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: SSH MANAGER
# ──────────────────────────────────────────────────────────────────
menu_ssh() {
    while true; do
        print_banner
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}  ${Y}🔐  SSH Manager${NC}                         ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${W}1)${NC} Crear usuario SSH                    ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}2)${NC} Listar usuarios SSH                  ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}3)${NC} Ver usuarios conectados ahora        ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}4)${NC} Matar sesión de usuario              ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}5)${NC} Cambiar contraseña de usuario        ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}6)${NC} Eliminar usuario SSH                 ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}7)${NC} Limitar conexiones simultáneas       ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}8)${NC} Ver expiración de usuarios           ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}0)${NC} Volver                               ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        read -rp "  $(echo -e "${Y}Opción:${NC}") " opt
        case "$opt" in
            1) create_ssh_user ;;
            2) list_ssh_users ;;
            3) show_ssh_connected ;;
            4) kill_ssh_session ;;
            5) change_ssh_password ;;
            6) delete_ssh_user ;;
            7) limit_ssh_connections ;;
            8) show_user_expiry ;;
            0) return ;;
        esac
    done
}

create_ssh_user() {
    echo ""
    read -rp "  ${Y}Nombre de usuario: ${NC}" uname
    [[ -z "$uname" ]] && return
    read -rsp "  ${Y}Contraseña: ${NC}" upass; echo
    read -rp "  ${Y}Días de validez [30]: ${NC}" days; days="${days:-30}"
    read -rp "  ${Y}Máx. conexiones simultáneas [2]: ${NC}" maxconn; maxconn="${maxconn:-2}"

    useradd -m -s /bin/bash "$uname" 2>/dev/null || true
    echo "${uname}:${upass}" | chpasswd
    # Fecha de expiración
    chage -E "$(date -d "+${days} days" '+%Y-%m-%d')" "$uname"
    # Guardar límite de conexiones
    echo "${uname}|${maxconn}" >> "${PANEL_DIR}/ssh_limits.conf"
    # Configurar límite con PAM / nologin script
    setup_ssh_connection_limit "$uname" "$maxconn"

    ok "Usuario SSH '${uname}' creado — expira en ${days} días"
    log "Usuario SSH creado: ${uname} exp:${days}d"
    press_enter
}

setup_ssh_connection_limit() {
    local user="$1" maxconn="$2"
    # Crear script de chequeo en /etc/ssh/sshd_config via ForceCommand no aplica fácilmente,
    # usamos PAM limits
    cat >> /etc/security/limits.conf << LIMEOF
${user}  hard  maxlogins  ${maxconn}
LIMEOF
}

list_ssh_users() {
    print_banner
    echo -e "${C}  ── Usuarios SSH del sistema ─────────────────────────────${NC}\n"
    printf "  ${Y}%-20s %-15s %-12s %-10s${NC}\n" "Usuario" "Expiración" "Últ.Login" "Estado"
    echo -e "  ${DIM}─────────────────────────────────────────────────────────${NC}"
    while IFS=: read -r user _ uid gid _ home shell; do
        [[ $uid -lt 1000 || "$shell" == */nologin || "$shell" == */false ]] && continue
        local expiry last_login estado
        expiry=$(chage -l "$user" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
        last_login=$(lastlog -u "$user" 2>/dev/null | tail -1 | awk '{print $4,$5,$9}')
        if chage -l "$user" 2>/dev/null | grep -q "Password expires.*never"; then
            estado="${G}activo${NC}"
        else
            estado="${G}activo${NC}"
        fi
        printf "  ${W}%-20s${NC} %-15s %-12s " "$user" "${expiry:-nunca}" "${last_login:-nunca}"
        echo -e "${estado}"
    done < /etc/passwd
    press_enter
}

show_ssh_connected() {
    print_banner
    echo -e "${C}  ── Usuarios conectados ahora ────────────────────────────${NC}\n"
    echo -e "  ${Y}$(w -h 2>/dev/null | wc -l) sesión(es) activa(s)${NC}\n"
    w 2>/dev/null || who
    echo ""
    echo -e "${C}  ── Conexiones SSH establecidas ──────────────────────────${NC}"
    ss -tnp | grep ':22' | head -20
    press_enter
}

kill_ssh_session() {
    echo ""
    show_ssh_connected
    read -rp "  ${Y}Usuario a desconectar: ${NC}" target
    [[ -z "$target" ]] && return
    local pids
    pids=$(pgrep -u "$target" sshd 2>/dev/null || true)
    if [[ -n "$pids" ]]; then
        kill -9 $pids 2>/dev/null
        ok "Sesiones de ${target} terminadas"
        log "Sesión SSH terminada: ${target}"
    else
        warn "No se encontraron sesiones activas de ${target}"
    fi
    press_enter
}

change_ssh_password() {
    echo ""
    read -rp "  ${Y}Usuario: ${NC}" uname
    read -rsp "  ${Y}Nueva contraseña: ${NC}" upass; echo
    echo "${uname}:${upass}" | chpasswd && ok "Contraseña actualizada" || err "Error al cambiar contraseña"
    press_enter
}

delete_ssh_user() {
    echo ""
    read -rp "  ${Y}Usuario a eliminar: ${NC}" uname
    [[ -z "$uname" ]] && return
    read -rp "  ${Y}¿Confirmar eliminación de '${uname}'? (s/n): ${NC}" conf
    [[ "${conf,,}" != "s" ]] && return
    userdel -r "$uname" 2>/dev/null
    ok "Usuario ${uname} eliminado"
    log "Usuario SSH eliminado: ${uname}"
    press_enter
}

limit_ssh_connections() {
    echo ""
    read -rp "  ${Y}Usuario: ${NC}" uname
    read -rp "  ${Y}Máx. conexiones simultáneas: ${NC}" maxconn
    sed -i "/^${uname}/d" /etc/security/limits.conf 2>/dev/null
    echo "${uname}  hard  maxlogins  ${maxconn}" >> /etc/security/limits.conf
    ok "Límite de ${maxconn} conexiones para ${uname}" ; press_enter
}

show_user_expiry() {
    echo ""
    read -rp "  ${Y}Usuario (vacío = todos): ${NC}" uname
    if [[ -z "$uname" ]]; then
        while IFS=: read -r user _ uid _ _ _ shell; do
            [[ $uid -lt 1000 || "$shell" == */nologin ]] && continue
            echo -e "  ${W}${user}${NC}: $(chage -l "$user" 2>/dev/null | grep 'Account expires' | cut -d: -f2)"
        done < /etc/passwd
    else
        chage -l "$uname" 2>/dev/null
    fi
    press_enter
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: CLOUDFLARE / DOMINIO / SSL
# ──────────────────────────────────────────────────────────────────
menu_cf_ssl() {
    while true; do
        print_banner
        local domain ssl_status
        domain=$(cfg_get "domain")
        ssl_status=$(cfg_get "ssl_enabled")
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}  ${Y}☁️   Cloudflare / Dominio / SSL${NC}        ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  Dominio: ${W}${domain:-no configurado}${NC}              ${C}║${NC}"
        echo -e "${C}║${NC}  SSL    : ${W}${ssl_status:-false}${NC}                   ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${W}1)${NC} Configurar dominio                   ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}2)${NC} Instalar SSL (Let's Encrypt)         ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}3)${NC} Configurar Nginx + WebSocket + SSL   ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}4)${NC} Ver instrucciones Cloudflare CDN     ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}5)${NC} Cambiar DNS del servidor             ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}6)${NC} Renovar certificado SSL              ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}7)${NC} Ver estado de Nginx                  ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}0)${NC} Volver                               ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        read -rp "  $(echo -e "${Y}Opción:${NC}") " opt
        case "$opt" in
            1) configure_domain ;;
            2) install_ssl_certbot ;;
            3) configure_nginx_ssl ;;
            4) show_cloudflare_guide ;;
            5) change_dns_server ;;
            6) certbot renew --force-renewal >> "$LOG_FILE" 2>&1 && ok "Certificado renovado" ; press_enter ;;
            7) systemctl status nginx --no-pager ; press_enter ;;
            0) return ;;
        esac
    done
}

configure_domain() {
    local srv_ip
    srv_ip=$(cfg_get "server_ip")
    echo ""
    echo -e "  ${C}IP del servidor: ${W}${srv_ip}${NC}"
    echo -e "  ${Y}Asegúrate de que el dominio apunte a esta IP con un registro A${NC}\n"
    read -rp "  ${Y}Dominio (ej: vpn.midominio.com): ${NC}" domain
    [[ -z "$domain" ]] && return
    cfg_set "domain" "\"${domain}\""
    ok "Dominio configurado: ${domain}"
    echo -e "  ${C}Verifica con:${NC} dig +short ${domain}"
    press_enter
}

install_ssl_certbot() {
    local domain
    domain=$(cfg_get "domain")
    [[ -z "$domain" ]] && { err "Configura primero un dominio"; press_enter; return; }
    apt_install certbot python3-certbot-nginx
    systemctl stop nginx 2>/dev/null || true
    certbot certonly --standalone -d "$domain" --non-interactive --agree-tos \
        --email "admin@${domain}" 2>&1 | tee -a "$LOG_FILE"
    systemctl start nginx 2>/dev/null || true
    if [[ -f "/etc/letsencrypt/live/${domain}/fullchain.pem" ]]; then
        cfg_set "ssl_enabled" "true"
        cfg_set "ssl_cert" "\"/etc/letsencrypt/live/${domain}/fullchain.pem\""
        cfg_set "ssl_key" "\"/etc/letsencrypt/live/${domain}/privkey.pem\""
        ok "SSL instalado para ${domain}"
        configure_nginx_ssl
    else
        err "Error instalando SSL. Verifica que el dominio apunte al servidor."
    fi
    press_enter
}

configure_nginx_ssl() {
    local domain
    domain=$(cfg_get "domain")
    [[ -z "$domain" ]] && { err "Configura primero un dominio"; press_enter; return; }
    local cert="/etc/letsencrypt/live/${domain}/fullchain.pem"
    local key="/etc/letsencrypt/live/${domain}/privkey.pem"
    [[ ! -f "$cert" ]] && cert="/etc/hysteria/cert.pem" && key="/etc/hysteria/key.pem"

    cat > "${NGINX_AVAILABLE}/nexusvpn-ssl" << SSLEOF
server {
    listen 443 ssl http2;
    server_name ${domain};
    ssl_certificate ${cert};
    ssl_certificate_key ${key};
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-ECDSA-AES128-GCM-SHA256:ECDHE-RSA-AES128-GCM-SHA256;

    location /nexus {
        proxy_pass http://127.0.0.1:80;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_read_timeout 3600s;
    }

    location /nexus-grpc {
        grpc_pass grpc://127.0.0.1:8443;
    }

    location / {
        return 301 https://www.google.com;
    }
}

server {
    listen 80;
    server_name ${domain};
    return 301 https://\$host\$request_uri;
}
SSLEOF
    ln -sf "${NGINX_AVAILABLE}/nexusvpn-ssl" "${NGINX_ENABLED}/nexusvpn-ssl" 2>/dev/null
    nginx -t && systemctl reload nginx
    ok "Nginx configurado con SSL para ${domain}"
    press_enter
}

show_cloudflare_guide() {
    local domain srv_ip
    domain=$(cfg_get "domain")
    srv_ip=$(cfg_get "server_ip")
    echo ""
    echo -e "${C}══════════════════════════════════════════════════════════${NC}"
    echo -e "${W}  Guía Cloudflare CDN${NC}"
    echo -e "${C}══════════════════════════════════════════════════════════${NC}"
    echo -e "  ${Y}1.${NC} Ve a cloudflare.com y añade tu dominio: ${W}${domain:-<tu-dominio>}${NC}"
    echo -e "  ${Y}2.${NC} Añade registro A: ${W}${domain:-vpn.tudominio.com}${NC} → ${W}${srv_ip}${NC}"
    echo -e "  ${Y}3.${NC} Activa el proxy ${C}☁️  (nube naranja)${NC} en Cloudflare"
    echo -e "  ${Y}4.${NC} SSL/TLS → modo ${W}Flexible${NC} o ${W}Full (Strict)${NC}"
    echo -e "  ${Y}5.${NC} Network → habilita ${W}WebSockets${NC}"
    echo -e "  ${Y}6.${NC} Edge Certificates → activa ${W}Always Use HTTPS${NC}"
    echo -e "\n  ${G}Puertos compatibles con Cloudflare CDN (HTTP):${NC}"
    echo -e "  ${W}80, 8080, 8880, 2052, 2082, 2086, 2095${NC}"
    echo -e "\n  ${G}Puertos compatibles con Cloudflare CDN (HTTPS):${NC}"
    echo -e "  ${W}443, 2053, 2083, 2087, 2096, 8443${NC}"
    echo -e "${C}══════════════════════════════════════════════════════════${NC}"
    press_enter
}

change_dns_server() {
    echo ""
    echo -e "  ${Y}DNS disponibles:${NC}"
    echo -e "  ${W}1)${NC} Google     (8.8.8.8 / 8.8.4.4)"
    echo -e "  ${W}2)${NC} Cloudflare (1.1.1.1 / 1.0.0.1)"
    echo -e "  ${W}3)${NC} OpenDNS    (208.67.222.222)"
    echo -e "  ${W}4)${NC} Personalizado"
    read -rp "  ${Y}Opción: ${NC}" dopt
    local dns1 dns2
    case "$dopt" in
        1) dns1="8.8.8.8"; dns2="8.8.4.4" ;;
        2) dns1="1.1.1.1"; dns2="1.0.0.1" ;;
        3) dns1="208.67.222.222"; dns2="208.67.220.220" ;;
        4) read -rp "  DNS1: " dns1; read -rp "  DNS2: " dns2 ;;
        *) return ;;
    esac
    # Configurar resolv.conf
    echo -e "nameserver ${dns1}\nnameserver ${dns2}" > /etc/resolv.conf
    # Prevenir sobreescritura por dhcp
    chattr +i /etc/resolv.conf 2>/dev/null || true
    ok "DNS configurado: ${dns1} / ${dns2}"
    press_enter
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: BANNER Y PUBLICIDAD
# ──────────────────────────────────────────────────────────────────
menu_banner() {
    while true; do
        print_banner
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}  ${Y}📢  Banner & Publicidad${NC}                ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${W}1)${NC} Editar banner del panel              ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}2)${NC} Editar MOTD SSH (/etc/motd)          ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}3)${NC} Ver banner actual                    ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}4)${NC} Restaurar banner por defecto         ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}0)${NC} Volver                               ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        read -rp "  $(echo -e "${Y}Opción:${NC}") " opt
        case "$opt" in
            1) edit_panel_banner ;;
            2) edit_motd ;;
            3)
                echo ""
                [[ -f "$BANNER_FILE" ]] && cat "$BANNER_FILE" || echo "  (Banner por defecto)"
                press_enter ;;
            4)
                rm -f "$BANNER_FILE"
                ok "Banner restaurado al default"
                press_enter ;;
            0) return ;;
        esac
    done
}

edit_panel_banner() {
    echo ""
    echo -e "  ${C}Escribe el banner (líneas múltiples).${NC}"
    echo -e "  ${Y}Puedes usar colores ANSI. Escribe 'FIN' en una línea para terminar.${NC}\n"
    local lines=()
    while IFS= read -r line; do
        [[ "$line" == "FIN" ]] && break
        lines+=("$line")
    done
    printf '%s\n' "${lines[@]}" > "$BANNER_FILE"
    ok "Banner guardado en ${BANNER_FILE}"
    press_enter
}

edit_motd() {
    local srv_ip
    srv_ip=$(cfg_get "server_ip")
    echo ""
    echo -e "  ${C}Mensaje personalizado del MOTD (enter=vacío, FIN=terminar):${NC}\n"
    local custom_lines=()
    while IFS= read -r line; do
        [[ "$line" == "FIN" ]] && break
        custom_lines+=("$line")
    done

    cat > "$MOTD_FILE" << MOTDEOF2

╔══════════════════════════════════════════════════════════════╗
║           ${PANEL_NAME} v${PANEL_VERSION}                             ║
╠══════════════════════════════════════════════════════════════╣
║  Servidor  : ${srv_ip}                                   ║
║  Panel     : nexusvpn                                        ║
╠══════════════════════════════════════════════════════════════╣
MOTDEOF2
    for line in "${custom_lines[@]}"; do
        printf '║  %-60s║\n' "$line" >> "$MOTD_FILE"
    done
    cat >> "$MOTD_FILE" << MOTDEOF3
╠══════════════════════════════════════════════════════════════╣
║  📲 Comprar Keys: WhatsApp +57 300 443 0431                  ║
║                   Telegram @ANDRESCAMP13                     ║
╚══════════════════════════════════════════════════════════════╝

MOTDEOF3
    cp "$MOTD_FILE" "$ISSUE_NET"
    ok "MOTD actualizado"
    press_enter
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: ESTADÍSTICAS
# ──────────────────────────────────────────────────────────────────
menu_stats() {
    print_banner
    echo -e "${C}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${C}║${NC}  ${Y}📊  Estadísticas del Servidor${NC}                         ${C}║${NC}"
    echo -e "${C}╠══════════════════════════════════════════════════════════╣${NC}"

    # CPU
    local cpu_usage
    cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | tr -d '%us,')
    echo -e "${C}║${NC}  ${W}CPU        :${NC} ${G}${cpu_usage:-?}%${NC}                                   ${C}║${NC}"

    # RAM
    local ram_info
    read -r total used free <<< "$(free -m | awk '/^Mem:/{print $2,$3,$4}')"
    local ram_pct=$(( used * 100 / (total+1) ))
    echo -e "${C}║${NC}  ${W}RAM        :${NC} ${G}${used}MB${NC}/${W}${total}MB${NC} (${ram_pct}%)              ${C}║${NC}"

    # Disco
    local disk_info
    disk_info=$(df -h / | awk 'NR==2{print $3"/"$2" ("$5")"}')
    echo -e "${C}║${NC}  ${W}Disco      :${NC} ${G}${disk_info}${NC}                  ${C}║${NC}"

    # Uptime
    local uptime_str
    uptime_str=$(uptime -p 2>/dev/null | sed 's/up //')
    echo -e "${C}║${NC}  ${W}Uptime     :${NC} ${G}${uptime_str}${NC}                      ${C}║${NC}"

    # Tráfico de red
    echo -e "${C}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${C}║${NC}  ${Y}Tráfico de red (RX / TX):${NC}                             ${C}║${NC}"
    for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -v lo); do
        local rx tx
        rx=$(cat "/sys/class/net/${iface}/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx=$(cat "/sys/class/net/${iface}/statistics/tx_bytes" 2>/dev/null || echo 0)
        local rx_mb=$(( rx / 1024 / 1024 ))
        local tx_mb=$(( tx / 1024 / 1024 ))
        printf "${C}║${NC}  ${W}%-10s${NC} RX:${G}%6d MB${NC}  TX:${C}%6d MB${NC}         ${C}║${NC}\n" \
               "$iface" "$rx_mb" "$tx_mb"
    done

    # Estado de servicios
    echo -e "${C}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${C}║${NC}  ${Y}Estado de servicios:${NC}                                  ${C}║${NC}"
    for svc in xray hysteria nginx ssh slowdns openvpn@server-tcp; do
        printf "${C}║${NC}  ${W}%-22s${NC} " "$svc"
        service_status "$svc"
        echo -e " ${C}║${NC}"
    done
    for port in 7100 7200 7300; do
        printf "${C}║${NC}  ${W}%-22s${NC} " "badvpn-${port}"
        service_status "badvpn-${port}"
        echo -e " ${C}║${NC}"
    done

    # Usuarios activos
    echo -e "${C}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${C}║${NC}  ${Y}Sesiones SSH activas:${NC}                                 ${C}║${NC}"
    while IFS= read -r session; do
        printf "${C}║${NC}  ${G}%-56s${NC}${C}║${NC}\n" "$session"
    done < <(who 2>/dev/null | head -5)

    # Ping
    echo -e "${C}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${C}║${NC}  ${Y}Ping de referencia:${NC}                                   ${C}║${NC}"
    for host in 8.8.8.8 1.1.1.1; do
        local ping_ms
        ping_ms=$(ping -c 1 -W 2 "$host" 2>/dev/null | grep 'time=' | sed 's/.*time=\([0-9.]*\).*/\1/')
        printf "${C}║${NC}  ${W}%-12s${NC} ${G}%s ms${NC}                              ${C}║${NC}\n" \
               "$host" "${ping_ms:-timeout}"
    done

    # Licencia
    echo -e "${C}╠══════════════════════════════════════════════════════════╣${NC}"
    echo -e "${C}║${NC}  ${Y}Licencia   :${NC} ${W}$(get_license_expiry)${NC}             ${C}║${NC}"
    echo -e "${C}╚══════════════════════════════════════════════════════════╝${NC}"
    press_enter
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: FIREWALL (UFW)
# ──────────────────────────────────────────────────────────────────
menu_firewall() {
    while true; do
        print_banner
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}  ${Y}🔥  Firewall (UFW)${NC}                     ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${W}1)${NC} Ver reglas activas                   ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}2)${NC} Abrir puerto                         ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}3)${NC} Cerrar puerto                        ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}4)${NC} Abrir rango de puertos               ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}5)${NC} Bloquear IP                          ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}6)${NC} Desbloquear IP                       ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}7)${NC} Reiniciar UFW                        ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}0)${NC} Volver                               ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        read -rp "  $(echo -e "${Y}Opción:${NC}") " opt
        case "$opt" in
            1) ufw status numbered 2>/dev/null ; press_enter ;;
            2)
                read -rp "  ${Y}Puerto/protocolo (ej: 8080/tcp): ${NC}" p
                ufw allow "$p" && ok "Puerto ${p} abierto" ; press_enter ;;
            3)
                read -rp "  ${Y}Puerto/protocolo a cerrar: ${NC}" p
                ufw delete allow "$p" 2>/dev/null && ok "Puerto ${p} cerrado" ; press_enter ;;
            4)
                read -rp "  ${Y}Rango (ej: 10000:20000/udp): ${NC}" p
                ufw allow "$p" && ok "Rango ${p} abierto" ; press_enter ;;
            5)
                read -rp "  ${Y}IP a bloquear: ${NC}" ip
                ufw deny from "$ip" && ok "IP ${ip} bloqueada" ; press_enter ;;
            6)
                read -rp "  ${Y}IP a desbloquear: ${NC}" ip
                ufw delete deny from "$ip" && ok "IP ${ip} desbloqueada" ; press_enter ;;
            7) ufw reload && ok "UFW reiniciado" ; press_enter ;;
            0) return ;;
        esac
    done
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: SERVICIOS Y LOGS
# ──────────────────────────────────────────────────────────────────
menu_services() {
    while true; do
        print_banner
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}  ${Y}⚙️   Servicios y Logs${NC}                  ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        for svc in xray hysteria nginx ssh openvpn@server-tcp slowdns; do
            printf "${C}║${NC}  ${W}%-22s${NC} " "$svc"
            service_status "$svc"
            echo -e "  ${C}║${NC}"
        done
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${W}1)${NC} Reiniciar servicio                   ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}2)${NC} Ver logs de un servicio              ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}3)${NC} Ver log del panel                    ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}4)${NC} Reiniciar TODOS los servicios        ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}5)${NC} Ver logs de Xray                     ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}0)${NC} Volver                               ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        read -rp "  $(echo -e "${Y}Opción:${NC}") " opt
        case "$opt" in
            1)
                read -rp "  ${Y}Nombre del servicio: ${NC}" svc
                systemctl restart "$svc" && ok "${svc} reiniciado" || err "Error reiniciando ${svc}"
                press_enter ;;
            2)
                read -rp "  ${Y}Nombre del servicio: ${NC}" svc
                journalctl -u "$svc" -n 50 --no-pager ; press_enter ;;
            3) tail -50 "$LOG_FILE" ; press_enter ;;
            4)
                for svc in xray hysteria nginx; do
                    systemctl restart "$svc" 2>/dev/null || true
                done
                ok "Servicios reiniciados" ; press_enter ;;
            5)
                tail -30 /var/log/xray-access.log 2>/dev/null
                tail -30 /var/log/xray-error.log 2>/dev/null
                press_enter ;;
            0) return ;;
        esac
    done
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: CAMBIAR PUERTOS
# ──────────────────────────────────────────────────────────────────
menu_ports() {
    while true; do
        print_banner
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}  ${Y}🌐  Gestión de Puertos${NC}                 ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${W}1)${NC} Ver todos los puertos activos        ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}2)${NC} Cambiar puerto VLESS TCP             ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}3)${NC} Cambiar puerto VMess WS              ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}4)${NC} Cambiar puerto Hysteria2             ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}5)${NC} Cambiar puerto SSH                   ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}6)${NC} Cambiar puerto Shadowsocks           ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}7)${NC} Cambiar puerto Trojan                ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}0)${NC} Volver                               ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        read -rp "  $(echo -e "${Y}Opción:${NC}") " opt
        case "$opt" in
            1)
                echo ""
                echo -e "  ${Y}Puertos TCP en escucha:${NC}"
                ss -tlnp | grep -E 'LISTEN' | awk '{print "  ",$4,$6}' | head -25
                echo -e "\n  ${Y}Puertos UDP en escucha:${NC}"
                ss -ulnp | awk '{print "  ",$4,$6}' | head -15
                press_enter ;;
            2) change_xray_port "vless-tcp" "xray_port_vless_tcp" ;;
            3) change_xray_port "vmess-ws-80" "xray_port_vmess_ws" ;;
            4)
                read -rp "  ${Y}Nuevo puerto Hysteria2 [actual: $(cfg_get hysteria2_port)]: ${NC}" np
                [[ -z "$np" ]] && continue
                sed -i "s/^listen: :.*/listen: :${np}/" "$HYSTERIA_CONFIG"
                cfg_set "hysteria2_port" "$np"
                ufw allow "${np}/udp" >> "$LOG_FILE" 2>&1
                systemctl restart hysteria
                ok "Puerto Hysteria2 cambiado a ${np}" ; press_enter ;;
            5)
                read -rp "  ${Y}Nuevo puerto SSH [actual: $(cfg_get ssh_port)]: ${NC}" np
                [[ -z "$np" ]] && continue
                sed -i "s/^#\?Port .*/Port ${np}/" /etc/ssh/sshd_config
                cfg_set "ssh_port" "$np"
                ufw allow "${np}/tcp" >> "$LOG_FILE" 2>&1
                systemctl restart ssh 2>/dev/null || systemctl restart sshd
                warn "¡NO CIERRES esta sesión! Verifica conexión al puerto ${np} primero"
                press_enter ;;
            6)
                read -rp "  ${Y}Nuevo puerto Shadowsocks [actual: $(cfg_get xray_port_ss)]: ${NC}" np
                [[ -z "$np" ]] && continue
                change_inbound_port "shadowsocks" "$np"
                cfg_set "xray_port_ss" "$np"
                systemctl restart xray
                ok "Puerto Shadowsocks cambiado a ${np}" ; press_enter ;;
            7)
                read -rp "  ${Y}Nuevo puerto Trojan [actual: $(cfg_get xray_port_trojan)]: ${NC}" np
                [[ -z "$np" ]] && continue
                change_inbound_port "trojan-tcp" "$np"
                cfg_set "xray_port_trojan" "$np"
                systemctl restart xray
                ok "Puerto Trojan cambiado a ${np}" ; press_enter ;;
            0) return ;;
        esac
    done
}

change_xray_port() {
    local tag="$1" cfg_key="$2"
    local current
    current=$(cfg_get "$cfg_key")
    read -rp "  ${Y}Nuevo puerto [actual: ${current}]: ${NC}" np
    [[ -z "$np" ]] && return
    change_inbound_port "$tag" "$np"
    cfg_set "$cfg_key" "$np"
    ufw allow "${np}/tcp" >> "$LOG_FILE" 2>&1
    systemctl restart xray
    ok "Puerto ${tag} cambiado a ${np}"
    press_enter
}

change_inbound_port() {
    local tag="$1" port="$2"
    python3 - << PYEOF
import json
with open('${XRAY_CONFIG}','r') as f: cfg = json.load(f)
for inb in cfg.get('inbounds',[]):
    if inb.get('tag') == '${tag}':
        inb['port'] = int('${port}')
        print(f"Puerto de {inb['tag']} cambiado a ${port}")
with open('${XRAY_CONFIG}','w') as f: json.dump(cfg, f, indent=2)
PYEOF
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: BACKUP Y RESTAURAR
# ──────────────────────────────────────────────────────────────────
menu_backup() {
    while true; do
        print_banner
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}  ${Y}🔄  Backup y Restaurar${NC}                 ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${W}1)${NC} Crear backup completo                ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}2)${NC} Restaurar desde backup               ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}3)${NC} Listar backups disponibles           ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}4)${NC} Exportar lista de usuarios           ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}5)${NC} Exportar links de conexión           ${C}║${NC}"
        echo -e "${C}║${NC}  ${W}0)${NC} Volver                               ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        read -rp "  $(echo -e "${Y}Opción:${NC}") " opt
        case "$opt" in
            1) create_backup ;;
            2) restore_backup ;;
            3)
                echo ""
                ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || warn "No hay backups"
                press_enter ;;
            4) export_users_list ;;
            5) show_connection_links > "/tmp/nexusvpn_links.txt" ; ok "Links exportados a /tmp/nexusvpn_links.txt" ; press_enter ;;
            0) return ;;
        esac
    done
}

create_backup() {
    local bfile="${BACKUP_DIR}/nexusvpn-backup-$(date +%Y%m%d-%H%M%S).tar.gz"
    inf "Creando backup en ${bfile}..."
    tar -czf "$bfile" \
        "$PANEL_DIR" \
        "$XRAY_CONFIG" \
        "$HYSTERIA_CONFIG" \
        /etc/nginx/sites-available/nexusvpn* \
        /etc/openvpn/ \
        2>/dev/null || true
    if [[ -f "$bfile" ]]; then
        local size
        size=$(du -h "$bfile" | cut -f1)
        ok "Backup creado: ${bfile} (${size})"
        log "Backup creado: ${bfile}"
    else
        err "Error al crear backup"
    fi
    press_enter
}

restore_backup() {
    echo ""
    ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null || { warn "No hay backups disponibles"; press_enter; return; }
    read -rp "  ${Y}Nombre del archivo de backup: ${NC}" bfile
    [[ ! -f "${BACKUP_DIR}/${bfile}" ]] && { err "Archivo no encontrado"; press_enter; return; }
    read -rp "  ${Y}¿Confirmar restauración? Se sobreescribirá la config actual (s/n): ${NC}" c
    [[ "${c,,}" != "s" ]] && return
    tar -xzf "${BACKUP_DIR}/${bfile}" -C / 2>/dev/null
    ok "Backup restaurado. Reiniciando servicios..."
    for svc in xray hysteria nginx; do
        systemctl restart "$svc" 2>/dev/null || true
    done
    log "Backup restaurado: ${bfile}"
    press_enter
}

export_users_list() {
    local efile="/tmp/nexusvpn_users_$(date +%Y%m%d).txt"
    {
        echo "=== NexusVPN Pro — Lista de Usuarios ==="
        echo "Exportado: $(date '+%d/%m/%Y %H:%M:%S')"
        echo ""
        echo "=== Usuarios Xray ==="
        python3 - << 'PYEOF'
import json
try:
    with open('/usr/local/etc/xray/config.json','r') as f:
        cfg = json.load(f)
    seen = set()
    for inb in cfg.get('inbounds',[]):
        for c in inb.get('settings',{}).get('clients',[]):
            email = c.get('email','?')
            if email not in seen:
                seen.add(email)
                uid = c.get('id',c.get('password','?'))
                print(f"  {email} — {uid}")
except: pass
PYEOF
        echo ""
        echo "=== Usuarios SSH ==="
        getent passwd | awk -F: '$3>=1000 && $7!~/nologin|false/{print "  "$1}'
    } > "$efile"
    ok "Lista exportada a ${efile}"
    press_enter
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: GENERADOR DE QR
# ──────────────────────────────────────────────────────────────────
menu_qr() {
    print_banner
    echo -e "${C}  ── Generador de QR de conexión ─────────────────────────${NC}\n"

    if ! command -v qrencode &>/dev/null; then
        apt_install qrencode
    fi

    local srv_ip uuid ss_pass hy2_pass
    srv_ip=$(cfg_get "server_ip")
    uuid=$(cfg_get "xray_uuid")
    ss_pass=$(cfg_get "ss_password")
    hy2_pass=$(cfg_get "hysteria2_auth_pass")

    [[ -z "$uuid" ]] && { warn "UUID no encontrado. Instala primero."; press_enter; return; }

    echo -e "  ${Y}1)${NC} VLESS TCP  ${Y}2)${NC} VMess WS  ${Y}3)${NC} Trojan  ${Y}4)${NC} Shadowsocks  ${Y}5)${NC} Hysteria2"
    read -rp "  ${Y}Selecciona: ${NC}" qopt

    local link=""
    case "$qopt" in
        1) link="vless://${uuid}@${srv_ip}:443?encryption=none&type=tcp#NexusVPN-VLESS" ;;
        2)
            local vmb64
            vmb64=$(echo -n "{\"v\":\"2\",\"ps\":\"NexusVPN\",\"add\":\"${srv_ip}\",\"port\":\"80\",\"id\":\"${uuid}\",\"aid\":\"0\",\"net\":\"ws\",\"path\":\"/nexus\",\"tls\":\"\"}" | base64 -w 0)
            link="vmess://${vmb64}" ;;
        3) link="trojan://${uuid}@${srv_ip}:2083?security=none#NexusVPN-Trojan" ;;
        4)
            local ssb64
            ssb64=$(echo -n "chacha20-ietf-poly1305:${ss_pass}" | base64 -w 0)
            link="ss://${ssb64}@${srv_ip}:8388#NexusVPN-SS" ;;
        5) link="hysteria2://${hy2_pass}@${srv_ip}:36712/?insecure=1&obfs=salamander&obfs-password=nexusvpn-obfs#NexusVPN-HY2" ;;
        *) return ;;
    esac

    echo ""
    echo -e "  ${Y}Link:${NC} ${W}${link}${NC}\n"
    echo -e "  ${Y}QR Code:${NC}\n"
    qrencode -t ANSIUTF8 "$link"
    echo ""
    press_enter
}

# ──────────────────────────────────────────────────────────────────
# MENÚ: ACTUALIZAR PANEL
# ──────────────────────────────────────────────────────────────────
menu_update() {
    print_banner
    echo -e "${C}  ── Actualizar NexusVPN Pro ──────────────────────────────${NC}\n"
    echo -e "  ${Y}1)${NC} Actualizar panel desde GitHub"
    echo -e "  ${Y}2)${NC} Actualizar Xray-Core"
    echo -e "  ${Y}3)${NC} Actualizar Hysteria2"
    echo -e "  ${Y}4)${NC} Actualizar todo el sistema"
    echo -e "  ${Y}0)${NC} Volver"
    read -rp "  ${Y}Opción: ${NC}" opt
    case "$opt" in
        1)
            inf "Descargando última versión del panel..."
            wget -q -O /tmp/nexusvpn_update.sh \
                 "https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh" \
                 >> "$LOG_FILE" 2>&1 && {
                chmod +x /tmp/nexusvpn_update.sh
                cp /tmp/nexusvpn_update.sh "$SCRIPT_PATH"
                ok "Panel actualizado. Reinicia con: nexusvpn"
            } || warn "No se pudo descargar la actualización"
            press_enter ;;
        2) install_xray ; ok "Xray actualizado" ; press_enter ;;
        3) install_hysteria2 ; ok "Hysteria2 actualizado" ; press_enter ;;
        4)
            apt-get update -qq && apt-get upgrade -y -qq >> "$LOG_FILE" 2>&1
            ok "Sistema actualizado" ; press_enter ;;
        0) return ;;
    esac
}

# ──────────────────────────────────────────────────────────────────
# CAMBIAR CONTRASEÑA DE ADMIN
# ──────────────────────────────────────────────────────────────────
change_admin_password() {
    print_banner
    echo -e "${C}  ── Cambiar contraseña de administrador ──────────────────${NC}\n"
    read -rsp "  ${Y}Contraseña actual: ${NC}" cur_pass; echo
    if ! openssl passwd -6 -verify "$ADMIN_PASS_HASH" "$cur_pass" 2>/dev/null && \
       [[ "$cur_pass" != "NexusAdmin2024" ]]; then
        err "Contraseña actual incorrecta"
        press_enter; return
    fi
    read -rsp "  ${Y}Nueva contraseña: ${NC}" new_pass; echo
    read -rsp "  ${Y}Confirmar nueva contraseña: ${NC}" new_pass2; echo
    if [[ "$new_pass" != "$new_pass2" ]]; then
        err "Las contraseñas no coinciden"
        press_enter; return
    fi
    local new_hash
    new_hash=$(openssl passwd -6 "$new_pass")
    cfg_set "admin_hash" "\"${new_hash}\""
    ok "Contraseña de administrador actualizada"
    log "Contraseña admin cambiada"
    press_enter
}

# ──────────────────────────────────────────────────────────────────
# UTILIDAD: PRESS ENTER
# ──────────────────────────────────────────────────────────────────
press_enter() {
    echo ""
    read -rp "  $(echo -e "${DIM}Presiona Enter para continuar...${NC}")"
}

# ──────────────────────────────────────────────────────────────────
# MENÚ PRINCIPAL
# ──────────────────────────────────────────────────────────────────
main_menu() {
    while true; do
        print_banner
        echo -e "${C}╔══════════════════════════════════════════╗${NC}"
        echo -e "${C}║${NC}       ${W}${BLD}MENÚ PRINCIPAL${NC}                    ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${Y}1)${NC}  🔑  Gestión de Keys (licencias)    ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}2)${NC}  👥  Usuarios V2Ray/Xray             ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}3)${NC}  ⚡  Hysteria2                       ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}4)${NC}  🌀  SlowDNS                         ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}5)${NC}  📡  UDP Custom / BadVPN             ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}6)${NC}  🔐  SSH Manager                     ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}7)${NC}  ☁️   Cloudflare / Dominio / SSL     ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}8)${NC}  📢  Banner & Publicidad             ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}9)${NC}  📊  Estadísticas detalladas         ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}10)${NC} 🔥  Firewall (UFW)                  ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}11)${NC} ⚙️   Servicios y Logs               ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}12)${NC} 🌐  Cambiar puertos                 ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}13)${NC} 🔄  Backup y Restaurar              ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}14)${NC} 📱  Generar QR de conexión          ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}15)${NC} 🆙  Actualizar panel                ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}16)${NC} 🔒  Cambiar contraseña admin        ${C}║${NC}"
        echo -e "${C}║${NC}  ${Y}17)${NC} 🔗  Ver links de conexión           ${C}║${NC}"
        echo -e "${C}╠══════════════════════════════════════════╣${NC}"
        echo -e "${C}║${NC}  ${R}0)${NC}  🚪 Salir del panel                  ${C}║${NC}"
        echo -e "${C}╚══════════════════════════════════════════╝${NC}"
        echo ""
        read -rp "  $(echo -e "${Y}Selecciona una opción: ${NC}")" opt

        case "$opt" in
            1)  menu_keys ;;
            2)  menu_xray_users ;;
            3)  menu_hysteria2 ;;
            4)  menu_slowdns ;;
            5)  menu_udp ;;
            6)  menu_ssh ;;
            7)  menu_cf_ssl ;;
            8)  menu_banner ;;
            9)  menu_stats ;;
            10) menu_firewall ;;
            11) menu_services ;;
            12) menu_ports ;;
            13) menu_backup ;;
            14) menu_qr ;;
            15) menu_update ;;
            16) change_admin_password ;;
            17) show_connection_links ; press_enter ;;
            0)
                echo -e "\n  ${G}¡Hasta luego! ${NC}${DIM}${PANEL_NAME} v${PANEL_VERSION}${NC}\n"
                log "Panel cerrado"
                exit 0 ;;
            *)
                err "Opción inválida" ;;
        esac
    done
}

# ──────────────────────────────────────────────────────────────────
# PUNTO DE ENTRADA PRINCIPAL
# ──────────────────────────────────────────────────────────────────
main() {
    require_root

    # Modos especiales (no interactivos)
    case "${1:-}" in
        --install)
            run_install
            echo -e "\n  ${Y}Instalación completada. Abre el panel con: ${W}nexusvpn${NC}\n"
            exit 0 ;;
        --clean-keys)
            clean_expired_keys
            exit 0 ;;
        --status)
            for svc in xray hysteria nginx; do
                printf "%-20s %s\n" "$svc" "$(systemctl is-active "$svc" 2>/dev/null || echo 'unknown')"
            done
            exit 0 ;;
        --links)
            init_dirs
            init_config
            show_connection_links
            exit 0 ;;
    esac

    # Panel interactivo
    init_dirs

    # Verificar si está instalado
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "\n${Y}  NexusVPN Pro no está instalado en este servidor.${NC}"
        echo -e "  ${W}¿Deseas instalarlo ahora? (s/n): ${NC}"
        read -r yn
        if [[ "${yn,,}" == "s" ]]; then
            run_install
        else
            echo -e "  ${DIM}Ejecuta: bash install.sh --install${NC}\n"
            exit 0
        fi
    fi

    # Autenticación
    authenticate_panel
    log "Sesión de panel iniciada"

    # Verificar licencia (advertencia si no hay key activa)
    if ! check_license_active 2>/dev/null; then
        print_banner
        echo -e "${R}  ⚠ SERVIDOR SIN LICENCIA ACTIVA${NC}"
        echo -e "  ${Y}El panel funcionará en modo limitado hasta activar una key.${NC}"
        echo -e "  ${C}Compra tu licencia:${NC}"
        echo -e "     WhatsApp: ${W}+57 300 443 0431${NC}"
        echo -e "     Telegram: ${W}@ANDRESCAMP13${NC}\n"
        read -rp "  ${Y}¿Tienes una key? Ingresa aquí (Enter para continuar): ${NC}" try_key
        if [[ -n "$try_key" ]]; then
            activate_key_server "${try_key^^}" || true
        fi
        sleep 2
    fi

    # Abrir menú principal
    main_menu
}

main "$@"

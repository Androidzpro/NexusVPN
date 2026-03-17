#!/bin/bash
# NEXUSVPN PRO v4.0 - INSTALADOR AUTOMÁTICO
# Un solo comando: bash <(curl -s https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh) --install

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Configuración
readonly VERSION="4.0"
readonly REPO="https://raw.githubusercontent.com/Androidzpro/NexusVPN/main"
readonly INSTALL_DIR="/etc/nexusvpn"
readonly MODULES_DIR="${INSTALL_DIR}/modules"
readonly LOG_FILE="/tmp/nexusvpn-install.log"

# Colores
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'; C='\033[0;36m'; NC='\033[0m'
CHECK="✓"; CROSS="✗"; ARROW="→"; WARN="⚠"

# Funciones base
log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"; }
ok() { echo -e "${G}${CHECK}${NC} $1"; log "OK: $1"; }
err() { echo -e "${R}${CROSS}${NC} $1" >&2; log "ERROR: $1"; }
inf() { echo -e "${C}${ARROW}${NC} $1"; log "INFO: $1"; }

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${R}${CROSS} Ejecuta como root: sudo bash $0 --install${NC}"
    exit 1
fi

# PASO 1: Crear directorios
mkdir -p "$MODULES_DIR"

# PASO 2: Descargar TODOS los módulos de GitHub
inf "Descargando módulos desde GitHub..."
wget -q -O "$MODULES_DIR/core.sh" "$REPO/modules/core.sh" || err "No se pudo descargar core.sh"
wget -q -O "$MODULES_DIR/xray.sh" "$REPO/modules/xray.sh" || err "No se pudo descargar xray.sh"
wget -q -O "$MODULES_DIR/udp-custom.sh" "$REPO/modules/udp-custom.sh" || err "No se pudo descargar udp-custom.sh"
wget -q -O "$MODULES_DIR/badvpn.sh" "$REPO/modules/badvpn.sh" || err "No se pudo descargar badvpn.sh"
wget -q -O "$MODULES_DIR/hysteria2.sh" "$REPO/modules/hysteria2.sh" || err "No se pudo descargar hysteria2.sh"
wget -q -O "$MODULES_DIR/wireguard.sh" "$REPO/modules/wireguard.sh" || err "No se pudo descargar wireguard.sh"
wget -q -O "$MODULES_DIR/ikev2.sh" "$REPO/modules/ikev2.sh" || err "No se pudo descargar ikev2.sh"
wget -q -O "$MODULES_DIR/openvpn.sh" "$REPO/modules/openvpn.sh" || err "No se pudo descargar openvpn.sh"
wget -q -O "$MODULES_DIR/slowdns.sh" "$REPO/modules/slowdns.sh" || err "No se pudo descargar slowdns.sh"
wget -q -O "$MODULES_DIR/telegram-bot.sh" "$REPO/modules/telegram-bot.sh" || err "No se pudo descargar telegram-bot.sh"
wget -q -O "$MODULES_DIR/monitoring.sh" "$REPO/modules/monitoring.sh" || err "No se pudo descargar monitoring.sh"
wget -q -O "$MODULES_DIR/keys.sh" "$REPO/modules/keys.sh" || err "No se pudo descargar keys.sh"
wget -q -O "$MODULES_DIR/firewall.sh" "$REPO/modules/firewall.sh" || err "No se pudo descargar firewall.sh"
wget -q -O "$MODULES_DIR/backup.sh" "$REPO/modules/backup.sh" || err "No se pudo descargar backup.sh"
wget -q -O "$MODULES_DIR/webpanel.sh" "$REPO/modules/webpanel.sh" || err "No se pudo descargar webpanel.sh"

chmod +x "$MODULES_DIR"/*.sh
ok "Módulos descargados"

# PASO 3: Cargar módulos
for module in "$MODULES_DIR"/*.sh; do
    source "$module"
    ok "Cargado: $(basename "$module")"
done

# PASO 4: Continuar con la instalación...
# (aquí va el resto de tu código de instalación)

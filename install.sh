#!/bin/bash
# NEXUSVPN PRO - Script de instalación
# Versión: 1.0 (construcción paso a paso)

set -euo pipefail
export DEBIAN_FRONTEND=noninteractive

# Colores básicos
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
C='\033[0;36m'; NC='\033[0m'; BLD='\033[1m'

# Directorios
INSTALL_DIR="/etc/nexusvpn"
LOG_FILE="/tmp/nexusvpn-install.log"

# Funciones base
log() { echo "[$(date '+%H:%M:%S')] $1" >> "$LOG_FILE"; }
ok() { echo -e "${G}✔${NC} $1"; log "OK: $1"; }
err() { echo -e "${R}✘${NC} $1" >&2; log "ERROR: $1"; }
inf() { echo -e "${C}➜${NC} $1"; log "INFO: $1"; }

# Verificar root
if [[ $EUID -ne 0 ]]; then
    echo -e "${R}Error: Ejecuta como root${NC}"
    echo "sudo bash $0 --install"
    exit 1
fi

# Detectar IP
get_ip() {
    curl -s4 ifconfig.me 2>/dev/null || hostname -I | awk '{print $1}'
}

# Instalación principal
install_base() {
    inf "Iniciando instalación base..."
    
    # Crear directorios
    mkdir -p "$INSTALL_DIR"
    
    # Actualizar sistema
    apt-get update -qq >> "$LOG_FILE" 2>&1
    apt-get upgrade -y -qq >> "$LOG_FILE" 2>&1
    ok "Sistema actualizado"
    
    # Dependencias esenciales
    apt-get install -y -qq curl wget unzip zip ufw >> "$LOG_FILE" 2>&1
    ok "Dependencias base instaladas"
    
    # Mostrar IP
    IP=$(get_ip)
    inf "IP del servidor: $IP"
    
    ok "Instalación base completada"
}

# Menú principal
case "${1:-}" in
    --install)
        install_base
        echo -e "\n${G}¡Base instalada correctamente!${NC}"
        echo "Próximos módulos: Xray, UDP Custom, etc."
        ;;
    *)
        echo "Uso: bash $0 --install"
        ;;
esac

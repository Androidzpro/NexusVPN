#!/bin/bash
# ============================================================
#   NexusVPN Pro - Instalador Principal
#   Repo:  https://github.com/TU_USUARIO/vpn-panel
#   Soporte: Ubuntu 20.04 / 22.04 / Debian 11
# ============================================================

set -e

REPO_URL="https://raw.githubusercontent.com/Androidzpro/NexusVPN/main"
PANEL_DIR="/etc/vpn-panel"
BIN_DIR="/usr/local/bin/vpn-panel"
VERSION="2.0.0"
MYIP=$(curl -s ifconfig.me 2>/dev/null || curl -s api.ipify.org)
OS_ID=$(. /etc/os-release && echo "$ID")
OS_VER=$(. /etc/os-release && echo "$VERSION_ID")

# Colores
R='\033[0;31m'; G='\033[0;32m'; Y='\033[1;33m'
B='\033[0;34m'; C='\033[0;36m'; W='\033[1;37m'; NC='\033[0m'

check_root() {
    [[ $EUID -ne 0 ]] && echo -e "${R}❌ Ejecutar como root: sudo bash install.sh${NC}" && exit 1
}

check_os() {
    if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" ]]; then
        echo -e "${R}❌ SO no compatible. Solo Ubuntu 20.04/22.04 y Debian 11${NC}"
        exit 1
    fi
}

show_banner() {
    clear
    echo -e "${B}"
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║                                                              ║"
    echo "║   ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗              ║"
    echo "║   ████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝              ║"
    echo "║   ██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗              ║"
    echo "║   ██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║              ║"
    echo "║   ██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║              ║"
    echo "║   ╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝              ║"
    echo "║        ██╗   ██╗██████╗ ███╗   ██╗    ██████╗ ██████╗  ██████╗ ║"
    echo "║        ██║   ██║██╔══██╗████╗  ██║    ██╔══██╗██╔══██╗██╔═══██╗║"
    echo "║        ██║   ██║██████╔╝██╔██╗ ██║    ██████╔╝██████╔╝██║   ██║║"
    echo "║        ╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║    ██╔═══╝ ██╔══██╗██║   ██║║"
    echo "║         ╚████╔╝ ██║     ██║ ╚████║    ██║     ██║  ██║╚██████╔╝║"
    echo "║          ╚═══╝  ╚═╝     ╚═╝  ╚═══╝    ╚═╝     ╚═╝  ╚═╝ ╚═════╝ ║"
    echo "║                                                              ║"
    echo "║                   NexusVPN Pro v2.0.0                      ║"
    echo "║         V2Ray • Hysteria2 • SlowDNS • UDP Custom           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "  ${Y}IP Pública :${NC} $MYIP"
    echo -e "  ${Y}Sistema    :${NC} $OS_ID $OS_VER"
    echo -e "  ${Y}Fecha      :${NC} $(date '+%Y-%m-%d %H:%M:%S')"
    echo -e "  ${Y}Versión    :${NC} $VERSION"
    echo -e "  ${C}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

install_all() {
    show_banner
    echo -e "\n${G}[→] Iniciando instalación completa...${NC}\n"
    
    # Descargar y ejecutar módulos
    wget -qO /tmp/vpnpanel_deps.sh "$REPO_URL/modules/deps.sh" && bash /tmp/vpnpanel_deps.sh
    wget -qO /tmp/vpnpanel_xray.sh "$REPO_URL/modules/xray.sh" && bash /tmp/vpnpanel_xray.sh
    wget -qO /tmp/vpnpanel_hysteria.sh "$REPO_URL/modules/hysteria.sh" && bash /tmp/vpnpanel_hysteria.sh
    wget -qO /tmp/vpnpanel_slowdns.sh "$REPO_URL/modules/slowdns.sh" && bash /tmp/vpnpanel_slowdns.sh
    wget -qO /tmp/vpnpanel_udp.sh "$REPO_URL/modules/udp.sh" && bash /tmp/vpnpanel_udp.sh
    wget -qO /tmp/vpnpanel_badvpn.sh "$REPO_URL/modules/badvpn.sh" && bash /tmp/vpnpanel_badvpn.sh
    wget -qO /tmp/vpnpanel_keys.sh "$REPO_URL/modules/keys.sh" && bash /tmp/vpnpanel_keys.sh
    wget -qO /tmp/vpnpanel_firewall.sh "$REPO_URL/modules/firewall.sh" && bash /tmp/vpnpanel_firewall.sh
    wget -qO /tmp/vpnpanel_menu.sh "$REPO_URL/modules/menu.sh"
    cp /tmp/vpnpanel_menu.sh /usr/local/bin/vpn-panel
    chmod +x /usr/local/bin/vpn-panel
    
    echo -e "\n${G}✅ Instalación completa finalizada!${NC}"
    echo -e "${Y}Ejecuta: ${C}vpn-panel${NC} para acceder al menú"
}

# Instalación rápida desde una sola línea
show_banner
echo -e "\n${Y}¿Cómo deseas instalar?${NC}"
echo -e "  ${C}1)${NC} Instalación completa (recomendado)"
echo -e "  ${C}2)${NC} Solo V2Ray/Xray"
echo -e "  ${C}3)${NC} Solo Hysteria2"
echo -e "  ${C}4)${NC} Solo SlowDNS"
echo -e "  ${C}5)${NC} Solo UDP Custom + BadVPN"
echo -e "  ${C}6)${NC} Actualizar panel existente"
echo -e "  ${C}0)${NC} Salir"
echo ""
read -p "  Opción [1-6]: " opt

case $opt in
    1) 
        # Descargar todo directamente (sin GitHub en la primera ejecución)
        wget -qO /tmp/vpnpanel_full.sh "$REPO_URL/modules/full_install.sh" 2>/dev/null \
        || curl -sL "$REPO_URL/modules/full_install.sh" -o /tmp/vpnpanel_full.sh
        bash /tmp/vpnpanel_full.sh
        ;;
    2) wget -qO- "$REPO_URL/modules/xray.sh" | bash ;;
    3) wget -qO- "$REPO_URL/modules/hysteria.sh" | bash ;;
    4) wget -qO- "$REPO_URL/modules/slowdns.sh" | bash ;;
    5) wget -qO- "$REPO_URL/modules/udp.sh" | bash && wget -qO- "$REPO_URL/modules/badvpn.sh" | bash ;;
    6) wget -qO- "$REPO_URL/modules/update.sh" | bash ;;
    0) exit 0 ;;
    *) echo -e "${R}Opción inválida${NC}"; exit 1 ;;
esac

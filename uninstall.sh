#!/bin/bash
# ═══════════════════════════════════════════════════════════
#  NexusVPN Pro v3.0 — Desinstalador
#  WhatsApp: 3004430431  |  Telegram: @ANDRESCAMP13
# ═══════════════════════════════════════════════════════════

set -euo pipefail

R='\033[0;31m' G='\033[0;32m' Y='\033[1;33m' C='\033[0;36m' W='\033[1;37m' NC='\033[0m'

[[ $EUID -ne 0 ]] && { echo -e "${R}Requiere root${NC}"; exit 1; }

echo -e "\n${C}═══════════════════════════════════════════════════${NC}"
echo -e "${W}  NexusVPN Pro — Desinstalador${NC}"
echo -e "${C}═══════════════════════════════════════════════════${NC}"
echo -e "${Y}  ADVERTENCIA: Esta acción eliminará:${NC}"
echo -e "  - Todos los servicios VPN (Xray, Hysteria2, BadVPN...)"
echo -e "  - Configuraciones en /etc/NexusVPN/"
echo -e "  - El comando 'nexusvpn'"
echo -e "  ${R}Los usuarios SSH del sistema NO se eliminarán${NC}"
echo -e "${C}═══════════════════════════════════════════════════${NC}\n"

read -rp "  ¿Confirmar desinstalación completa? (escribe 'CONFIRMAR'): " confirm
[[ "$confirm" != "CONFIRMAR" ]] && { echo -e "${Y}  Cancelado.${NC}"; exit 0; }

echo -e "\n${Y}  Deteniendo y deshabilitando servicios...${NC}"
for svc in xray hysteria slowdns badvpn-7100 badvpn-7200 badvpn-7300 openvpn@server-tcp openvpn@server-udp; do
    systemctl stop "$svc" 2>/dev/null || true
    systemctl disable "$svc" 2>/dev/null || true
done

echo -e "${Y}  Eliminando archivos de servicio...${NC}"
for svc in xray hysteria slowdns badvpn-7100 badvpn-7200 badvpn-7300; do
    rm -f "/etc/systemd/system/${svc}.service"
done
rm -f /etc/systemd/system/udpcustom-*.service
systemctl daemon-reload 2>/dev/null || true

echo -e "${Y}  Eliminando binarios...${NC}"
rm -f /usr/local/bin/xray /usr/local/bin/hysteria /usr/local/bin/badvpn-udpgw
rm -f /usr/local/bin/dnstt-server /usr/local/bin/nexusvpn

echo -e "${Y}  Eliminando configuraciones...${NC}"
rm -rf /etc/NexusVPN /usr/local/etc/xray /etc/hysteria
rm -f /var/log/nexusvpn.log /var/log/xray-access.log /var/log/xray-error.log
rm -f /etc/nginx/sites-available/nexusvpn* /etc/nginx/sites-enabled/nexusvpn*

echo -e "${Y}  Restaurando MOTD...${NC}"
echo "" > /etc/motd
echo "" > /etc/issue.net 2>/dev/null || true

# Recargar Nginx
nginx -t 2>/dev/null && systemctl reload nginx 2>/dev/null || true

# Limpiar crontab
sed -i '/nexusvpn/d' /etc/crontab 2>/dev/null || true

echo -e "\n${G}  ✔  NexusVPN Pro desinstalado completamente${NC}"
echo -e "  ${Y}OpenVPN y Nginx NO fueron desinstalados (pueden tener otros usos).${NC}"
echo -e "  Para reinstalar: bash install.sh --install\n"

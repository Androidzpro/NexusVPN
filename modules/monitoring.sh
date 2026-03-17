#!/bin/bash
# Módulo de Monitoreo para NexusVPN Pro
# Funciones: ver usuarios conectados, estadísticas en tiempo real

show_online_users() {
    clear_screen
    echo -e "${C}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${W}  📡  USUARIOS CONECTADOS AHORA - NEXUSVPN PRO ${NC}"
    echo -e "${C}═══════════════════════════════════════════════════════════════════════${NC}"
    
    printf "${Y}%-20s %-15s %-20s %-10s %-15s %-12s${NC}\n" "USUARIO" "PROTOCOLO" "IP ORIGEN" "PUERTO" "PAÍS" "DURACIÓN"
    echo -e "${DIM}───────────────────────────────────────────────────────────────────────────────${NC}"
    
    local total_users=0
    
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            local user=$(echo "$line" | awk '{print $1}')
            local ip=$(echo "$line" | awk '{print $5}' | tr -d '()')
            local login_time=$(echo "$line" | awk '{print $3, $4}')
            local country="?"
            
            if [[ "$ip" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
                country=$(curl -s "http://ip-api.com/line/${ip}?fields=country" 2>/dev/null | head -1 || echo "?")
                [[ -z "$country" ]] && country="?"
            fi
            
            local duration="?"
            if [[ -n "$login_time" ]] && date -d "$login_time" +%s >/dev/null 2>&1; then
                local login_epoch=$(date -d "$login_time" +%s 2>/dev/null)
                local now_epoch=$(date +%s)
                local diff=$((now_epoch - login_epoch))
                local hours=$((diff / 3600))
                local minutes=$(( (diff % 3600) / 60 ))
                duration=$(printf "%02d:%02d" $hours $minutes)
            fi
            
            printf "  %-18s SSH        %-20s %-10s %-15s %-12s\n" "$user" "$ip" "22" "$country" "$duration"
            ((total_users++))
        fi
    done < <(who --ips 2>/dev/null | grep -v "127.0.0.1")
    
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
    
    echo -e "${C}───────────────────────────────────────────────────────────────────────────────${NC}"
    
    if [[ $total_users -eq 0 ]]; then
        echo -e "  ${Y}No hay usuarios conectados en este momento${NC}"
    else
        echo -e "  ${G}Total: ${W}${total_users}${G} usuario(s) conectado(s)${NC}"
    fi
    echo -e "${C}═══════════════════════════════════════════════════════════════════════${NC}"
}

count_active_users() {
    local count=0
    count=$(( count + $(who 2>/dev/null | wc -l) ))
    count=$(( count + $(ss -tnp 2>/dev/null | grep -E 'xray|v2ray' | wc -l) ))
    if command -v wg &>/dev/null; then
        count=$(( count + $(wg show 2>/dev/null | grep -c "peer:") ))
    fi
    echo "$count"
}

show_system_stats() {
    echo -e "${C}═══════════════════════════════════════════════════════════════════════${NC}"
    echo -e "${W}  📊  ESTADÍSTICAS DEL SERVIDOR ${NC}"
    echo -e "${C}═══════════════════════════════════════════════════════════════════════${NC}"
    
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo -e "  ${Y}CPU:${NC} ${G}${cpu_usage:-0}%${NC}"
    
    local ram_total=$(free -m | awk '/^Mem:/{print $2}')
    local ram_used=$(free -m | awk '/^Mem:/{print $3}')
    local ram_percent=$(( ram_used * 100 / ram_total ))
    echo -e "  ${Y}RAM:${NC} ${G}${ram_used}MB${NC}/${W}${ram_total}MB${NC} (${ram_percent}%)"
    
    local disk_used=$(df -h / | awk 'NR==2{print $3}')
    local disk_total=$(df -h / | awk 'NR==2{print $2}')
    local disk_percent=$(df -h / | awk 'NR==2{print $5}' | tr -d '%')
    echo -e "  ${Y}Disco:${NC} ${G}${disk_used}${NC}/${W}${disk_total}${NC} (${disk_percent}%)"
    
    local uptime=$(uptime -p | sed 's/up //')
    echo -e "  ${Y}Uptime:${NC} ${G}${uptime}${NC}"
    
    echo -e "${C}───────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${W}  🌐  TRÁFICO DE RED ${NC}"
    
    for iface in $(ip -o link show | awk -F': ' '{print $2}' | grep -v lo); do
        local rx=$(cat "/sys/class/net/${iface}/statistics/rx_bytes" 2>/dev/null || echo 0)
        local tx=$(cat "/sys/class/net/${iface}/statistics/tx_bytes" 2>/dev/null || echo 0)
        local rx_mb=$(( rx / 1024 / 1024 ))
        local tx_mb=$(( tx / 1024 / 1024 ))
        printf "  ${W}%-8s${NC}  RX: ${G}%6d MB${NC}  TX: ${C}%6d MB${NC}\n" "$iface" "$rx_mb" "$tx_mb"
    done
    
    echo -e "${C}───────────────────────────────────────────────────────────────────────────${NC}"
    echo -e "${W}  ⚙️  ESTADO DE SERVICIOS ${NC}"
    
    for svc in xray hysteria wg-quick@wg0 openvpn@server-tcp slowdns nginx ssh; do
        local status=$(systemctl is-active "$svc" 2>/dev/null || echo "inactive")
        if [[ "$status" == "active" ]]; then
            printf "  ${W}%-20s${NC} ${G}● activo${NC}\n" "$svc"
        else
            printf "  ${W}%-20s${NC} ${R}● inactivo${NC}\n" "$svc"
        fi
    done
    
    echo -e "${C}═══════════════════════════════════════════════════════════════════════${NC}"
}

get_ip_country() {
    local ip="$1"
    curl -s "http://ip-api.com/line/${ip}?fields=country" 2>/dev/null | head -1 || echo "?"
}

monitor_traffic() {
    local user="$1"
    local iface=$(ip route | grep default | awk '{print $5}' | head -1)
    echo -e "${C}Monitoreando tráfico para $user (Ctrl+C para salir)${NC}"
    trap 'echo -e "\n${G}Monitoreo finalizado${NC}"; return' INT
    
    while true; do
        local rx=$(cat "/sys/class/net/${iface}/statistics/rx_bytes" 2>/dev/null || echo 0)
        local tx=$(cat "/sys/class/net/${iface}/statistics/tx_bytes" 2>/dev/null || echo 0)
        printf "\rRX: ${G}%10d KB${NC}  TX: ${C}%10d KB${NC}" $((rx/1024)) $((tx/1024))
        sleep 2
    done
}

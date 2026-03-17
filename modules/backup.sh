#!/bin/bash
# Módulo de Backup para NexusVPN Pro
# Funciones: crear, restaurar, listar backups

BACKUP_DIR="${INSTALL_DIR}/backups"

create_backup() {
    local backup_name="nexusvpn-backup-$(date +%Y%m%d-%H%M%S)"
    local backup_file="${BACKUP_DIR}/${backup_name}.tar.gz"
    local backup_info="${BACKUP_DIR}/${backup_name}.info"
    
    inf "Creando backup completo del sistema..."
    log_info "Iniciando backup: $backup_name"
    
    local tmp_dir=$(mktemp -d)
    mkdir -p "$tmp_dir/backup"
    
    cp -r "$INSTALL_DIR" "$tmp_dir/backup/" 2>/dev/null
    
    mkdir -p "$tmp_dir/backup/services"
    [[ -d /usr/local/etc/xray ]] && cp -r /usr/local/etc/xray "$tmp_dir/backup/services/"
    [[ -d /etc/hysteria ]] && cp -r /etc/hysteria "$tmp_dir/backup/services/"
    [[ -d /etc/wireguard ]] && cp -r /etc/wireguard "$tmp_dir/backup/services/"
    [[ -d /etc/openvpn ]] && cp -r /etc/openvpn "$tmp_dir/backup/services/"
    [[ -d /etc/ipsec.d ]] && cp -r /etc/ipsec.d "$tmp_dir/backup/services/"
    [[ -d /etc/nginx/sites-available ]] && cp /etc/nginx/sites-available/nexus* "$tmp_dir/backup/services/" 2>/dev/null
    
    mkdir -p "$tmp_dir/backup/certs"
    cp /etc/letsencrypt/live/*/*.pem "$tmp_dir/backup/certs/" 2>/dev/null
    cp /etc/hysteria/*.pem "$tmp_dir/backup/certs/" 2>/dev/null
    
    mkdir -p "$tmp_dir/backup/database"
    cp "$USERS_DB" "$KEYS_DB" "$TRAFFIC_DB" "$tmp_dir/backup/database/" 2>/dev/null
    
    cp /usr/local/bin/nexusvpn* "$tmp_dir/backup/" 2>/dev/null
    
    cat > "$tmp_dir/backup/backup-info.txt" << EOF
NEXUSVPN PRO BACKUP
Fecha: $(date '+%Y-%m-%d %H:%M:%S')
Versión: $SCRIPT_VERSION
Hostname: $(hostname)
IP: $(get_server_ip)
OS: $(get_os_name)
EOF
    
    cd "$tmp_dir" || return 1
    tar -czf "$backup_file" backup/ >> "$INSTALL_LOG" 2>&1
    
    cat > "$backup_info" << EOF
Backup: $backup_name
Fecha: $(date '+%Y-%m-%d %H:%M:%S')
Tamaño: $(du -h "$backup_file" | cut -f1)
MD5: $(md5sum "$backup_file" | cut -d' ' -f1)
EOF
    
    cd /
    rm -rf "$tmp_dir"
    
    if [[ -f "$backup_file" ]]; then
        local size=$(du -h "$backup_file" | cut -f1)
        log_info "Backup creado: $backup_name ($size)"
        ok "Backup creado: ${W}$backup_name${NC} (${G}$size${NC})"
        clean_old_backups
    else
        err "Error al crear backup"
        return 1
    fi
}

clean_old_backups() {
    local backups=($(ls -t "$BACKUP_DIR"/*.tar.gz 2>/dev/null))
    local count=${#backups[@]}
    
    if [[ $count -gt 10 ]]; then
        for ((i=10; i<count; i++)); do
            rm -f "${backups[$i]}" "${backups[$i]%.tar.gz}.info"
            log_info "Backup antiguo eliminado: ${backups[$i]}"
        done
        inf "Backups antiguos limpiados (conservados los últimos 10)"
    fi
}

restore_backup() {
    inf "Preparando restauración de backup..."
    
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
    
    create_backup
    
    local tmp_dir=$(mktemp -d)
    tar -xzf "$selected" -C "$tmp_dir" >> "$INSTALL_LOG" 2>&1
    
    if [[ -d "$tmp_dir/backup" ]]; then
        systemctl stop xray hysteria wg-quick@wg0 openvpn@server-tcp openvpn@server-udp slowdns nexusvpn-bot nginx 2>/dev/null
        
        cp -rf "$tmp_dir/backup/$(basename "$INSTALL_DIR")"/* "$INSTALL_DIR/" 2>/dev/null
        [[ -d "$tmp_dir/backup/services/xray" ]] && cp -rf "$tmp_dir/backup/services/xray"/* /usr/local/etc/xray/ 2>/dev/null
        [[ -d "$tmp_dir/backup/services/hysteria" ]] && cp -rf "$tmp_dir/backup/services/hysteria"/* /etc/hysteria/ 2>/dev/null
        [[ -d "$tmp_dir/backup/services/wireguard" ]] && cp -rf "$tmp_dir/backup/services/wireguard"/* /etc/wireguard/ 2>/dev/null
        [[ -d "$tmp_dir/backup/services/openvpn" ]] && cp -rf "$tmp_dir/backup/services/openvpn"/* /etc/openvpn/ 2>/dev/null
        [[ -d "$tmp_dir/backup/services/ipsec.d" ]] && cp -rf "$tmp_dir/backup/services/ipsec.d"/* /etc/ipsec.d/ 2>/dev/null
        
        [[ -f "$tmp_dir/backup/database/users.db" ]] && cp "$tmp_dir/backup/database/users.db" "$USERS_DB"
        [[ -f "$tmp_dir/backup/database/keys.db" ]] && cp "$tmp_dir/backup/database/keys.db" "$KEYS_DB"
        
        systemctl daemon-reload
        systemctl start xray hysteria wg-quick@wg0 openvpn@server-tcp openvpn@server-udp slowdns nexusvpn-bot nginx 2>/dev/null
        
        ok "Backup restaurado correctamente"
        log_info "Backup restaurado: $(basename "$selected")"
    else
        err "El backup no tiene la estructura esperada"
    fi
    
    rm -rf "$tmp_dir"
}

list_backups() {
    echo -e "\n${C}Backups disponibles en $BACKUP_DIR:${NC}\n"
    
    local backups=($(ls -lh "$BACKUP_DIR"/*.tar.gz 2>/dev/null))
    
    if [[ ${#backups[@]} -eq 0 ]]; then
        warn "No hay backups"
        return
    fi
    
    for backup in "${backups[@]}"; do
        local name=$(basename "$backup")
        local size=$(du -h "$backup" | cut -f1)
        local date=$(stat -c '%y' "$backup" 2>/dev/null | cut -d. -f1)
        echo -e "  ${W}$name${NC} (${G}$size${NC}) - ${DIM}$date${NC}"
    done
}

export_users_list() {
    local efile="/tmp/nexusvpn_users_$(date +%Y%m%d).txt"
    
    {
        echo "=== NexusVPN Pro — Lista de Usuarios ==="
        echo "Exportado: $(date '+%d/%m/%Y %H:%M:%S')"
        echo ""
        echo "=== Usuarios Xray ==="
        
        if [[ -f "$XRAY_CONFIG" ]]; then
            python3 -c "
import json
try:
    with open('$XRAY_CONFIG','r') as f:
        cfg = json.load(f)
    seen = set()
    for inb in cfg.get('inbounds',[]):
        for c in inb.get('settings',{}).get('clients',[]):
            email = c.get('email','?')
            if email not in seen:
                seen.add(email)
                uid = c.get('id',c.get('password','?'))
                print(f'  {email} — {uid}')
except: pass
" >> "$efile"
        fi
        
        echo "" >> "$efile"
        echo "=== Usuarios SSH ===" >> "$efile"
        getent passwd | awk -F: '$3>=1000 && $7!~/nologin|false/{print "  "$1}' >> "$efile" 2>/dev/null
    }
    
    ok "Lista exportada a ${efile}"
}

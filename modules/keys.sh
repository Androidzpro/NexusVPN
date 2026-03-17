#!/bin/bash
# Módulo de Sistema de Keys para NexusVPN Pro
# Funciones: generación, validación, gestión de licencias

KEYS_DB="${DATABASE_DIR}/keys.db"

generate_key() {
    local part
    part() {
        head -c 3 /dev/urandom | od -An -tx1 | tr -d ' \n' | tr '[:lower:]' '[:upper:]' | head -c 6
    }
    echo "NEXUS-$(part)-$(part)-$(part)-$(part)-$(part)"
}

key_hash() {
    echo -n "$1" | sha256sum | cut -c1-24
}

create_key() {
    local days="${1:-30}"
    local max_users="${2:-0}"
    local max_gb="${3:-0}"
    local note="${4:-}"
    
    local key expiry hash
    
    key=$(generate_key)
    
    if date -d "+${days} days" +%s >/dev/null 2>&1; then
        expiry=$(date -d "+${days} days" +%s)
    else
        expiry=$(date -v "+${days}d" +%s 2>/dev/null || echo $(( $(date +%s) + days * 86400 )))
    fi
    
    hash=$(key_hash "$key")
    
    echo "${key}|${hash}|${expiry}|${max_users}|${max_gb}|0|1|$(date +%s)|${note}" >> "$KEYS_DB"
    
    log_info "Key creada: ${key:0:8}... exp:${days}d users:${max_users} gb:${max_gb}"
    echo "$key"
}

validate_key() {
    local input_key="$1"
    
    if [[ ! -f "$KEYS_DB" ]]; then
        return 1
    fi
    
    local now=$(date +%s)
    
    while IFS='|' read -r key hash expiry max_users max_gb used_gb active created note; do
        [[ -z "$key" ]] && continue
        
        if [[ "$key" == "$input_key" && "$active" == "1" ]]; then
            if [[ $now -le $expiry ]]; then
                echo "$expiry|$max_users|$max_gb|$used_gb"
                return 0
            else
                sed -i "s/^${key}|${hash}|${expiry}|${max_users}|${max_gb}|${used_gb}|1|${created}|${note}$/${key}|${hash}|${expiry}|${max_users}|${max_gb}|${used_gb}|0|${created}|${note}/" "$KEYS_DB"
                return 2
            fi
        fi
    done < "$KEYS_DB"
    
    return 1
}

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
    
    cfg_set "license.active" "true"
    cfg_set "license.key" "\"${key:0:8}...\""
    cfg_set "license.expiry" "$expiry"
    cfg_set "license.max_users" "$max_users"
    cfg_set "license.max_traffic" "$max_gb"
    
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

get_license_expiry() {
    local expiry=$(cfg_get "license.expiry")
    
    if [[ -z "$expiry" || "$expiry" == "0" ]]; then
        echo "Sin licencia activa"
        return
    fi
    
    local now=$(date +%s)
    
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

check_license_active() {
    local active=$(cfg_get "license.active")
    local expiry=$(cfg_get "license.expiry")
    
    [[ "$active" != "true" ]] && return 1
    [[ -z "$expiry" || "$expiry" == "0" ]] && return 1
    [[ $(date +%s) -le $expiry ]] && return 0 || return 1
}

clean_expired_keys() {
    local now=$(date +%s)
    
    if [[ ! -f "$KEYS_DB" ]]; then
        return
    fi
    
    local tmp_file=$(mktemp)
    local modified=0
    
    while IFS='|' read -r key hash expiry max_users max_gb used_gb active created note; do
        [[ -z "$key" ]] && continue
        
        if [[ $now -gt $expiry && "$active" == "1" ]]; then
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

list_keys() {
    print_banner
    echo -e "${C}  ── Keys registradas ────────────────────────────────${NC}\n"
    
    if [[ ! -f "$KEYS_DB" || ! -s "$KEYS_DB" ]]; then
        warn "No hay keys registradas."
        press_enter
        return
    fi
    
    local now=$(date +%s)
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

revoke_key() {
    local prefix="$1"
    
    if grep -q "^${prefix}" "$KEYS_DB" 2>/dev/null; then
        sed -i "s/^\(${prefix}[^|]*\|\([^|]*|\)\{5\}\)1|/\10|/" "$KEYS_DB"
        ok "Key revocada"
    else
        err "Key no encontrada"
    fi
}

create_key_interactive() {
    print_banner
    echo -e "${C}  ── Crear nueva Key ──────────────────────${NC}\n"
    
    read_input "Días de validez [30]" days "30"
    read_input "Máx. usuarios [0=ilimitado]" mu "0"
    read_input "Máx. GB [0=ilimitado]" mg "0"
    read_input "Nota/cliente" note
    
    local newkey=$(create_key "$days" "$mu" "$mg" "$note")
    
    echo ""
    echo -e "${G}  ╔═══════════════════════════════════════════════════╗${NC}"
    echo -e "${G}  ║  KEY GENERADA EXITOSAMENTE                       ║${NC}"
    echo -e "${G}  ╠═══════════════════════════════════════════════════╣${NC}"
    echo -e "${G}  ║${NC}  ${W}${newkey}${NC}"
    echo -e "${G}  ║${NC}  Días: ${W}${days}${NC}  |  Usuarios: ${W}${mu:-Ilimitado}${NC}  |  GB: ${W}${mg:-Ilimitado}${NC}"
    echo -e "${G}  ╚═══════════════════════════════════════════════════╝${NC}"
    
    press_enter
}

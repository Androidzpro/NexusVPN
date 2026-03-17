#!/bin/bash
# Módulo de IKEv2 para NexusVPN Pro
# Funciones: instalación, configuración, gestión de clientes

IKEV2_CONFIG_DIR="/etc/ipsec.d"
IKEV2_LOG_DIR="/var/log/ipsec"

install_ikev2() {
    inf "Instalando IKEv2 para dispositivos móviles (iPhone/iPad/Android)..."
    log_info "Instalando IKEv2"
    
    apt_install strongswan strongswan-pki libcharon-extra-plugins libcharon-extauth-plugins libstrongswan-extra-plugins
    
    mkdir -p "$IKEV2_CONFIG_DIR"/{cacerts,certs,private}
    generate_ikev2_certs
    configure_ikev2
    
    echo "net.ipv4.ip_forward = 1" >> /etc/sysctl.conf
    echo "net.ipv6.conf.all.forwarding = 1" >> /etc/sysctl.conf
    sysctl -p
    
    ok "IKEv2 instalado correctamente"
}

generate_ikev2_certs() {
    local server_ip=$(get_server_ip)
    
    cd "$IKEV2_CONFIG_DIR" || return 1
    
    pki --gen --type rsa --size 4096 --outform pem > private/ca-key.pem
    pki --self --ca --lifetime 3650 --in private/ca-key.pem \
        --dn "CN=NexusVPN CA, O=NexusVPN, C=US" \
        --outform pem > cacerts/ca-cert.pem
    
    pki --gen --type rsa --size 2048 --outform pem > private/server-key.pem
    pki --pub --in private/server-key.pem --type rsa \
        | pki --issue --lifetime 1825 \
        --cacert cacerts/ca-cert.pem \
        --cakey private/ca-key.pem \
        --dn "CN=${server_ip}, O=NexusVPN, C=US" \
        --san "${server_ip}" \
        --flag serverAuth --flag ikeIntermediate \
        --outform pem > certs/server-cert.pem
    
    pki --gen --type rsa --size 2048 --outform pem > private/client-key.pem
    pki --pub --in private/client-key.pem --type rsa \
        | pki --issue --lifetime 1825 \
        --cacert cacerts/ca-cert.pem \
        --cakey private/ca-key.pem \
        --dn "CN=client, O=NexusVPN, C=US" \
        --outform pem > certs/client-cert.pem
    
    chmod 600 private/*.pem
    log_info "Certificados IKEv2 generados"
}

configure_ikev2() {
    local server_ip=$(get_server_ip)
    
    cat > /etc/strongswan/swanctl/swanctl.conf << SWANCTL
connections {
    ikev2-vpn {
        local_addrs = ${server_ip}
        remote_addrs = %any
        
        local {
            auth = pubkey
            certs = server-cert.pem
            id = ${server_ip}
        }
        
        remote {
            auth = pubkey
            certs = client-cert.pem
            id = client
        }
        
        children {
            ikev2-vpn {
                local_ts = 0.0.0.0/0
                remote_ts = 0.0.0.0/0
                updown = /usr/lib/ipsec/_updown iptables
                rekey_time = 0
                esp_proposals = aes256-sha256-modp2048
            }
        }
        
        version = 2
        mobike = yes
        proposals = aes256-sha256-modp2048
    }
}

secrets { }

pools {
    vpn-pool {
        addrs = 10.10.10.0/24
        dns = 8.8.8.8, 8.8.4.4
    }
}
SWANCTL

    cat > /etc/ipsec.conf << IPSECCONF
config setup
    charondebug="ike 2, knl 2, cfg 2"
    uniqueids=no

conn ikev2-vpn
    auto=add
    compress=no
    type=tunnel
    keyexchange=ikev2
    fragmentation=yes
    forceencaps=yes
    ike=aes256-sha256-modp2048!
    esp=aes256-sha256-modp2048!
    dpdaction=clear
    dpddelay=300s
    rekey=no
    left=%any
    leftid=@${server_ip}
    leftcert=server-cert.pem
    leftsendcert=always
    leftsubnet=0.0.0.0/0
    right=%any
    rightid=%any
    rightauth=pubkey
    rightsourceip=10.10.10.0/24
    rightdns=8.8.8.8,8.8.4.4
    rightsendcert=never
IPSECCONF

    cp "$IKEV2_CONFIG_DIR"/cacerts/ca-cert.pem /etc/ipsec.d/cacerts/
    cp "$IKEV2_CONFIG_DIR"/certs/server-cert.pem /etc/ipsec.d/certs/
    cp "$IKEV2_CONFIG_DIR"/private/server-key.pem /etc/ipsec.d/private/
    
    systemctl restart strongswan-starter
    systemctl enable strongswan-starter
    ufw allow 500/udp >> "$INSTALL_LOG" 2>&1
    ufw allow 4500/udp >> "$INSTALL_LOG" 2>&1
    
    log_info "IKEv2 configurado correctamente"
}

ikev2_add_client() {
    local client_name="$1"
    
    if [[ -z "$client_name" ]]; then
        read_input "Nombre del cliente" client_name
    fi
    
    cd "$IKEV2_CONFIG_DIR" || return 1
    
    pki --gen --type rsa --size 2048 --outform pem > "private/${client_name}-key.pem"
    pki --pub --in "private/${client_name}-key.pem" --type rsa \
        | pki --issue --lifetime 1825 \
        --cacert cacerts/ca-cert.pem \
        --cakey private/ca-key.pem \
        --dn "CN=${client_name}, O=NexusVPN, C=US" \
        --outform pem > "certs/${client_name}-cert.pem"
    
    mkdir -p "/etc/ipsec.d/client-configs/${client_name}"
    
    cat > "/etc/ipsec.d/client-configs/${client_name}/${client_name}.p12" << EOF
Certificado generado para ${client_name}
CA Cert: /etc/ipsec.d/cacerts/ca-cert.pem
Client Cert: /etc/ipsec.d/certs/${client_name}-cert.pem
Client Key: /etc/ipsec.d/private/${client_name}-key.pem
EOF

    echo -e "\n${Y}Cliente IKEv2 '${client_name}' creado${NC}"
    echo "Certificados en: /etc/ipsec.d/client-configs/${client_name}/"
}

ikev2_list_clients() {
    echo -e "\n${C}Clientes IKEv2 configurados:${NC}"
    ls -1 /etc/ipsec.d/client-configs/ 2>/dev/null | while read client; do
        echo "  $client"
    done
}

# NexusVPN Pro v2.0.0

> Panel completo para servidor VPN con V2Ray, Hysteria2, SlowDNS, UDP Custom y BadVPN. Sistema de llaves (Keys) por tiempo para venta de acceso.

## ⚡ Instalación rápida (1 línea)

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh)
```

**Requisitos:** Ubuntu 20.04 / 22.04 / Debian 11 — root

---

## 🛡️ Protocolos incluidos

| Protocolo | Puerto | Descripción |
|-----------|--------|-------------|
| VLESS TCP | 443 | V2Ray moderno sin cifrado extra |
| VMess WebSocket | 8080 | Para inyección HTTP |
| VMess mKCP | 1194/UDP | Tunneling sobre UDP |
| Trojan | 8443 | Trojan-Go compatible |
| **Hysteria2** | 36712/UDP | Ultra-rápido, anti-censura |
| SlowDNS | 5300/UDP | Bypass via DNS |
| UDP Custom | variable | Redirección UDP libre |
| BadVPN UDP-GW | 7100-7300 | Para clientes SSH UDP |

---

## 🔑 Sistema de Keys (para venta)

### Crear una key

```bash
# Key de 30 días, 1 usuario
vpn-keys create 30 1 "Cliente Premium"

# Key de 7 días, 3 usuarios
vpn-keys create 7 3 "Pack Familiar"
```

### Activar key para usuario

```bash
vpn-keys activate VPN-XXXX-YYYY-ZZZZ nombre_usuario
```

El sistema genera automáticamente:
- UUID único para el usuario
- Links de conexión para todos los protocolos
- Archivo `.txt` guardado en `/root/`
- Desactiva automáticamente al expirar (cron horario)

### Panel interactivo

```bash
vpn-panel        # Menú principal
vpn-keys menu    # Solo gestión de keys
```

---

## 📱 Configuración en clientes

### HTTP Injector / HTTP Custom
- **Host:** IP del servidor  
- **Puerto SSL:** 443 (VLESS) o 8443 (Trojan)

### V2RayNG / V2RayN / Shadowrocket
Importar el link VLESS o VMess generado al crear usuario.

### SocksDroid (BadVPN UDP)
- **Servidor UDP-GW:** 127.0.0.1:7300
- Activar en la app SSH del cliente

### Hysteria2
```
server: TU_IP:36712
auth: usuario:contraseña
bandwidth:
  up: 50 mbps
  down: 200 mbps
obfs:
  type: salamander
  salamander:
    password: (ver /etc/hysteria/obfs.key)
tls:
  insecure: true
```

### SlowDNS
- **Servidor:** IP del servidor  
- **Puerto:** 5300 UDP  
- **Public Key:** ver `cat /etc/vpn-panel/slowdns_pubkey.txt`

---

## 🔧 Gestión de puertos UDP

```bash
# Agregar puerto UDP
udp-custom add 10000 8.8.8.8:53

# Eliminar puerto
udp-custom del 10000

# Listar todos
udp-custom list
```

---

## 📂 Estructura de archivos

```
/etc/vpn-panel/
├── keys.db           # Base de datos de keys
├── users.db          # Usuarios activos
├── udp-ports.conf    # Puertos UDP configurados
└── slowdns_pubkey.txt

/usr/local/bin/
├── vpn-panel         # Menú principal
├── vpn-keys          # Gestor de keys
└── udp-custom        # Gestor UDP

/usr/local/etc/xray/config.json   # Config Xray/V2Ray
/etc/hysteria/config.yaml          # Config Hysteria2
/etc/slowdns/                      # Claves SlowDNS
```

---

## 🆙 Actualizar

```bash
vpn-panel  # → opción 7
# o directamente:
bash <(curl -fsSL https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh)
```

---

## ❓ Soporte

Abre un Issue en este repositorio:
https://github.com/Androidzpro/NexusVPN/issues

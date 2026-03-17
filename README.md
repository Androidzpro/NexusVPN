<div align="center">

```
███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗██╗   ██╗██████╗ ███╗   ██╗
████╗  ██║██╔════╝╚██╗██╔╝██║   ██║██╔════╝██║   ██║██╔══██╗████╗  ██║
██╔██╗ ██║█████╗   ╚███╔╝ ██║   ██║███████╗██║   ██║██████╔╝██╔██╗ ██║
██║╚██╗██║██╔══╝   ██╔██╗ ██║   ██║╚════██║╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║
██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║ ╚████╔╝ ██║     ██║ ╚████║
╚═╝  ╚═══╝╚══════╝╚═╝  ╚═╝ ╚═════╝ ╚══════╝  ╚═══╝  ╚═╝     ╚═╝  ╚═══╝
                      ██████╗ ██████╗  ██████╗                          
                      ██╔══██╗██╔══██╗██╔═══██╗                         
                      ██████╔╝██████╔╝██║   ██║                         
                      ██╔═══╝ ██╔══██╗██║   ██║                         
                      ██║     ██║  ██║╚██████╔╝                         
                      ╚═╝     ╚═╝  ╚═╝ ╚═════╝                         
```

# NexusVPN Pro v3.0

**Panel profesional de VPN para servidores Linux — Mercado Latinoamericano**

[![Version](https://img.shields.io/badge/versión-3.0-00d4ff?style=for-the-badge&logo=rocket&logoColor=white)](https://github.com/Androidzpro/NexusVPN)
[![Bash](https://img.shields.io/badge/bash-5.0%2B-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)](https://www.gnu.org/software/bash/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04%2F22.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Debian](https://img.shields.io/badge/Debian-10%2F11-A81D33?style=for-the-badge&logo=debian&logoColor=white)](https://debian.org)
[![Licencia](https://img.shields.io/badge/licencia-Propietaria-FFD700?style=for-the-badge&logo=key&logoColor=black)](https://github.com/Androidzpro/NexusVPN)
[![Contacto](https://img.shields.io/badge/WhatsApp-3004430431-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)](https://wa.me/573004430431)
[![Telegram](https://img.shields.io/badge/Telegram-@ANDRESCAMP13-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/ANDRESCAMP13)

---

> **Un solo archivo. Instalación silenciosa. Todos los protocolos. Panel completo.**  
> El panel VPN más completo del mercado latinoamericano, construido para administradores serios.

---

</div>

## 📑 Tabla de Contenidos

- [✨ Características](#-características)
- [🛰️ Protocolos Incluidos](#️-protocolos-incluidos)
- [⚡ Instalación Rápida](#-instalación-rápida)
- [🖥️ Uso del Panel](#️-uso-del-panel)
- [🔑 Sistema de Licencias (Keys)](#-sistema-de-licencias-keys)
- [📋 Menú Principal — 17 Opciones](#-menú-principal--17-opciones)
- [📡 Links de Conexión](#-links-de-conexión)
- [🔐 Gestión SSH](#-gestión-ssh)
- [☁️ Cloudflare y SSL](#️-cloudflare-y-ssl)
- [📊 Estadísticas](#-estadísticas)
- [🔄 Backup y Restaurar](#-backup-y-restaurar)
- [🏗️ Estructura de Archivos](#️-estructura-de-archivos)
- [🖥️ Compatibilidad](#️-compatibilidad)
- [🛡️ Seguridad](#️-seguridad)
- [📲 Comprar Licencia](#-comprar-licencia)
- [❓ FAQ](#-faq)

---

## ✨ Características

<table>
<tr>
<td width="50%">

### 🚀 Instalación Premium
- ✅ **Un solo archivo** `install.sh`
- ✅ Sin preguntas, sin confirmaciones
- ✅ Barra de progreso animada por cada paso
- ✅ Resumen completo al finalizar
- ✅ Se copia solo a `/usr/local/bin/nexusvpn`

### 🔑 Sistema de Keys / Licencias
- ✅ Formato `NEXUS-XXXX-XXXX-XXXX-XXXX`
- ✅ Expiración: 1, 7, 15, 30, 90 días o personalizado
- ✅ Límite de usuarios por key (opcional)
- ✅ Límite de GB por key (opcional)
- ✅ Cron horario de expiración automática
- ✅ Keys encriptadas con SHA-256
- ✅ Panel no abre sin key válida

</td>
<td width="50%">

### 🎨 Diseño Visual
- ✅ Banner ASCII en cada pantalla
- ✅ IP, usuarios activos, expiración siempre visibles
- ✅ Colores: Cyan bordes · Amarillo opciones · Verde OK · Rojo errores
- ✅ MOTD SSH personalizado con tu marca
- ✅ Banners editables desde el menú
- ✅ QR codes en terminal para clientes

### 🛡️ Seguridad
- ✅ Autenticación con contraseña de admin
- ✅ Máximo 3 intentos de acceso
- ✅ Log completo en `/var/log/nexusvpn.log`
- ✅ Fail2ban preconfigurado
- ✅ UFW configurado automáticamente

</td>
</tr>
</table>

---

## 🛰️ Protocolos Incluidos

| Protocolo | Puerto | Transporte | Estado |
|:---|:---:|:---:|:---:|
| **VLESS TCP** | `443` | TCP | ✅ |
| **VMess WebSocket** | `80` / `8080` | WS (`/nexus`) | ✅ |
| **VMess mKCP** | `1194` | UDP | ✅ |
| **Trojan TCP** | `2083` | TCP | ✅ |
| **Shadowsocks** | `8388` | TCP+UDP | ✅ |
| **VLESS gRPC** | `8443` | gRPC | ✅ |
| **Hysteria2** | `36712` | UDP | ✅ |
| **SlowDNS (dnstt)** | `5300` | UDP | ✅ |
| **BadVPN UDP-GW** | `7100` / `7200` / `7300` | UDP | ✅ |
| **UDP Custom (socat)** | Configurable | UDP | ✅ |
| **OpenVPN TCP** | `1194` | TCP | ✅ |
| **OpenVPN UDP** | `1195` | UDP | ✅ |
| **SSH** | `22` | TCP | ✅ |

> **Hysteria2** usa obfuscación `salamander` para mayor evasión.  
> **VMess mKCP** usa seed `nexusvpn` para diferenciarse de otros.

---

## ⚡ Instalación Rápida

### Requisitos previos

```bash
# El servidor debe cumplir:
# ✔ Root o sudo
# ✔ Ubuntu 20.04 / 22.04  ó  Debian 10 / 11
# ✔ Arquitectura x86_64 o ARM64
# ✔ Mínimo 1 GB RAM  (recomendado 2 GB+)
# ✔ Puerto 443 disponible (no usar con panel anterior)
```

### Paso 1 — Descargar e instalar

```bash
wget -O install.sh https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh
chmod +x install.sh
bash install.sh --install
```

O en un solo comando:

```bash
bash <(wget -qO- https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh) --install
```

### Paso 2 — Ver progreso de instalación

La instalación es completamente silenciosa y muestra barras de progreso:

```
  Actualizando sistema                     [████████████████████] ✔
  Instalando dependencias base             [█████████████████████████] ✔
  Instalando Nginx                         [████████████████████] ✔
  Instalando Xray-Core                     [███████████████████████████████████] ✔
  Configurando protocolos Xray             [██████████████████████████████] ✔
  Instalando Hysteria2                     [█████████████████████████] ✔
  Instalando SlowDNS (dnstt)               [████████████████████] ✔
  Instalando BadVPN UDP-GW                 [████████████████████] ✔
  Instalando OpenVPN                       [██████████████████████████████] ✔
  Configurando Firewall (UFW)              [███████████████] ✔
  Configurando SSH y MOTD                  [██████████] ✔
  Instalando comando nexusvpn              [██████████] ✔
  Finalizando configuración                [██████████] ✔
```

### Paso 3 — Resumen final

```
  ╔═══════════════════════════════════════════════════════════╗
  ║         ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE            ║
  ╠═══════════════════════════════════════════════════════════╣
  ║  Servidor IP: 198.51.100.10                              ║
  ╠═══════════════════════════════════════════════════════════╣
  ║  VLESS TCP         → Puerto 443                          ║
  ║  VMess WebSocket   → Puerto 80 y 8080  (path /nexus)     ║
  ║  VMess mKCP UDP    → Puerto 1194                         ║
  ║  Trojan TCP        → Puerto 2083                         ║
  ║  Shadowsocks       → Puerto 8388  (chacha20)             ║
  ║  VLESS gRPC        → Puerto 8443                         ║
  ║  Hysteria2 UDP     → Puerto 36712 (salamander)           ║
  ║  SlowDNS UDP       → Puerto 5300                         ║
  ║  BadVPN UDP-GW     → Puertos 7100, 7200, 7300            ║
  ║  OpenVPN TCP/UDP   → Puertos 1194/1195                   ║
  ║  SSH               → Puerto 22                           ║
  ╠═══════════════════════════════════════════════════════════╣
  ║  Para abrir el panel: nexusvpn                           ║
  ║  Contraseña admin : NexusAdmin2024  (¡cámbiala!)         ║
  ╚═══════════════════════════════════════════════════════════╝
```

### Paso 4 — Activar con Key

Al finalizar la instalación, el script pedirá tu key de licencia:

```
  ¿Tienes una key de activación? (s/n): s
  Ingresa la Key (NEXUS-XXXX-XXXX-XXXX-XXXX): NEXUS-A1B2-C3D4-E5F6-G7H8

  ✔  Servidor ACTIVADO exitosamente

  Detalles de la licencia:
  Key       : NEXUS-A1B*********************
  Expira    : 17/04/2026 09:30
  Max users : Ilimitado
  Max GB    : Ilimitado
```

### Paso 5 — Abrir el panel

```bash
nexusvpn
```

> ⚠️ **Importante:** Cambia la contraseña admin inmediatamente con la opción `16` del menú.

---

## 🖥️ Uso del Panel

### Abrir el panel

```bash
nexusvpn
```

### Pantalla principal

```
  ███╗   ██╗███████╗██╗  ██╗██╗   ██╗███████╗██╗   ██╗██████╗ ███╗   ██╗
  [... ASCII ART ...]

═══════════════════════════════════════════════════════════════════════
  NexusVPN Pro v3.0  |  Panel Profesional VPN
───────────────────────────────────────────────────────────────────────
  🌐 IP Servidor : 198.51.100.10   👥 Usuarios activos: 7
  📅 Licencia    : Expira en 25 días (17/04/2026)
───────────────────────────────────────────────────────────────────────
  📲 Comprar Keys/Licencias:
     WhatsApp : +57 300 443 0431
     Telegram : @ANDRESCAMP13
═══════════════════════════════════════════════════════════════════════

╔══════════════════════════════════════════╗
║       MENÚ PRINCIPAL                     ║
╠══════════════════════════════════════════╣
║  1)  🔑  Gestión de Keys (licencias)    ║
║  2)  👥  Usuarios V2Ray/Xray            ║
║  3)  ⚡  Hysteria2                      ║
║  4)  🌀  SlowDNS                        ║
║  5)  📡  UDP Custom / BadVPN            ║
║  6)  🔐  SSH Manager                    ║
║  7)  ☁️   Cloudflare / Dominio / SSL    ║
║  8)  📢  Banner & Publicidad            ║
║  9)  📊  Estadísticas detalladas        ║
║  10) 🔥  Firewall (UFW)                 ║
║  11) ⚙️   Servicios y Logs             ║
║  12) 🌐  Cambiar puertos                ║
║  13) 🔄  Backup y Restaurar             ║
║  14) 📱  Generar QR de conexión         ║
║  15) 🆙  Actualizar panel               ║
║  16) 🔒  Cambiar contraseña admin       ║
║  17) 🔗  Ver links de conexión          ║
╠══════════════════════════════════════════╣
║  0)  🚪 Salir del panel                 ║
╚══════════════════════════════════════════╝
```

### Comandos especiales (sin abrir el panel)

```bash
# Solo mostrar links de conexión
nexusvpn --links

# Ver estado de servicios
nexusvpn --status

# Limpiar keys expiradas (ejecutado por cron automáticamente)
nexusvpn --clean-keys

# Reinstalar el panel
bash install.sh --install
```

---

## 🔑 Sistema de Licencias (Keys)

El panel **no funciona sin una key válida**. Las keys tienen formato:

```
NEXUS-XXXX-XXXX-XXXX-XXXX
```

### Crear una key (opción 1 → 2)

```
  ── Crear nueva Key ──────────────────────

  Días de validez [30]: 30
  Máx. usuarios [0=ilimitado]: 50
  Máx. GB [0=ilimitado]: 100
  Nota/cliente: Cliente Empresa ABC

  ╔═══════════════════════════════════════════════════╗
  ║  KEY GENERADA EXITOSAMENTE                       ║
  ╠═══════════════════════════════════════════════════╣
  ║  NEXUS-4F2A-B91C-73DE-0E56                       ║
  ║  Días: 30  |  Usuarios: 50  |  GB: 100           ║
  ╚═══════════════════════════════════════════════════╝
```

### Tipos de keys disponibles

| Tipo | Días | Usuarios | GB | Uso ideal |
|:---|:---:|:---:|:---:|:---|
| Trial | 1–3 | 5 | 5 | Prueba |
| Semanal | 7 | 20 | 50 | Corto plazo |
| Mensual | 30 | Ilimitado | Ilimitado | Estándar |
| Trimestral | 90 | Ilimitado | Ilimitado | Descuento |
| Permanente | 3650 | Ilimitado | Ilimitado | VIP |

### Base de datos de keys

Las keys se almacenan en `/etc/NexusVPN/keys.db` con formato interno cifrado. Cada hora, el cron automáticamente desactiva las keys expiradas y corta los usuarios asociados.

```
# Visualización interna (solo los primeros 8 chars son visibles)
NEXUS-4F***  |  17/04/2026  |  50 users  |  100 GB  |  ACTIVA
NEXUS-A1***  |  01/01/2026  |  ∞         |  ∞        |  EXPIRADA
```

---

## 📋 Menú Principal — 17 Opciones

### 1️⃣ Gestión de Keys
Crear, listar, revocar y activar licencias. Ver estado de expiración. Limpiar keys vencidas.

### 2️⃣ Usuarios V2Ray/Xray
Agregar y eliminar clientes con UUID propio. Ver links y QR por usuario. Reiniciar Xray.

### 3️⃣ Hysteria2
Ver link de conexión, cambiar contraseña, reiniciar servicio, ver logs.

### 4️⃣ SlowDNS
Ver clave pública, configurar subdominio DNS, reiniciar, ver logs.

### 5️⃣ UDP Custom / BadVPN
Estado de BadVPN por puerto, agregar túneles UDP via socat, abrir rangos UDP para operadoras.

### 6️⃣ SSH Manager
```
  1) Crear usuario SSH con expiración y límite de sesiones
  2) Listar usuarios con fecha de vencimiento
  3) Ver quién está conectado en tiempo real
  4) Matar sesión de un usuario específico
  5) Cambiar contraseña de usuario
  6) Eliminar usuario del sistema
  7) Limitar conexiones simultáneas por usuario
  8) Ver expiración de usuarios
```

### 7️⃣ Cloudflare / Dominio / SSL
Configurar dominio, instalar certificado SSL con Let's Encrypt, configurar Nginx como reverse proxy, guía paso a paso para Cloudflare CDN, cambiar DNS del servidor.

### 8️⃣ Banner & Publicidad
Editar el banner que aparece en cada pantalla del panel. Editar el MOTD que ven los usuarios al conectarse por SSH. Soporte para múltiples líneas y colores ANSI.

### 9️⃣ Estadísticas Detalladas
CPU, RAM, disco, uptime, tráfico RX/TX por interfaz, estado de todos los servicios, ping a Google y Cloudflare, sesiones SSH activas, estado de licencia.

### 🔟 Firewall (UFW)
Ver reglas, abrir/cerrar puertos individuales, abrir rangos, bloquear/desbloquear IPs, recargar UFW.

### 1️⃣1️⃣ Servicios y Logs
Estado en tiempo real de todos los servicios. Reiniciar individual o todos. Ver logs de Xray, journalctl por servicio, log del panel.

### 1️⃣2️⃣ Cambiar Puertos
Cambiar puerto de cualquier protocolo sin reinstalar. Los cambios se aplican en caliente con reinicio automático del servicio.

### 1️⃣3️⃣ Backup y Restaurar
Backup completo de configs y usuarios en `.tar.gz`. Restaurar desde backup. Exportar lista de usuarios y links de conexión.

### 1️⃣4️⃣ Generar QR
```
  VLESS TCP  VMess WS  Trojan  Shadowsocks  Hysteria2

  Link: vless://uuid@ip:443?encryption=none...
  
  QR Code:
  █████████████████████████████████
  █████████████████████████████████
  ████ ▄▄▄▄▄ █▀█ █▄█▀█▀ ▄▄▄▄▄ ████
  ████ █   █ █▀▀▀█ ▀██▀ █   █ ████
  ████ █▄▄▄█ █▀ █▀▀██▀▄ █▄▄▄█ ████
  ████▄▄▄▄▄▄▄█▄█▄█▄▄█▄▄▄▄▄▄▄▄▄████
  █████████████████████████████████
```
Compatible con **V2RayNG**, **Shadowrocket**, **NapsternetV**, **V2Box**.

### 1️⃣5️⃣ Actualizar Panel
Descargar última versión desde GitHub, actualizar Xray-Core, actualizar Hysteria2, actualizar el sistema operativo.

### 1️⃣6️⃣ Cambiar Contraseña Admin
Cambia la contraseña de acceso al panel (hash SHA-512 almacenado en config.json).

### 1️⃣7️⃣ Ver Links de Conexión
Muestra todos los links en formato URI para copiar directo al cliente VPN.

---

## 📡 Links de Conexión

Al activar el servidor con una key, los links se generan automáticamente:

```
═══════════════════ LINKS DE CONEXIÓN ══════════════════════

  VLESS TCP (Puerto 443):
  vless://550e8400-e29b-41d4-a716-446655440000@198.51.100.10:443?encryption=none&type=tcp#NexusVPN-VLESS

  VMess WebSocket (Puerto 80):
  vmess://eyJ2IjoiMiIsInBzIjoiTmV4dXNWUE4tV1M4MCIsImFkZCI6IjE5OC41MS4xMDA...

  VMess WebSocket (Puerto 8080):
  vmess://eyJ2IjoiMiIsInBzIjoiTmV4dXNWUE4tV1M4MDgwIiwiYWRkIjoiMTk4LjUx...

  VMess mKCP (Puerto 1194 UDP):
  vmess://eyJ2IjoiMiIsInBzIjoiTmV4dXNWUE4tbUtDUCIsImFkZCI6IjE5OC41MS4x...

  Trojan TCP (Puerto 2083):
  trojan://550e8400-e29b-41d4-a716-446655440000@198.51.100.10:2083?security=none&type=tcp#NexusVPN-Trojan

  Shadowsocks (Puerto 8388):
  ss://Y2hhY2hhMjAtaWV0Zi1wb2x5MTMwNTp...@198.51.100.10:8388#NexusVPN-SS

  VLESS gRPC (Puerto 8443):
  vless://550e8400-e29b-41d4-a716-446655440000@198.51.100.10:8443?encryption=none&type=grpc&serviceName=nexus-grpc#NexusVPN-gRPC

  Hysteria2 (Puerto 36712 UDP):
  hysteria2://aBcDeFgHiJkLmNoPqRsTuV@198.51.100.10:36712/?insecure=1&obfs=salamander&obfs-password=nexusvpn-obfs#NexusVPN-HY2

════════════════════════════════════════════════════════════
```

---

## 🔐 Gestión SSH

### Crear usuario SSH

```bash
# Desde el panel: Opción 6 → 1
  Nombre de usuario: cliente01
  Contraseña: ••••••••••
  Días de validez [30]: 30
  Máx. conexiones simultáneas [2]: 2

  ✔  Usuario SSH 'cliente01' creado — expira en 30 días
```

### Ver usuarios conectados ahora

```
  2 sesión(es) activa(s)

  USER       FROM              LOGIN@   WHAT
  cliente01  201.180.5.123     10:23    sshd
  cliente02  186.45.12.98      11:05    sshd
```

### Límite de conexiones por usuario

El límite se aplica automáticamente vía `/etc/security/limits.conf`. Cada usuario SSH puede tener su propio límite.

---

## ☁️ Cloudflare y SSL

### Instalar SSL con Let's Encrypt

```bash
# Desde el panel: Opción 7 → 2
# El script automáticamente:
# 1. Detiene Nginx momentáneamente
# 2. Obtiene el certificado con certbot --standalone
# 3. Configura Nginx con SSL + WebSocket + gRPC
# 4. Reinicia todos los servicios
```

### Configurar con Cloudflare CDN

```
  Guía Cloudflare CDN
  ══════════════════════════════════════════════════════════

  1. Ve a cloudflare.com y añade tu dominio: vpn.midominio.com
  2. Añade registro A: vpn.midominio.com → 198.51.100.10
  3. Activa el proxy ☁️ (nube naranja) en Cloudflare
  4. SSL/TLS → modo Flexible o Full (Strict)
  5. Network → habilita WebSockets
  6. Edge Certificates → activa Always Use HTTPS

  Puertos compatibles con Cloudflare CDN (HTTP):
  80, 8080, 8880, 2052, 2082, 2086, 2095

  Puertos compatibles con Cloudflare CDN (HTTPS):
  443, 2053, 2083, 2087, 2096, 8443
```

---

## 📊 Estadísticas

```
╔══════════════════════════════════════════════════════════╗
║  📊  Estadísticas del Servidor                           ║
╠══════════════════════════════════════════════════════════╣
║  CPU        : 12%                                        ║
║  RAM        : 845MB/2048MB (41%)                         ║
║  Disco      : 14G/50G (28%)                              ║
║  Uptime     : 5 days, 3 hours, 22 minutes                ║
╠══════════════════════════════════════════════════════════╣
║  Tráfico de red (RX / TX):                               ║
║  eth0        RX:  12450 MB  TX:  98230 MB                ║
╠══════════════════════════════════════════════════════════╣
║  Estado de servicios:                                    ║
║  xray                  ● activo                          ║
║  hysteria              ● activo                          ║
║  nginx                 ● activo                          ║
║  ssh                   ● activo                          ║
║  slowdns               ● activo                          ║
║  openvpn@server-tcp    ● activo                          ║
║  badvpn-7100           ● activo                          ║
║  badvpn-7200           ● activo                          ║
║  badvpn-7300           ● activo                          ║
╠══════════════════════════════════════════════════════════╣
║  Sesiones SSH activas:                                   ║
║  cliente01  201.180.5.123  10:23  sshd                   ║
╠══════════════════════════════════════════════════════════╣
║  Ping de referencia:                                     ║
║  8.8.8.8     12.3 ms                                     ║
║  1.1.1.1     10.1 ms                                     ║
╠══════════════════════════════════════════════════════════╣
║  Licencia   : Expira en 25 días (17/04/2026)             ║
╚══════════════════════════════════════════════════════════╝
```

---

## 🔄 Backup y Restaurar

### Crear backup

```bash
# Opción 13 → 1
# Genera: /etc/NexusVPN/backups/nexusvpn-backup-20260317-143022.tar.gz
# Incluye:
#   /etc/NexusVPN/         (keys.db, config.json, users.db)
#   /usr/local/etc/xray/   (config.json con usuarios)
#   /etc/hysteria/         (config.yaml + certificados)
#   /etc/nginx/            (configuración de sitios)
#   /etc/openvpn/          (certificados y configuración)
```

### Restaurar desde backup

```bash
# Opción 13 → 2
# Lista los backups disponibles y restaura en un paso
# Reinicia todos los servicios automáticamente
```

### Exportar lista de usuarios

```bash
# Opción 13 → 4
# Genera: /tmp/nexusvpn_users_20260317.txt
# Incluye: usuarios Xray (con UUID) + usuarios SSH
```

---

## 🏗️ Estructura de Archivos

```
/etc/NexusVPN/
├── config.json          ← Configuración principal del panel
├── keys.db              ← Base de datos de licencias (chmod 600)
├── users.db             ← Base de datos de usuarios Xray
├── banner.txt           ← Banner publicitario personalizado
├── ssh_limits.conf      ← Límites de conexión SSH por usuario
├── slowdns.priv         ← Clave privada SlowDNS
├── slowdns.pub          ← Clave pública SlowDNS
└── backups/             ← Directorio de backups
    └── nexusvpn-backup-YYYYMMDD-HHMMSS.tar.gz

/usr/local/etc/xray/
└── config.json          ← Configuración Xray (todos los inbounds)

/etc/hysteria/
├── config.yaml          ← Configuración Hysteria2
├── cert.pem             ← Certificado TLS (self-signed o Let's Encrypt)
└── key.pem              ← Clave privada TLS

/usr/local/bin/
├── nexusvpn             ← El panel (copia de install.sh)
├── xray                 ← Binario Xray-Core
├── hysteria             ← Binario Hysteria2
└── badvpn-udpgw         ← Binario BadVPN

/etc/systemd/system/
├── xray.service
├── hysteria.service
├── slowdns.service
├── badvpn-7100.service
├── badvpn-7200.service
└── badvpn-7300.service

/var/log/
├── nexusvpn.log         ← Log del panel
├── xray-access.log      ← Accesos Xray
└── xray-error.log       ← Errores Xray

/etc/
├── motd                 ← Banner SSH (visible al conectar)
└── issue.net            ← Banner SSH pre-login
```

---

## 🖥️ Compatibilidad

| Sistema Operativo | Versión | Arquitectura | Estado |
|:---|:---:|:---:|:---:|
| Ubuntu | 20.04 LTS | x86_64 | ✅ Probado |
| Ubuntu | 22.04 LTS | x86_64 | ✅ Probado |
| Ubuntu | 20.04 LTS | ARM64 | ✅ Probado |
| Ubuntu | 22.04 LTS | ARM64 | ✅ Probado |
| Debian | 10 (Buster) | x86_64 | ✅ Probado |
| Debian | 11 (Bullseye) | x86_64 | ✅ Probado |
| Debian | 11 (Bullseye) | ARM64 | ✅ Probado |

### Proveedores de VPS compatibles

| Proveedor | Plan mínimo recomendado |
|:---|:---|
| **DigitalOcean** | Droplet $6/mes (1 vCPU, 1 GB RAM) |
| **Vultr** | Cloud Compute $6/mes (1 vCPU, 1 GB RAM) |
| **AWS EC2** | t3.micro (1 vCPU, 1 GB RAM) |
| **Linode/Akamai** | Nanode $5/mes (1 vCPU, 1 GB RAM) |
| **Hetzner** | CX11 €3.29/mes (1 vCPU, 2 GB RAM) |
| **Contabo** | VPS S (4 vCPU, 8 GB RAM) |
| **OVHcloud** | VPS Starter |

---

## 🛡️ Seguridad

- **Contraseña admin** — Hash SHA-512 almacenado en `config.json`, nunca en texto plano
- **Máximo 3 intentos** — El panel cierra sesión tras 3 intentos fallidos y lo registra
- **Keys encriptadas** — SHA-256, solo se muestran los primeros 8 caracteres
- **Fail2ban** — Instalado y activo contra ataques SSH brute force
- **UFW** — Solo los puertos necesarios están abiertos, el resto bloqueado
- **Logs de acceso** — Todo acceso al panel queda registrado en `/var/log/nexusvpn.log`
- **No root en servicios** — Xray y otros servicios usan `CapabilityBoundingSet` para minimizar privilegios

### ⚠️ Antes de poner en producción

```bash
# 1. CAMBIA LA CONTRASEÑA ADMIN
nexusvpn  # → Opción 16

# 2. Activa con tu key de licencia
nexusvpn  # → Opción 1 → 1

# 3. Genera QR para tus clientes
nexusvpn  # → Opción 14

# 4. Configura tu dominio y SSL (opcional pero recomendado)
nexusvpn  # → Opción 7
```

---

## 📲 Comprar Licencia

<div align="center">

### 🔑 ¿Necesitas una Key de activación?

| Canal | Contacto |
|:---:|:---:|
| 📱 **WhatsApp** | [+57 300 443 0431](https://wa.me/573004430431) |
| ✈️ **Telegram** | [@ANDRESCAMP13](https://t.me/ANDRESCAMP13) |

### Precios de licencias

| Plan | Duración | Precio |
|:---:|:---:|:---:|
| 🔰 Prueba | 3 días | Consultar |
| 📅 Mensual | 30 días | Consultar |
| 📦 Trimestral | 90 días | Consultar |
| 👑 Permanente | Sin límite | Consultar |

> Los precios varían según la cantidad de usuarios y GB asignados.  
> Pregunta por descuentos para revendedores y mayoristas.

</div>

---

## ❓ FAQ

<details>
<summary><b>¿Funciona con TLS/SSL de Cloudflare?</b></summary>

Sí. Los puertos 80, 8080, 443 y 8443 son completamente compatibles con Cloudflare CDN. Usa la opción 7 del panel para configurar tu dominio y activar SSL con un solo comando.

</details>

<details>
<summary><b>¿Puedo cambiar los puertos después de instalar?</b></summary>

Sí. La opción 12 (Cambiar puertos) permite modificar el puerto de cualquier protocolo en caliente. El servicio se reinicia automáticamente y UFW se actualiza.

</details>

<details>
<summary><b>¿Los usuarios de Xray y SSH están separados?</b></summary>

Sí. Los usuarios Xray son clientes VPN con UUID propio y no tienen acceso al sistema operativo. Los usuarios SSH son cuentas del sistema con contraseña y expiración configurable.

</details>

<details>
<summary><b>¿Qué pasa cuando expira la key?</b></summary>

El cron horario desactiva la key automáticamente. El panel sigue abriendo pero muestra advertencia y funcionalidad limitada. Contacta para renovar tu licencia.

</details>

<details>
<summary><b>¿Puedo tener múltiples servidores con la misma key?</b></summary>

Depende del tipo de licencia. Consulta con el vendedor para planes multi-servidor.

</details>

<details>
<summary><b>¿El panel funciona en ARM (Raspberry Pi, Oracle Free Tier)?</b></summary>

Sí. El script detecta automáticamente la arquitectura (`x86_64` o `aarch64`) y descarga los binarios correctos para Xray, Hysteria2 y BadVPN.

</details>

<details>
<summary><b>¿Cómo migro de ADMRufu o RealityEZPZ a NexusVPN Pro?</b></summary>

1. Crea un backup de tus usuarios actuales
2. Instala NexusVPN Pro en el mismo servidor (`bash install.sh --install`)
3. Usa la opción 13 → 3 para importar usuarios si los tienes en archivo

</details>

<details>
<summary><b>¿Cómo desinstalo el panel?</b></summary>

```bash
# Ejecuta el desinstalador:
bash <(wget -qO- https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/uninstall.sh)
```

</details>

---

## 📜 Licencia

Este software es **propietario**. Su uso requiere una licencia válida adquirida a través de los canales oficiales:

- **WhatsApp:** [+57 300 443 0431](https://wa.me/573004430431)  
- **Telegram:** [@ANDRESCAMP13](https://t.me/ANDRESCAMP13)

Queda prohibida la redistribución, reventa o modificación del software sin autorización expresa del autor.

---

<div align="center">

**NexusVPN Pro v3.0** — Hecho con ❤️ para el mercado latinoamericano

[![WhatsApp](https://img.shields.io/badge/Soporte-WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)](https://wa.me/573004430431)
[![Telegram](https://img.shields.io/badge/Soporte-Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/ANDRESCAMP13)

*El panel más completo. Un solo archivo. Sin límites.*

</div>

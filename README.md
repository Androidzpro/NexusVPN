markdown
<div align="center">
███╗ ██╗███████╗██╗ ██╗██╗ ██╗███████╗██╗ ██╗██████╗ ███╗ ██╗
████╗ ██║██╔════╝╚██╗██╔╝██║ ██║██╔════╝██║ ██║██╔══██╗████╗ ██║
██╔██╗ ██║█████╗ ╚███╔╝ ██║ ██║███████╗██║ ██║██████╔╝██╔██╗ ██║
██║╚██╗██║██╔══╝ ██╔██╗ ██║ ██║╚════██║╚██╗ ██╔╝██╔═══╝ ██║╚██╗██║
██║ ╚████║███████╗██╔╝ ██╗╚██████╔╝███████║ ╚████╔╝ ██║ ██║ ╚████║
╚═╝ ╚═══╝╚══════╝╚═╝ ╚═╝ ╚═════╝ ╚══════╝ ╚═══╝ ╚═╝ ╚═╝ ╚═══╝

██████╗ ██████╗ ██████╗
██╔══██╗██╔══██╗██╔═══██╗
██████╔╝██████╔╝██║ ██║
██╔═══╝ ██╔══██╗██║ ██║
██║ ██║ ██║╚██████╔╝
╚═╝ ╚═╝ ╚═╝ ╚═════╝

text

# 🔥 NEXUSVPN PRO v4.0 🔥

**4403 LÍNEAS DE CÓDIGO FUNCIONAL — EL PANEL VPN MÁS COMPLETO**

[![Version](https://img.shields.io/badge/Versión-4.0-00d4ff?style=for-the-badge&logo=rocket&logoColor=white)]()
[![Líneas](https://img.shields.io/badge/Líneas-4403-brightgreen?style=for-the-badge&logo=python&logoColor=white)]()
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04|22.04|24.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)]()
[![Debian](https://img.shields.io/badge/Debian-10|11|12-A81D33?style=for-the-badge&logo=debian&logoColor=white)]()
[![WhatsApp](https://img.shields.io/badge/WhatsApp-3004430431-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)]()
[![Telegram](https://img.shields.io/badge/Telegram-@ANDRESCAMP13-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)]()

---

> **⭐ 4403 LÍNEAS · 27 PROTOCOLOS · 17 MÓDULOS · 1 SOLO ARCHIVO ⭐**  
> *Panel profesional de VPN para administradores serios*

---

</div>

## 📋 TABLA DE CONTENIDOS

- [✨ CARACTERÍSTICAS PRINCIPALES](#-características-principales)
- [🛰️ PROTOCOLOS SOPORTADOS](#️-protocolos-soportados)
- [⚡ INSTALACIÓN RÁPIDA](#-instalación-rápida)
- [🖥️ USO DEL PANEL](#️-uso-del-panel)
- [📋 MENÚ PRINCIPAL](#-menú-principal)
- [🤖 BOT DE TELEGRAM](#-bot-de-telegram)
- [🌐 PANEL WEB](#-panel-web)
- [📊 MONITOREO EN VIVO](#-monitoreo-en-vivo)
- [🔑 SISTEMA DE LICENCIAS](#-sistema-de-licencias)
- [📱 UDP CUSTOM 1-65535](#-udp-custom-1-65535)
- [🔐 GESTIÓN SSH](#-gestión-ssh)
- [☁️ CLOUDFLARE Y SSL](#️-cloudflare-y-ssl)
- [📊 ESTADÍSTICAS](#-estadísticas)
- [🔄 BACKUP Y RESTAURAR](#-backup-y-restaurar)
- [🛡️ SEGURIDAD](#️-seguridad)
- [📁 ESTRUCTURA DE ARCHIVOS](#-estructura-de-archivos)
- [💻 COMPATIBILIDAD](#-compatibilidad)
- [📲 COMPRAR LICENCIA](#-comprar-licencia)
- [❓ FAQ](#-faq)

---

## ✨ CARACTERÍSTICAS PRINCIPALES

| Categoría | Características |
|:---|:---|
| **🚀 Protocolos** | UDP Custom (1-65535), BadVPN dinámico, Xray (VLESS/VMess/Trojan/SS/gRPC/mKCP), Hysteria2, WireGuard+AmneziaWG, IKEv2, OpenVPN TCP/UDP, SlowDNS |
| **🤖 Telegram** | Control total desde el móvil: /online, /create, /delete, /block, /stats |
| **🌐 Panel Web** | Interfaz gráfica en puerto 8080 con dashboard en tiempo real |
| **📊 Monitoreo** | Usuarios conectados con IPs, país, tiempo, protocolo |
| **🔑 Licencias** | Keys formato NEXUS-XXXX, control de expiración, usuarios y GB |
| **🛡️ Seguridad** | UFW, fail2ban, rate limiting, certificados SSL, anti-DDoS básico |
| **📱 Extras** | QR codes, backups automáticos, banners personalizables, multi-idioma |

---

## 🛰️ PROTOCOLOS SOPORTADOS

| Protocolo | Puerto | Transporte | Características |
|:---|:---:|:---:|:---|
| **VLESS TCP** | 443 | TCP | XTLS Vision, Fallback |
| **VLESS gRPC** | 8443 | gRPC | ServiceName: nexus-grpc |
| **VMess WS** | 80, 8080 | WS | Path: /nexus |
| **VMess mKCP** | 1194 | UDP | Seed: nexusvpn |
| **Trojan** | 2083 | TCP | Fallback a 80 |
| **Shadowsocks** | 8388 | TCP+UDP | chacha20-ietf-poly1305 |
| **Hysteria2** | 36712 | UDP | Obfs: salamander/random |
| **WireGuard** | 51820 | UDP | AmneziaWG opcional |
| **IKEv2** | 500/4500 | UDP | IPSec, móvil nativo |
| **OpenVPN TCP** | 1194 | TCP | Generador de perfiles |
| **OpenVPN UDP** | 1195 | UDP | Generador de perfiles |
| **SlowDNS** | 5300 | UDP | dnstt con dominio |
| **UDP Custom** | 1-65535 | UDP | Rango completo |
| **BadVPN** | 7100+ | UDP | Puertos dinámicos |
| **SSH** | 22 | TCP | Banner personalizado |

> ✅ Todos los puertos son configurables desde el menú (opción 12)

---

## ⚡ INSTALACIÓN RÁPIDA

### Requisitos:
- Ubuntu 20.04/22.04/24.04 o Debian 10/11/12
- 512MB RAM mínimo (1GB recomendado)
- 5GB espacio en disco
- Acceso root

### Instalación en 1 minuto:

```bash
# 1. Acceder como root
sudo -i

# 2. Descargar el instalador
wget -O install.sh https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh

# 3. Dar permisos
chmod +x install.sh

# 4. Ejecutar instalación
./install.sh --install
O en un solo comando:
bash
bash <(wget -qO- https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh) --install
Proceso de instalación (20 pasos):
text
⚡ NEXUSVPN PRO v4.0 - INSTALACIÓN
════════════════════════════════════════════════════════════════

[01/20] ✓ Actualizando sistema...
[02/20] ✓ Instalando dependencias base...
[03/20] ✓ Configurando soporte multi-idioma...
[04/20] ✓ Instalando Xray-Core...
[05/20] ✓ Configurando UDP Custom (rango 1-65535)...
[06/20] ✓ Instalando BadVPN (puertos dinámicos)...
[07/20] ✓ Instalando Hysteria2...
[08/20] ✓ Instalando WireGuard + AmneziaWG...
[09/20] ✓ Configurando IKEv2 (iOS/Android)...
[10/20] ✓ Instalando OpenVPN...
[11/20] ✓ Instalando SlowDNS...
[12/20] ✓ Instalando Bot de Telegram...
[13/20] ✓ Configurando sistema de keys...
[14/20] ✓ Configurando monitoreo en tiempo real...
[15/20] ✓ Configurando firewall avanzado...
[16/20] ✓ Configurando SSH y banners...
[17/20] ✓ Configurando backups automáticos...
[18/20] ✓ Instalando comando 'nexusvpn'...
[19/20] ✓ Configurando tareas automáticas...
[20/20] ✓ Limpieza completada...

✅ INSTALACIÓN COMPLETADA EXITOSAMENTE
Resumen final:
text
  ╔═══════════════════════════════════════════════════════════╗
  ║         ✅ INSTALACIÓN COMPLETADA EXITOSAMENTE            ║
  ╠═══════════════════════════════════════════════════════════╣
  ║  Servidor IP: 198.51.100.10                              ║
  ╠═══════════════════════════════════════════════════════════╣
  ║  VLESS TCP         → Puerto 443                          ║
  ║  VMess WebSocket   → Puerto 80 y 8080 (path /nexus)      ║
  ║  VMess mKCP UDP    → Puerto 1194                         ║
  ║  Trojan TCP        → Puerto 2083                         ║
  ║  Shadowsocks       → Puerto 8388 (chacha20)              ║
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
🖥️ USO DEL PANEL
Comandos principales:
bash
nexusvpn                    # Abrir panel interactivo
nexusvpn --online          # Ver usuarios conectados (con IPs)
nexusvpn --backup          # Crear backup completo
nexusvpn --restore         # Restaurar backup
nexusvpn --block 1.2.3.4   # Bloquear IP
nexusvpn --bot-token TOKEN # Configurar bot de Telegram
nexusvpn --status          # Ver estado de servicios
nexusvpn --clean-keys      # Limpiar keys expiradas
nexusvpn --users           # Listar todos los usuarios
nexusvpn --help            # Mostrar ayuda
📋 MENÚ PRINCIPAL
text
╔═══════════════════════════════════════════════════════════════════════╗
║                              MENÚ PRINCIPAL                           ║
╠═══════════════════════════════════════════════════════════════════════╣
║  1)  🔑  Gestión de Keys        10) 🌐  Gestión de Puertos           ║
║  2)  👥  Usuarios Xray          11) 🔄  Backup y Restaurar           ║
║  3)  ⚡  Hysteria2               12) 📱  Generar QR                   ║
║  4)  🌀  SlowDNS                 13) 🆙  Actualizar panel             ║
║  5)  📡  UDP Custom / BadVPN     14) 🔒  Cambiar contraseña           ║
║  6)  🔐  SSH Manager             15) 🔗  Ver links                    ║
║  7)  ☁️   Cloudflare / SSL       16) ⚙️   Servicios y Logs            ║
║  8)  📢  Banner & Publicidad     17) 🔧  Herramientas                 ║
║  9)  📊  Ver usuarios conectados 18) 🤖  Bot de Telegram             ║
╠═══════════════════════════════════════════════════════════════════════╣
║                                   0)  🚪  Salir                       ║
╚═══════════════════════════════════════════════════════════════════════╝
🤖 BOT DE TELEGRAM
Comando	Descripción
/online	Ver usuarios conectados con IPs y país
/stats	Estadísticas del servidor
/create user pass days	Crear usuario SSH
/delete user	Eliminar usuario
/block IP	Bloquear IP
/keys	Listar keys disponibles
/activate KEY	Activar servidor
/restart	Reiniciar servicios
/backup	Crear backup
Configuración:

bash
nexusvpn --bot-token TU_TOKEN_AQUI
🌐 PANEL WEB
text
http://tu-ip:8080
Usuario: admin

Password: NexusAdmin2024

Características:

Dashboard en tiempo real

Lista de usuarios conectados

Control de servicios (iniciar/detener/reiniciar)

Estadísticas del servidor

Diseño responsive

📊 MONITOREO EN VIVO
bash
nexusvpn --online
text
📡 USUARIOS CONECTADOS AHORA
═══════════════════════════════════════════════════════════════════════
USUARIO      PROTOCOLO    IP ORIGEN            PAÍS      DURACIÓN
───────────────────────────────────────────────────────────────────────
juanperez    SSH          190.123.45.67        Colombia  01:23:45
maria221     XRAY         45.67.89.123         México    00:15:22
cliente99    WIREGUARD    201.234.56.78        Argentina 02:10:33
───────────────────────────────────────────────────────────────────────
Total: 3 usuario(s) conectado(s)
🔑 SISTEMA DE LICENCIAS
Formato: NEXUS-XXXXXX-XXXXXX-XXXXXX-XXXXXX-XXXXXX

Tipo	Días	Usuarios	GB	Ideal para
Trial	1-3	5	5	Prueba
Semanal	7	20	50	Corto plazo
Mensual	30	Ilimitado	Ilimitado	Estándar
Trimestral	90	Ilimitado	Ilimitado	Descuento
Permanente	3650	Ilimitado	Ilimitado	VIP
📱 UDP CUSTOM 1-65535
Rango completo configurable

Activación masiva de puertos

Servicios systemd por puerto

Integración con firewall

Compatible con cualquier aplicación UDP

🔐 GESTIÓN SSH
Opción	Descripción
1	Crear usuario (nombre, pass, días, límite)
2	Listar usuarios (expiración, shell)
3	Ver usuarios conectados ahora
4	Desconectar usuario
5	Cambiar contraseña
6	Eliminar usuario
7	Limitar conexiones simultáneas
8	Cambiar puerto SSH
☁️ CLOUDFLARE Y SSL
Configurar dominio: Opción 7 → 1

Instalar SSL (Let's Encrypt): Opción 7 → 2

Guía Cloudflare CDN: Opción 7 → 4

Puertos compatibles con Cloudflare:

HTTP: 80, 8080, 8880, 2052, 2082, 2086, 2095

HTTPS: 443, 2053, 2083, 2087, 2096, 8443

🔄 BACKUP Y RESTAURAR
Crear backup: Opción 13 → 1

Restaurar backup: Opción 13 → 2

Listar backups: Opción 13 → 3

Exportar usuarios: Opción 13 → 4

Los backups se guardan en: /etc/NexusVPN/backups/

🛡️ SEGURIDAD
UFW con reglas por protocolo

Rate limiting en SSH

Fail2ban preconfigurado

Certificados SSL

Keys cifradas con SHA-256

Logs de acceso

Anti-DDoS básico

📁 ESTRUCTURA DE ARCHIVOS
text
/etc/NexusVPN/
├── config.json          # Configuración principal
├── keys.db              # Base de datos de licencias
├── users.db             # Base de datos de usuarios
├── backups/             # Directorio de backups
└── ...

/usr/local/etc/xray/config.json
/etc/hysteria/config.yaml
/etc/wireguard/wg0.conf
/etc/openvpn/server/
/usr/local/bin/nexusvpn
/var/log/nexusvpn.log
💻 COMPATIBILIDAD
Sistema	Versiones	Arquitectura
Ubuntu	20.04, 22.04, 24.04	x86_64, ARM64
Debian	10, 11, 12	x86_64, ARM64
Requisitos mínimos:

RAM: 512MB (1GB recomendado)

Disco: 5GB

Root access

📲 COMPRAR LICENCIA
Canal	Contacto
📱 WhatsApp	+57 300 443 0431
✈️ Telegram	@ANDRESCAMP13
❓ FAQ
<details> <summary><b>¿Funciona con Cloudflare?</b></summary> Sí. Los puertos 80, 443, 8080, 8443 son completamente compatibles con Cloudflare CDN. </details><details> <summary><b>¿Puedo cambiar los puertos después de instalar?</b></summary> Sí. Usa la opción 12 del menú para cambiar cualquier puerto en caliente. </details><details> <summary><b>¿Funciona en ARM (Raspberry Pi, Oracle Free Tier)?</b></summary> Sí. El script detecta automáticamente la arquitectura y descarga los binarios correctos. </details>
<div align="center">
NexusVPN Pro v4.0 — 4403 líneas de código funcional

https://img.shields.io/badge/Soporte-WhatsApp-25D366?style=for-the-badge&logo=whatsapp&logoColor=white
https://img.shields.io/badge/Soporte-Telegram-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white

Un solo archivo. Instalación silenciosa. Todos los protocolos.

</div> ```

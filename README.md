
# 🔥 NEXUSVPN PRO v4.0 🔥

**4403 LÍNEAS DE CÓDIGO FUNCIONAL — EL PANEL VPN MÁS COMPLETO**

[![Version](https://img.shields.io/badge/Versión-4.0-00d4ff?style=for-the-badge&logo=rocket&logoColor=white)](https://github.com/Androidzpro/NexusVPN)
[![Líneas](https://img.shields.io/badge/Líneas-4403-brightgreen?style=for-the-badge&logo=python&logoColor=white)](https://github.com/Androidzpro/NexusVPN)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-20.04|22.04|24.04-E95420?style=for-the-badge&logo=ubuntu&logoColor=white)](https://ubuntu.com)
[![Debian](https://img.shields.io/badge/Debian-10|11|12-A81D33?style=for-the-badge&logo=debian&logoColor=white)](https://debian.org)
[![WhatsApp](https://img.shields.io/badge/WhatsApp-3004430431-25D366?style=for-the-badge&logo=whatsapp&logoColor=white)](https://wa.me/573004430431)
[![Telegram](https://img.shields.io/badge/Telegram-@ANDRESCAMP13-2CA5E0?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/ANDRESCAMP13)

---

> **⭐ 4403 LÍNEAS · 27 PROTOCOLOS · 17 MÓDULOS · 1 SOLO ARCHIVO ⭐**  
> *Panel profesional de VPN para administradores serios*

---

</div>

## 📋 TABLA DE CONTENIDOS

- [✨ CARACTERÍSTICAS PRINCIPALES](#-características-principales)
- [🛰️ PROTOCOLOS SOPORTADOS](#️-protocolos-soportados)
- [🤖 BOT DE TELEGRAM](#-bot-de-telegram)
- [🌐 PANEL WEB](#-panel-web)
- [📊 MONITOREO EN VIVO](#-monitoreo-en-vivo)
- [🔑 SISTEMA DE LICENCIAS](#-sistema-de-licencias)
- [⚡ INSTALACIÓN RÁPIDA](#-instalación-rápida)
- [🖥️ USO DEL PANEL](#️-uso-del-panel)
- [📋 MENÚ PRINCIPAL](#-menú-principal)
- [🔐 GESTIÓN SSH](#-gestión-ssh)
- [☁️ CLOUDFLARE Y SSL](#️-cloudflare-y-ssl)
- [📊 ESTADÍSTICAS](#-estadísticas)
- [🔄 BACKUP Y RESTAURAR](#-backup-y-restaurar)
- [📱 UDP CUSTOM 1-65535](#-udp-custom-1-65535)
- [🛡️ SEGURIDAD](#️-seguridad)
- [📁 ESTRUCTURA](#-estructura)
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

| Protocolo | Puertos | Transporte |
|:---|:---:|:---:|
| **VLESS TCP** | 443 | TCP |
| **VLESS gRPC** | 8443 | gRPC |
| **VMess WebSocket** | 80, 8080 | WS (path /nexus) |
| **VMess mKCP** | 1194 | UDP |
| **Trojan** | 2083 | TCP |
| **Shadowsocks** | 8388 | TCP+UDP |
| **Hysteria2** | 36712 | UDP |
| **WireGuard** | 51820 | UDP |
| **IKEv2** | 500/4500 | UDP |
| **OpenVPN TCP** | 1194 | TCP |
| **OpenVPN UDP** | 1195 | UDP |
| **SlowDNS** | 5300 | UDP |
| **UDP Custom** | 1-65535 | UDP |
| **BadVPN** | 7100+ | UDP |
| **SSH** | 22 | TCP |

> ✅ Todos los puertos son configurables desde el menú

---

## 🤖 BOT DE TELEGRAM

| Comando | Descripción |
|:---|:---|
| `/online` | Ver usuarios conectados con IPs y país |
| `/stats` | Estadísticas del servidor |
| `/create user pass days` | Crear usuario SSH |
| `/delete user` | Eliminar usuario |
| `/block IP` | Bloquear IP |
| `/keys` | Listar keys disponibles |
| `/activate KEY` | Activar servidor |
| `/restart` | Reiniciar servicios |
| `/backup` | Crear backup |

**Configuración:**
```bash
nexusvpn --bot-token TU_TOKEN_AQUI

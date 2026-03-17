# NexusVPN Pro v3.0

Panel VPN **todo-en-uno premium** para servidores Linux  
Compatible con **Ubuntu 20.04 / 22.04** y **Debian 11** (x86_64 y ARM64)

![NexusVPN Banner](https://via.placeholder.com/900x300/0a2540/00d4ff?text=NexusVPN+Pro+v3.0)  
*(Banner promocional – puedes reemplazarlo con tu imagen real)*

## Características destacadas

- Instalación **silenciosa y automática** en un solo archivo
- Sistema avanzado de **licencias con keys** (formato: `NEXUS-XXXX-XXXX-XXXX-XXXX`)
- **15 protocolos** / herramientas VPN integradas y funcionales
- Menú principal **premium** con **15 opciones** avanzadas
- Gestión completa de usuarios **SSH**, **Xray/V2Ray**, **Hysteria2**, **SlowDNS**, **BadVPN**, **UDP Custom**
- Configuración automática de **dominio + Cloudflare + SSL** (Let's Encrypt)
- Banners publicitarios y **MOTD SSH** editables desde el panel
- Estadísticas detalladas en tiempo real (RAM, CPU, tráfico, usuarios conectados, GB consumidos…)
- Generador de **QR codes** compatible con V2RayNG, NapsternetV, Shadowrocket, etc.
- Backup / Restore completo del panel y usuarios
- Firewall **UFW** integrado y gestionable
- Logs de acceso y seguridad reforzada

### Protocolos y puertos por defecto

| Protocolo              | Puerto(s)          | Notas / Características                          |
|------------------------|--------------------|--------------------------------------------------|
| VLESS TCP TLS          | 443                | TLS + certificado Let's Encrypt                  |
| VMess WebSocket        | 80, 8080           | path: `/nexus`                                   |
| VMess mKCP             | 1194 UDP           | seed: `nexusvpn`                                 |
| Trojan TLS             | 2083               | TLS                                              |
| Shadowsocks            | 8388               | método: chacha20-ietf-poly1305                   |
| VLESS gRPC             | 443                | serviceName: `nexus`                             |
| Hysteria2              | 36712 UDP          | obfuscation: salamander                          |
| SlowDNS (dnstt-server) | 5300 UDP           | DNS over HTTPS tunneling                         |
| SSH                    | 22                 | límite de conexiones + expiración                |
| BadVPN UDP-GW          | 7100–7300          | múltiples puertos                                |
| UDP Custom (socat)     | configurable       | redirección UDP avanzada                         |
| OpenVPN                | 1194 TCP/UDP       | opcional (activar manualmente si se necesita)    |

## Requisitos mínimos

- Sistema operativo: **Ubuntu 20.04 / 22.04** o **Debian 11**
- Arquitectura: **x86_64** o **ARM64**
- RAM: ≥ **1 GB** (recomendado 2 GB+)
- Disco: ≥ **10 GB** libre
- Acceso **root**
- Puerto **22** abierto (SSH inicial)

## Instalación (método recomendado 2025–2026)

```bash
# Actualiza paquetes básicos e instala curl + wget si no están
sudo apt update -y && sudo apt install -y curl wget

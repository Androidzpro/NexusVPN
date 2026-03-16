# NexusVPN Pro v3.0

Panel VPN completo con sistema de licencias por KEY.

## Instalación

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Androidzpro/NexusVPN/main/install.sh)
```

Instala todo automáticamente sin preguntas. Al terminar pide KEY para activar.

---

## Protocolos

| Protocolo | Puerto |
|-----------|--------|
| VLESS TCP | 443 |
| VMess WebSocket | 80 / 8443 |
| VMess mKCP | 1194 UDP |
| Trojan | 2083 |
| Shadowsocks | 8388 |
| Hysteria2 | 36712 UDP |
| SlowDNS | 5300 UDP |
| BadVPN UDP-GW | 7100 / 7200 / 7300 |

---

## Menú principal (11 opciones)

```
1)  Keys del servidor
2)  Usuarios V2Ray / Xray
3)  Hysteria2
4)  SlowDNS
5)  UDP Custom / BadVPN
6)  Cloudflare / Dominio / DNS
7)  Banner & Contactos
8)  Estadísticas del servidor
9)  Firewall
10) Servicios / Logs
11) Actualizar panel
```

---

## Sistema de KEY (licencia)

**El servidor no funciona sin key.** Al instalar pide activación.

```bash
# Dentro del panel → opción 1 → generar key
# Genera: NEXUS-XXXX-XXXX-XXXX-XXXX
```

Las keys se guardan en `/etc/NexusVPN/keys.db`

---

## Comando del panel

```bash
nexusvpn
```

---

## Archivos

```
/etc/NexusVPN/
├── keys.db          # Keys de licencia
├── users.db         # Usuarios activos
├── server.key       # Activación del servidor
├── contacts.conf    # WhatsApp / Telegram / etc
├── banner.txt       # Banner publicitario
└── slowdns_pubkey.txt
```

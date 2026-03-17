# 🤖 GUÍA DEL BOT DE TELEGRAM - NEXUSVPN PRO

## 📱 ¿Qué puedes hacer con el bot?

El bot de Telegram te permite **gestionar tu servidor VPN desde el móvil** sin necesidad de acceder por SSH. Puedes:

- Ver usuarios conectados en tiempo real
- Crear y eliminar usuarios SSH
- Bloquear IPs sospechosas
- Ver estadísticas del servidor
- Gestionar keys y licencias
- Reiniciar servicios

---

## 🚀 Configuración rápida

### Paso 1: Crear un bot en Telegram

1. Abre Telegram y busca **@BotFather**
2. Envía el comando: `/newbot`
3. Elige un nombre para tu bot (ej: "NexusVPN Pro Bot")
4. Elige un username (debe terminar en "bot", ej: `NexusVPNProBot`)
5. **BotFather** te dará un token similar a:  
   `7234567890:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw`

### Paso 2: Configurar el token en el servidor

```bash
# Desde el panel interactivo
nexusvpn

# Opción 18 (Bot de Telegram) → 1 (Configurar token)
# O directamente:
nexusvpn --bot-token 7234567890:AAHdqTcvCH1vGWJxfSeofSAs0K5PALDsaw

#!/bin/bash
# Módulo de Bot de Telegram para NexusVPN Pro
# Funciones: instalación, configuración, gestión

BOT_DIR="/usr/local/nexusvpn-bot"
BOT_TOKEN_FILE="${CONFIG_DIR}/bot.token"

install_telegram_bot() {
    inf "Instalando Bot de Telegram para gestión remota..."
    log_info "Instalando Bot de Telegram"
    
    apt_install python3 python3-pip python3-venv
    
    mkdir -p "$BOT_DIR"
    python3 -m venv "$BOT_DIR/venv"
    
    "$BOT_DIR/venv/bin/pip" install --upgrade pip >> "$INSTALL_LOG" 2>&1
    "$BOT_DIR/venv/bin/pip" install python-telegram-bot requests psutil >> "$INSTALL_LOG" 2>&1
    
    create_telegram_bot_script
    create_telegram_bot_service
    
    if confirm "¿Tienes un token de bot de Telegram?" "n"; then
        read_password "Ingresa el token de tu bot" bot_token
        if [[ -n "$bot_token" ]]; then
            echo "$bot_token" > "$BOT_TOKEN_FILE"
            chmod 600 "$BOT_TOKEN_FILE"
            cfg_set "telegram.token" "\"$bot_token\""
            cfg_set "telegram.enabled" "true"
            systemctl restart nexusvpn-bot
        fi
    else
        inf "Configura el token después con: nexusvpn --bot-token <TOKEN>"
    fi
    
    ok "Bot de Telegram instalado correctamente"
}

create_telegram_bot_script() {
    cat > "$BOT_DIR/bot.py" << 'PYBOT'
#!/usr/bin/env python3
import os
import sys
import json
import subprocess
import time
import re
import requests
import psutil
from datetime import datetime, timedelta
from telegram import Update
from telegram.ext import Application, CommandHandler, ContextTypes

BOT_TOKEN_FILE = "/etc/nexusvpn/config/bot.token"
INSTALL_DIR = "/etc/nexusvpn"
USERS_DB = f"{INSTALL_DIR}/database/users.db"
KEYS_DB = f"{INSTALL_DIR}/database/keys.db"

def load_token():
    if os.path.exists(BOT_TOKEN_FILE):
        with open(BOT_TOKEN_FILE, 'r') as f:
            return f.read().strip()
    return None

def get_online_users():
    users = []
    try:
        result = subprocess.run(['who'], capture_output=True, text=True)
        for line in result.stdout.split('\n'):
            if line:
                parts = line.split()
                if len(parts) >= 5:
                    users.append({
                        'user': parts[0],
                        'ip': parts[4].strip('()'),
                        'protocol': 'SSH',
                        'time': parts[2] + ' ' + parts[3]
                    })
    except:
        pass
    return users

def get_system_stats():
    stats = {}
    stats['cpu'] = psutil.cpu_percent(interval=1)
    memory = psutil.virtual_memory()
    stats['ram_used'] = memory.used / (1024**3)
    stats['ram_total'] = memory.total / (1024**3)
    stats['ram_percent'] = memory.percent
    disk = psutil.disk_usage('/')
    stats['disk_used'] = disk.used / (1024**3)
    stats['disk_total'] = disk.total / (1024**3)
    stats['disk_percent'] = disk.percent
    stats['uptime'] = time.time() - psutil.boot_time()
    stats['users_online'] = len(get_online_users())
    return stats

def block_ip(ip):
    try:
        subprocess.run(['iptables', '-A', 'INPUT', '-s', ip, '-j', 'DROP'], check=True)
        return True
    except:
        return False

def create_ssh_user(username, password, days):
    try:
        subprocess.run(['useradd', '-m', '-s', '/bin/bash', username], check=True)
        subprocess.run(['chpasswd'], input=f"{username}:{password}", text=True, check=True)
        expire_date = (datetime.now() + timedelta(days=int(days))).strftime('%Y-%m-%d')
        subprocess.run(['chage', '-E', expire_date, username], check=True)
        return True
    except:
        return False

def delete_user(username):
    try:
        subprocess.run(['userdel', '-r', username], check=True)
        return True
    except:
        return False

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "🤖 NexusVPN Pro Bot\n\n"
        "Comandos:\n"
        "/online - Usuarios conectados\n"
        "/stats - Estadísticas\n"
        "/block <IP> - Bloquear IP\n"
        "/create <user> <pass> <days> - Crear usuario\n"
        "/delete <user> - Eliminar usuario\n"
        "/keys - Listar keys\n"
        "/help - Ayuda"
    )

async def online(update: Update, context: ContextTypes.DEFAULT_TYPE):
    users = get_online_users()
    if not users:
        await update.message.reply_text("📡 No hay usuarios conectados")
        return
    message = "📡 Usuarios Conectados:\n\n"
    for user in users:
        message += f"👤 {user['user']}\n   IP: {user['ip']}\n   Protocolo: {user['protocol']}\n\n"
    await update.message.reply_text(message)

async def stats(update: Update, context: ContextTypes.DEFAULT_TYPE):
    stats = get_system_stats()
    uptime_days = int(stats['uptime'] // 86400)
    uptime_hours = int((stats['uptime'] % 86400) // 3600)
    message = (
        f"📊 Estadísticas:\n"
        f"CPU: {stats['cpu']}%\n"
        f"RAM: {stats['ram_used']:.1f}GB/{stats['ram_total']:.1f}GB ({stats['ram_percent']}%)\n"
        f"Disco: {stats['disk_used']:.1f}GB/{stats['disk_total']:.1f}GB ({stats['disk_percent']}%)\n"
        f"Uptime: {uptime_days}d {uptime_hours}h\n"
        f"Usuarios online: {stats['users_online']}"
    )
    await update.message.reply_text(message)

async def block(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("Uso: /block <IP>")
        return
    ip = context.args[0]
    if block_ip(ip):
        await update.message.reply_text(f"✅ IP {ip} bloqueada")
    else:
        await update.message.reply_text(f"❌ Error bloqueando {ip}")

async def create(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if len(context.args) < 3:
        await update.message.reply_text("Uso: /create <user> <pass> <days>")
        return
    username, password, days = context.args[0], context.args[1], context.args[2]
    if not days.isdigit():
        await update.message.reply_text("❌ Los días deben ser un número")
        return
    if create_ssh_user(username, password, days):
        await update.message.reply_text(f"✅ Usuario {username} creado por {days} días")
    else:
        await update.message.reply_text(f"❌ Error creando usuario")

async def delete(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not context.args:
        await update.message.reply_text("Uso: /delete <user>")
        return
    username = context.args[0]
    if delete_user(username):
        await update.message.reply_text(f"✅ Usuario {username} eliminado")
    else:
        await update.message.reply_text(f"❌ Error eliminando usuario")

async def keys(update: Update, context: ContextTypes.DEFAULT_TYPE):
    if not os.path.exists(KEYS_DB):
        await update.message.reply_text("📋 No hay keys registradas")
        return
    try:
        with open(KEYS_DB, 'r') as f:
            keys = f.readlines()
        message = "🔑 Keys:\n\n"
        for key_line in keys[:10]:
            parts = key_line.strip().split('|')
            if len(parts) >= 7:
                key, expiry, active = parts[0], parts[2], parts[6]
                message += f"`{key[:8]}...` | {'✅' if active == '1' else '❌'}\n"
        await update.message.reply_text(message)
    except:
        await update.message.reply_text("❌ Error leyendo keys")

async def help(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "🤖 Ayuda:\n"
        "/online - Ver usuarios\n"
        "/stats - Estadísticas\n"
        "/block <IP> - Bloquear IP\n"
        "/create <user> <pass> <days> - Crear usuario\n"
        "/delete <user> - Eliminar\n"
        "/keys - Listar keys"
    )

def main():
    token = load_token()
    if not token:
        print("❌ Token no encontrado")
        sys.exit(1)
    app = Application.builder().token(token).build()
    app.add_handler(CommandHandler("start", start))
    app.add_handler(CommandHandler("online", online))
    app.add_handler(CommandHandler("stats", stats))
    app.add_handler(CommandHandler("block", block))
    app.add_handler(CommandHandler("create", create))
    app.add_handler(CommandHandler("delete", delete))
    app.add_handler(CommandHandler("keys", keys))
    app.add_handler(CommandHandler("help", help))
    print("✅ Bot iniciado")
    app.run_polling()

if __name__ == "__main__":
    main()
PYBOT

    chmod +x "$BOT_DIR/bot.py"
    log_info "Script del bot creado"
}

create_telegram_bot_service() {
    cat > /etc/systemd/system/nexusvpn-bot.service << EOF
[Unit]
Description=NexusVPN Pro Telegram Bot
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$BOT_DIR
ExecStart=$BOT_DIR/venv/bin/python $BOT_DIR/bot.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable nexusvpn-bot
    systemctl start nexusvpn-bot
    log_info "Servicio del bot creado"
}

configure_bot_token() {
    local token="$1"
    echo "$token" > "$BOT_TOKEN_FILE"
    chmod 600 "$BOT_TOKEN_FILE"
    cfg_set "telegram.token" "\"$token\""
    cfg_set "telegram.enabled" "true"
    systemctl restart nexusvpn-bot 2>/dev/null || true
    ok "Token de Telegram configurado"
}

bot_status() {
    systemctl status nexusvpn-bot --no-pager
}

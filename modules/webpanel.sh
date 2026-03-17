#!/bin/bash
# Módulo de Panel Web para NexusVPN Pro
# Funciones: instalación, configuración, gestión

WEB_DIR="/var/www/nexusvpn"
WEB_PORT=$(cfg_get "ports.webpanel" "$DEFAULT_WEB_PANEL_PORT")

install_web_panel() {
    inf "Instalando panel web básico (puerto $WEB_PORT)..."
    log_info "Instalando panel web"
    
    apt_install nginx python3 python3-flask python3-psutil
    
    mkdir -p "$WEB_DIR"/{static,templates}
    
    cat > "$WEB_DIR/app.py" << 'WEBPY'
#!/usr/bin/env python3
import os
import json
import subprocess
import psutil
import time
from datetime import datetime
from flask import Flask, render_template, jsonify, request, redirect, url_for, session
import functools

app = Flask(__name__)
app.secret_key = os.urandom(24)

INSTALL_DIR = "/etc/nexusvpn"
CONFIG_FILE = f"{INSTALL_DIR}/config/config.json"

def load_config():
    try:
        with open(CONFIG_FILE, 'r') as f:
            return json.load(f)
    except:
        return {}

def login_required(view):
    @functools.wraps(view)
    def wrapped_view(**kwargs):
        if not session.get('logged_in'):
            return redirect(url_for('login'))
        return view(**kwargs)
    return wrapped_view

@app.route('/login', methods=['GET', 'POST'])
def login():
    if request.method == 'POST':
        password = request.form.get('password')
        if password == "NexusAdmin2024":
            session['logged_in'] = True
            return redirect(url_for('index'))
        return render_template('login.html', error=True)
    return render_template('login.html', error=False)

@app.route('/logout')
def logout():
    session.clear()
    return redirect(url_for('login'))

@app.route('/')
@login_required
def index():
    return render_template('index.html')

@app.route('/api/stats')
@login_required
def api_stats():
    stats = {
        'cpu': psutil.cpu_percent(interval=1),
        'ram': psutil.virtual_memory().percent,
        'disk': psutil.disk_usage('/').percent,
        'uptime': time.time() - psutil.boot_time(),
        'users_online': 0
    }
    who = subprocess.run(['who', '--ips'], capture_output=True, text=True)
    stats['users_online'] = len(who.stdout.strip().split('\n')) if who.stdout else 0
    return jsonify(stats)

@app.route('/api/users')
@login_required
def api_users():
    users = []
    who = subprocess.run(['who', '--ips'], capture_output=True, text=True)
    for line in who.stdout.strip().split('\n'):
        if line:
            parts = line.split()
            if len(parts) >= 5:
                users.append({
                    'username': parts[0],
                    'ip': parts[4].strip('()'),
                    'protocol': 'SSH',
                    'time': f"{parts[2]} {parts[3]}"
                })
    return jsonify(users)

@app.route('/api/services')
@login_required
def api_services():
    services = ['xray', 'hysteria', 'wg-quick@wg0', 'openvpn@server-tcp', 
                'openvpn@server-udp', 'slowdns', 'nginx', 'ssh']
    result = []
    for svc in services:
        status = subprocess.run(['systemctl', 'is-active', svc], capture_output=True, text=True)
        result.append({
            'name': svc,
            'status': status.stdout.strip() if status.returncode == 0 else 'inactive'
        })
    return jsonify(result)

@app.route('/api/restart/<service>', methods=['POST'])
@login_required
def restart_service(service):
    result = subprocess.run(['systemctl', 'restart', service], capture_output=True, text=True)
    return jsonify({'success': result.returncode == 0})

if __name__ == '__main__':
    app.run(host='127.0.0.1', port=5000)
WEBPY

    cat > "$WEB_DIR/templates/login.html" << 'LOGINHTML'
<!DOCTYPE html>
<html>
<head>
    <title>NexusVPN Pro - Login</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            height: 100vh;
            display: flex;
            justify-content: center;
            align-items: center;
        }
        .login-container {
            background: white;
            padding: 40px;
            border-radius: 10px;
            box-shadow: 0 10px 25px rgba(0,0,0,0.1);
            width: 100%;
            max-width: 400px;
        }
        .login-container h1 {
            text-align: center;
            margin-bottom: 30px;
            color: #333;
        }
        .login-container input {
            width: 100%;
            padding: 12px;
            margin: 8px 0;
            border: 1px solid #ddd;
            border-radius: 5px;
            font-size: 16px;
        }
        .login-container button {
            width: 100%;
            padding: 12px;
            background: #667eea;
            color: white;
            border: none;
            border-radius: 5px;
            font-size: 16px;
            cursor: pointer;
            margin-top: 20px;
        }
        .login-container button:hover {
            background: #5a67d8;
        }
        .error {
            color: #e53e3e;
            text-align: center;
            margin-top: 10px;
        }
        .logo {
            text-align: center;
            margin-bottom: 20px;
            font-size: 24px;
            font-weight: bold;
            color: #667eea;
        }
    </style>
</head>
<body>
    <div class="login-container">
        <div class="logo">🔐 NexusVPN Pro</div>
        <h1>Iniciar Sesión</h1>
        {% if error %}
        <div class="error">Contraseña incorrecta</div>
        {% endif %}
        <form method="post">
            <input type="password" name="password" placeholder="Contraseña" required>
            <button type="submit">Entrar</button>
        </form>
    </div>
</body>
</html>
LOGINHTML

    cat > "$WEB_DIR/templates/index.html" << 'INDEXHTML'
<!DOCTYPE html>
<html>
<head>
    <title>NexusVPN Pro - Dashboard</title>
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
            background: #f5f7fa;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 20px;
            box-shadow: 0 2px 10px rgba(0,0,0,0.1);
        }
        .header h1 {
            font-size: 24px;
        }
        .container {
            max-width: 1200px;
            margin: 20px auto;
            padding: 0 20px;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .stat-card {
            background: white;
            padding: 20px;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .stat-card h3 {
            color: #718096;
            font-size: 14px;
            margin-bottom: 10px;
        }
        .stat-card .value {
            font-size: 32px;
            font-weight: bold;
            color: #2d3748;
        }
        .progress-bar {
            width: 100%;
            height: 8px;
            background: #e2e8f0;
            border-radius: 4px;
            margin-top: 10px;
        }
        .progress-fill {
            height: 100%;
            background: linear-gradient(90deg, #667eea, #764ba2);
            border-radius: 4px;
        }
        .section {
            background: white;
            border-radius: 8px;
            padding: 20px;
            margin-bottom: 20px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .section h2 {
            color: #2d3748;
            margin-bottom: 15px;
            font-size: 18px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
        }
        th {
            text-align: left;
            padding: 12px;
            background: #f7fafc;
            color: #4a5568;
            font-weight: 600;
            font-size: 14px;
        }
        td {
            padding: 12px;
            border-bottom: 1px solid #e2e8f0;
            color: #2d3748;
        }
        .badge {
            padding: 4px 8px;
            border-radius: 4px;
            font-size: 12px;
            font-weight: 600;
        }
        .badge-active {
            background: #c6f6d5;
            color: #22543d;
        }
        .badge-inactive {
            background: #fed7d7;
            color: #742a2a;
        }
        .btn {
            padding: 8px 16px;
            border: none;
            border-radius: 4px;
            cursor: pointer;
            font-size: 14px;
        }
        .btn-primary {
            background: #667eea;
            color: white;
        }
        .btn-primary:hover {
            background: #5a67d8;
        }
        .logout {
            float: right;
            color: white;
            text-decoration: none;
            padding: 5px 10px;
            border: 1px solid white;
            border-radius: 4px;
        }
        .logout:hover {
            background: rgba(255,255,255,0.1);
        }
    </style>
</head>
<body>
    <div class="header">
        <h1>🔐 NexusVPN Pro Dashboard
            <a href="/logout" class="logout">Cerrar Sesión</a>
        </h1>
    </div>
    
    <div class="container">
        <div class="stats-grid" id="stats">
            <div class="stat-card">
                <h3>CPU</h3>
                <div class="value" id="cpu">0</div>
                <div class="unit">%</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="cpu-bar" style="width: 0%"></div>
                </div>
            </div>
            <div class="stat-card">
                <h3>RAM</h3>
                <div class="value" id="ram">0</div>
                <div class="unit">%</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="ram-bar" style="width: 0%"></div>
                </div>
            </div>
            <div class="stat-card">
                <h3>DISCO</h3>
                <div class="value" id="disk">0</div>
                <div class="unit">%</div>
                <div class="progress-bar">
                    <div class="progress-fill" id="disk-bar" style="width: 0%"></div>
                </div>
            </div>
            <div class="stat-card">
                <h3>USUARIOS ONLINE</h3>
                <div class="value" id="users">0</div>
            </div>
        </div>

        <div class="section">
            <h2>📡 Usuarios Conectados</h2>
            <table id="users-table">
                <thead>
                    <tr>
                        <th>Usuario</th>
                        <th>IP</th>
                        <th>Protocolo</th>
                        <th>Tiempo</th>
                    </tr>
                </thead>
                <tbody id="users-tbody">
                    <tr><td colspan="4">Cargando...</td></tr>
                </tbody>
            </table>
        </div>

        <div class="section">
            <h2>⚙️ Servicios</h2>
            <table id="services-table">
                <thead>
                    <tr>
                        <th>Servicio</th>
                        <th>Estado</th>
                        <th>Acciones</th>
                    </tr>
                </thead>
                <tbody id="services-tbody">
                    <tr><td colspan="3">Cargando...</td></tr>
                </tbody>
            </table>
        </div>
    </div>

    <script>
        function updateStats() {
            fetch('/api/stats')
                .then(r => r.json())
                .then(data => {
                    document.getElementById('cpu').textContent = data.cpu;
                    document.getElementById('cpu-bar').style.width = data.cpu + '%';
                    document.getElementById('ram').textContent = data.ram;
                    document.getElementById('ram-bar').style.width = data.ram + '%';
                    document.getElementById('disk').textContent = data.disk;
                    document.getElementById('disk-bar').style.width = data.disk + '%';
                    document.getElementById('users').textContent = data.users_online;
                });
        }

        function updateUsers() {
            fetch('/api/users')
                .then(r => r.json())
                .then(users => {
                    const tbody = document.getElementById('users-tbody');
                    if (users.length === 0) {
                        tbody.innerHTML = '<tr><td colspan="4">No hay usuarios conectados</td></tr>';
                        return;
                    }
                    let html = '';
                    users.forEach(u => {
                        html += `<tr><td>${u.username}</td><td>${u.ip}</td><td>${u.protocol}</td><td>${u.time}</td></tr>`;
                    });
                    tbody.innerHTML = html;
                });
        }

        function updateServices() {
            fetch('/api/services')
                .then(r => r.json())
                .then(services => {
                    const tbody = document.getElementById('services-tbody');
                    let html = '';
                    services.forEach(s => {
                        const statusClass = s.status === 'active' ? 'badge-active' : 'badge-inactive';
                        html += `<tr><td>${s.name}</td><td><span class="badge ${statusClass}">${s.status}</span></td>`;
                        html += `<td><button class="btn btn-primary" onclick="restartService('${s.name}')">Reiniciar</button></td></tr>`;
                    });
                    tbody.innerHTML = html;
                });
        }

        function restartService(name) {
            if (confirm(`¿Reiniciar ${name}?`)) {
                fetch(`/api/restart/${name}`, {method: 'POST'})
                    .then(r => r.json())
                    .then(data => {
                        if (data.success) {
                            alert('Servicio reiniciado');
                            updateServices();
                        }
                    });
            }
        }

        setInterval(updateStats, 5000);
        setInterval(updateUsers, 10000);
        setInterval(updateServices, 15000);
        
        updateStats();
        updateUsers();
        updateServices();
    </script>
</body>
</html>
INDEXHTML

    chmod +x "$WEB_DIR/app.py"
    
    cat > "${NGINX_AVAILABLE}/nexusvpn-web" << WEB
server {
    listen $WEB_PORT;
    server_name _;
    location / {
        proxy_pass http://127.0.0.1:5000;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
WEB

    ln -sf "${NGINX_AVAILABLE}/nexusvpn-web" "${NGINX_ENABLED}/nexusvpn-web"
    
    cat > /etc/systemd/system/nexusvpn-web.service << WEB
[Unit]
Description=NexusVPN Pro Web Panel
After=network.target

[Service]
Type=simple
User=root
WorkingDirectory=$WEB_DIR
ExecStart=/usr/bin/python3 $WEB_DIR/app.py
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
WEB

    systemctl daemon-reload
    systemctl enable nexusvpn-web
    systemctl start nexusvpn-web
    systemctl reload nginx
    
    cfg_set "features.web_panel" "true"
    log_info "Panel web instalado en puerto $WEB_PORT"
    ok "Panel web instalado en http://$(get_server_ip):$WEB_PORT"
}

web_panel_status() {
    systemctl status nexusvpn-web --no-pager
}

web_panel_restart() {
    systemctl restart nexusvpn-web
    ok "Panel web reiniciado"
}

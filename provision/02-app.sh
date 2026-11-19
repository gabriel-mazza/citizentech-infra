#!/usr/bin/env bash
# 02-app.sh - Provisiona a aplicacao web CitizenTech: dependencias, config, servico systemd
set -euo pipefail

LOG_DIR=/var/log/provision
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/02-app.log") 2>&1
log() { echo "$(date '+%F %T') [APP] $*"; }

APP_DIR=/opt/citizentech
ENV_DIR=/etc/citizentech

log "Instalando dependencias"
apt-get install -y python3 curl

log "Criando aplicacao em $APP_DIR"
mkdir -p "$APP_DIR" "$ENV_DIR"
cat > "$APP_DIR/app.py" <<'EOF'
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

class Handler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path == "/health":
            body = b"OK"
        else:
            body = (b"<h1>CitizenTech - Deslocai</h1>"
                    b"<p>Aplicacao web no ar, provisionada via Shell Script.</p>")
        self.send_response(200)
        self.end_headers()
        self.wfile.write(body)

port = int(os.environ.get("APP_PORT", "8080"))
HTTPServer(("0.0.0.0", port), Handler).serve_forever()
EOF

log "Configurando variaveis de ambiente"
echo "APP_PORT=8080" > "$ENV_DIR/env"
chown -R citizentech: "$APP_DIR"

log "Criando servico systemd"
cat > /etc/systemd/system/citizentech-app.service <<'EOF'
[Unit]
Description=CitizenTech Web App
After=network.target

[Service]
User=citizentech
EnvironmentFile=/etc/citizentech/env
ExecStart=/usr/bin/python3 /opt/citizentech/app.py
Restart=always
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now citizentech-app
sleep 2

if curl -fs http://localhost:8080/health >/dev/null; then
  log "App respondendo em http://localhost:8080"
else
  log "ERRO: app nao respondeu"; exit 1
fi
echo "$(date '+%F %T') user=${SUDO_USER:-$USER} action=app-deployed service=citizentech-app" >> /var/log/citizentech-audit.log
log "Aplicacao OK"

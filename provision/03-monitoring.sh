#!/usr/bin/env bash
# 03-monitoring.sh - Instala o monitor como servico systemd tolerante a falhas
set -euo pipefail

LOG_DIR=/var/log/provision
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/03-monitoring.log") 2>&1
log() { echo "$(date '+%F %T') [MON] $*"; }

BASE="$(cd "$(dirname "$0")/.." && pwd)"

log "Instalando monitor em /usr/local/bin"
install -m 755 "$BASE/monitoring/monitor.sh" /usr/local/bin/infra-monitor.sh

log "Criando servico systemd"
cat > /etc/systemd/system/infra-monitor.service <<'EOF'
[Unit]
Description=Monitoramento de infraestrutura (CPU, memoria, disco)
After=network.target citizentech-app.service
StartLimitIntervalSec=0

[Service]
ExecStart=/usr/local/bin/infra-monitor.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now infra-monitor
sleep 3
log "Estado do servico: $(systemctl is-active infra-monitor)"
echo "$(date '+%F %T') user=${SUDO_USER:-$USER} action=monitor-deployed service=infra-monitor" >> /var/log/citizentech-audit.log
log "Monitoramento OK"

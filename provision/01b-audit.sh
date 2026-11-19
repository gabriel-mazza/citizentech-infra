#!/usr/bin/env bash
# 01b-audit.sh - Auditoria: log central de eventos + exportacao dos eventos de sudo
set -euo pipefail

LOG_DIR=/var/log/provision
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/01b-audit.log") 2>&1
log() { echo "$(date '+%F %T') [AUDIT] $*"; }

AUDIT_LOG=/var/log/citizentech-audit.log

log "Executado por: ${SUDO_USER:-$USER}"

log "Criando log central de auditoria"
touch "$AUDIT_LOG"
chmod 640 "$AUDIT_LOG"
echo "$(date '+%F %T') user=${SUDO_USER:-$USER} action=provision-audit-enabled host=$(hostname)" >> "$AUDIT_LOG"

log "Exportando eventos de sudo (quem executou o que)"
if [ -f /var/log/auth.log ]; then
  grep -h "sudo" /var/log/auth.log | tail -n 20 >> "$AUDIT_LOG" || true
else
  journalctl -t sudo --no-pager -n 20 >> "$AUDIT_LOG" 2>/dev/null || true
fi

log "Auditoria OK (central: $AUDIT_LOG | execucao: $LOG_DIR/)"

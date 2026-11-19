#!/usr/bin/env bash
# install.sh - Provisiona toda a infraestrutura CitizenTech de forma automatizada
# Uso: sudo ./install.sh
set -euo pipefail

BASE="$(cd "$(dirname "$0")" && pwd)"
LOG_DIR=/var/log/provision
AUDIT=/var/log/citizentech-audit.log

[ "$EUID" -eq 0 ] || { echo "Execute com sudo: sudo ./install.sh"; exit 1; }
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/install.log") 2>&1
log() { echo "$(date '+%F %T') [INSTALL] $*"; }

trap 'log "ERRO na linha $LINENO (comando: $BASH_COMMAND)"; echo "$(date "+%F %T") user=${SUDO_USER:-$USER} action=install-failed line=$LINENO cmd=$BASH_COMMAND" >> "$AUDIT"; exit 1' ERR

log "Iniciando provisionamento"

if [ "$(ps -p 1 -o comm=)" != "systemd" ]; then
  if grep -qi microsoft /proc/version; then
    log "systemd inativo no WSL. Habilitando em /etc/wsl.conf"
    grep -q "systemd=true" /etc/wsl.conf 2>/dev/null || printf '[boot]\nsystemd=true\n' >> /etc/wsl.conf
    log "Reinicie o WSL (PowerShell: wsl --shutdown), abra o Ubuntu e rode novamente: sudo ./install.sh"
    exit 0
  fi
  log "ERRO: systemd e necessario"; exit 1
fi
log "systemd ativo"

for step in 01-infra 01b-audit 02-app 03-monitoring; do
  log "Executando provision/$step.sh"
  bash "$BASE/provision/$step.sh"
done

log "Validando ambiente"
curl -fs http://localhost:8080/health >/dev/null && log "Aplicacao: OK" || { log "Aplicacao: FALHOU"; exit 1; }
for svc in citizentech-app infra-monitor; do
  log "Servico $svc: $(systemctl is-active "$svc") (habilitado: $(systemctl is-enabled "$svc"))"
done

echo "$(date '+%F %T') user=${SUDO_USER:-$USER} action=install-completed host=$(hostname)" >> "$AUDIT"
log "Provisionamento concluido com sucesso"

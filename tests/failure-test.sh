#!/usr/bin/env bash
# failure-test.sh - Simula falhas e mostra a recuperacao automatica pelo systemd
# Executar com: sudo ./tests/failure-test.sh
set -u

LOG=/var/log/failure-test.log
log() { echo "$(date '+%F %T') [TESTE] $*" | tee -a "$LOG"; }
audit() { echo "$(date '+%F %T') user=${SUDO_USER:-$USER} action=$1" >> /var/log/citizentech-audit.log; }

log "=== TESTE 1: derrubando a aplicacao com SIGKILL ==="
audit "failure-test-app-kill"
systemctl kill -s SIGKILL citizentech-app
sleep 1
log "Estado logo apos a falha: $(systemctl is-active citizentech-app)"
sleep 6
log "Estado apos recuperacao: $(systemctl is-active citizentech-app)"
if curl -fs http://localhost:8080/health >/dev/null; then
  log "RESULTADO: app voltou sozinha e responde em /health"
else
  log "RESULTADO: FALHA, app nao voltou"
fi

log "=== TESTE 2: app parada por 12s para o monitor detectar ==="
audit "failure-test-app-stop"
systemctl stop citizentech-app
sleep 12
log "Alertas do monitor:"
grep "fora do ar" /var/log/infra-monitor.log | tail -n 2 | tee -a "$LOG"
systemctl start citizentech-app
sleep 2
log "App restaurada: $(systemctl is-active citizentech-app)"

log "=== TESTE 3: derrubando o proprio monitor com SIGKILL ==="
audit "failure-test-monitor-kill"
systemctl kill -s SIGKILL infra-monitor
sleep 1
log "Estado logo apos a falha: $(systemctl is-active infra-monitor)"
sleep 8
log "Estado apos recuperacao: $(systemctl is-active infra-monitor)"

log "=== TESTE 4: estresse de CPU por 30s (deve gerar ALERTA) ==="
audit "failure-test-cpu-stress"
stress-ng --cpu 0 --timeout 30s >/dev/null 2>&1
sleep 3
log "Alertas de CPU:"
grep "ALERTA" /var/log/infra-monitor.log | grep "CPU" | tail -n 3 | tee -a "$LOG"

log "=== FIM DOS TESTES (log em $LOG) ==="

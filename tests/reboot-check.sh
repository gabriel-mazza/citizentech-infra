#!/usr/bin/env bash
# reboot-check.sh - Verifica se os servicos subiram sozinhos apos reinicializacao
# Uso: ./tests/reboot-check.sh  (depois de: wsl --shutdown e reabrir o Ubuntu)
LOG=/tmp/reboot-check.log
echo "=== Verificacao pos-reinicializacao ($(date '+%F %T')) ===" | tee "$LOG"
echo "Uptime: $(uptime -p)" | tee -a "$LOG"
for svc in citizentech-app infra-monitor; do
  echo "$svc -> ativo: $(systemctl is-active $svc) | habilitado: $(systemctl is-enabled $svc)" | tee -a "$LOG"
done
curl -fs http://localhost:8080/health >/dev/null && echo "Aplicacao responde em /health: OK" | tee -a "$LOG" || echo "Aplicacao NAO responde" | tee -a "$LOG"
echo "Ultimos registros do monitor:" | tee -a "$LOG"
tail -n 3 /var/log/infra-monitor.log | tee -a "$LOG"

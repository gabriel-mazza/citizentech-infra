#!/usr/bin/env bash
# script-failure-test.sh - Provoca falha controlada em um script e verifica se o erro foi registrado
# Uso: sudo ./tests/script-failure-test.sh
set -u
LOG=/var/log/failure-test.log
AUDIT=/var/log/citizentech-audit.log
log() { echo "$(date '+%F %T') [TESTE-SCRIPT] $*" | tee -a "$LOG"; }

FAULTY=$(mktemp /tmp/faulty-XXXX.sh)
cat > "$FAULTY" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
echo "executando etapa 1"
cat /arquivo/que/nao/existe
echo "esta linha nunca executa"
EOF

log "Executando script com falha proposital"
if bash "$FAULTY" 2>/tmp/faulty.err; then
  log "RESULTADO: script nao falhou (inesperado)"
else
  code=$?
  err=$(tr '\n' ' ' < /tmp/faulty.err)
  log "Script falhou com codigo $code. Erro capturado: $err"
  echo "$(date '+%F %T') user=${SUDO_USER:-$USER} action=script-failure code=$code error=$err" >> "$AUDIT"
  log "RESULTADO: erro registrado no log de auditoria ($AUDIT)"
fi
rm -f "$FAULTY" /tmp/faulty.err
grep "script-failure" "$AUDIT" | tail -n 1 | tee -a "$LOG"

#!/usr/bin/env bash
# monitor.sh - Monitora CPU, memoria, disco e saude da app; gera alertas em log
set -u

LOG=/var/log/infra-monitor.log
CPU_MAX=${CPU_MAX:-80}
MEM_MAX=${MEM_MAX:-80}
DISK_MAX=${DISK_MAX:-80}
INTERVAL=${INTERVAL:-10}
APP_URL=${APP_URL:-http://localhost:8080/health}

touch "$LOG"; chmod 644 "$LOG"
log() {
  local line
  line="$(date '+%F %T') [$1] $2"
  echo "$line" | tee -a "$LOG"
  logger -t infra-monitor "[$1] $2"
}

cpu_usage() {
  local u1 n1 s1 i1 w1 q1 sq1 u2 n2 s2 i2 w2 q2 sq2 idle total
  read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < /proc/stat
  sleep 1
  read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < /proc/stat
  idle=$(( (i2 + w2) - (i1 + w1) ))
  total=$(( (u2+n2+s2+i2+w2+q2+sq2) - (u1+n1+s1+i1+w1+q1+sq1) ))
  [ "$total" -le 0 ] && { echo 0; return; }
  echo $(( 100 * (total - idle) / total ))
}

log INFO "Monitor iniciado (limites: CPU=${CPU_MAX}% MEM=${MEM_MAX}% DISCO=${DISK_MAX}%)"

while true; do
  cpu=$(cpu_usage)
  mem=$(free | awk '/Mem:/ {printf "%d", $3/$2*100}')
  disk=$(df / | awk 'NR==2 {gsub("%",""); print $5}')

  for item in "CPU:$cpu:$CPU_MAX" "MEMORIA:$mem:$MEM_MAX" "DISCO:$disk:$DISK_MAX"; do
    IFS=: read -r name val max <<< "$item"
    if [ "$val" -ge "$max" ]; then
      log ALERTA "$name em ${val}% (limite ${max}%)"
    else
      log INFO "$name ${val}%"
    fi
  done

  if ! curl -fs --max-time 3 "$APP_URL" >/dev/null; then
    log ALERTA "Aplicacao fora do ar ($APP_URL)"
  fi
  sleep "$INTERVAL"
done

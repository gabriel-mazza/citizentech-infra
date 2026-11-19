#!/usr/bin/env bash
# 01-infra.sh - Provisiona hostname, DNS, rede, usuario de servico, firewall e auditoria
set -euo pipefail

LOG_DIR=/var/log/provision
mkdir -p "$LOG_DIR"
exec > >(tee -a "$LOG_DIR/01-infra.log") 2>&1
log() { echo "$(date '+%F %T') [INFRA] $*"; }

HOSTNAME_NEW="citizentech-srv"
APP_DOMAIN="citizentech.local"

log "Definindo hostname: $HOSTNAME_NEW"
echo "$HOSTNAME_NEW" > /etc/hostname
hostname "$HOSTNAME_NEW"
grep -q "$APP_DOMAIN" /etc/hosts || echo "127.0.0.1 $APP_DOMAIN $HOSTNAME_NEW" >> /etc/hosts

log "Configurando DNS"
grep -q "1.1.1.1" /etc/resolv.conf 2>/dev/null || echo "nameserver 1.1.1.1" >> /etc/resolv.conf

log "Instalando pacotes base"
apt-get update -y
apt-get install -y curl net-tools ufw auditd stress-ng

log "Criando usuario de servico"
id citizentech &>/dev/null || useradd -r -m -s /usr/sbin/nologin citizentech

log "Configurando regras de auditoria"
mkdir -p /opt/citizentech
cat > /etc/audit/rules.d/citizentech.rules <<'EOF'
-w /opt/citizentech -p wa -k app_changes
-w /etc/systemd/system -p wa -k systemd_changes
-w /var/log/provision -p wa -k provision_logs
EOF
augenrules --load 2>/dev/null || log "AVISO: auditd limitado no WSL, usando logs proprios"

log "Firewall: liberando porta 8080 (regra registrada)"
ufw allow 8080/tcp || true

log "Resumo de rede:"
log "  hostname: $(hostname)"
log "  ip: $(hostname -I)"
log "  dns: $(grep nameserver /etc/resolv.conf | tr '\n' ' ')"
log "Infra OK"

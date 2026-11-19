# CitizenTech - Infraestrutura Linux (Operating Systems)

Infraestrutura Linux provisionada de forma automatica por Shell Script para hospedar uma aplicacao web CitizenTech (Deslocai), com monitoramento, auditoria e teste de falha.

**Integrantes:** Gabriel Barros Mazzariol - RM 555410, Jefferson Junior Alvarez Urbina - RM 558497
**Ambiente:** Ubuntu no WSL2 com systemd habilitado.

## Estrutura

    provision/01-infra.sh       hostname, DNS, rede, usuario de servico, firewall
    provision/01b-audit.sh      auditoria (log central + eventos de sudo)
    provision/02-app.sh         dependencias, aplicacao, variaveis, servico systemd
    provision/03-monitoring.sh  instala o monitor como servico systemd
    monitoring/monitor.sh       monitor de CPU, memoria, disco e saude da app
    tests/failure-test.sh       teste de falha
    systemd/                    unit files usados
    app/app.py                  aplicacao web
    docs/evidencias/            logs e status gerados na execucao

## Como executar

    sudo ./provision/01-infra.sh
    sudo ./provision/01b-audit.sh
    sudo ./provision/02-app.sh
    sudo ./provision/03-monitoring.sh
    sudo ./tests/failure-test.sh

Pre-requisito: systemd habilitado em /etc/wsl.conf ([boot] systemd=true).

## Criterios de avaliacao

| Criterio | Onde esta |
|---|---|
| Provisionamento de infra (rede, DNS, IP) | provision/01-infra.sh |
| Provisionamento da aplicacao | provision/02-app.sh |
| Monitor com alertas de CPU, disco e memoria | monitoring/monitor.sh |
| Monitor como servico tolerante a falhas | systemd/infra-monitor.service (Restart=always) |
| Logs de auditoria e execucao | /var/log/provision/, /var/log/citizentech-audit.log |
| Funcionamento completo | aplicacao em http://localhost:8080 + teste de falha |

## Monitoramento

O monitor le CPU (/proc/stat), memoria (free) e disco (df) a cada 10 segundos. Quando um valor passa de 80% (configuravel por variaveis), registra [ALERTA] em /var/log/infra-monitor.log e no journal. Tambem verifica a saude da aplicacao em /health.

## Auditoria e logs

- Cada script grava sua execucao em /var/log/provision/<script>.log
- Eventos importantes (deploy, testes de falha) vao para /var/log/citizentech-audit.log com usuario e data
- Limitacao: o kernel do WSL2 nao suporta o auditd, entao a auditoria foi implementada com logs proprios

## Teste de falha

O script tests/failure-test.sh executa:

1. SIGKILL na aplicacao: o systemd a reinicia sozinho (Restart=always)
2. Aplicacao parada: o monitor registra ALERTA de aplicacao fora do ar
3. SIGKILL no monitor: o systemd o reinicia sozinho
4. Estresse de CPU (stress-ng): o monitor registra ALERTA de CPU em 99%

Resultado completo em docs/evidencias/failure-test.log.

## Limitacoes do ambiente (WSL2)

O IP e gerenciado pelo Windows (NAT) e o hostname/DNS sao configurados via /etc/hostname, /etc/hosts e /etc/resolv.conf. O resumo de rede fica registrado em docs/evidencias/01-infra.log.

## Instalacao automatizada (um comando)

    sudo ./install.sh

O install.sh habilita o systemd (se necessario no WSL), executa os scripts de provisionamento em ordem (infra, auditoria, aplicacao, monitoramento), valida a aplicacao e os servicos, e registra tudo em /var/log/provision/install.log. Qualquer erro e gravado em /var/log/citizentech-audit.log (trap ERR).

## Testes adicionais

    sudo ./tests/failure-test.sh           # falhas de servicos e estresse de CPU
    sudo ./tests/script-failure-test.sh    # falha controlada em script, erro registrado no log de auditoria
    ./tests/reboot-check.sh                # apos wsl --shutdown: servicos sobem sozinhos (systemd enabled)

## Evidencias

- Logs de execucao e alertas: docs/evidencias/*.log
- Capturas de tela: docs/evidencias/prints/

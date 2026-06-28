#!/usr/bin/env bash
# Expõe Jenkins (porta 8080) via ngrok e configura webhook do GitHub.
#
# Pré-requisitos:
#   1. Jenkins rodando: bash scripts/setup-jenkins.sh
#   2. ngrok instalado: https://ngrok.com/download
#   3. Token configurado: ngrok config add-authtoken SEU_TOKEN
#
# Uso:
#   bash scripts/setup-ngrok.sh          # inicia túnel e mostra URL do webhook
#   bash scripts/setup-ngrok.sh --webhook # inicia túnel + configura webhook GitHub
#   bash scripts/setup-ngrok.sh --stop    # encerra túnel ngrok
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
NGROK_DIR="${ROOT_DIR}/.ngrok"
NGROK_PID_FILE="${NGROK_DIR}/ngrok.pid"
NGROK_LOG="${NGROK_DIR}/ngrok.log"
JENKINS_PORT="${JENKINS_PORT:-8080}"
NGROK_API="http://127.0.0.1:4040"
CONFIGURE_WEBHOOK=false
STOP=false

for arg in "$@"; do
  case "${arg}" in
    --webhook) CONFIGURE_WEBHOOK=true ;;
    --stop) STOP=true ;;
    -h|--help)
      sed -n '2,12p' "$0"
      exit 0
      ;;
  esac
done

mkdir -p "${NGROK_DIR}"

ngrok_cmd() {
  if command -v ngrok >/dev/null 2>&1; then
    command ngrok "$@"
  elif [[ -x "${NGROK_DIR}/bin/ngrok" ]]; then
    "${NGROK_DIR}/bin/ngrok" "$@"
  else
    return 127
  fi
}

resolve_ngrok_bin() {
  if command -v ngrok >/dev/null 2>&1; then
    command -v ngrok
  elif [[ -x "${NGROK_DIR}/bin/ngrok" ]]; then
    echo "${NGROK_DIR}/bin/ngrok"
  else
    return 1
  fi
}

stop_ngrok() {
  if [[ -f "${NGROK_PID_FILE}" ]]; then
    local pid
    pid="$(cat "${NGROK_PID_FILE}")"
    if kill -0 "${pid}" 2>/dev/null; then
      kill "${pid}"
      echo "Túnel ngrok encerrado (PID ${pid})."
    fi
    rm -f "${NGROK_PID_FILE}"
  else
    pkill -f "ngrok http ${JENKINS_PORT}" 2>/dev/null && echo "Túnel ngrok encerrado." || echo "Nenhum túnel ngrok em execução."
  fi
}

if [[ "${STOP}" == true ]]; then
  stop_ngrok
  exit 0
fi

if ! ngrok_cmd version >/dev/null 2>&1; then
  echo "ERRO: ngrok não encontrado."
  echo ""
  echo "Instale em: https://ngrok.com/download"
  echo ""
  echo "Linux (amd64, no projeto):"
  echo "  mkdir -p .ngrok/bin"
  echo "  curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok-v3-stable-linux-amd64.tgz | tar xz -C .ngrok/bin ngrok"
  echo ""
  echo "Ou globalmente:"
  echo "  curl -sSL https://ngrok-agent.s3.amazonaws.com/ngrok-v3-stable-linux-amd64.tgz | sudo tar xz -C /usr/local/bin ngrok"
  echo ""
  echo "Depois configure o token (conta gratuita em https://dashboard.ngrok.com):"
  echo "  ngrok config add-authtoken SEU_TOKEN"
  exit 1
fi

if ! curl -sf "http://localhost:${JENKINS_PORT}/login" > /dev/null 2>&1; then
  echo "ERRO: Jenkins não está respondendo em http://localhost:${JENKINS_PORT}"
  echo "Execute primeiro: bash scripts/setup-jenkins.sh"
  exit 1
fi

if [[ -f "${NGROK_PID_FILE}" ]]; then
  old_pid="$(cat "${NGROK_PID_FILE}")"
  if kill -0 "${old_pid}" 2>/dev/null; then
    echo "Túnel ngrok já em execução (PID ${old_pid})."
  else
    rm -f "${NGROK_PID_FILE}"
  fi
fi

if [[ ! -f "${NGROK_PID_FILE}" ]]; then
  NGROK_BIN="$(resolve_ngrok_bin)"
  echo "==> Iniciando túnel ngrok na porta ${JENKINS_PORT}"
  nohup "${NGROK_BIN}" http "${JENKINS_PORT}" --log=stdout > "${NGROK_LOG}" 2>&1 &
  echo $! > "${NGROK_PID_FILE}"
fi

echo "==> Aguardando URL pública do ngrok"
PUBLIC_URL=""
for i in $(seq 1 30); do
  PUBLIC_URL="$(curl -sf "${NGROK_API}/api/tunnels" 2>/dev/null | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    for t in data.get('tunnels', []):
        url = t.get('public_url', '')
        if url.startswith('https://'):
            print(url)
            break
except Exception:
    pass
" 2>/dev/null || echo "")"
  if [[ -n "${PUBLIC_URL}" ]]; then
    break
  fi
  sleep 1
done

if [[ -z "${PUBLIC_URL}" ]]; then
  echo "ERRO: não foi possível obter a URL do ngrok."
  echo "Verifique o log: ${NGROK_LOG}"
  if [[ -f "${NGROK_LOG}" ]]; then
    echo ""
    echo "--- últimas linhas do log ---"
    tail -10 "${NGROK_LOG}"
  fi
  echo ""
  echo "Confirme que o authtoken está configurado: ngrok config add-authtoken SEU_TOKEN"
  exit 1
fi

echo "${PUBLIC_URL}" > "${NGROK_DIR}/public_url.txt"

WEBHOOK_URL="${PUBLIC_URL%/}/github-webhook/"

echo ""
echo "=========================================="
echo "  Jenkins público (ngrok)"
echo "=========================================="
echo "  URL Jenkins : ${PUBLIC_URL}"
echo "  Webhook GitHub: ${WEBHOOK_URL}"
echo "  Painel ngrok  : ${NGROK_API}"
echo "  Log           : ${NGROK_LOG}"
echo ""
echo "Configure no Jenkins (Manage Jenkins → System):"
echo "  Jenkins URL = ${PUBLIC_URL}"
echo ""
echo "Para encerrar o túnel:"
echo "  bash scripts/setup-ngrok.sh --stop"
echo "=========================================="

if [[ "${CONFIGURE_WEBHOOK}" == true ]]; then
  echo ""
  JENKINS_URL="${PUBLIC_URL}" bash "${ROOT_DIR}/scripts/configure-github-webhook.sh"
fi

#!/usr/bin/env bash
# Dispara build do pipeline Jenkins e aguarda conclusão.
set -euo pipefail

JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_CONTAINER="${JENKINS_CONTAINER:-jenkins}"
JOB_NAME="${JOB_NAME:-biblioteca-api-pipeline}"
ADMIN_PASSWORD="${JENKINS_PASSWORD:-$(docker exec "${JENKINS_CONTAINER}" cat /var/jenkins_home/secrets/initialAdminPassword)}"

COOKIE_JAR="$(mktemp)"
trap 'rm -f "${COOKIE_JAR}"' EXIT

CRUMB="$(curl -sf -c "${COOKIE_JAR}" -u "admin:${ADMIN_PASSWORD}" \
  "${JENKINS_URL}/crumbIssuer/api/json" | python3 -c "import sys,json; print(json.load(sys.stdin)['crumb'])")"

echo "==> Disparando build do job '${JOB_NAME}'"
QUEUE_URL="$(curl -sf -X POST -b "${COOKIE_JAR}" -c "${COOKIE_JAR}" \
  -u "admin:${ADMIN_PASSWORD}" \
  -H "Jenkins-Crumb: ${CRUMB}" \
  "${JENKINS_URL}/job/${JOB_NAME}/build" \
  -D - -o /dev/null | grep -i '^Location:' | awk '{print $2}' | tr -d '\r')"

if [[ -z "${QUEUE_URL}" ]]; then
  echo "ERRO: não foi possível enfileirar o build."
  exit 1
fi

echo "==> Aguardando build iniciar (queue: ${QUEUE_URL})"
BUILD_URL=""
for i in $(seq 1 60); do
  BUILD_URL="$(curl -sf -u "admin:${ADMIN_PASSWORD}" "${QUEUE_URL}api/json" | python3 -c "
import sys, json
data = json.load(sys.stdin)
exe = data.get('executable')
print(exe['url'] if exe else '')
" 2>/dev/null || echo "")"
  if [[ -n "${BUILD_URL}" ]]; then
    break
  fi
  sleep 2
done

if [[ -z "${BUILD_URL}" ]]; then
  echo "ERRO: build não iniciou a tempo."
  exit 1
fi

BUILD_NUMBER="$(basename "${BUILD_URL%/}")"
echo "==> Build #${BUILD_NUMBER} em execução: ${BUILD_URL}"

for i in $(seq 1 120); do
  RESULT="$(curl -sf -u "admin:${ADMIN_PASSWORD}" "${BUILD_URL}api/json" | python3 -c "
import sys, json
print(json.load(sys.stdin).get('result') or '')
" 2>/dev/null || echo "")"
  if [[ -n "${RESULT}" ]]; then
    echo "==> Build #${BUILD_NUMBER} finalizado: ${RESULT}"
    if [[ "${RESULT}" == "SUCCESS" ]]; then
      exit 0
    fi
    exit 1
  fi
  sleep 5
done

echo "ERRO: timeout aguardando conclusão do build."
exit 1

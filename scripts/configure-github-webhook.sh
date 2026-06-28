#!/usr/bin/env bash
# Configura webhook do GitHub para disparar o Jenkins em push na main.
# Requer: gh CLI autenticado e Jenkins acessível pela URL informada.
set -euo pipefail

REPO="${GITHUB_REPO:-leticiaafigueiredo/tp2-gerencia-conf}"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
WEBHOOK_URL="${JENKINS_URL%/}/github-webhook/"

if ! command -v gh >/dev/null 2>&1; then
  echo "AVISO: gh CLI não encontrado. Configure manualmente em:"
  echo "  https://github.com/${REPO}/settings/hooks"
  echo ""
  echo "  Payload URL: ${WEBHOOK_URL}"
  echo "  Content type: application/json"
  echo "  Events: Just the push event"
  echo ""
  if [[ "${JENKINS_URL}" == *"localhost"* ]] || [[ "${JENKINS_URL}" == *"127.0.0.1"* ]]; then
    echo "NOTA: GitHub não alcança localhost. Use um túnel (ngrok/cloudflare) ou"
    echo "      Jenkins em servidor público, e então reexecute este script com:"
    echo "      JENKINS_URL=https://seu-dominio-publico bash scripts/configure-github-webhook.sh"
  fi
  exit 0
fi

echo "==> Configurando webhook em github.com/${REPO}"
echo "    URL: ${WEBHOOK_URL}"

gh api "repos/${REPO}/hooks" \
  -f name=web \
  -f active=true \
  -f "config[url]=${WEBHOOK_URL}" \
  -f "config[content_type]=json" \
  -f "config[insecure_ssl]=0" \
  --input - <<EOF
{
  "events": ["push"]
}
EOF

echo "Webhook configurado com sucesso."

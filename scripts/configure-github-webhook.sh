#!/usr/bin/env bash
# Configura webhook do GitHub para disparar o Jenkins em push na main.
# Requer: gh CLI autenticado e Jenkins acessível pela URL informada.
set -euo pipefail

REPO="${GITHUB_REPO:-leticiaafigueiredo/tp2-gerencia-conf}"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
WEBHOOK_URL="${JENKINS_URL%/}/github-webhook/"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERRO: gh CLI não encontrado. Instale com: sudo apt install gh"
  echo "Configure manualmente em: https://github.com/${REPO}/settings/hooks"
  echo "  Payload URL: ${WEBHOOK_URL}"
  echo "  Content type: application/json"
  echo "  Events: Just the push event"
  exit 1
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

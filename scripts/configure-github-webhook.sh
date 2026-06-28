#!/usr/bin/env bash
# Configura webhook do GitHub para disparar o Jenkins em push na main.
# Requer: gh CLI autenticado (ou configure manualmente) e Jenkins acessível pela URL informada.
#
# Com ngrok:
#   bash scripts/setup-ngrok.sh --webhook
#   # ou
#   JENKINS_URL=https://xxxx.ngrok-free.app bash scripts/configure-github-webhook.sh
set -euo pipefail

REPO="${GITHUB_REPO:-leticiaafigueiredo/tp2-gerencia-conf}"
ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"

# Usa URL salva pelo setup-ngrok.sh quando disponível
if [[ "${JENKINS_URL}" == "http://localhost:8080" ]] && [[ -f "${ROOT_DIR}/.ngrok/public_url.txt" ]]; then
  JENKINS_URL="$(cat "${ROOT_DIR}/.ngrok/public_url.txt")"
fi
WEBHOOK_URL="${JENKINS_URL%/}/github-webhook/"

print_manual_instructions() {
  echo "Configure manualmente em:"
  echo "  https://github.com/${REPO}/settings/hooks"
  echo ""
  echo "  Payload URL: ${WEBHOOK_URL}"
  echo "  Content type: application/json"
  echo "  Secret: (deixe vazio)"
  echo "  SSL verification: Enable SSL verification"
  echo "  Events: Just the push event"
}

if ! command -v gh >/dev/null 2>&1; then
  echo "AVISO: gh CLI não encontrado."
  print_manual_instructions
  echo ""
  if [[ "${JENKINS_URL}" == *"localhost"* ]] || [[ "${JENKINS_URL}" == *"127.0.0.1"* ]]; then
    echo "NOTA: use ngrok primeiro: bash scripts/setup-ngrok.sh"
  fi
  exit 0
fi

if ! gh auth status >/dev/null 2>&1; then
  echo "AVISO: gh não autenticado. Execute: gh auth login"
  print_manual_instructions
  exit 0
fi

echo "==> Configurando webhook em github.com/${REPO}"
echo "    URL: ${WEBHOOK_URL}"

EXISTING_HOOK_ID="$(gh api "repos/${REPO}/hooks" --jq ".[] | select(.config.url | test(\"github-webhook\")) | .id" 2>/dev/null | head -1 || true)"

if [[ -n "${EXISTING_HOOK_ID}" ]]; then
  echo "    Atualizando webhook existente (id ${EXISTING_HOOK_ID})"
  gh api -X PATCH "repos/${REPO}/hooks/${EXISTING_HOOK_ID}" \
    -f active=true \
    -f "config[url]=${WEBHOOK_URL}" \
    -f "config[content_type]=json" \
    -f "config[insecure_ssl]=0"
else
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
fi

echo "Webhook configurado com sucesso."
echo ""
echo "Teste com:"
echo "  git commit --allow-empty -m 'test: webhook ngrok' && git push origin main"

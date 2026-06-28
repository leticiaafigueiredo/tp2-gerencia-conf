#!/usr/bin/env bash
# Ativa GitHub Push Trigger no job Jenkins (necessário para webhook disparar builds).
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JENKINS_PASSWORD="${JENKINS_PASSWORD:-$(docker exec jenkins cat /var/jenkins_home/secrets/initialAdminPassword)}"

bash "${ROOT_DIR}/scripts/create-jenkins-job.sh"

echo ""
echo "Verificando trigger..."
docker exec jenkins grep -A2 "<triggers>" /var/jenkins_home/jobs/biblioteca-api-pipeline/config.xml

echo ""
echo "Teste com:"
echo "  git commit --allow-empty -m 'test: webhook' && git push origin main"

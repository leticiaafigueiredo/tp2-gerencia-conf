#!/usr/bin/env bash
# Sobe Jenkins via Docker e instala plugins necessários para o pipeline.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_CONTAINER="${JENKINS_CONTAINER:-jenkins}"

echo "==> Subindo Jenkins"
docker compose -f "${ROOT_DIR}/docker-compose.jenkins.yml" up -d

echo "==> Aguardando Jenkins iniciar"
for i in $(seq 1 60); do
  if curl -sf "${JENKINS_URL}/login" > /dev/null 2>&1; then
    break
  fi
  sleep 2
done

if ! curl -sf "${JENKINS_URL}/login" > /dev/null 2>&1; then
  echo "ERRO: Jenkins não respondeu em ${JENKINS_URL}"
  exit 1
fi

echo "==> Instalando plugins (Git, GitHub, Pipeline, Docker)"
PLUGINS=(
  git
  github
  workflow-aggregator
  pipeline-stage-view
  docker-workflow
  credentials-binding
)

docker exec "${JENKINS_CONTAINER}" jenkins-plugin-cli --plugins "${PLUGINS[@]}" || {
  echo "AVISO: jenkins-plugin-cli falhou. Instale os plugins manualmente no Jenkins UI."
}

echo ""
echo "Jenkins disponível em: ${JENKINS_URL}"
echo ""
echo "Próximos passos manuais:"
echo "  1. Obter senha inicial: docker exec ${JENKINS_CONTAINER} cat /var/jenkins_home/secrets/initialAdminPassword"
echo "  2. Criar job Pipeline apontando para o repositório Git (branch main, Script Path: Jenkinsfile)"
echo "  3. Marcar 'GitHub hook trigger for GITScm polling' no job"
echo "  4. Configurar webhook no GitHub: ${JENKINS_URL}/github-webhook/"
echo ""
echo "Para instalar Python e Make no agente Jenkins:"
echo "  docker exec -u root ${JENKINS_CONTAINER} apt-get update"
echo "  docker exec -u root ${JENKINS_CONTAINER} apt-get install -y python3 python3-pip python3-venv make curl"
echo "  docker exec -u root ${JENKINS_CONTAINER} usermod -aG docker jenkins"

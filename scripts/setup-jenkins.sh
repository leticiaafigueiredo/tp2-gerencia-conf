# Sobe Jenkins via Docker e instala plugins necessários para o pipeline.
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
JENKINS_URL="${JENKINS_URL:-http://localhost:8080}"
JENKINS_CONTAINER="${JENKINS_CONTAINER:-jenkins}"

echo "==> Construindo imagem Jenkins (Python, Docker CLI, Make)"
HOST_DOCKER_GID="${HOST_DOCKER_GID:-$(getent group docker | cut -d: -f3)}"
export HOST_DOCKER_GID
docker compose -f "${ROOT_DIR}/docker-compose.jenkins.yml" build
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
echo "Próximos passos:"
echo "  1. Criar job: bash scripts/create-jenkins-job.sh"
echo "  2. Ativar trigger GitHub: bash scripts/enable-github-trigger.sh"
echo "  3. Expor Jenkins com ngrok: bash scripts/setup-ngrok.sh --webhook"

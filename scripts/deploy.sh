#!/usr/bin/env bash
# Script de implantação para uso no pipeline Jenkins (etapa de Lançamento)
set -euo pipefail

IMAGE_NAME="${IMAGE_NAME:-biblioteca-api}"
IMAGE_TAG="${IMAGE_TAG:-latest}"
CONTAINER_NAME="${CONTAINER_NAME:-biblioteca-api}"
HOST_PORT="${HOST_PORT:-8000}"

echo "==> Build da imagem Docker"
docker build -t "${IMAGE_NAME}:${IMAGE_TAG}" .

echo "==> Parando container anterior (se existir)"
docker stop "${CONTAINER_NAME}" 2>/dev/null || true
docker rm "${CONTAINER_NAME}" 2>/dev/null || true

echo "==> Implantando nova versão"
docker run -d \
  --name "${CONTAINER_NAME}" \
  -p "${HOST_PORT}:8000" \
  --restart unless-stopped \
  "${IMAGE_NAME}:${IMAGE_TAG}"

echo "==> Verificando saúde da aplicação"
for i in $(seq 1 10); do
  if curl -sf "http://localhost:${HOST_PORT}/api/v1/health" > /dev/null; then
    echo "Implantação concluída com sucesso!"
    exit 0
  fi
  sleep 2
done

echo "ERRO: aplicação não respondeu ao health check"
docker logs "${CONTAINER_NAME}"
exit 1

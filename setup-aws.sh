#!/bin/bash
set -e

echo "Payment Service - AWS Academy Setup"
echo "======================================"

# Check .env.aws
if [ ! -f .env.aws ]; then
    echo "Criando .env.aws..."
    cp .env.aws.template .env.aws
    echo "[Warning]  Edite .env.aws com suas credenciais AWS!"
    exit 1
fi

# Build
echo "[Info]  Building..."
docker-compose -f docker-compose.aws.yml build

# Start
echo "[Info]  Iniciando..."
docker-compose -f docker-compose.aws.yml --env-file .env.aws up -d

echo "[Info]  Containers iniciados!"
echo "[Info]  Ver logs: docker logs ms-payments -f"
echo "[Info]  Health: http://localhost:8082/actuator/health"

# AWS Academy Setup Guide

## Passo 1: Credenciais AWS
1. AWS Academy Learner Lab → Start Lab
2. AWS Details → Show (AWS CLI)
3. Copiar: AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, AWS_SESSION_TOKEN

## Passo 2: Criar Recursos AWS
1. **SQS Queue**: order-payments-queue
2. **SNS Topic**: payment-status
3. Copiar ARN do topico SNS

## Passo 3: Configurar
```bash
cp .env.aws.template .env.aws
nano .env.aws  # Colar credenciais + ARN
```

## Passo 4: Executar
```bash
./setup-aws.sh
```

## Endpoints
- http://localhost:8082/actuator/health
- http://localhost:8082/swagger-ui.html

## Troubleshooting
- Logs: docker logs ms-payments -f
- AWS Env: docker exec ms-payments env | grep AWS
- Parar: docker-compose -f docker-compose.aws.yml down

**Credenciais expiram em 4 horas!**

# Payment Service

Microsserviço responsável pelo gerenciamento de pagamentos do sistema SOAT - Grupo 75.

## Tecnologias

- **Java 21** (Eclipse Temurin)
- **Spring Boot**
- **PostgreSQL 17**
- **Flyway** (Migrações de banco de dados)
- **RSA Encryption** (JWT/Token signing)
- **Docker & Docker Compose**
- **Kubernetes** (Deployments, Services, HPA)
- **Maven 3.9.9**

## Pré-requisitos

- Java 21+
- Maven 3.9+
- Docker & Docker Compose
- Kubernetes (kubectl) - para deploy em cluster

## Execução Local

### Usando Docker Compose

```bash
# Subir a aplicação com PostgreSQL
docker-compose up -d

# Ver logs
docker-compose logs -f payment-service-backend

# Parar os serviços
docker-compose down
```

A aplicação estará disponível em: `http://localhost:8082`

### Usando Maven

```bash
# Compilar o projeto
./mvnw clean package -DskipTests

# Executar a aplicação
./mvnw spring-boot:run
```

## Docker

### Build da imagem

```bash
docker build -t payment-service:latest .
```

### Executar container

```bash
docker run -p 8082:8082 \
  -e DB_URL=jdbc:postgresql://localhost:5432/payment \
  -e DB_USER=admin \
  -e DB_PASS=123456 \
  payment-service:latest
```

## Deploy no Kubernetes

### Configurar variáveis de ambiente

Antes de fazer o deploy, configure as variáveis de ambiente:

```bash
export SOAT_DB_URL="jdbc:postgresql://postgres-service:5432/payment"
export SOAT_DB_USER="admin"
export SOAT_DB_PASS="your-secure-password"
export K8S_IMAGE_TAG="payment-service:latest"
```

### Deploy usando Kustomize

```bash
# Aplicar todos os recursos
kubectl apply -k infra/

# Verificar os recursos criados
kubectl get all -n payment-service

# Verificar logs
kubectl logs -f deployment/payment-service-backend -n payment-service

# Verificar HPA
kubectl get hpa -n payment-service
```

### Acessar a aplicação

```bash
# Obter o IP externo do LoadBalancer
kubectl get service payment-service-backend -n payment-service

# Acessar a aplicação
curl http://<EXTERNAL-IP>/health
```

## Endpoints

### Health Check
- `GET /health` - Verifica o status da aplicação

### API Documentation
- `GET /swagger-ui.html` - Swagger UI
- `GET /v3/api-docs` - OpenAPI JSON

## Configuração

### Variáveis de Ambiente

| Variável | Descrição | Padrão |
|----------|-----------|--------|
| `DB_URL` | URL de conexão com PostgreSQL | `jdbc:postgresql://localhost:5432/payment` |
| `DB_USER` | Usuário do banco de dados | `admin` |
| `DB_PASS` | Senha do banco de dados | `123456` |

## Recursos Kubernetes

- **Namespace**: `payment-service`
- **Replicas**: 2 (inicial)
- **HPA**: 2-5 replicas (baseado em 75% CPU)
- **Resources**:
  - Requests: CPU 100m, Memory 512Mi
  - Limits: CPU 500m, Memory 1Gi
- **Service Type**: LoadBalancer
- **Port**: 8082

## Monitoramento

### Probes

- **Startup Probe**: `/health` - 60 tentativas, 5s intervalo
- **Readiness Probe**: `/health` - 15s delay inicial
- **Liveness Probe**: `/health` - 30s delay inicial

### Scaling

O HPA está configurado para escalar baseado em CPU:
- **Min Replicas**: 2
- **Max Replicas**: 5
- **Target CPU**: 75%

## Banco de Dados

### Porta PostgreSQL
- **Docker Compose**: `localhost:5434`
- **Container Name**: `payment-service-postgres`
- **Database**: `payment`

### Migrações

As migrações são gerenciadas pelo Flyway e executadas automaticamente na inicialização da aplicação.

Localização: `src/main/resources/db/migration/`

## Segurança

Este serviço utiliza chaves RSA para assinatura de tokens e criptografia.

Chaves RSA localizadas em: `src/main/resources/rsa/`
- `private.pem` - Chave privada
- `public.pem` - Chave pública
- `rsa-key.json` - Configuração das chaves

## Testes

```bash
# Executar todos os testes
./mvnw test

# Executar com coverage
./mvnw verify
```

## Estrutura do Projeto

```
payment-service/
├── k8n/                          # Kubernetes manifests
│   ├── configmaps/                 # ConfigMaps
│   ├── deployments/                # Deployments
│   ├── hpas/                       # Horizontal Pod Autoscalers
│   ├── secrets/                    # Secrets
│   ├── services/                   # Services
│   ├── kustomization.yaml          # Kustomize config
│   └── namespace.yml               # Namespace definition
├── src/
│   ├── main/
│   │   ├── java/                   # Código fonte Java
│   │   └── resources/
│   │       ├── rsa/                # RSA keys
│   │       └── db/migration/       # Flyway migrations
│   └── test/                       # Testes
├── Dockerfile                      # Multi-stage Docker build
├── docker-compose.yml              # Docker Compose para dev local
└── pom.xml                         # Maven dependencies
```

## Funcionalidades

- Gerenciamento de pagamentos
- Integração com gateways de pagamento
- Validação e processamento de transações
- Event Store para auditoria de pagamentos

Tabela: `payments` (criada pela migração V202505241714)

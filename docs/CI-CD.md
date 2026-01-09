# ��� CI/CD Pipeline - Payment Service

## Visão Geral

A esteira de CI/CD do Payment Service é executada automaticamente via **GitHub Actions** e realiza:

1. **Build e Testes** - Compilação e execução de testes
2. **Build Docker** - Criação da imagem Docker e push para AWS ECR
3. **Deploy EKS** - Deploy automático no cluster Kubernetes (somente branch `main`)

---

## Workflows

### **Triggers (Gatilhos)**

- **Push** nas branches: `main`, `feature/aws-deploy`
- **Pull Request** para `main`
- **Manual** via `workflow_dispatch`

---

## Jobs

### **1. build_test_and_analyze**

**Objetivo:** Build, testes e análise de qualidade

**Steps:**
1. Checkout do código
2. Configurar JDK 21
3. Permissões ao mvnw
4. Cache de dependências Maven
5. Executar `./mvnw clean verify`
6. Upload dos relatórios de teste

**Duração estimada:** ~3-5 min

---

### **2. build_and_push_ecr**

**Objetivo:** Build da imagem Docker e push para AWS ECR

**Condições:**
- Executa após `build_test_and_analyze` ter sucesso
- Somente em **push** ou **workflow_dispatch**
- Branches: `main` ou `feature/aws-deploy`

**Steps:**
1. Checkout do código
2. Configurar credenciais AWS
3. Login no Amazon ECR
4. Verificar/Criar repositório ECR (`payment-service-repo`)
5. Build e push da imagem Docker
   - Tag: `<ecr-registry>/payment-service-repo:<commit-sha>`
   - Tag: `<ecr-registry>/payment-service-repo:latest`

**Outputs:**
- `image_uri_tag`: URI da imagem com digest
- `image_uri_digest`: URI da imagem com commit SHA

**Duração estimada:** ~2-4 min

---

### **3. deploy_to_eks**

**Objetivo:** Deploy automático no cluster EKS

**Condições:**
- Executa após `build_and_push_ecr` ter sucesso
- Somente em **push** ou **workflow_dispatch**
- **Apenas branch `main`**

**Steps:**
1. Checkout do código
2. Configurar credenciais AWS
3. Configurar kubectl para o cluster EKS
4. Instalar ferramentas (`envsubst`, `sponge`)
5. Verificar/Criar recursos AWS (SQS, SNS)
6. Aplicar manifests Kubernetes com substituição de variáveis
7. Aguardar rollout do deployment
8. Verificar status do deploy

**Recursos AWS criados automaticamente:**
- **SQS Queue:** `order-payments-queue`
- **SNS Topic:** `payment-status`

**Duração estimada:** ~3-5 min

---

### **4. deploy_to_dev**

**Objetivo:** Notificação de deploy em ambiente de desenvolvimento

**Condições:**
- Executa após `build_and_push_ecr` ter sucesso
- Somente branch `feature/aws-deploy`

**Comportamento:**
- Apenas notifica que a imagem foi construída
- **Não faz deploy automático** (somente na `main`)

---

## ��� Secrets Necessários

Configure no **GitHub Repository Settings → Secrets and variables → Actions**:

| Secret | Descrição | Exemplo |
|--------|-----------|---------|
| `AWS_ACCESS_KEY_ID` | AWS Access Key ID | `ASIA...` |
| `AWS_SECRET_ACCESS_KEY` | AWS Secret Access Key | `wJalr...` |
| `AWS_SESSION_TOKEN` | AWS Session Token (AWS Academy) | `IQoJb3...` |
| `PAYMENTS_DB_USER_B64` | DB User (base64) | `YWRtaW4=` |
| `PAYMENTS_DB_PASS_B64` | DB Password (base64) | `MTIzNDU2` |
| `PAYMENTS_DB_URL` | JDBC Connection String | `jdbc:postgresql://...` |

### **Gerar Secrets Base64:**

```bash
# User
echo -n "admin" | base64
# Output: YWRtaW4=

# Password
echo -n "123456" | base64
# Output: MTIzNDU2
```

---

## ��� Fluxo Completo

### **Branch `feature/aws-deploy`:**

```
Push → Build/Test → Docker Build → Push ECR → Notificação
```

**Resultado:** Imagem Docker disponível no ECR, sem deploy

---

### **Branch `main`:**

```
Push → Build/Test → Docker Build → Push ECR → Create AWS Resources → Deploy EKS → Verify
```

**Resultado:** Deploy completo no ambiente de produção

---

## ��� Monitoramento

### **GitHub Actions UI**

Acesse: `https://github.com/vinicius-ma/payment-service/actions`

**Visualização:**
- Status de cada job (✅ sucesso, ❌ falha, ��� em execução)
- Logs detalhados de cada step
- Artefatos gerados (test-results)

### **Comandos Úteis**

```bash
# Ver pods
kubectl get pods -n payments

# Ver logs
kubectl logs -f deployment/payments-app -n payments

# Ver eventos
kubectl get events -n payments --sort-by='.lastTimestamp'

# Verificar HPA
kubectl get hpa -n payments

# Rollback (se necessário)
kubectl rollout undo deployment/payments-app -n payments
```

---

## ��� Troubleshooting

### **Build Falha**

**Problema:** Testes falhando
```bash
# Executar localmente
./mvnw clean verify
```

**Problema:** Erro de compilação
```bash
# Limpar cache Maven
./mvnw clean
rm -rf ~/.m2/repository
```

---

### **Docker Push Falha**

**Problema:** Credenciais AWS expiradas
- AWS Academy: Credenciais expiram em **4 horas**
- Solução: Atualizar secrets no GitHub

**Problema:** Repositório ECR não existe
- Pipeline cria automaticamente
- Verificar: `aws ecr describe-repositories --region us-east-1`

---

### **Deploy EKS Falha**

**Problema:** Cluster não acessível
```bash
# Verificar credenciais
aws eks update-kubeconfig --region us-east-1 --name soat-infra-eks
kubectl get nodes
```

**Problema:** Recursos AWS não criados
```bash
# Verificar SQS
aws sqs list-queues --region us-east-1

# Verificar SNS
aws sns list-topics --region us-east-1
```

**Problema:** Pod crashlooping
```bash
# Ver logs
kubectl logs -f <pod-name> -n payments

# Descrever pod
kubectl describe pod <pod-name> -n payments
```

---

## ��� Atualizações

### **Atualizar Credenciais AWS (AWS Academy)**

1. Acessar AWS Academy Learner Lab
2. Start Lab → AWS Details → Show
3. Copiar credenciais
4. Atualizar no GitHub:
   - Settings → Secrets → Actions
   - Editar: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`

**⚠️ Renovar a cada 4 horas!**

---

### **Alterar Configuração do Pipeline**

Arquivo: `.github/workflows/ci-cd.yml`

**Exemplos:**

```yaml
# Adicionar nova branch
on:
  push:
    branches:
      - main
      - feature/aws-deploy
      - develop  # <- Nova branch
```

```yaml
# Alterar timeout do deploy
kubectl rollout status deployment/payments-app -n payments --timeout=10m
```

---

## ��� Referências

- [GitHub Actions Documentation](https://docs.github.com/actions)
- [AWS ECR Documentation](https://docs.aws.amazon.com/ecr/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubectl Documentation](https://kubernetes.io/docs/reference/kubectl/)

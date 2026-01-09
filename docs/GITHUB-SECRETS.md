# ⚙️ Configuração de Secrets - GitHub Actions

## Passo a Passo

1. Acesse o repositório no GitHub: `https://github.com/vinicius-ma/payment-service`
2. Vá em **Settings** → **Secrets and variables** → **Actions**
3. Clique em **New repository secret**
4. Adicione cada secret conforme instruções abaixo

---

## Secrets a Configurar

### **1. AWS Credentials (AWS Academy)**

Essas credenciais são obtidas no **AWS Academy Learner Lab**.

#### **AWS_ACCESS_KEY_ID**

**Descrição:** ID da chave de acesso AWS

**Como obter:**
1. Acesse o AWS Academy Learner Lab
2. Clique em **Start Lab** (aguarde o ícone verde)
3. Clique em **AWS Details** → **Show**
4. Copie o valor de `aws_access_key_id`

**Exemplo:** `ASIAX3WFAKEIDEXAMPLE`

---

#### **AWS_SECRET_ACCESS_KEY**

**Descrição:** Chave secreta de acesso AWS

**Como obter:**
1. Mesmo processo do Access Key ID
2. Copie o valor de `aws_secret_access_key`

**Exemplo:** `wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY`

---

#### **AWS_SESSION_TOKEN**

**Descrição:** Token de sessão temporário (AWS Academy)

**Como obter:**
1. Mesmo processo das credenciais anteriores
2. Copie o valor de `aws_session_token`

**Exemplo:** `IQoJb3JpZ2luX2VjEHQaCXVzLWVhc3QtMSJ...` (muito longo)

**⚠️ IMPORTANTE:**
- Token expira em **4 horas**
- Renovar antes de cada deploy
- Se o pipeline falhar com erro de credenciais, renove

---

### **2. Database Credentials**

As credenciais do banco de dados devem ser codificadas em **Base64**.

#### **PAYMENTS_DB_USER_B64**

**Descrição:** Usuário do banco (base64)

**Como gerar:**

```bash
echo -n "admin" | base64
```

**Resultado:** `YWRtaW4=`

**Adicionar no GitHub:**
- Name: `PAYMENTS_DB_USER_B64`
- Secret: `YWRtaW4=`

---

#### **PAYMENTS_DB_PASS_B64**

**Descrição:** Senha do banco (base64)

**Como gerar:**

```bash
echo -n "123456" | base64
```

**Resultado:** `MTIzNDU2`

**Adicionar no GitHub:**
- Name: `PAYMENTS_DB_PASS_B64`
- Secret: `MTIzNDU2`

---

#### **PAYMENTS_DB_URL**

**Descrição:** String de conexão JDBC do PostgreSQL

**Formato:**

```
jdbc:postgresql://<RDS_ENDPOINT>:5432/payments
```

**Exemplo:**

```
jdbc:postgresql://payments-db.c1a2b3c4d5e6.us-east-1.rds.amazonaws.com:5432/payments
```

**Como obter o RDS Endpoint:**

```bash
# Via AWS CLI
aws rds describe-db-instances \
  --query 'DBInstances[*].[DBInstanceIdentifier,Endpoint.Address]' \
  --output table
```

Ou via Console AWS:
1. RDS → Databases
2. Clique na instância `payments-db`
3. Copie o **Endpoint** da seção "Connectivity & security"

**Adicionar no GitHub:**
- Name: `PAYMENTS_DB_URL`
- Secret: `jdbc:postgresql://<endpoint>:5432/payments`

---

## Verificar Configuração

### **Via GitHub CLI**

```bash
# Listar secrets (não mostra valores)
gh secret list --repo vinicius-ma/payment-service
```

**Saída esperada:**

```
AWS_ACCESS_KEY_ID          Updated 2025-01-09
AWS_SECRET_ACCESS_KEY      Updated 2025-01-09
AWS_SESSION_TOKEN          Updated 2025-01-09
PAYMENTS_DB_USER_B64       Updated 2025-01-09
PAYMENTS_DB_PASS_B64       Updated 2025-01-09
PAYMENTS_DB_URL            Updated 2025-01-09
```

---

### **Via GitHub Actions**

Trigger o pipeline e verifique os logs:

```bash
# Via push
git push origin feature/aws-deploy

# Via workflow_dispatch
gh workflow run ci-cd.yml --repo vinicius-ma/payment-service
```

**Verificar logs:**
1. Acesse: `https://github.com/vinicius-ma/payment-service/actions`
2. Clique no workflow em execução
3. Verifique se os jobs executaram sem erros de credenciais

---

## Renovar Credenciais AWS

### **Quando renovar?**

- **Antes de cada deploy** (se passaram mais de 4 horas)
- **Quando o pipeline falhar** com erro de credenciais
- **Proativamente** antes de sessões de desenvolvimento

---

### **Como renovar?**

#### **Via GitHub UI:**

1. Settings → Secrets → Actions
2. Clique em `AWS_ACCESS_KEY_ID` → **Update**
3. Cole o novo valor → **Update secret**
4. Repita para `AWS_SECRET_ACCESS_KEY` e `AWS_SESSION_TOKEN`

---

#### **Via GitHub CLI:**

```bash
# Obter credenciais do AWS CLI
aws configure list

# Atualizar secrets (substitua pelos valores reais)
gh secret set AWS_ACCESS_KEY_ID --body "ASIA..." --repo vinicius-ma/payment-service
gh secret set AWS_SECRET_ACCESS_KEY --body "wJalr..." --repo vinicius-ma/payment-service
gh secret set AWS_SESSION_TOKEN --body "IQoJb3..." --repo vinicius-ma/payment-service
```

---

## Template de Configuração

Crie um arquivo `setup-github-secrets.sh` (não commitar!):

```bash
#!/bin/bash

REPO="vinicius-ma/payment-service"

# AWS Credentials (obter do AWS Academy)
gh secret set AWS_ACCESS_KEY_ID --body "ASIA..." --repo $REPO
gh secret set AWS_SECRET_ACCESS_KEY --body "wJalr..." --repo $REPO
gh secret set AWS_SESSION_TOKEN --body "IQoJb3..." --repo $REPO

# Database Credentials
gh secret set PAYMENTS_DB_USER_B64 --body "$(echo -n 'admin' | base64)" --repo $REPO
gh secret set PAYMENTS_DB_PASS_B64 --body "$(echo -n '123456' | base64)" --repo $REPO
gh secret set PAYMENTS_DB_URL --body "jdbc:postgresql://payments-db.XXX.us-east-1.rds.amazonaws.com:5432/payments" --repo $REPO

echo "✅ Secrets configurados com sucesso!"
```

**Uso:**

```bash
chmod +x setup-github-secrets.sh
./setup-github-secrets.sh
```

---

## Segurança

### **Boas Práticas:**

✅ **FAZER:**
- Renovar credenciais AWS regularmente
- Usar Base64 para senhas do banco
- Verificar logs do pipeline para vazamentos acidentais
- Documentar o processo de renovação
- Usar credenciais de AWS Academy apenas em desenvolvimento

❌ **NÃO FAZER:**
- Commitar secrets no código
- Compartilhar credenciais em chats/emails
- Usar credenciais de produção em desenvolvimento
- Logar valores de secrets no pipeline
- Hardcoded secrets em Dockerfiles ou Kubernetes manifests

---

### **Mascaramento de Logs:**

O GitHub Actions **mascara automaticamente** os valores dos secrets nos logs:

```yaml
- name: Debug AWS Credentials
  run: echo "Access Key: ${{ secrets.AWS_ACCESS_KEY_ID }}"
  # Output: Access Key: ***
```

---

## Referências

- [GitHub Secrets Documentation](https://docs.github.com/actions/security-guides/encrypted-secrets)
- [AWS Academy Credentials](https://awsacademy.instructure.com/)
- [Base64 Encoding](https://www.base64encode.org/)
- [GitHub CLI Secrets](https://cli.github.com/manual/gh_secret)

---

## Troubleshooting

### **Erro: "Invalid AWS Credentials"**

**Solução:**
1. Verificar se credenciais AWS estão atualizadas (4h de validade)
2. Copiar novamente do AWS Academy Learner Lab
3. Atualizar os 3 secrets: ACCESS_KEY, SECRET_KEY, SESSION_TOKEN

---

### **Erro: "Database connection failed"**

**Solução:**
1. Verificar se `PAYMENTS_DB_URL` está correto
2. Testar conexão localmente:

```bash
# Decodificar credenciais
echo "YWRtaW4=" | base64 -d  # admin
echo "MTIzNDU2" | base64 -d  # 123456

# Testar conexão
psql "jdbc:postgresql://payments-db.XXX.us-east-1.rds.amazonaws.com:5432/payments?user=admin&password=123456"
```

---

### **Erro: "Secret not found"**

**Solução:**
1. Verificar se secret foi criado corretamente:

```bash
gh secret list --repo vinicius-ma/payment-service
```

2. Verificar nome do secret no workflow (case-sensitive)
3. Recriar o secret se necessário

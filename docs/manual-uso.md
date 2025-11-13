# Manual de Uso - UniFIAP Pay SPB

## 🚀 Como Executar o Projeto

### Pré-requisitos
- Docker e Docker Compose
- Kubernetes (Minikube, Kind ou cluster)
- kubectl configurado
- Conta no Docker Hub (para push das imagens)

### Passo a Passo Completo

#### 1. Clone e Configuração Inicial
```bash
git clone <seu-repositorio>
cd unifiap-pay-spb

# Verificar estrutura do projeto
ls -la
```

#### 2. Configurar Variáveis
Edite o arquivo `docker/.env` e configure:
- Seu RM na tag das imagens
- Valor da reserva bancária
- Configurações específicas

#### 3. Build das Imagens
```bash
# Linux/Mac
./scripts/build.sh

# Windows
scripts\build.bat
```

#### 4. Testar Localmente (Opcional)
```bash
cd docker
docker-compose up -d
```

#### 5. Deploy no Kubernetes
```bash
# Linux/Mac
./scripts/deploy-k8s.sh

# Windows
scripts\deploy-k8s.bat
```

#### 6. Coletar Evidências
```bash
./scripts/collect-evidences.sh
```

## 📊 Endpoints da API

### Health Check
```bash
GET /health
```

### Consultar Saldo da Reserva
```bash
GET /saldo-reserva
```

### Processar PIX
```bash
POST /pix
Content-Type: application/json

{
  "valor": 100.50,
  "chave_pix": "usuario@exemplo.com",
  "banco_destinatario": "123",
  "descricao": "Pagamento teste"
}
```

### Listar Instruções
```bash
GET /instrucoes
```

### Consultar Instrução Específica
```bash
GET /instrucoes/{id}
```

## 🔧 Comandos Úteis

### Docker
```bash
# Ver logs da API
docker logs unifiap-api-pagamentos

# Ver logs do Auditoria
docker logs unifiap-auditoria-service

# Inspecionar rede
docker network inspect unifiap_net
```

### Kubernetes
```bash
# Ver status dos pods
kubectl get pods -n unifiapay

# Escalar a API
kubectl scale deployment api-pagamentos --replicas=3 -n unifiapay

# Ver logs
kubectl logs -f deployment/api-pagamentos -n unifiapay

# Port forward para teste local
kubectl port-forward service/api-pagamentos-service 5000:80 -n unifiapay

# Executar CronJob manualmente
kubectl create job --from=cronjob/cronjob-fechamento-reserva manual-test -n unifiapay
```

### Troubleshooting
```bash
# Verificar se cluster está rodando
kubectl cluster-info

# Ver eventos
kubectl get events -n unifiapay

# Diagnosticar pod com problema
kubectl describe pod <pod-name> -n unifiapay

# Limpar tudo
kubectl delete namespace unifiapay
```

## 📁 Estrutura do Projeto

```
unifiap-pay-spb/
├── api-pagamentos/          # Microsserviço da API
│   ├── app.py               # Código principal
│   ├── requirements.txt     # Dependências Python
│   └── Dockerfile           # Multi-stage build
├── auditoria-service/       # Microsserviço de auditoria
│   ├── app.py               # Sistema de liquidação
│   ├── requirements.txt     # Dependências Python
│   └── Dockerfile           # Multi-stage build
├── k8s/                     # Manifests Kubernetes
│   ├── 01-namespace.yaml    # Namespace unifiapay
│   ├── 02-configmap.yaml    # Configurações
│   ├── 03-secret.yaml       # Secrets (PIX key)
│   ├── 04-pvc.yaml         # Volume compartilhado
│   ├── 05-rbac.yaml        # Permissões RBAC
│   ├── 06-api-pagamentos-deployment.yaml
│   ├── 07-api-pagamentos-service.yaml
│   ├── 08-auditoria-service-deployment.yaml
│   ├── 09-cronjob.yaml     # CronJob a cada 6h
│   └── 10-network-policy.yaml
├── docker/                  # Configurações Docker
│   ├── docker-compose.yml  # Orquestração local
│   ├── .env                # Variáveis de ambiente
│   └── pix.key             # Chave PIX simulada
├── scripts/                 # Scripts de automação
│   ├── build.sh/.bat       # Build e push imagens
│   ├── deploy-k8s.sh/.bat  # Deploy no K8s
│   └── collect-evidences.sh # Coleta evidências
└── docs/                    # Documentação
    ├── evidencias-README.md
    └── manual-uso.md
```

## 🔐 Configurações de Segurança

### Docker
- ✅ Multi-stage builds
- ✅ Usuário não-root
- ✅ Scan de vulnerabilidades
- ✅ Rede isolada customizada

### Kubernetes
- ✅ SecurityContext (runAsNonRoot)
- ✅ Resource limits
- ✅ RBAC com permissões mínimas
- ✅ Network Policies
- ✅ Secrets para dados sensíveis

## 📈 Monitoramento

### Logs Importantes
```bash
# API processando PIX
[INFO] PIX processado com sucesso - ID: abc123, Valor: R$ 100.50

# Auditoria liquidando
[INFO] Liquidação concluída: abc123

# Reserva bancária
[INFO] Reserva Bancária configurada: R$ 1000000.00
```

### Métricas
- CPU/Memory usage dos pods
- Número de PIX processados
- Taxa de liquidação
- Latência da API

## 🎯 Critérios de Avaliação Atendidos

### ✅ Etapa 1: Docker e Imagem Segura (1,5 pts)
- Multi-stage Dockerfile
- Push com tag v1.93744
- Scan de vulnerabilidades

### ✅ Etapa 2: Rede, Comunicação e Segmentação (2,5 pts)
- Rede customizada 172.25.0.0/24
- Comunicação entre containers
- Leitura de variáveis de ambiente

### ✅ Etapa 3: Kubernetes – Estrutura, Escala e Deploy (3,0 pts)
- API com 2+ réplicas
- Volume compartilhado entre pods
- CronJob funcionando

### ✅ Etapa 4: Kubernetes – Segurança, Observação e Operação (2,0 pts)
- Resource limits configurados
- SecurityContext implementado
- RBAC com permissões restritas
- Network Policies ativas
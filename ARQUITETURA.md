# Arquitetura do Sistema UniFIAP Pay SPB

## Visão Geral

O sistema UniFIAP Pay SPB é uma solução de pagamento PIX que implementa os princípios do Sistema de Pagamentos Brasileiro (SPB) através de uma arquitetura de microsserviços containerizada.

**Aluno:** Hugo Griilo Alves | **RM:** 555354

---

## Componentes Principais

### 1. API de Pagamentos (`api-pagamentos`)

**Responsabilidade:** Simula o Banco Originador (UniFIAP Pay)

#### Funcionalidades:
- Consulta saldo da Reserva Bancária no BACEN
- Valida se há saldo suficiente para o PIX
- Registra instruções de pagamento com status `AGUARDANDO_LIQUIDACAO`
- Fornece endpoints RESTful para criação e consulta de PIX

#### Endpoints:
- `GET /health` - Health check
- `GET /api/v1/saldo` - Consulta saldo
- `POST /api/v1/pix` - Cria instrução PIX
- `GET /api/v1/instrucoes` - Lista instruções
- `GET /api/v1/instrucoes/<id>` - Obtém instrução específica

#### Validações:
```
SE Valor do PIX > RESERVA_BANCARIA_SALDO
   ENTÃO Rejeitar com erro 402
SENÃO
   Registrar instrução com status AGUARDANDO_LIQUIDACAO
```

### 2. Serviço de Auditoria (`auditoria-service`)

**Responsabilidade:** Simula o Sistema de Liquidação (BACEN/STR)

#### Funcionalidades:
- Monitora o arquivo de instruções (`instrucoes.log`)
- Processa transações com status `AGUARDANDO_LIQUIDACAO`
- Atualiza status para `LIQUIDADO`
- Executa automaticamente via CronJob a cada 6 horas

#### Endpoints:
- `GET /health` - Health check
- `GET /api/v1/auditoria/status` - Status da auditoria
- `POST /api/v1/auditoria/processar` - Processa manualmente
- `GET /api/v1/auditoria/instrucoes` - Lista instruções

---

## Fluxo de Dados

```
┌─────────────────┐
│   Cliente PIX   │
└────────┬────────┘
         │
         │ POST /api/v1/pix
         ▼
┌──────────────────────┐
│  API de Pagamentos   │
│  (api-pagamentos)    │
│                      │
│ 1. Valida saldo      │
│ 2. Registra instr.   │
└──────────┬───────────┘
           │
           │ Escreve
           ▼
┌──────────────────────┐
│  Arquivo Compartilh. │
│  (PVC)               │
│  /var/logs/api/      │
│  instrucoes.log      │
└──────────┬───────────┘
           │ Lê periodicamente
           │ (CronJob 6h)
           ▼
┌──────────────────────┐
│ Serviço de Auditoria │
│ (auditoria-service)  │
│                      │
│ 1. Processa instr.   │
│ 2. Atualiza status   │
│ 3. Liquidado         │
└──────────┬───────────┘
           │ Escreve
           ▼
┌──────────────────────┐
│  Arquivo Compartilh. │
│  (PVC)               │
│  /var/logs/api/      │
│  instrucoes.log      │
└──────────────────────┘
```

---

## Camadas da Arquitetura

### 1. Camada de Aplicação

```
┌─────────────────────────────────────────┐
│      Camada de Aplicação                │
├─────────────────────────────────────────┤
│  API-Pagamentos    │  Auditoria-Service │
│  (2 replicas)      │  (1 replica)       │
│                    │                    │
│  Port: 8080        │  Port: 8081        │
└─────────────────────────────────────────┘
```

### 2. Camada de Armazenamento

```
┌─────────────────────────────────────────┐
│      Camada de Armazenamento            │
├─────────────────────────────────────────┤
│  PVC Logs                               │
│  └─ /var/logs/api/instrucoes.log        │
│                                         │
│  PVC Data                               │
│  └─ /data                               │
└─────────────────────────────────────────┘
```

### 3. Camada de Configuração

```
┌─────────────────────────────────────────┐
│   Camada de Configuração                │
├─────────────────────────────────────────┤
│  ConfigMap                              │
│  ├─ RESERVA_BANCARIA_SALDO              │
│  ├─ API_PORT                            │
│  ├─ AUDITORIA_PORT                      │
│  └─ LOG_LEVEL                           │
│                                         │
│  Secret                                 │
│  ├─ pix-key                             │
│  ├─ db-password                         │
│  └─ api-token                           │
└─────────────────────────────────────────┘
```

### 4. Camada de Orquestração

```
┌─────────────────────────────────────────┐
│   Camada de Orquestração                │
├─────────────────────────────────────────┤
│  Kubernetes (Minikube)                  │
│  ├─ Deployments                         │
│  ├─ Services                            │
│  ├─ StatefulSets                        │
│  ├─ CronJobs                            │
│  ├─ NetworkPolicies                     │
│  ├─ RBAC                                │
│  └─ HPA (Auto-scaling)                  │
└─────────────────────────────────────────┘
```

---

## Modelo de Segurança

### 1. Isolamento de Rede

- **NetworkPolicy** restrita
- Pods só podem comunicar com pods do mesmo namespace
- Acesso restrito a DNS externo

### 2. Segurança de Container

- **Usuário não-root** (UID 1000)
- **ReadOnlyRootFilesystem** desabilitado apenas onde necessário
- **SecurityContext** aplicado a todos os pods
- **Capabilities** droppadas ao mínimo necessário

### 3. RBAC (Role-Based Access Control)

- **ServiceAccount** dedicada `unifiapay-sa`
- **Role** com permissões mínimas:
  - Get/list pods e logs
  - Get ConfigMaps
  - Get Secrets
  - Get/list Jobs e CronJobs

### 4. Secrets Management

- Armazenamento em **Kubernetes Secrets** (encoded em base64)
- **PIX-KEY** protegida
- **API-TOKEN** para autenticação
- **DB-PASSWORD** para dados sensíveis

---

## Escalabilidade

### 1. Horizontal Pod Autoscaler (HPA)

```yaml
minReplicas: 2
maxReplicas: 5
targetCPUUtilization: 70%
targetMemoryUtilization: 80%
```

### 2. Limites de Recursos

```yaml
requests:
  cpu: 100m
  memory: 256Mi
limits:
  cpu: 500m
  memory: 512Mi
```

### 3. Estratégia de Deploy

- **RollingUpdate**: Transição suave entre versões
- **PodDisruptionBudget**: Proteção contra interrupções

---

## Persistência de Dados

### 1. Persistent Volume Claim (PVC)

- **logs-pvc**: Armazena instruções de pagamento (1Gi)
- **data-pvc**: Armazena dados adicionais (5Gi)
- **AccessMode**: ReadWriteMany (compartilhado entre pods)

### 2. Volume Compartilhado

O arquivo `instrucoes.log` é compartilhado entre:
- **API** (escreve novas instruções)
- **Auditoria** (lê e processa)
- **CronJob** (processa em background)

---

## Monitoramento e Observabilidade

### 1. Health Checks

- **Liveness Probe**: Verifica se pod está vivo
- **Readiness Probe**: Verifica se pod está pronto para receber tráfego

### 2. Métricas

- **CPU e Memory**: Monitoradas pelo metrics-server
- **Pods**: Podem ser escalados baseado em uso

### 3. Logging

- **Log Level**: Configurável via ConfigMap (INFO/DEBUG)
- **Estruturado**: JSON format para fácil parsing
- **Persistência**: Volumes compartilhados

---

## Fluxo de PIX

### Exemplo: Transferência PIX de R$ 1.000,00

```
1. Cliente envia requisição para API
   POST /api/v1/pix
   {
     "valor": 1000.00,
     "pix_destino": "12345678901234567890123456789012",
     "descricao": "Pagamento fornecedor"
   }

2. API valida:
   - Valor > 0? ✓
   - PIX destino preenchido? ✓
   - Saldo >= 1000? ✓ (100.000 disponível)

3. API registra instrução:
   {
     "id": "uuid-xxx",
     "valor": 1000.00,
     "pix_destino": "12345678...",
     "status": "AGUARDANDO_LIQUIDACAO",
     "criado_em": "2025-11-13T10:30:00Z"
   }
   → Arquivo: /var/logs/api/instrucoes.log

4. A cada 6 horas, CronJob executa:
   - Auditoria lê instrucoes.log
   - Busca por AGUARDANDO_LIQUIDACAO
   - Atualiza para LIQUIDADO
   - Adiciona timestamp de liquidação

5. Status final:
   {
     "id": "uuid-xxx",
     "valor": 1000.00,
     "status": "LIQUIDADO",
     "liquidado_em": "2025-11-13T16:30:00Z"
   }
```

---

## Requisitos SPB Implementados

### 1. Reserva Bancária ✓

- API valida saldo antes de autorizar PIX
- ConfigMap define limite de RESERVA_BANCARIA_SALDO
- Rejeita transferências acima do saldo

### 2. Compensação e Liquidação ✓

- Instruções registradas com status inicial
- Auditoria processa e atualiza status
- CronJob automatiza processamento

### 3. Segmentação de Rede ✓

- NetworkPolicy isola pods
- Comunicação restrita apenas entre serviços necessários

### 4. Auditoria ✓

- Todas as operações registradas
- Histórico persistente em volume compartilhado
- Rastreabilidade completa

---

## Diagrama C4

### Context (Nível 1)

```
┌──────────────────────┐
│   Cliente PIX        │
└──────────┬───────────┘
           │
           │
           ▼
┌──────────────────────────────────────┐
│   UniFIAP Pay SPB System             │
│  (Kubernetes - Minikube)             │
│                                      │
│  ├─ API Pagamentos                   │
│  ├─ Auditoria Service                │
│  ├─ Volumes Compartilhados           │
│  └─ Configurações (ConfigMap/Secret) │
└──────────────────────────────────────┘
           │
           │
           ▼
┌──────────────────────┐
│  BACEN (Simulado)    │
│  STR (Simulado)      │
└──────────────────────┘
```

---

## Dependências Externas

### Python
- **Flask**: Web framework
- **python-dotenv**: Gerenciamento de variáveis
- **Gunicorn**: WSGI server

### Kubernetes
- **Minikube**: Kubernetes local
- **Helm**: Gerenciador de pacotes
- **kubectl**: CLI do Kubernetes

### Container
- **Docker**: Containerização
- **Docker Scout**: Análise de vulnerabilidades

---

## Recursos Utilizados

| Recurso | Quantidade | Especificação |
|---------|-----------|---------------|
| CPU Request | 200m | 100m por pod |
| CPU Limit | 1000m | 500m por pod |
| Memória Request | 512Mi | 256Mi por pod |
| Memória Limit | 1024Mi | 512Mi por pod |
| PVC Logs | 1Gi | ReadWriteMany |
| PVC Data | 5Gi | ReadWriteMany |
| Replicas API | 2-5 | Auto-scaling |
| Replicas Auditoria | 1 | Fixo |

---

## Pontos de Extensão

1. **Autenticação**: Adicionar OAuth/JWT
2. **Monitoramento**: Integrar Prometheus/Grafana
3. **Tracing**: Implementar Jaeger/Zipkin
4. **Logging**: Integrar ELK Stack
5. **CI/CD**: Adicionar GitLab CI ou GitHub Actions
6. **Backup**: Implementar estratégia de backup de PVCs
7. **Disaster Recovery**: Replicação cross-cluster

---

**Documento preparado para o Desafio UniFIAP Pay SPB**  
**Data:** 13 de Novembro de 2025

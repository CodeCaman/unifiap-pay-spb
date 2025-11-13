# 🚀 Desafio UniFIAP Pay SPB

## Dados do Aluno

**Nome:** Renan Assi de Freitas  
**RM:** 93744  
**Docker Hub:** renanafs  
**Pontuação Total:** 9,0 pts

---

## 1. Arquitetura da Solução

Sistema de pagamentos PIX seguindo as regras do **SPB (Sistema de Pagamentos Brasileiro)** com arquitetura de microsserviços.

**Componentes:**
- **api-pagamentos**: Banco Originador - Valida reserva bancária e registra instruções PIX
- **auditoria-service**: Sistema de Liquidação - Monitora e liquida transações
- **frontend-pix**: Interface web para transações
- **Kubernetes**: Orquestração e escala
- **PersistentVolume**: Livro-Razão compartilhado (`/var/logs/api/instrucoes.log`)
- **Prometheus + Grafana**: Monitoramento

---

## 2. Execução do Projeto

### Passo 1: Build das Imagens

```powershell
cd core/api-pagamentos
docker build -t renanafs/unifiap-api-pagamentos:v1.93744 .

cd ../auditoria-service
docker build -t renanafs/unifiap-auditoria:v1.93744 .

cd ../frontend-pix
docker build -t renanafs/unifiap-frontend-pix:v1.93744 .
cd ../..
```

### Passo 2: Push para Docker Hub

```powershell
docker login
docker push renanafs/unifiap-api-pagamentos:v1.93744
docker push renanafs/unifiap-auditoria:v1.93744
docker push renanafs/unifiap-frontend-pix:v1.93744
```

### Passo 3: Deploy no Kubernetes

```powershell
kubectl apply -f k8s/unifiap-pay-spb.yaml
kubectl apply -f k8s/kube-state-metrics.yaml
```

---

## 3. Evidências e Resultados

### 3.1. Etapa 1: Docker e Imagem Segura (1,5 pts)

#### Print 1: Multi-Stage Build

**Comando:**
```powershell
docker build -t renanafs/unifiap-api-pagamentos:v1.93744 core/api-pagamentos
```

<img width="925" height="731" alt="image" src="https://github.com/user-attachments/assets/5c601bea-862d-4cf0-8cb8-9159a975ebb7" />


---

#### Print 2: Push para Docker Hub

**Comando:**
```powershell
docker push renanafs/unifiap-api-pagamentos:v1.93744
```

<img width="905" height="297" alt="image" src="https://github.com/user-attachments/assets/501a74e1-053f-490e-a1c3-25853a545444" />

```
v1.93744: digest: sha256:... size: 856
```

---

#### Print 3: Docker Scout - 0 CRITICAL

**Comando:**
```powershell
docker scout cves renanafs/unifiap-api-pagamentos:v1.93744
```

<img width="678" height="270" alt="image" src="https://github.com/user-attachments/assets/23b5d685-7e8a-4f9b-94f4-4dc0df260d5a" />

```
vulnerabilities │    0C     3H     5M    20L
```

---

### 3.2. Etapa 2: Rede, Comunicação e Segmentação (2,5 pts)

#### Print 1: Variáveis de Ambiente

**Comando:**
```powershell
kubectl logs -n unifiapay -l app=api-pagamentos --tail=50
```

<img width="931" height="728" alt="image" src="https://github.com/user-attachments/assets/b0d1626a-a9bc-42bf-93ed-b91d3ff850fd" />

```
INFO - Iniciando API de Pagamentos - Reserva Bancária: R$ 1000000.00
```

---

#### Print 2: Comunicação entre Serviços

**Comando:**
```powershell
kubectl exec -n unifiapay deployment/api-pagamentos-simple -- curl -s http://auditoria-service:8080/health
```

<img width="928" height="97" alt="image" src="https://github.com/user-attachments/assets/63e8cc01-81b8-4856-91c1-9878f141cd40" />


---

#### Print 3: Inspeção de Rede

**Comando:**
```powershell
kubectl get services -n unifiapay
```

<img width="919" height="218" alt="image" src="https://github.com/user-attachments/assets/5aa67dcc-0036-4247-9fea-2ab6dbe848e4" />


---

### 3.3. Etapa 3: Kubernetes – Estrutura, Escala e Deploy (3,0 pts)

#### Print 1: Múltiplas Réplicas (2 pods)

**Comando:**
```powershell
kubectl scale deployment api-pagamentos-simple -n unifiapay --replicas=2
kubectl get pods -n unifiapay -l app=api-pagamentos
```

<img width="925" height="173" alt="image" src="https://github.com/user-attachments/assets/7ae4441a-792f-4bd4-adb0-edcef2c88b79" />


---

#### Print 2: Escalabilidade (3 pods)

**Comando:**
```powershell
kubectl scale deployment api-pagamentos-simple -n unifiapay --replicas=3
kubectl get pods -n unifiapay -l app=api-pagamentos
```

<img width="787" height="118" alt="image" src="https://github.com/user-attachments/assets/c605702e-7399-44f2-9ceb-fc606948c489" />


---

#### Print 3: Volume Compartilhado

**Comando:**
```powershell
$PODS = (kubectl get pods -n unifiapay -l app=api-pagamentos -o jsonpath='{.items[*].metadata.name}') -split ' '; foreach ($POD in $PODS) { Write-Host "`n=== Pod: $POD ==="; kubectl exec -n unifiapay $POD -- tail -3 /var/logs/api/instrucoes.log }
```

<img width="917" height="875" alt="image" src="https://github.com/user-attachments/assets/5f6f5d99-27b9-4726-943b-fbf6fa27b988" />


---

#### Print 4: Logs de Auditoria

**Comando:**
```powershell
kubectl logs -n unifiapay -l app=auditoria-service --tail=20
```

<img width="929" height="505" alt="image" src="https://github.com/user-attachments/assets/feee638e-0693-4735-8841-f24a3b5b538b" />


---

### 3.4. Etapa 4: Segurança, Observação e Operação (2,0 pts)

#### Print 1: Resource Limits

**Comando:**
```powershell
kubectl describe pod -n unifiapay -l app=api-pagamentos | Select-String -Pattern "Limits|Requests" -Context 0,3
```

<img width="930" height="567" alt="image" src="https://github.com/user-attachments/assets/09e9bfc7-bf3b-4c74-b793-17d9989267cc" />

```

---

#### Print 2: Security Context (Non-Root)

**Comando:**
```powershell
kubectl get deployment api-pagamentos-simple -n unifiapay -o jsonpath='{.spec.template.spec.containers[0].securityContext}' | python -c "import sys; import json; data = sys.stdin.read().strip(); parsed = json.loads(data) if data else {}; print(json.dumps(parsed, indent=2))"
```

<img width="921" height="190" alt="image" src="https://github.com/user-attachments/assets/991f49ca-022e-47de-a33b-9ccd4736f3c1" />


---

#### Print 3: RBAC e Permissões

**Comando:**
```powershell
kubectl get serviceaccount -n unifiapay
kubectl get clusterrolebinding kube-state-metrics
kubectl describe clusterrolebinding kube-state-metrics
```

<img width="826" height="405" alt="image" src="https://github.com/user-attachments/assets/5f5cd2fd-8b7d-4415-90c0-71e2c58cb1c9" />


---

#### Print 4: Métricas do Prometheus

**Acesse:** http://localhost:30090/targets

<img width="1892" height="948" alt="image" src="https://github.com/user-attachments/assets/4a1f57b4-1b3b-4f30-ad5a-4d46ae854516" />

---

#### Print 5: Dashboard do Grafana

**Acesse:** (http://localhost:30300/d/unifiap-spb-complete/unifiap-pay-spb-sistema-completo?orgId=1&from=now-15m&to=now&timezone=browser&refresh=5s) (admin/admin)

<img width="1919" height="709" alt="image" src="https://github.com/user-attachments/assets/6fe2e8de-4967-43d6-83fe-b0beee84eb18" />

--

PRINTS DE ENTREGAS BONUS:

Frontend funcional:

<img width="1824" height="960" alt="image" src="https://github.com/user-attachments/assets/af48bcb7-c307-499e-8bb2-76aabea01c0e" />

Rancher configurado com os workflows funcionais:

<img width="1912" height="682" alt="image" src="https://github.com/user-attachments/assets/06b05613-cb4f-4343-8ae3-bdc859d02934" />

Dashboard centralizado para acessar funcionalidades:

<img width="1819" height="972" alt="image" src="https://github.com/user-attachments/assets/181992b3-6f12-449d-9535-47537ce1159f" />


## 4. Checklist de Entrega

### Etapa 1: Docker e Imagem Segura (1,5 pts)
- [ ] Print 1: Multi-stage build (linhas [builder] e [stage-1])
- [ ] Print 2: Push com digest no Docker Hub
- [ ] Print 3: Docker Scout mostrando 0C (0 CRITICAL)

### Etapa 2: Rede, Comunicação e Segmentação (2,5 pts)
- [ ] Print 1: Logs mostrando variável RESERVA_BANCARIA_SALDO
- [ ] Print 2: Comunicação entre serviços (curl)
- [ ] Print 3: Lista de services com ClusterIP

### Etapa 3: Kubernetes – Estrutura, Escala e Deploy (3,0 pts)
- [ ] Print 1: 2 réplicas rodando
- [ ] Print 2: 3 réplicas rodando
- [ ] Print 3: 3 pods lendo mesmo arquivo compartilhado
- [ ] Print 4: Logs de auditoria/liquidação

### Etapa 4: Segurança, Observação e Operação (2,0 pts)
- [ ] Print 1: Resource limits definidos
- [ ] Print 2: SecurityContext (runAsNonRoot)
- [ ] Print 3: RBAC configurado
- [ ] Print 4: Prometheus targets UP
- [ ] Print 5: Dashboard Grafana funcionando

---

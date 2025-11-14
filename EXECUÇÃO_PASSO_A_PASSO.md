# 📋 Guia de Execução Passo a Passo (SEM SCRIPTS)

**Aluno:** Hugo Griilo Alves | **RM:** 555354

Execute manualmente os seguintes comandos em seu terminal (PowerShell ou Bash).

---

## 🎯 PASSO 1: Verificar Pré-requisitos

Abra um terminal PowerShell ou cmd e execute: 

```powershell 
docker --version 
minikube version
kubectl version --client
helm version --short
```

**Resultado esperado:**
- Docker version 20.X ou superior
- minikube version: vX.X.X
- Client Version: vX.X.X
- vX.X.X

Se algum não estiver instalado, instale em:
- Docker: https://www.docker.com/products/docker-desktop
- Minikube: https://minikube.sigs.k8s.io/docs/start/
- kubectl: https://kubernetes.io/docs/tasks/tools/
- Helm: https://helm.sh/docs/intro/install/

---

## 🚀 PASSO 2: Iniciar Minikube

```bash
minikube start --cpus=4 --memory=8192 --driver=docker --container-runtime=docker
```

**Espere:** 2-3 minutos

**Resultado esperado:**
```
🎉  minikube v1.X.X on Windows 10
✨  Using the docker driver based on user configuration
...
🏄  Done! kubectl is now configured to use "minikube" cluster and "default" namespace by default
```

---

## ✅ PASSO 3: Aguardar Minikube Ficar Pronto

```bash
minikube wait --all=true --timeout=600s
minikube status
```

**Resultado esperado:**
```
minikube
type: Control Plane
host: Running
kubelet: Running
apiserver: Running
```

---

## 📦 PASSO 4: Habilitar Addons do Minikube

```bash
minikube addons enable metrics-server
minikube addons enable ingress
minikube addons enable dashboard
```

**Resultado esperado:**
```
✅  metrics-server was successfully enabled
✅  ingress was successfully enabled
✅  dashboard was successfully enabled
```

---

## 🏗️ PASSO 5: Criar Namespace

```bash
kubectl create namespace unifiapay
```

**Resultado esperado:**
```
namespace/unifiapay created
```

---

## 🔧 PASSO 6: Criar ConfigMap

```bash
kubectl apply -f k8s/01-configmap.yaml
```

**Resultado esperado:**
```
configmap/unifiapay-config created
```

---

## 🔐 PASSO 7: Criar Secrets

```bash
kubectl apply -f k8s/02-secret.yaml
```

**Resultado esperado:**
```
secret/unifiapay-secrets created
```

---

## 💾 PASSO 8: Criar PVC (Persistent Volumes)

```bash
kubectl apply -f k8s/03-pvc.yaml
```

**Resultado esperado:**
```
persistentvolumeclaim/unifiapay-logs-pvc created
persistentvolumeclaim/unifiapay-data-pvc created
```

---

## 🔑 PASSO 9: Criar ServiceAccount e RBAC

```bash
kubectl apply -f k8s/04-serviceaccount.yaml
```

**Resultado esperado:**
```
serviceaccount/unifiapay-sa created
role.rbac.authorization.k8s.io/unifiapay-role created
rolebinding.rbac.authorization.k8s.io/unifiapay-rolebinding created
```

---

## 🐳 PASSO 10: Fazer Login no Docker Hub

```bash
docker login
```

**Digite:**
- Username: seu_usuario_dockerhub
- Password: sua_senha_dockerhub

**Resultado esperado:**
```
Login Succeeded
```

---

## 🏗️ PASSO 11: Build da Imagem API

```bash
docker build -f docker/Dockerfile.api -t codecaman/api-pagamentos:v1.555354 .
```

**Espere:** 2-3 minutos

**Resultado esperado:**
```
[+] Building 120s
...
Successfully tagged codecaman/api-pagamentos:v1.555354
```

---

## 🏗️ PASSO 12: Build da Imagem Auditoria

```bash
docker build -f docker/Dockerfile.auditoria -t codecaman/auditoria-service:v1.555354 .
```

**Espere:** 2-3 minutos

**Resultado esperado:**
```
[+] Building 115s
...
Successfully tagged codecaman/auditoria-service:v1.555354
```

---

## 🔍 PASSO 13: Escanear Vulnerabilidades (opcional)

```bash
docker scout cves codecaman/api-pagamentos:v1.555354
docker scout cves codecaman/auditoria-service:v1.555354
```

**Resultado esperado:**
```
✓ Image is up to date
✗ Warnings
```

Se não tiver docker-scout instalado, ignore este passo.

---

## 📤 PASSO 14: Push das Imagens no Docker Hub

```bash
docker push codecaman/api-pagamentos:v1.555354
docker push codecaman/auditoria-service:v1.555354
```

**Espere:** 2-5 minutos (depende da conexão)

**Resultado esperado:**
```
v1.555354: digest: sha256:xxxxxxxxxxxxx size: xxxxx
```

---

## ☸️ PASSO 15: Aplicar Manifests Kubernetes

### 15a. NetworkPolicy
```bash
kubectl apply -f k8s/10-networkpolicy.yaml
```

### 15b. Deployment da API
```bash
kubectl apply -f k8s/05-api-deployment.yaml
```

### 15c. Services da API
```bash
kubectl apply -f k8s/06-api-service.yaml
```

### 15d. Deployment Auditoria
```bash
kubectl apply -f k8s/07-auditoria-deployment.yaml
```

### 15e. Service Auditoria
```bash
kubectl apply -f k8s/08-auditoria-service.yaml
```

### 15f. CronJob
```bash
kubectl apply -f k8s/09-cronjob.yaml
```

### 15g. HPA (Auto-scaling)
```bash
kubectl apply -f k8s/11-hpa.yaml
```

**Resultado esperado:**
```
deployment.apps/api-pagamentos created
service/api-pagamentos-service created
service/api-pagamentos-nodeport created
deployment.apps/auditoria-service created
service/auditoria-service-svc created
cronjob.batch/cronjob-fechamento-reserva created
horizontalpodautoscaler.autoscaling/api-pagamentos-hpa created
networkpolicy.networking.k8s.io/unifiapay-netpolicy created
```

---

## ⏳ PASSO 16: Aguardar Pods Ficarem Prontos

```bash
kubectl wait --for=condition=ready pod -l app=api-pagamentos -n unifiapay --timeout=300s
kubectl wait --for=condition=ready pod -l app=auditoria-service -n unifiapay --timeout=300s
```

**Espere:** 1-2 minutos

**Resultado esperado:**
```
pod/api-pagamentos-xxxxx-xxxxx condition met
pod/auditoria-service-xxxxx-xxxxx condition met
```

---

## ✅ PASSO 17: Verificar Deployment

```bash
kubectl get pods -n unifiapay
kubectl get services -n unifiapay
kubectl get deployments -n unifiapay
kubectl get cronjob -n unifiapay
```

**Resultado esperado:**
```
NAME                                READY   STATUS    RESTARTS   AGE
api-pagamentos-xxxxx-xxxxx         2/2     Running   0          2m
api-pagamentos-xxxxx-xxxxx         2/2     Running   0          2m
auditoria-service-xxxxx-xxxxx      1/1     Running   0          2m

NAME                       TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)
api-pagamentos-service     ClusterIP   10.96.xxx.xxx   <none>        80/TCP
api-pagamentos-nodeport    NodePort    10.96.xxx.xxx   <none>        8080:30080/TCP
auditoria-service-svc      ClusterIP   10.96.xxx.xxx   <none>        8081/TCP

NAME               READY   UP-TO-DATE   AVAILABLE   AGE
api-pagamentos     2/2     2            2           2m
auditoria-service  1/1     1            1           2m

NAME                               SCHEDULE    SUSPEND   ACTIVE   LAST SCHEDULE   AGE
cronjob-fechamento-reserva         0 */6 * * *   False     0       <none>          1m
```

---

## 🧪 PASSO 18: Testar a API (em outro terminal)

### Terminal A: Port-forward da API

```bash
kubectl port-forward -n unifiapay svc/api-pagamentos-service 8080:80
```

### Terminal B: Testes

```bash
# 1. Health check
curl http://localhost:8080/health

# 2. Readiness check
curl http://localhost:8080/ready

# 3. Consultar saldo
curl http://localhost:8080/api/v1/saldo

# 4. Criar PIX (deve retornar 201)
curl -X POST http://localhost:8080/api/v1/pix \
  -H "Content-Type: application/json" \
  -d '{
    "valor": 100.00,
    "pix_destino": "12345678901234567890123456789012",
    "descricao": "Teste PIX"
  }'

# 5. Listar instruções
curl http://localhost:8080/api/v1/instrucoes

# 6. Criar PIX sem destino (deve retornar 400)
curl -X POST http://localhost:8080/api/v1/pix \
  -H "Content-Type: application/json" \
  -d '{"valor": 100.00}'

# 7. Criar PIX acima da reserva (deve retornar 402)
curl -X POST http://localhost:8080/api/v1/pix \
  -H "Content-Type: application/json" \
  -d '{
    "valor": 999999.00,
    "pix_destino": "12345678901234567890123456789012"
  }'
```

**Resultado esperado:**
```
1. {"status":"healthy",...}
2. {"status":"ready",...}
3. {"saldo":100000.0,"moeda":"BRL",...}
4. {"id":"uuid-xxx","status":"AGUARDANDO_LIQUIDACAO",...} (201)
5. {"total":1,"instrucoes":[...]}
6. {"erro":"PIX destino é obrigatório"} (400)
7. {"erro":"Saldo insuficiente na reserva bancária",...} (402)
```

---

## 🧪 PASSO 19: Testar Auditoria (em outro terminal)

### Terminal C: Port-forward da Auditoria

```bash
kubectl port-forward -n unifiapay svc/auditoria-service-svc 8081:8081
```

### Terminal D: Testes Auditoria

```bash
# 1. Health check
curl http://localhost:8081/health

# 2. Status
curl http://localhost:8081/api/v1/auditoria/status

# 3. Listar instruções
curl http://localhost:8081/api/v1/auditoria/instrucoes

# 4. Processar manualmente
curl -X POST http://localhost:8081/api/v1/auditoria/processar

# 5. Verificar instruções após processamento
curl http://localhost:8081/api/v1/auditoria/instrucoes
```

**Resultado esperado:**
```
1. {"status":"healthy",...}
2. {"status":"operacional","instrucoes_processadas":0,...}
3. {"total":1,"aguardando_liquidacao":1,"liquidadas":0,...}
4. {"sucesso":true,"instrucoes_processadas":1,...}
5. {"total":1,"aguardando_liquidacao":0,"liquidadas":1,...}
```

---

## 📊 PASSO 20: Verificar Métricas e Recursos

```bash
# Ver métricas dos pods
kubectl top pods -n unifiapay

# Ver status do HPA
kubectl get hpa -n unifiapay

# Ver logs da API
kubectl logs -n unifiapay deployment/api-pagamentos

# Ver logs da Auditoria
kubectl logs -n unifiapay deployment/auditoria-service

# Ver PVCs
kubectl get pvc -n unifiapay

# Ver RBAC
kubectl get role -n unifiapay
kubectl get rolebinding -n unifiapay
```

**Resultado esperado:**
```
NAME                      CPU(cores)   MEMORY(bytes)
api-pagamentos-xxxxx      50m          256Mi
auditoria-service-xxxxx   30m          180Mi

NAME                     REFERENCE                      TARGETS         MINPODS   MAXPODS   REPLICAS   AGE
api-pagamentos-hpa       Deployment/api-pagamentos      35%/70%, 20%/80%   2         5         2          5m
```

---

## 🎯 PASSO 21: Testes Adicionais

### Teste de Escalabilidade

```bash
# Ver HPA status
kubectl get hpa -n unifiapay

# Escalar manualmente
kubectl scale deployment api-pagamentos --replicas=4 -n unifiapay

# Verificar
kubectl get pods -n unifiapay -l app=api-pagamentos
```

### Teste de CronJob

```bash
# Listar CronJobs
kubectl get cronjob -n unifiapay

# Criar job manual
kubectl create job --from=cronjob/cronjob-fechamento-reserva audit-manual -n unifiapay

# Ver jobs
kubectl get job -n unifiapay

# Ver logs do job
kubectl logs -n unifiapay -l job-name=audit-manual
```

### Teste de Persistência

```bash
# Ver arquivo de instruções
kubectl exec -it -n unifiapay deployment/api-pagamentos -- cat /var/logs/api/instrucoes.log

# Deletar pod
kubectl delete pod -n unifiapay -l app=api-pagamentos --all

# Novo pod é criado automaticamente
kubectl get pods -n unifiapay -l app=api-pagamentos

# Verificar dados persistem
kubectl exec -it -n unifiapay deployment/api-pagamentos -- cat /var/logs/api/instrucoes.log
```

---

## 🎛️ PASSO 22: Rancher (Opcional) - ⏭️ PULAR

> **⚠️ Nota Importante:** A instalação do Rancher foi desabilitada neste guia devido a uma incompatibilidade com sua versão do Kubernetes (v1.34.0).
>
> Os gráficos do Helm do Rancher atualmente disponíveis requerem `kubeVersion: < 1.34.0-0`, que é incompatível com sua versão.
>
> **Rancher é uma ferramenta opcional de gerenciamento.** Sua aplicação principal (API de Pagamentos e Serviço de Auditoria) funcionará perfeitamente sem ele.

Se você precisar de uma ferramenta de gerenciamento, considere:
- **Usar o Minikube Dashboard:** `minikube dashboard` (já habilitado no PASSO 4)
- **Aguardar uma atualização do Rancher** para suportar Kubernetes v1.34.0
- **Usar versões anteriores do Minikube** com versões do Kubernetes < 1.34.0

Para continuar, pule este passo e vá para o **PASSO 23: Limpeza**.

---

## 🧹 PASSO 23: Limpeza (Quando Terminar)

```bash
# Remover namespace
kubectl delete namespace unifiapay

# Parar Minikube
minikube stop

# Deletar Minikube (opcional)
minikube delete
```

---

## ✅ Checklist Final

- [ ] Minikube iniciado com sucesso
- [ ] Addons habilitados (metrics-server, ingress, dashboard)
- [ ] Namespace `unifiapay` criado
- [ ] ConfigMap criado
- [ ] Secrets criado
- [ ] PVCs criados
- [ ] ServiceAccount e RBAC criados
- [ ] Imagens Docker buildadas e publicadas
- [ ] Manifests aplicados com sucesso
- [ ] Pods rodando (2x API + 1x Auditoria)
- [ ] Services acessíveis
- [ ] Testes API passaram
- [ ] Testes Auditoria passaram
- [ ] Métricas funcionando
- [ ] HPA ativo
- [ ] CronJob criado

---

## 📞 Se Houver Erro

### Erro: Pod não inicia

```bash
kubectl describe pod -n unifiapay <pod-name>
kubectl logs -n unifiapay <pod-name>
```

### Erro: Imagem não encontrada

```bash
docker images | grep codecaman
docker pull codecaman/api-pagamentos:v1.555354
```

### Erro: Connection refused

```bash
# Verificar se pods estão rodando
kubectl get pods -n unifiapay

# Verificar port-forward
kubectl port-forward -n unifiapay svc/api-pagamentos-service 8080:80
```

### Erro: PVC não bound

```bash
kubectl get pvc -n unifiapay
kubectl describe pvc -n unifiapay <pvc-name>
```

---

**Aluno:** Hugo Griilo Alves  
**RM:** 555354  
**Data:** 13 de Novembro de 2025

---

*Boa sorte! Tudo pronto para começar! 🚀*

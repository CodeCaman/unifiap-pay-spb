# 🚀 Instruções para Executar Manualmente

**Aluno:** Hugo Griilo Alves | **RM:** 555354

Como os scripts devem ser executados manualmente em seu ambiente, segue o guia completo:

---

## ⚠️ Importante: Pré-requisitos

Antes de começar, verifique se tem instalado:

```bash
# Verificar Docker
docker --version
# Deve retornar: Docker version X.XX.X

# Verificar Minikube
minikube version
# Deve retornar: minikube version: vX.X.X

# Verificar kubectl
kubectl version --client
# Deve retornar: Client Version: v1.X.X

# Verificar Helm
helm version --short
# Deve retornar: vX.X.X
```

Se algum não estiver instalado, instale de:
- Docker: https://www.docker.com/products/docker-desktop
- Minikube: https://minikube.sigs.k8s.io/docs/start/
- kubectl: https://kubernetes.io/docs/tasks/tools/
- Helm: https://helm.sh/docs/intro/install/

---

## 📋 Passo 1: Setup do Minikube

Execute em seu terminal:

```bash
cd f:\gsdocker-originalcruPURO\gsdocker\unifiap-pay-spb

bash scripts/setup-minikube.sh
```

**O que faz:**
- Inicia Minikube com 4 CPUs e 8GB RAM
- Habilita addons (metrics-server, ingress, dashboard)
- Cria namespace `unifiapay`
- Cria ConfigMaps, Secrets e PVCs

**Tempo esperado:** 3-5 minutos

**Saída esperada:**
```
✓ minikube start
✓ minikube wait
✓ minikube status
✓ minikube addons enable metrics-server
✓ minikube addons enable ingress
✓ minikube addons enable dashboard
✓ kubectl apply -f ../k8s/00-namespace.yaml
✓ kubectl apply -f ../k8s/01-configmap.yaml
✓ kubectl apply -f ../k8s/02-secret.yaml
✓ kubectl apply -f ../k8s/03-pvc.yaml
✓ kubectl apply -f ../k8s/04-serviceaccount.yaml
```

---

## 📋 Passo 2: Build e Push das Imagens Docker

Abra um terminal e execute:

```bash
# 1. Configure seu usuário Docker Hub
export DOCKER_USER=seu_usuario_dockerhub

# 2. Execute o script
bash scripts/build-and-push.sh
```

**O que faz:**
- Faz login no Docker Hub
- Build Dockerfile.api (multi-stage)
- Build Dockerfile.auditoria (multi-stage)
- Escaneia vulnerabilidades com docker-scout
- Faz push com tag `v1.555354`

**Tempo esperado:** 5-10 minutos (primeira vez)

**Saída esperada:**
```
Fazer login no Docker Hub
Login Succeeded

Building API image: codecaman/api-pagamentos:v1.555354
[+] Building 45.3s
Successfully tagged codecaman/api-pagamentos:v1.555354

Building Auditoria image: codecaman/auditoria-service:v1.555354
[+] Building 42.1s
Successfully tagged codecaman/auditoria-service:v1.555354

Escaneando vulnerabilidades com docker scout...
✓ Verificando API image com scout...
✓ Verificando Auditoria image com scout...

Push de imagens para Docker Hub...
Pushed codecaman/api-pagamentos:v1.555354
Pushed codecaman/auditoria-service:v1.555354
```

**Importante:** Se receber erro de autenticação:
```bash
docker login
# Digite seu usuário e senha do Docker Hub
```

---

## 📋 Passo 3: Deploy no Kubernetes

No mesmo terminal, execute:

```bash
bash scripts/deploy-kubernetes.sh
```

**O que faz:**
- Aplica todos os 12 manifests Kubernetes
- Cria Deployments (2 replicas API + 1 Auditoria)
- Cria Services e CronJob
- Habilita NetworkPolicy
- Configura HPA (auto-scaling)
- Aguarda pods ficarem prontos

**Tempo esperado:** 3-5 minutos

**Saída esperada:**
```
✓ Manifestos aplicados com sucesso!
✓ Aguardando pods ficarem prontos...

Recursos criados:
Pods:
NAME                                READY   STATUS    RESTARTS
api-pagamentos-xxxxx-xxxxx         2/2     Running   0
auditoria-service-xxxxx-xxxxx      1/1     Running   0

Services:
NAME                       TYPE        CLUSTER-IP
api-pagamentos-service     ClusterIP   10.96.xxx.xxx
api-pagamentos-nodeport    NodePort    10.96.xxx.xxx
auditoria-service-svc      ClusterIP   10.96.xxx.xxx
```

---

## 📋 Passo 4: Testar o Deployment

Em um novo terminal, execute:

```bash
bash scripts/test-api.sh
```

**O que faz:**
- Executa 15 testes automáticos
- Valida health checks
- Testa criação de PIX
- Testa validações
- Testa liquidação
- Testa carga

**Tempo esperado:** 2-3 minutos

**Saída esperada:**
```
=== Testes da API UniFIAP Pay SPB ===

✓ PASSOU Health check da API
✓ PASSOU Readiness check da API
✓ PASSOU Consulta de saldo
✓ PASSOU Criação de PIX válido
✓ PASSOU Rejeição de PIX com valor inválido
✓ PASSOU Rejeição de PIX sem destino
✓ PASSOU Rejeição de PIX acima da reserva
✓ PASSOU Listagem de instruções
✓ PASSOU Obtenção de instrução específica
✓ PASSOU Health check da Auditoria
✓ PASSOU Consulta de status da Auditoria
✓ PASSOU Listagem de instruções via Auditoria
✓ PASSOU Processamento manual de instruções
✓ PASSOU PIX liquidado com sucesso
✓ PASSOU Teste de carga
```

---

## 📋 Passo 5: Acessar os Serviços

Após o deploy, em terminais separados:

### Terminal A: API de Pagamentos
```bash
kubectl port-forward -n unifiapay svc/api-pagamentos-service 8080:80
# Acessar: http://localhost:8080
```

Testar:
```bash
# Health check
curl http://localhost:8080/health

# Saldo
curl http://localhost:8080/api/v1/saldo

# Criar PIX
curl -X POST http://localhost:8080/api/v1/pix \
  -H "Content-Type: application/json" \
  -d '{
    "valor": 100.00,
    "pix_destino": "12345678901234567890123456789012",
    "descricao": "Teste"
  }'

# Listar instruções
curl http://localhost:8080/api/v1/instrucoes
```

### Terminal B: Auditoria Service
```bash
kubectl port-forward -n unifiapay svc/auditoria-service-svc 8081:8081
# Acessar: http://localhost:8081
```

Testar:
```bash
# Health check
curl http://localhost:8081/health

# Status
curl http://localhost:8081/api/v1/auditoria/status

# Processar manualmente
curl -X POST http://localhost:8081/api/v1/auditoria/processar

# Listar instruções
curl http://localhost:8081/api/v1/auditoria/instrucoes
```

### Terminal C: Rancher (opcional)
```bash
bash scripts/setup-rancher.sh
kubectl port-forward -n cattle-system svc/rancher 443:443
# Acessar: https://localhost
# User: admin | Pass: unifiapay555354
```

---

## 🔍 Monitoramento

Em um novo terminal:

```bash
# Ver pods
kubectl get pods -n unifiapay

# Ver logs da API
kubectl logs -f -n unifiapay deployment/api-pagamentos

# Ver logs da Auditoria
kubectl logs -f -n unifiapay deployment/auditoria-service

# Ver métricas
kubectl top pods -n unifiapay

# Ver status do HPA
kubectl get hpa -n unifiapay

# Ver CronJobs
kubectl get cronjob -n unifiapay

# Ver Jobs
kubectl get job -n unifiapay
```

---

## 📊 Validações Importantes

Após deploy, valide:

```bash
# 1. Todos os pods devem estar "Running"
kubectl get pods -n unifiapay
# STATUS deve ser "Running"

# 2. Services devem estar criados
kubectl get svc -n unifiapay
# Deve mostrar 3 services

# 3. PVCs devem estar "Bound"
kubectl get pvc -n unifiapay
# STATUS deve ser "Bound"

# 4. ConfigMap e Secrets devem existir
kubectl get configmap -n unifiapay
kubectl get secret -n unifiapay

# 5. RBAC deve estar configurado
kubectl get role -n unifiapay
kubectl get rolebinding -n unifiapay

# 6. HPA deve estar ativo
kubectl get hpa -n unifiapay

# 7. CronJob deve estar criado
kubectl get cronjob -n unifiapay

# 8. NetworkPolicy deve estar aplicada
kubectl get networkpolicy -n unifiapay
```

---

## 🛠️ Troubleshooting

### Pod não inicia?
```bash
# Ver erro
kubectl describe pod -n unifiapay <pod-name>

# Ver logs
kubectl logs -n unifiapay <pod-name>
```

### Imagem não encontrada?
```bash
# Verificar imagens locais
docker images | grep codecaman

# Fazer pull manual
docker pull codecaman/api-pagamentos:v1.555354
docker pull codecaman/auditoria-service:v1.555354
```

### Conectar ao serviço?
```bash
# Testar dentro do pod
kubectl exec -it -n unifiapay <pod-name> -- curl http://api-pagamentos-service:80/health
```

### Verificar persistência?
```bash
# Acessar arquivo de instruções
kubectl exec -it -n unifiapay <pod-name> -- cat /var/logs/api/instrucoes.log
```

---

## 🧹 Limpeza Completa

Para remover tudo:

```bash
# 1. Remover namespace (remove tudo dentro)
kubectl delete namespace unifiapay

# 2. Remover Rancher (se instalado)
helm uninstall rancher -n cattle-system

# 3. Parar Minikube
minikube stop

# 4. Deletar Minikube
minikube delete
```

---

## ✅ Checklist de Conclusão

- [ ] Docker, Minikube, kubectl e Helm instalados
- [ ] `bash scripts/setup-minikube.sh` executado com sucesso
- [ ] `bash scripts/build-and-push.sh` executado com sucesso
- [ ] `bash scripts/deploy-kubernetes.sh` executado com sucesso
- [ ] `bash scripts/test-api.sh` passou em todos os testes
- [ ] Pods estão rodando (`kubectl get pods -n unifiapay`)
- [ ] Serviços estão acessíveis (port-forward funcionando)
- [ ] Testes automáticos validados
- [ ] Rancher acessível (opcional)

---

## 📞 Próximos Passos

1. **Primeiro:** Verifique pré-requisitos
2. **Depois:** Execute Passo 1 (Setup Minikube)
3. **Depois:** Execute Passo 2 (Build Docker)
4. **Depois:** Execute Passo 3 (Deploy K8s)
5. **Depois:** Execute Passo 4 (Testes)
6. **Depois:** Execute Passo 5 (Acessar serviços)

---

**Aluno:** Hugo Griilo Alves  
**RM:** 555354  
**Data:** 13 de Novembro de 2025

---

*Se tiver dúvidas, consulte:*
- *QUICKSTART.md - Troubleshooting rápido*
- *INSTRUÇÕES_EXECUÇÃO.md - Guia completo*
- *ARQUITETURA.md - Entender o design*

# Quick Start - UniFIAP Pay SPB

**Aluno:** Hugo Griilo Alves | **RM:** 555354

## 🚀 Início Rápido (5 minutos)

### Pré-requisitos
```bash
# Verificar instalação
docker --version
kubectl version --client
minikube version
helm version
```

### 1️⃣ Setup do Minikube
```bash
bash scripts/setup-minikube.sh
```

### 2️⃣ Build e Push das Imagens
```bash
# Configure seu usuário Docker
export DOCKER_USER=seu_usuario

# Build e push
bash scripts/build-and-push.sh
```

### 3️⃣ Deploy no Kubernetes
```bash
bash scripts/deploy-kubernetes.sh
```

### 4️⃣ Verificar Status
```bash
kubectl get pods -n unifiapay
kubectl get svc -n unifiapay
kubectl top pods -n unifiapay
```

## 🧪 Testar a API

### Terminal 1: Port-forward da API
```bash
kubectl port-forward -n unifiapay svc/api-pagamentos-service 8080:80
```

### Terminal 2: Testar endpoints
```bash
# Consultar saldo
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

### Executar testes automáticos
```bash
bash scripts/test-api.sh
```

## 📊 Monitoramento

### Ver logs em tempo real
```bash
kubectl logs -f -n unifiapay deployment/api-pagamentos
kubectl logs -f -n unifiapay deployment/auditoria-service
```

### Escalar manualmente
```bash
kubectl scale deployment api-pagamentos --replicas=4 -n unifiapay
```

### Dashboard do Kubernetes
```bash
minikube dashboard
```

## 🎛️ Rancher (Gerenciamento Visual)

```bash
# Setup
bash scripts/setup-rancher.sh

# Terminal separado: Port-forward
kubectl port-forward -n cattle-system svc/rancher 443:443

# Acesse: https://localhost
# User: admin | Pass: unifiapay555354
```

## 🧹 Limpeza

```bash
# Remover namespace
kubectl delete namespace unifiapay

# Remover Rancher
helm uninstall rancher -n cattle-system

# Parar Minikube
minikube stop

# Deletar Minikube
minikube delete
```

## 📚 Documentação Completa

- **Instruções**: `INSTRUÇÕES_EXECUÇÃO.md`
- **Arquitetura**: `ARQUITETURA.md`
- **README**: `README.md`

## 🎯 Estrutura do Projeto

```
unifiap-pay-spb/
├── docker/          # Dockerfiles (multi-stage)
├── k8s/             # Manifests Kubernetes
├── src/             # Código-fonte (Python/Flask)
├── scripts/         # Scripts de automação
├── docker-compose.yml  # Teste local
└── README.md        # Documentação
```

## ✅ Checklist de Tarefas

- [ ] Minikube iniciado
- [ ] Imagens buildadas e publicadas
- [ ] Deploy no Kubernetes completo
- [ ] Pods rodando (2x API + 1x Auditoria)
- [ ] Health checks passando
- [ ] Testes de API passando
- [ ] Rancher acessível
- [ ] CronJob configurado
- [ ] NetworkPolicy aplicada
- [ ] RBAC funcionando

## 🔧 Troubleshooting

### Pods não iniciam
```bash
kubectl describe pod -n unifiapay <pod-name>
kubectl logs -n unifiapay <pod-name>
```

### Erro de imagem
```bash
# Verificar imagens disponíveis
docker images | grep codecaman

# Re-fazer pull
docker pull codecaman/api-pagamentos:v1.555354
```

### Erro de permissão
```bash
# Verificar RBAC
kubectl auth can-i list pods --as=system:serviceaccount:unifiapay:unifiapay-sa

# Descrever role
kubectl describe role -n unifiapay unifiapay-role
```

### Persistência de dados
```bash
# Verificar PVCs
kubectl get pvc -n unifiapay

# Verificar conteúdo
kubectl exec -it <pod-name> -n unifiapay -- cat /var/logs/api/instrucoes.log
```

## 📞 Suporte

Para dúvidas sobre implementação:
- Consulte `ARQUITETURA.md`
- Verifique logs com `kubectl logs`
- Use `kubectl describe` para detalhes
- Monitore métricas com `kubectl top`

---

**Documento criado para:** Desafio UniFIAP Pay SPB  
**Data:** 13 de Novembro de 2025  
**Status:** ✅ Projeto Completo

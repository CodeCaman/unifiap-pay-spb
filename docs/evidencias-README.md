# Documentação de Evidências - UniFIAP Pay SPB

Este diretório contém todas as evidências necessárias para validação do projeto conforme os critérios de avaliação.

## Estrutura de Evidências

### 📁 etapa1-docker-imagem-segura/
**Critério:** Docker e Imagem Segura (1,5 pts)
- `docker-build-multistage.png` - Print do comando docker build mostrando multi-stage
- `docker-push-with-tag.png` - Saída do docker push com a tag v1.93744
- `docker-scout-vulnerabilities.png` - Saída do docker scout comprovando ausência de vulnerabilidades críticas
- `dockerfile-security-analysis.md` - Análise das configurações de segurança dos Dockerfiles

### 📁 etapa2-rede-comunicacao-segmentacao/
**Critério:** Rede, Comunicação e Segmentação (2,5 pts)
- `docker-inspect-network.png` - Saída de docker inspect unifiap_net mostrando bloco IP customizado
- `container-communication-test.png` - Saída de curl ou ping entre containers
- `api-env-configuration.png` - Logs da API lendo RESERVA_BANCARIA_SALDO do arquivo .env
- `network-topology-diagram.png` - Diagrama da topologia de rede criada

### 📁 etapa3-kubernetes-estrutura-escala/
**Critério:** Kubernetes – Estrutura, Escala e Deploy (3,0 pts)
- `kubectl-get-pods-replicas.png` - kubectl get pods -n unifiapay mostrando API com 2 réplicas
- `kubectl-scale-deployment.png` - Saída do kubectl scale e subsequente kubectl get pods
- `pod-logs-shared-volume.png` - Logs de dois Pods da API e do Pod da Auditoria
- `kubectl-get-cronjob.png` - Saída de kubectl get cronjob e kubectl get job

### 📁 etapa4-kubernetes-seguranca-observacao/
**Critério:** Kubernetes – Segurança, Observação e Operação (2,0 pts)
- `kubectl-top-pods-resources.png` - kubectl top pods -n unifiapay mostrando limites
- `security-context-yaml.png` - Trecho do manifest mostrando securityContext
- `security-policy-block-test.png` - Tentativa de deploy insegura sendo bloqueada
- `rbac-permissions-test.png` - Saída do kubectl auth can-i provando permissões restritas

## Como Coletar as Evidências

### Pré-requisitos
1. Ter completado o build das imagens: `./scripts/build.sh` ou `./scripts/build.bat`
2. Ter feito o deploy no Kubernetes: `./scripts/deploy-k8s.sh` ou `./scripts/deploy-k8s.bat`

### Scripts de Coleta de Evidências

Execute os comandos abaixo para gerar as evidências necessárias:

#### Etapa 1 - Docker
```bash
# Build multi-stage
docker build -t codecaman/api-pagamentos:v1.93744 ./api-pagamentos/

# Push com tag
docker push codecaman/api-pagamentos:v1.93744

# Scan de vulnerabilidades
docker scout cves codecaman/api-pagamentos:v1.93744
docker scout cves codecaman/auditoria-service:v1.93744
```

#### Etapa 2 - Rede Docker
```bash
# Inspecionar rede
docker network inspect unifiap_net

# Testar comunicação entre containers
docker exec unifiap-api-pagamentos curl http://unifiap-auditoria-service:8080/health

# Verificar configuração ENV
docker logs unifiap-api-pagamentos | grep RESERVA_BANCARIA
```

#### Etapa 3 - Kubernetes Básico
```bash
# Ver pods com réplicas
kubectl get pods -n unifiapay

# Escalar deployment
kubectl scale deployment api-pagamentos --replicas=3 -n unifiapay
kubectl get pods -n unifiapay

# Ver logs dos pods
kubectl logs deployment/api-pagamentos -n unifiapay
kubectl logs deployment/auditoria-service -n unifiapay

# Verificar CronJob
kubectl get cronjobs -n unifiapay
kubectl create job --from=cronjob/cronjob-fechamento-reserva manual-test -n unifiapay
kubectl get jobs -n unifiapay
```

#### Etapa 4 - Kubernetes Avançado
```bash
# Verificar recursos dos pods
kubectl top pods -n unifiapay

# Testar permissões RBAC
kubectl auth can-i get pods --as=system:serviceaccount:unifiapay:unifiap-service-account -n unifiapay
kubectl auth can-i delete deployments --as=system:serviceaccount:unifiapay:unifiap-service-account -n unifiapay

# Criar pod inseguro para testar bloqueio
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  name: insecure-pod
  namespace: unifiapay
spec:
  containers:
  - name: insecure
    image: nginx
    securityContext:
      runAsUser: 0  # Root user (inseguro)
      privileged: true
EOF

kubectl describe pod insecure-pod -n unifiapay
```

## Template de Relatório

### Para cada etapa, documente:
1. **Comando executado**
2. **Screenshot da saída**
3. **Explicação do resultado**
4. **Como isso atende ao critério avaliativo**

### Exemplo de documentação:
```markdown
## Etapa 1.1 - Build Multi-stage

**Comando:**
```bash
docker build -t codecaman/api-pagamentos:v1.93744 ./api-pagamentos/
```

**Resultado:**
- ✅ Build concluído com sucesso
- ✅ Multi-stage detectado (builder + runtime)
- ✅ Imagem final otimizada (tamanho reduzido)

**Evidência:** [Screenshot anexado]

**Atendimento ao critério:** Demonstra uso de multi-stage build para otimização e segurança da imagem.
```

## Checklist de Validação

- [ ] **Etapa 1:** 3 evidências coletadas
- [ ] **Etapa 2:** 4 evidências coletadas  
- [ ] **Etapa 3:** 4 evidências coletadas
- [ ] **Etapa 4:** 4 evidências coletadas
- [ ] **Total:** 15 evidências documentadas
- [ ] **Relatório:** Documento final com explicações preparado
#!/bin/bash

# Script para deploy no Kubernetes
# UniFIAP Pay SPB - Kubernetes Deploy

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}    UniFIAP Pay SPB - Kubernetes Deploy       ${NC}"
echo -e "${BLUE}================================================${NC}"

# Função para logging
log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[$(date '+%Y-%m-%d %H:%M:%S')] WARNING:${NC} $1"
}

error() {
    echo -e "${RED}[$(date '+%Y-%m-%d %H:%M:%S')] ERROR:${NC} $1"
}

# Verificar se kubectl está instalado e funcionando
if ! command -v kubectl &> /dev/null; then
    error "kubectl não encontrado. Por favor instale o kubectl"
    exit 1
fi

if ! kubectl cluster-info &> /dev/null; then
    error "Não foi possível conectar ao cluster Kubernetes"
    echo "Verifique se o Minikube/Kind está rodando:"
    echo "  minikube start"
    echo "  ou"
    echo "  kind create cluster"
    exit 1
fi

log "Cluster Kubernetes detectado:"
kubectl cluster-info

# Verificar se as imagens estão disponíveis no Docker Hub
log "Verificando disponibilidade das imagens..."
if ! docker manifest inspect codecaman/api-pagamentos:v1.93744 &> /dev/null; then
    warn "Imagem api-pagamentos:v1.93744 não encontrada no Docker Hub"
    echo "Execute primeiro: ./scripts/build.sh"
fi

if ! docker manifest inspect codecaman/auditoria-service:v1.93744 &> /dev/null; then
    warn "Imagem auditoria-service:v1.93744 não encontrada no Docker Hub"
    echo "Execute primeiro: ./scripts/build.sh"
fi

# Deploy dos manifests
log "Iniciando deploy dos manifests Kubernetes..."

# 1. Namespace
log "Criando namespace unifiapay..."
kubectl apply -f k8s/01-namespace.yaml

# 2. ConfigMap
log "Aplicando ConfigMap..."
kubectl apply -f k8s/02-configmap.yaml

# 3. Secret
log "Aplicando Secret..."
kubectl apply -f k8s/03-secret.yaml

# 4. PVC
log "Criando PersistentVolumeClaim..."
kubectl apply -f k8s/04-pvc.yaml

# 5. RBAC
log "Configurando RBAC..."
kubectl apply -f k8s/05-rbac.yaml

# 6. API Pagamentos Deployment
log "Deploy da API Pagamentos..."
kubectl apply -f k8s/06-api-pagamentos-deployment.yaml

# 7. API Pagamentos Service
log "Criando Service da API Pagamentos..."
kubectl apply -f k8s/07-api-pagamentos-service.yaml

# 8. Auditoria Service Deployment
log "Deploy do Auditoria Service..."
kubectl apply -f k8s/08-auditoria-service-deployment.yaml

# 9. CronJob
log "Configurando CronJob de fechamento..."
kubectl apply -f k8s/09-cronjob.yaml

# 10. Network Policy
log "Aplicando Network Policies..."
kubectl apply -f k8s/10-network-policy.yaml

# Aguardar pods ficarem prontos
log "Aguardando pods ficarem prontos..."
kubectl wait --for=condition=ready pod -l app=api-pagamentos -n unifiapay --timeout=300s
kubectl wait --for=condition=ready pod -l app=auditoria-service -n unifiapay --timeout=300s

# Status do deployment
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}           Status do Deployment               ${NC}"
echo -e "${BLUE}================================================${NC}"

kubectl get pods -n unifiapay
echo
kubectl get services -n unifiapay
echo
kubectl get cronjobs -n unifiapay
echo
kubectl get pvc -n unifiapay

# Verificar se a API está respondendo
log "Testando API de Pagamentos..."
API_PORT=$(kubectl get service api-pagamentos-service -n unifiapay -o jsonpath='{.spec.ports[0].nodePort}')
CLUSTER_IP=$(kubectl get service api-pagamentos-service -n unifiapay -o jsonpath='{.spec.clusterIP}')

if command -v minikube &> /dev/null; then
    MINIKUBE_IP=$(minikube ip)
    API_URL="http://${MINIKUBE_IP}:${API_PORT}"
else
    API_URL="http://localhost:${API_PORT}"
fi

echo -e "${BLUE}API disponível em:${NC}"
echo -e "  Externo: ${API_URL}"
echo -e "  Interno: http://${CLUSTER_IP}:80"

# Teste de conectividade
if command -v curl &> /dev/null; then
    log "Testando conectividade da API..."
    if kubectl run test-pod --rm -i --tty --image=curlimages/curl -- curl -f http://api-pagamentos-internal:5000/health -n unifiapay 2>/dev/null; then
        log "✓ API está respondendo corretamente"
    else
        warn "API pode ainda estar inicializando"
    fi
else
    warn "curl não disponível para teste de conectividade"
fi

# Comandos úteis
echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}           Comandos Úteis                     ${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "Monitorar pods:"
echo -e "  ${YELLOW}kubectl get pods -n unifiapay -w${NC}"
echo -e ""
echo -e "Ver logs da API:"
echo -e "  ${YELLOW}kubectl logs -f deployment/api-pagamentos -n unifiapay${NC}"
echo -e ""
echo -e "Ver logs da Auditoria:"
echo -e "  ${YELLOW}kubectl logs -f deployment/auditoria-service -n unifiapay${NC}"
echo -e ""
echo -e "Escalar API (para evidências):"
echo -e "  ${YELLOW}kubectl scale deployment api-pagamentos --replicas=3 -n unifiapay${NC}"
echo -e ""
echo -e "Executar job manual:"
echo -e "  ${YELLOW}kubectl create job --from=cronjob/cronjob-fechamento-reserva manual-job -n unifiapay${NC}"
echo -e ""
echo -e "Port forward para acesso local:"
echo -e "  ${YELLOW}kubectl port-forward service/api-pagamentos-service 5000:80 -n unifiapay${NC}"
echo -e ""
echo -e "Remover tudo:"
echo -e "  ${YELLOW}kubectl delete namespace unifiapay${NC}"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}     Deploy concluído com sucesso!           ${NC}"
echo -e "${GREEN}================================================${NC}"
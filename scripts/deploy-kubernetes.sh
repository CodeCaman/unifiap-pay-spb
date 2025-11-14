#!/bin/bash

# Script de deploy no Kubernetes
# Autor: Hugo Griilo Alves
# RM: 555354

set -e

echo "=== UniFIAP Pay SPB - Deploy Kubernetes ==="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    error "kubectl não está instalado"
    exit 1
fi

# Verificar context
info "Contexto kubectl atual:"
kubectl config current-context

# Aplicar manifests em ordem
info "Aplicando manifests Kubernetes..."

# Namespace já foi criado, mas reaplica por segurança
kubectl apply -f ../k8s/00-namespace.yaml

# ConfigMap, Secrets, PVC
kubectl apply -f ../k8s/01-configmap.yaml
kubectl apply -f ../k8s/02-secret.yaml
kubectl apply -f ../k8s/03-pvc.yaml
kubectl apply -f ../k8s/04-serviceaccount.yaml

# NetworkPolicy
kubectl apply -f ../k8s/10-networkpolicy.yaml

# Deployments e Services
kubectl apply -f ../k8s/05-api-deployment.yaml
kubectl apply -f ../k8s/06-api-service.yaml
kubectl apply -f ../k8s/07-auditoria-deployment.yaml
kubectl apply -f ../k8s/08-auditoria-service.yaml

# HPA
kubectl apply -f ../k8s/11-hpa.yaml

# CronJob
kubectl apply -f ../k8s/09-cronjob.yaml

info "✓ Manifests aplicados com sucesso!"
echo ""

# Aguardar pods
info "Aguardando pods ficarem prontos..."
kubectl wait --for=condition=ready pod -l app=api-pagamentos -n unifiapay --timeout=300s || warn "API pods podem estar demorando"
kubectl wait --for=condition=ready pod -l app=auditoria-service -n unifiapay --timeout=300s || warn "Auditoria pods podem estar demorando"

# Listar recursos
echo ""
info "Recursos criados:"
echo ""
info "Pods:"
kubectl get pods -n unifiapay

echo ""
info "Services:"
kubectl get services -n unifiapay

echo ""
info "Deployments:"
kubectl get deployments -n unifiapay

echo ""
info "Verificando CronJob:"
kubectl get cronjob -n unifiapay

echo ""
info "Próximas ações:"
echo "  - Obter logs: kubectl logs -n unifiapay <pod-name>"
echo "  - Acessar API: kubectl port-forward -n unifiapay svc/api-pagamentos-service 8080:80"
echo "  - Dashboard: minikube dashboard"
echo "  - Setup Rancher: ./setup-rancher.sh"

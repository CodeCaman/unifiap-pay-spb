#!/bin/bash

# Script de setup do Rancher
# Autor: Hugo Griilo Alves
# RM: 555354

set -e

echo "=== UniFIAP Pay SPB - Setup Rancher ==="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar kubectl
if ! command -v kubectl &> /dev/null; then
    error "kubectl não está instalado"
    exit 1
fi

# Verificar helm
if ! command -v helm &> /dev/null; then
    warn "Helm não está instalado. Instalando..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

info "Helm encontrado: $(helm version --short)"

# Adicionar repositório Rancher
info "Adicionando repositório Rancher Helm..."
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
helm repo update

# Criar namespace para Rancher
info "Criando namespace 'cattle-system' para Rancher..."
kubectl create namespace cattle-system --dry-run=client -o yaml | kubectl apply -f -

# Instalar cert-manager (requisito do Rancher)
info "Instalando cert-manager..."
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
kubectl wait --for=condition=ready pod -l app.kubernetes.io/instance=cert-manager -n cert-manager --timeout=300s || warn "cert-manager demorando"

# Instalar Rancher
info "Instalando Rancher (isso pode levar alguns minutos)..."
helm install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=rancher.local \
  --set replicas=1 \
  --set bootstrapPassword=unifiapay555354

info "✓ Rancher instalado com sucesso!"
echo ""

# Aguardar Rancher ficar pronto
info "Aguardando Rancher ficar pronto..."
kubectl rollout status deployment/rancher -n cattle-system --timeout=600s || warn "Rancher demorando"

# Obter IP local
MINIKUBE_IP=$(minikube ip)

echo ""
info "Rancher instalado e rodando!"
echo ""
echo "Para acessar o Rancher:"
echo "  1. Execute: kubectl port-forward -n cattle-system svc/rancher 443:443"
echo "  2. Acesse: https://localhost (ignore avisos de certificado auto-assinado)"
echo "  3. Login com:"
echo "     - Usuário: admin"
echo "     - Senha: unifiapay555354"
echo ""

# Mostrar informações dos pods
info "Status dos pods do Rancher:"
kubectl get pods -n cattle-system

echo ""
info "Status do cert-manager:"
kubectl get pods -n cert-manager

echo ""
warn "Para remover Rancher later: helm uninstall rancher -n cattle-system"

#!/bin/bash

# Script de configuração do Minikube e Rancher para o projeto UniFIAP Pay
# Autor: Hugo Griilo Alves
# RM: 555354

set -e

echo "=== UniFIAP Pay SPB - Setup Minikube e Rancher ==="
echo "Aluno: Hugo Griilo Alves | RM: 555354"
echo ""

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Função para imprimir com cores
info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Verificar if Minikube is installed
if ! command -v minikube &> /dev/null; then
    error "Minikube não está instalado. Instale em: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

info "Minikube encontrado"

# Verificar se kubectl está instalado
if ! command -v kubectl &> /dev/null; then
    error "kubectl não está instalado. Instale em: https://kubernetes.io/docs/tasks/tools/"
    exit 1
fi

info "kubectl encontrado"

# Iniciar Minikube
info "Iniciando Minikube..."
minikube start --cpus=4 --memory=8192 --driver=docker --container-runtime=docker

info "Aguardando Minikube ficar pronto..."
minikube wait --all=true --timeout=600s

# Verificar status
minikube status

# Habilitar addons úteis
info "Habilitando addons do Minikube..."
minikube addons enable metrics-server
minikube addons enable ingress
minikube addons enable dashboard

# Criar namespace
info "Criando namespace 'unifiapay'..."
kubectl apply -f ../k8s/00-namespace.yaml

# Criar ConfigMap, Secrets e PVC
info "Criando ConfigMaps e Secrets..."
kubectl apply -f ../k8s/01-configmap.yaml
kubectl apply -f ../k8s/02-secret.yaml
kubectl apply -f ../k8s/03-pvc.yaml
kubectl apply -f ../k8s/04-serviceaccount.yaml

# Informação sobre Docker Hub
echo ""
warn "Próximo passo: Build e push das imagens no Docker Hub"
echo "Executar: ./build-and-push.sh"
echo ""

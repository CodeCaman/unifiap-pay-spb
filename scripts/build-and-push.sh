#!/bin/bash

# Script de build e push das imagens Docker
# Autor: Hugo Griilo Alves
# RM: 555354

set -e

DOCKER_USER="${DOCKER_USER:-codecaman}"
RM="555354"
TAG="v1.${RM}"
API_IMAGE="${DOCKER_USER}/api-pagamentos:${TAG}"
AUDITORIA_IMAGE="${DOCKER_USER}/auditoria-service:${TAG}"

echo "=== UniFIAP Pay SPB - Build e Push de Imagens ==="
echo "RM: $RM | Tag: $TAG"
echo ""

# Cores
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

# Verificar Docker
if ! command -v docker &> /dev/null; then
    error "Docker não está instalado"
    exit 1
fi

info "Docker encontrado"

# Fazer login no Docker Hub
warn "Faça login no Docker Hub"
docker login

# Build da imagem API
info "Building API image: $API_IMAGE"
docker build -f ../docker/Dockerfile.api -t $API_IMAGE ..

# Build da imagem Auditoria
info "Building Auditoria image: $AUDITORIA_IMAGE"
docker build -f ../docker/Dockerfile.auditoria -t $AUDITORIA_IMAGE ..

# Scanner de vulnerabilidades com docker scout
info "Escaneando vulnerabilidades com docker scout..."

if command -v docker-scout &> /dev/null; then
    info "Verificando API image com scout..."
    docker-scout cves $API_IMAGE || warn "Docker Scout encontrou problemas - verifique acima"
    
    info "Verificando Auditoria image com scout..."
    docker-scout cves $AUDITORIA_IMAGE || warn "Docker Scout encontrou problemas - verifique acima"
else
    warn "docker-scout não instalado. Pulando verificação de vulnerabilidades"
    warn "Instale com: curl https://raw.githubusercontent.com/docker/scout-cli/main/install.sh | sh"
fi

# Push das imagens
info "Push de imagens para Docker Hub..."
docker push $API_IMAGE
docker push $AUDITORIA_IMAGE

info "✓ Imagens construídas e publicadas com sucesso!"
echo ""
info "Imagens disponíveis em Docker Hub:"
echo "  - $API_IMAGE"
echo "  - $AUDITORIA_IMAGE"

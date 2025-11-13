#!/bin/bash

# Script para build e push das imagens Docker
# UniFIAP Pay SPB - Build e Deploy

set -e

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
RM_ALUNO="93744"
VERSION="v1.${RM_ALUNO}"
DOCKER_USER="codecaman"

API_IMAGE="${DOCKER_USER}/api-pagamentos:${VERSION}"
AUDITORIA_IMAGE="${DOCKER_USER}/auditoria-service:${VERSION}"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}        UniFIAP Pay SPB - Build Script        ${NC}"
echo -e "${BLUE}================================================${NC}"
echo -e "RM do Aluno: ${RM_ALUNO}"
echo -e "Versão: ${VERSION}"
echo -e "Usuário Docker: ${DOCKER_USER}"
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

# Verificar se Docker está rodando
if ! docker info >/dev/null 2>&1; then
    error "Docker não está rodando ou não está acessível"
    exit 1
fi

# Verificar se está logado no Docker Hub
if ! docker info | grep -q "Username"; then
    warn "Você pode precisar fazer login no Docker Hub"
    echo "Execute: docker login"
    read -p "Pressione Enter para continuar..."
fi

# 1. Build da API de Pagamentos
log "Building API Pagamentos..."
cd api-pagamentos
docker build -t ${API_IMAGE} .
if [ $? -eq 0 ]; then
    log "✓ Build da API Pagamentos concluído com sucesso"
else
    error "✗ Falha no build da API Pagamentos"
    exit 1
fi
cd ..

# 2. Build do Auditoria Service
log "Building Auditoria Service..."
cd auditoria-service
docker build -t ${AUDITORIA_IMAGE} .
if [ $? -eq 0 ]; then
    log "✓ Build do Auditoria Service concluído com sucesso"
else
    error "✗ Falha no build do Auditoria Service"
    exit 1
fi
cd ..

# 3. Scan de vulnerabilidades (se Docker Scout estiver disponível)
log "Verificando vulnerabilidades..."
if command -v docker &> /dev/null; then
    if docker scout --help >/dev/null 2>&1; then
        echo -e "${BLUE}Scanning vulnerabilidades da API Pagamentos:${NC}"
        docker scout cves ${API_IMAGE} || warn "Docker Scout não disponível ou falhou"
        
        echo -e "${BLUE}Scanning vulnerabilidades do Auditoria Service:${NC}"
        docker scout cves ${AUDITORIA_IMAGE} || warn "Docker Scout não disponível ou falhou"
    else
        warn "Docker Scout não está instalado. Pulando scan de vulnerabilidades."
    fi
fi

# 4. Push das imagens para Docker Hub
read -p "Fazer push das imagens para o Docker Hub? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Pushing API Pagamentos para Docker Hub..."
    docker push ${API_IMAGE}
    if [ $? -eq 0 ]; then
        log "✓ Push da API Pagamentos concluído"
    else
        error "✗ Falha no push da API Pagamentos"
        exit 1
    fi
    
    log "Pushing Auditoria Service para Docker Hub..."
    docker push ${AUDITORIA_IMAGE}
    if [ $? -eq 0 ]; then
        log "✓ Push do Auditoria Service concluído"
    else
        error "✗ Falha no push do Auditoria Service"
        exit 1
    fi
    
    log "✓ Todas as imagens foram enviadas para o Docker Hub"
else
    log "Push cancelado pelo usuário"
fi

# 5. Listar imagens criadas
echo -e "${BLUE}Imagens criadas:${NC}"
docker images | grep -E "(api-pagamentos|auditoria-service)" | grep ${VERSION}

# 6. Criar rede Docker customizada (para teste local)
log "Criando rede Docker customizada..."
docker network create --driver bridge --subnet=172.25.0.0/24 unifiap_net 2>/dev/null || warn "Rede já existe ou falha na criação"

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}           Build concluído com sucesso!       ${NC}"
echo -e "${GREEN}================================================${NC}"
echo -e "Próximos passos:"
echo -e "1. Para testar localmente: ${YELLOW}docker-compose up -d${NC}"
echo -e "2. Para deploy no K8s: ${YELLOW}./scripts/deploy-k8s.sh${NC}"
echo -e "3. Imagens disponíveis:"
echo -e "   - ${API_IMAGE}"
echo -e "   - ${AUDITORIA_IMAGE}"
echo -e "${GREEN}================================================${NC}"
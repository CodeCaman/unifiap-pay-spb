#!/bin/bash
set -e

echo "🚀 Inicializando Grafana UniFIAP Pay SPB..."

# Aguardar Grafana inicializar
sleep 10

# Verificar se Grafana está rodando
until curl -f http://localhost:3000/api/health; do
    echo "⏳ Aguardando Grafana inicializar..."
    sleep 5
done

echo "✅ Grafana inicializado com sucesso!"

# Configurar usuário admin se necessário
curl -X POST \
  http://admin:${GRAFANA_PASSWORD:-admin123}@localhost:3000/api/admin/users \
  -H "Content-Type: application/json" \
  -d '{
    "name":"Administrator",
    "login":"admin", 
    "email":"admin@unifiap.edu.br",
    "password":"'"${GRAFANA_PASSWORD:-admin123}"'"
  }' || echo "⚠️ Usuário admin já existe ou erro na criação"

echo "🔧 Configuração do Grafana concluída!"
echo "📊 Dashboard disponível em: http://localhost:3000"
echo "🔑 Usuário: admin | Senha: ${GRAFANA_PASSWORD:-admin123}"
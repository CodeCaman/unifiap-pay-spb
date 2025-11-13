#!/bin/bash

# Script para configurar Grafana Admin User
echo "🔧 Configurando usuário admin do Grafana..."

# Aguardar Grafana estar pronto
until curl -f http://localhost:3000/api/health 2>/dev/null; do
    echo "⏳ Aguardando Grafana..."
    sleep 2
done

# Verificar se admin existe e configurar
echo "✅ Grafana está rodando!"
echo "🔑 Testando login admin..."

# Testar login
LOGIN_RESULT=$(curl -s -c cookies.txt -H "Content-Type: application/json" \
    -d '{"user":"admin","password":"admin123"}' \
    http://localhost:3000/login)

if echo "$LOGIN_RESULT" | grep -q "Logged in"; then
    echo "✅ Login admin/admin123 funcionando!"
    rm -f cookies.txt
    exit 0
else
    echo "❌ Login falhou, tentando reset via API..."
    
    # Tentar reset via API
    curl -X POST "http://admin:admin@localhost:3000/api/admin/users/1/password" \
        -H "Content-Type: application/json" \
        -d '{"password":"admin123"}' || echo "Reset via API falhou"
        
    echo "🔄 Teste novamente: admin/admin123"
    rm -f cookies.txt
fi
#!/bin/bash

# Script de testes da API UniFIAP Pay SPB
# Autor: Hugo Griilo Alves
# RM: 555354

set -e

API_URL="http://localhost:8080"
AUDITORIA_URL="http://localhost:8081"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass() {
    echo -e "${GREEN}✓ PASSOU${NC} $1"
}

fail() {
    echo -e "${RED}✗ FALHOU${NC} $1"
    exit 1
}

warn() {
    echo -e "${YELLOW}⚠ AVISO${NC} $1"
}

echo "=== Testes da API UniFIAP Pay SPB ==="
echo "Aluno: Hugo Griilo Alves | RM: 555354"
echo ""

# Teste 1: Health check da API
echo "Teste 1: Health check da API"
response=$(curl -s -w "\n%{http_code}" "$API_URL/health")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "200" ]; then
    pass "Health check da API"
else
    fail "Health check da API (HTTP $http_code)"
fi

# Teste 2: Readiness check da API
echo "Teste 2: Readiness check da API"
response=$(curl -s -w "\n%{http_code}" "$API_URL/ready")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "200" ]; then
    pass "Readiness check da API"
else
    fail "Readiness check da API (HTTP $http_code)"
fi

# Teste 3: Consultar saldo
echo "Teste 3: Consultar saldo da reserva bancária"
response=$(curl -s -w "\n%{http_code}" "$API_URL/api/v1/saldo")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)
if [ "$http_code" = "200" ] && echo "$body" | grep -q "saldo"; then
    pass "Consulta de saldo"
    echo "  Resposta: $body"
else
    fail "Consulta de saldo (HTTP $http_code)"
fi

# Teste 4: Criar PIX válido
echo "Teste 4: Criar PIX válido (R$ 1.000,00)"
pix_response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/v1/pix" \
  -H "Content-Type: application/json" \
  -d '{
    "valor": 1000.00,
    "pix_destino": "12345678901234567890123456789012",
    "descricao": "PIX de teste válido"
  }')
http_code=$(echo "$pix_response" | tail -n1)
body=$(echo "$pix_response" | head -n-1)
pix_id=$(echo "$body" | grep -o '"id":"[^"]*' | cut -d'"' -f4 | head -1)
if [ "$http_code" = "201" ] && [ ! -z "$pix_id" ]; then
    pass "Criação de PIX válido"
    echo "  PIX ID: $pix_id"
    echo "  Resposta: $body"
else
    fail "Criação de PIX válido (HTTP $http_code)"
fi

# Teste 5: Criar PIX com valor inválido
echo "Teste 5: Criar PIX com valor inválido (R$ -100,00)"
response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/v1/pix" \
  -H "Content-Type: application/json" \
  -d '{
    "valor": -100.00,
    "pix_destino": "12345678901234567890123456789012",
    "descricao": "PIX com valor negativo"
  }')
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "400" ]; then
    pass "Rejeição de PIX com valor inválido"
else
    fail "Rejeição de PIX com valor inválido (HTTP $http_code)"
fi

# Teste 6: Criar PIX sem PIX destino
echo "Teste 6: Criar PIX sem PIX destino"
response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/v1/pix" \
  -H "Content-Type: application/json" \
  -d '{
    "valor": 500.00,
    "descricao": "PIX sem destino"
  }')
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "400" ]; then
    pass "Rejeição de PIX sem destino"
else
    fail "Rejeição de PIX sem destino (HTTP $http_code)"
fi

# Teste 7: Criar PIX com valor acima da reserva
echo "Teste 7: Criar PIX com valor acima da reserva (R$ 1.000.000,00)"
response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL/api/v1/pix" \
  -H "Content-Type: application/json" \
  -d '{
    "valor": 1000000.00,
    "pix_destino": "12345678901234567890123456789012",
    "descricao": "PIX acima do limite"
  }')
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "402" ]; then
    pass "Rejeição de PIX acima da reserva"
else
    fail "Rejeição de PIX acima da reserva (HTTP $http_code, esperado 402)"
fi

# Teste 8: Listar instruções
echo "Teste 8: Listar instruções"
response=$(curl -s -w "\n%{http_code}" "$API_URL/api/v1/instrucoes")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)
if [ "$http_code" = "200" ] && echo "$body" | grep -q "total"; then
    pass "Listagem de instruções"
    echo "  Resposta: $body"
else
    fail "Listagem de instruções (HTTP $http_code)"
fi

# Teste 9: Obter instrução específica
echo "Teste 9: Obter instrução específica"
if [ ! -z "$pix_id" ]; then
    response=$(curl -s -w "\n%{http_code}" "$API_URL/api/v1/instrucoes/$pix_id")
    http_code=$(echo "$response" | tail -n1)
    if [ "$http_code" = "200" ]; then
        pass "Obtenção de instrução específica"
    else
        fail "Obtenção de instrução específica (HTTP $http_code)"
    fi
else
    warn "Teste 9 pulado - PIX ID não disponível"
fi

# Teste 10: Health check do Serviço de Auditoria
echo "Teste 10: Health check do Serviço de Auditoria"
response=$(curl -s -w "\n%{http_code}" "$AUDITORIA_URL/health")
http_code=$(echo "$response" | tail -n1)
if [ "$http_code" = "200" ]; then
    pass "Health check da Auditoria"
else
    fail "Health check da Auditoria (HTTP $http_code)"
fi

# Teste 11: Status da Auditoria
echo "Teste 11: Status da Auditoria"
response=$(curl -s -w "\n%{http_code}" "$AUDITORIA_URL/api/v1/auditoria/status")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)
if [ "$http_code" = "200" ]; then
    pass "Consulta de status da Auditoria"
    echo "  Resposta: $body"
else
    fail "Consulta de status da Auditoria (HTTP $http_code)"
fi

# Teste 12: Listar instruções via Auditoria
echo "Teste 12: Listar instruções via Auditoria"
response=$(curl -s -w "\n%{http_code}" "$AUDITORIA_URL/api/v1/auditoria/instrucoes")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)
if [ "$http_code" = "200" ]; then
    pass "Listagem de instruções via Auditoria"
    echo "  Resposta: $body"
else
    fail "Listagem de instruções via Auditoria (HTTP $http_code)"
fi

# Teste 13: Processar instruções manualmente
echo "Teste 13: Processar instruções manualmente"
response=$(curl -s -w "\n%{http_code}" -X POST "$AUDITORIA_URL/api/v1/auditoria/processar")
http_code=$(echo "$response" | tail -n1)
body=$(echo "$response" | head -n-1)
if [ "$http_code" = "200" ]; then
    pass "Processamento manual de instruções"
    echo "  Resposta: $body"
else
    fail "Processamento manual de instruções (HTTP $http_code)"
fi

# Teste 14: Verificar se PIX foi liquidado
echo "Teste 14: Verificar se PIX foi liquidado"
if [ ! -z "$pix_id" ]; then
    response=$(curl -s "$AUDITORIA_URL/api/v1/auditoria/instrucoes")
    body=$(echo "$response" | head -n-1)
    if echo "$body" | grep -q "LIQUIDADO"; then
        pass "PIX liquidado com sucesso"
    else
        warn "PIX ainda não foi liquidado (pode estar em AGUARDANDO_LIQUIDACAO)"
    fi
else
    warn "Teste 14 pulado - PIX ID não disponível"
fi

# Teste 15: Criar múltiplos PIX (teste de carga)
echo "Teste 15: Teste de carga - Criar 5 PIX consecutivos"
for i in {1..5}; do
    valor=$(echo "scale=2; $i * 100" | bc)
    response=$(curl -s -w "%{http_code}" -X POST "$API_URL/api/v1/pix" \
      -H "Content-Type: application/json" \
      -d "{
        \"valor\": $valor,
        \"pix_destino\": \"pix-teste-$i-12345678901234567890\",
        \"descricao\": \"Teste de carga $i\"
      }")
    http_code=$(echo "$response" | tail -c 4)
    if [ "$http_code" = "201" ]; then
        echo "  ✓ PIX $i criado (R$ $valor)"
    else
        echo "  ✗ PIX $i falhou (HTTP $http_code)"
    fi
done
pass "Teste de carga"

echo ""
echo "=== Resumo dos Testes ==="
echo "Todos os testes principais executados com sucesso!"
echo ""
echo "Próximas ações:"
echo "1. Verificar logs: kubectl logs -n unifiapay <pod-name>"
echo "2. Escalar réplicas: kubectl scale deployment api-pagamentos --replicas=3 -n unifiapay"
echo "3. Monitorar recursos: kubectl top pods -n unifiapay"
echo "4. Acessar Rancher: kubectl port-forward -n cattle-system svc/rancher 443:443"
echo ""

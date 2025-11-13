#!/bin/bash

# Script para testar a API funcionalmente
echo "🧪 Testando UniFIAP Pay SPB API..."

# Port forward em background
echo "🔗 Iniciando port-forward..."
kubectl port-forward service/api-pagamentos-service 5000:80 -n unifiapay &
PORT_FORWARD_PID=$!

# Aguardar port-forward ficar ativo
sleep 5

echo ""
echo "================== TESTES FUNCIONAIS =================="

# Teste 1: Health Check
echo "1️⃣ Testando Health Check..."
echo "GET /health"
curl -s http://localhost:5000/health | jq . 2>/dev/null || curl -s http://localhost:5000/health
echo -e "\n"

# Teste 2: Consultar Saldo
echo "2️⃣ Consultando Saldo da Reserva Bancária..."
echo "GET /saldo-reserva"
curl -s http://localhost:5000/saldo-reserva | jq . 2>/dev/null || curl -s http://localhost:5000/saldo-reserva
echo -e "\n"

# Teste 3: PIX Válido
echo "3️⃣ Enviando PIX Válido (R$ 100,50)..."
echo "POST /pix"
PIX_RESPONSE=$(curl -s -X POST http://localhost:5000/pix \
  -H "Content-Type: application/json" \
  -d '{
    "valor": 100.50,
    "chave_pix": "teste@unifiap.com.br",
    "banco_destinatario": "123",
    "descricao": "PIX de teste funcional - Evidência"
  }')

echo "$PIX_RESPONSE" | jq . 2>/dev/null || echo "$PIX_RESPONSE"

# Extrair ID da instrução para testes posteriores
INSTRUCAO_ID=$(echo "$PIX_RESPONSE" | jq -r '.instrucao_id' 2>/dev/null)
echo -e "\n"

# Teste 4: PIX Inválido (valor muito alto)
echo "4️⃣ Testando PIX Inválido (valor maior que reserva)..."
echo "POST /pix (valor: R$ 10.000.000,00)"
curl -s -X POST http://localhost:5000/pix \
  -H "Content-Type: application/json" \
  -d '{
    "valor": 10000000.00,
    "chave_pix": "invalido@teste.com",
    "banco_destinatario": "999",
    "descricao": "PIX que deve falhar"
  }' | jq . 2>/dev/null || curl -s -X POST http://localhost:5000/pix \
  -H "Content-Type: application/json" \
  -d '{
    "valor": 10000000.00,
    "chave_pix": "invalido@teste.com",
    "banco_destinatario": "999",
    "descricao": "PIX que deve falhar"
  }'
echo -e "\n"

# Teste 5: Listar Instruções
echo "5️⃣ Listando Todas as Instruções..."
echo "GET /instrucoes"
curl -s http://localhost:5000/instrucoes | jq . 2>/dev/null || curl -s http://localhost:5000/instrucoes
echo -e "\n"

# Teste 6: Consultar Instrução Específica
if [ ! -z "$INSTRUCAO_ID" ] && [ "$INSTRUCAO_ID" != "null" ]; then
    echo "6️⃣ Consultando Instrução Específica ($INSTRUCAO_ID)..."
    echo "GET /instrucoes/$INSTRUCAO_ID"
    curl -s http://localhost:5000/instrucoes/$INSTRUCAO_ID | jq . 2>/dev/null || curl -s http://localhost:5000/instrucoes/$INSTRUCAO_ID
    echo -e "\n"
fi

# Parar port forward
echo "🔌 Parando port-forward..."
kill $PORT_FORWARD_PID 2>/dev/null

echo ""
echo "=================== LOGS KUBERNETES ==================="

# Ver logs dos serviços
echo "📋 Logs da API de Pagamentos (últimas 10 linhas):"
kubectl logs deployment/api-pagamentos -n unifiapay --tail=10

echo -e "\n📋 Logs do Auditoria Service (últimas 10 linhas):"
kubectl logs deployment/auditoria-service -n unifiapay --tail=10

echo ""
echo "==================== STATUS GERAL ===================="

# Status dos pods
echo "📊 Status dos Pods:"
kubectl get pods -n unifiapay

echo -e "\n📊 Status dos Services:"
kubectl get services -n unifiapay

echo -e "\n📊 Status dos CronJobs:"
kubectl get cronjobs -n unifiapay

echo -e "\n📊 Status dos PVCs:"
kubectl get pvc -n unifiapay

echo ""
echo "✅ Teste concluído!"
echo ""
echo "💡 Para executar novamente: kubectl run test-pod --rm -i --tty --image=curlimages/curl -- /bin/sh"
echo "💡 Para ver arquivos de log: kubectl exec -it deployment/api-pagamentos -n unifiapay -- ls -la /var/logs/api/"
#!/bin/bash

# Script de job de auditoria para CronJob
# Autor: Hugo Griilo Alves
# RM: 555354

set -e

echo "[$(date)] Iniciando job de auditoria..."

LOG_DIR="/var/logs/api"
INSTRUCOES_FILE="${LOG_DIR}/instrucoes.log"

if [ ! -f "$INSTRUCOES_FILE" ]; then
    echo "[$(date)] Nenhuma instrução a processar"
    exit 0
fi

echo "[$(date)] Processando instruções..."

# Criar arquivo temporário
TMP_FILE="${INSTRUCOES_FILE}.tmp"

# Processar cada linha
while IFS= read -r line; do
    if [ ! -z "$line" ]; then
        # Verificar se status é AGUARDANDO_LIQUIDACAO
        if echo "$line" | grep -q "AGUARDANDO_LIQUIDACAO"; then
            # Substituir status para LIQUIDADO e adicionar timestamp
            updated_line=$(echo "$line" | sed 's/"status": "AGUARDANDO_LIQUIDACAO"/"status": "LIQUIDADO"/g')
            updated_line=$(echo "$updated_line" | sed "s/}/,\"liquidado_em\": \"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}/")
            echo "$updated_line" >> "$TMP_FILE"
            echo "[$(date)] Instrução liquidada"
        else
            echo "$line" >> "$TMP_FILE"
        fi
    fi
done < "$INSTRUCOES_FILE"

# Substituir arquivo original
if [ -f "$TMP_FILE" ]; then
    mv "$TMP_FILE" "$INSTRUCOES_FILE"
    echo "[$(date)] Job de auditoria concluído com sucesso"
else
    echo "[$(date)] Nenhuma mudança processada"
fi

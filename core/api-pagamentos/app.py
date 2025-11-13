"""
UniFIAP Pay SPB - API de Pagamentos
Microsserviço que simula o Banco Originador (UniFIAP Pay)
Responsável por validar reserva bancária e registrar instruções PIX
"""

from flask import Flask, request, jsonify
import os
import logging
import datetime
import json
from decimal import Decimal
import uuid
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter, Histogram, Gauge

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

app = Flask(__name__)

# Configurar métricas Prometheus
metrics = PrometheusMetrics(app)
metrics.info('app_info', 'Application info', version='1.0.0')
# O endpoint /metrics é criado automaticamente pelo PrometheusMetrics

# Métricas customizadas
pix_transactions_total = Counter('unifiap_pix_transactions_total', 'Total de transações PIX')
pix_value_total = Counter('unifiap_pix_value_total', 'Valor total transacionado em PIX')
reserva_bancaria_gauge = Gauge('unifiap_reserva_bancaria_saldo', 'Saldo da reserva bancária')
transaction_processing_time = Histogram('unifiap_transaction_processing_seconds', 'Tempo de processamento de transações')

# Configurar CORS para permitir acesso do frontend
@app.after_request
def after_request(response):
    response.headers.add('Access-Control-Allow-Origin', '*')
    response.headers.add('Access-Control-Allow-Headers', 'Content-Type,Authorization')
    response.headers.add('Access-Control-Allow-Methods', 'GET,PUT,POST,DELETE,OPTIONS')
    return response

# Configurações
RESERVA_BANCARIA_SALDO = Decimal(os.environ.get('RESERVA_BANCARIA_SALDO', '1000000.00'))
LOG_DIR = '/var/logs/api'
INSTRUCOES_LOG_FILE = f'{LOG_DIR}/instrucoes.log'

# Criar diretório de logs se não existir
os.makedirs(LOG_DIR, exist_ok=True)

class PixPaymentProcessor:
    """Processador de pagamentos PIX seguindo regras SPB"""
    
    def __init__(self):
        self.saldo_reserva = RESERVA_BANCARIA_SALDO
        logger.info(f"Iniciando API de Pagamentos - Reserva Bancária: R$ {self.saldo_reserva}")
    
    def validar_saldo_reserva(self, valor_pix):
        """Valida se há saldo suficiente na reserva bancária"""
        return Decimal(str(valor_pix)) <= self.saldo_reserva
    
    def registrar_instrucao_pagamento(self, dados_pix):
        """Registra instrução de pagamento no arquivo de log (Livro-Razão)"""
        timestamp = datetime.datetime.now().isoformat()
        instrucao = {
            'id': str(uuid.uuid4()),
            'timestamp': timestamp,
            'valor': str(dados_pix['valor']),
            'chave_pix': dados_pix['chave_pix'],
            'banco_destinatario': dados_pix.get('banco_destinatario', 'N/A'),
            'descricao': dados_pix.get('descricao', ''),
            'status': 'AGUARDANDO_LIQUIDACAO'
        }
        
        # Escrever no arquivo de instruções
        try:
            with open(INSTRUCOES_LOG_FILE, 'a', encoding='utf-8') as f:
                f.write(json.dumps(instrucao) + '\n')
            logger.info(f"Instrução registrada: {instrucao['id']}")
            return instrucao
        except Exception as e:
            logger.error(f"Erro ao registrar instrução: {e}")
            raise

# Instância global do processador
pix_processor = PixPaymentProcessor()

@app.route('/health', methods=['GET'])
def health_check():
    """Health check endpoint"""
    return jsonify({
        'status': 'healthy',
        'service': 'api-pagamentos',
        'timestamp': datetime.datetime.now().isoformat(),
        'reserva_saldo': str(pix_processor.saldo_reserva)
    }), 200

@app.route('/metrics', methods=['GET'])
def metrics_endpoint():
    """Endpoint explícito para métricas Prometheus"""
    from prometheus_client import generate_latest, CONTENT_TYPE_LATEST
    return generate_latest(), 200, {'Content-Type': CONTENT_TYPE_LATEST}

@app.route('/saldo-reserva', methods=['GET'])
def consultar_saldo_reserva():
    """Consulta saldo da reserva bancária"""
    # Atualizar métrica da reserva bancária
    reserva_bancaria_gauge.set(float(pix_processor.saldo_reserva))
    
    return jsonify({
        'reserva_bancaria_saldo': str(pix_processor.saldo_reserva),
        'timestamp': datetime.datetime.now().isoformat()
    }), 200

@app.route('/pix', methods=['POST'])
def processar_pix():
    """
    Processa pagamento PIX seguindo as regras SPB:
    1. Lê saldo da reserva bancária
    2. Pré-valida: valor PIX <= RESERVA_BANCARIA_SALDO
    3. Se aprovado, registra instrução com status AGUARDANDO_LIQUIDACAO
    """
    try:
        dados = request.get_json()
        
        # Validação dos dados obrigatórios
        campos_obrigatorios = ['valor', 'chave_pix']
        for campo in campos_obrigatorios:
            if campo not in dados or not dados[campo]:
                return jsonify({
                    'erro': f'Campo obrigatório ausente: {campo}',
                    'timestamp': datetime.datetime.now().isoformat()
                }), 400
        
        valor_pix = Decimal(str(dados['valor']))
        
        # Validação do valor
        if valor_pix <= 0:
            return jsonify({
                'erro': 'Valor do PIX deve ser positivo',
                'timestamp': datetime.datetime.now().isoformat()
            }), 400
        
        # Regra SPB: Validar saldo da reserva bancária
        if not pix_processor.validar_saldo_reserva(valor_pix):
            logger.warning(f"PIX rejeitado - Saldo insuficiente. Valor: R$ {valor_pix}, Reserva: R$ {pix_processor.saldo_reserva}")
            return jsonify({
                'erro': 'Saldo insuficiente na reserva bancária',
                'valor_solicitado': str(valor_pix),
                'saldo_disponivel': str(pix_processor.saldo_reserva),
                'timestamp': datetime.datetime.now().isoformat()
            }), 422
        
        # Registrar instrução de pagamento
        instrucao = pix_processor.registrar_instrucao_pagamento(dados)
        
        # Métricas: Incrementar contadores
        pix_transactions_total.inc()
        pix_value_total.inc(float(valor_pix))
        reserva_bancaria_gauge.set(float(pix_processor.saldo_reserva))
        
        logger.info(f"PIX processado com sucesso - ID: {instrucao['id']}, Valor: R$ {valor_pix}")
        
        return jsonify({
            'sucesso': True,
            'instrucao_id': instrucao['id'],
            'valor': str(valor_pix),
            'status': 'AGUARDANDO_LIQUIDACAO',
            'timestamp': instrucao['timestamp'],
            'mensagem': 'PIX registrado e aguardando liquidação pelo BACEN'
        }), 201
        
    except ValueError as e:
        return jsonify({
            'erro': f'Valor inválido: {str(e)}',
            'timestamp': datetime.datetime.now().isoformat()
        }), 400
    except Exception as e:
        logger.error(f"Erro interno ao processar PIX: {e}")
        return jsonify({
            'erro': 'Erro interno do servidor',
            'timestamp': datetime.datetime.now().isoformat()
        }), 500

@app.route('/instrucoes', methods=['GET'])
def listar_instrucoes():
    """Lista todas as instruções de pagamento registradas"""
    try:
        instrucoes = []
        if os.path.exists(INSTRUCOES_LOG_FILE):
            with open(INSTRUCOES_LOG_FILE, 'r', encoding='utf-8') as f:
                for linha in f:
                    if linha.strip():
                        instrucoes.append(json.loads(linha.strip()))
        
        return jsonify({
            'instrucoes': instrucoes,
            'total': len(instrucoes),
            'timestamp': datetime.datetime.now().isoformat()
        }), 200
        
    except Exception as e:
        logger.error(f"Erro ao listar instruções: {e}")
        return jsonify({
            'erro': 'Erro ao consultar instruções',
            'timestamp': datetime.datetime.now().isoformat()
        }), 500

@app.route('/instrucoes/<instrucao_id>', methods=['GET'])
def consultar_instrucao(instrucao_id):
    """Consulta uma instrução específica por ID"""
    try:
        if os.path.exists(INSTRUCOES_LOG_FILE):
            with open(INSTRUCOES_LOG_FILE, 'r', encoding='utf-8') as f:
                for linha in f:
                    if linha.strip():
                        instrucao = json.loads(linha.strip())
                        if instrucao['id'] == instrucao_id:
                            return jsonify({
                                'instrucao': instrucao,
                                'timestamp': datetime.datetime.now().isoformat()
                            }), 200
        
        return jsonify({
            'erro': 'Instrução não encontrada',
            'instrucao_id': instrucao_id,
            'timestamp': datetime.datetime.now().isoformat()
        }), 404
        
    except Exception as e:
        logger.error(f"Erro ao consultar instrução {instrucao_id}: {e}")
        return jsonify({
            'erro': 'Erro ao consultar instrução',
            'timestamp': datetime.datetime.now().isoformat()
        }), 500

if __name__ == '__main__':
    logger.info("Iniciando UniFIAP Pay SPB - API de Pagamentos")
    logger.info(f"Reserva Bancária configurada: R$ {RESERVA_BANCARIA_SALDO}")
    logger.info(f"Arquivo de instruções: {INSTRUCOES_LOG_FILE}")
    
    app.run(
        host='0.0.0.0',
        port=int(os.environ.get('PORT', 5000)),
        debug=os.environ.get('FLASK_DEBUG', 'False').lower() == 'true'
    )
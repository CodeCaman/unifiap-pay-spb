import os
import json
import logging
from datetime import datetime
from flask import Flask, request, jsonify
from dotenv import load_dotenv
import uuid

load_dotenv()

app = Flask(__name__)

# Configuração de logging
logging.basicConfig(
    level=os.getenv('LOG_LEVEL', 'INFO'),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configurações
RESERVA_BANCARIA_SALDO = float(os.getenv('RESERVA_BANCARIA_SALDO', '100000.00'))
API_PORT = int(os.getenv('API_PORT', 8080))
PIX_KEY = os.getenv('PIX_KEY', 'default-pix-key')
LOG_DIR = '/var/logs/api'

# Garante que o diretório de logs existe
os.makedirs(LOG_DIR, exist_ok=True)
INSTRUCOES_FILE = os.path.join(LOG_DIR, 'instrucoes.log')

class PixPayment:
    def __init__(self, valor, pix_destino, descricao=''):
        self.id = str(uuid.uuid4())
        self.valor = float(valor)
        self.pix_destino = pix_destino
        self.descricao = descricao
        self.status = 'AGUARDANDO_LIQUIDACAO'
        self.criado_em = datetime.now().isoformat()
    
    def to_dict(self):
        return {
            'id': self.id,
            'valor': self.valor,
            'pix_destino': self.pix_destino,
            'descricao': self.descricao,
            'status': self.status,
            'criado_em': self.criado_em
        }

def registrar_instrucao(payment):
    """Registra a instrução de pagamento no arquivo de log"""
    try:
        with open(INSTRUCOES_FILE, 'a') as f:
            f.write(json.dumps(payment.to_dict()) + '\n')
        logger.info(f"Instrução registrada: {payment.id}")
        return True
    except Exception as e:
        logger.error(f"Erro ao registrar instrução: {str(e)}")
        return False

@app.route('/health', methods=['GET'])
def health():
    """Endpoint de health check"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()}), 200

@app.route('/ready', methods=['GET'])
def ready():
    """Endpoint de readiness check"""
    return jsonify({'status': 'ready', 'timestamp': datetime.now().isoformat()}), 200

@app.route('/api/v1/saldo', methods=['GET'])
def get_saldo():
    """Retorna o saldo da reserva bancária"""
    logger.info("Consultando saldo da reserva bancária")
    return jsonify({
        'saldo': RESERVA_BANCARIA_SALDO,
        'moeda': 'BRL',
        'timestamp': datetime.now().isoformat()
    }), 200

@app.route('/api/v1/pix', methods=['POST'])
def criar_pix():
    """Cria uma instrução de pagamento PIX"""
    try:
        data = request.get_json()
        
        # Validações
        if not data:
            return jsonify({'erro': 'Corpo da requisição vazio'}), 400
        
        valor = float(data.get('valor', 0))
        pix_destino = data.get('pix_destino', '')
        descricao = data.get('descricao', '')
        
        if valor <= 0:
            return jsonify({'erro': 'Valor deve ser maior que zero'}), 400
        
        if not pix_destino:
            return jsonify({'erro': 'PIX destino é obrigatório'}), 400
        
        # Validação da reserva bancária
        if valor > RESERVA_BANCARIA_SALDO:
            logger.warning(f"PIX rejeitado: valor {valor} > saldo {RESERVA_BANCARIA_SALDO}")
            return jsonify({
                'erro': 'Saldo insuficiente na reserva bancária',
                'saldo_disponivel': RESERVA_BANCARIA_SALDO,
                'valor_solicitado': valor
            }), 402
        
        # Criar instrução de pagamento
        payment = PixPayment(valor, pix_destino, descricao)
        
        # Registrar no arquivo de log
        if registrar_instrucao(payment):
            logger.info(f"PIX criado com sucesso: {payment.id}")
            return jsonify({
                'id': payment.id,
                'status': payment.status,
                'valor': payment.valor,
                'pix_destino': pix_destino,
                'criado_em': payment.criado_em
            }), 201
        else:
            return jsonify({'erro': 'Erro ao registrar instrução'}), 500
            
    except ValueError as e:
        logger.error(f"Erro na conversão de valores: {str(e)}")
        return jsonify({'erro': 'Dados inválidos'}), 400
    except Exception as e:
        logger.error(f"Erro ao criar PIX: {str(e)}")
        return jsonify({'erro': 'Erro interno do servidor'}), 500

@app.route('/api/v1/instrucoes', methods=['GET'])
def listar_instrucoes():
    """Lista todas as instruções de pagamento"""
    try:
        instrucoes = []
        if os.path.exists(INSTRUCOES_FILE):
            with open(INSTRUCOES_FILE, 'r') as f:
                for linha in f:
                    if linha.strip():
                        instrucoes.append(json.loads(linha))
        
        logger.info(f"Listando {len(instrucoes)} instruções")
        return jsonify({
            'total': len(instrucoes),
            'instrucoes': instrucoes
        }), 200
    except Exception as e:
        logger.error(f"Erro ao listar instruções: {str(e)}")
        return jsonify({'erro': 'Erro ao listar instruções'}), 500

@app.route('/api/v1/instrucoes/<instrucao_id>', methods=['GET'])
def get_instrucao(instrucao_id):
    """Obtém uma instrução específica"""
    try:
        if os.path.exists(INSTRUCOES_FILE):
            with open(INSTRUCOES_FILE, 'r') as f:
                for linha in f:
                    if linha.strip():
                        instr = json.loads(linha)
                        if instr['id'] == instrucao_id:
                            return jsonify(instr), 200
        
        return jsonify({'erro': 'Instrução não encontrada'}), 404
    except Exception as e:
        logger.error(f"Erro ao obter instrução: {str(e)}")
        return jsonify({'erro': 'Erro ao obter instrução'}), 500

@app.errorhandler(404)
def not_found(error):
    return jsonify({'erro': 'Endpoint não encontrado'}), 404

@app.errorhandler(500)
def internal_error(error):
    logger.error(f"Erro interno: {str(error)}")
    return jsonify({'erro': 'Erro interno do servidor'}), 500

if __name__ == '__main__':
    logger.info(f"Iniciando API de Pagamentos PIX - Saldo Reserva: {RESERVA_BANCARIA_SALDO}")
    app.run(host='0.0.0.0', port=API_PORT, debug=False)

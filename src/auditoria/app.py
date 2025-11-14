import os
import json
import logging
import time
from datetime import datetime
from flask import Flask, jsonify
from dotenv import load_dotenv

load_dotenv()

app = Flask(__name__)

# Configuração de logging
logging.basicConfig(
    level=os.getenv('LOG_LEVEL', 'INFO'),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configurações
AUDITORIA_PORT = int(os.getenv('AUDITORIA_PORT', 8081))
LOG_DIR = '/var/logs/api'
INSTRUCOES_FILE = os.path.join(LOG_DIR, 'instrucoes.log')

os.makedirs(LOG_DIR, exist_ok=True)

class AuditoriaService:
    def __init__(self):
        self.ultima_posicao = 0
        self.instrucoes_processadas = 0
        self.carrega_posicao()
    
    def carrega_posicao(self):
        """Carrega a última posição processada"""
        try:
            posicao_file = os.path.join(LOG_DIR, '.auditoria_posicao')
            if os.path.exists(posicao_file):
                with open(posicao_file, 'r') as f:
                    self.ultima_posicao = int(f.read().strip())
                    logger.info(f"Posição carregada: {self.ultima_posicao}")
        except Exception as e:
            logger.error(f"Erro ao carregar posição: {str(e)}")
    
    def salva_posicao(self):
        """Salva a última posição processada"""
        try:
            posicao_file = os.path.join(LOG_DIR, '.auditoria_posicao')
            with open(posicao_file, 'w') as f:
                f.write(str(self.ultima_posicao))
        except Exception as e:
            logger.error(f"Erro ao salvar posição: {str(e)}")
    
    def processar_instrucoes(self):
        """Processa instruções aguardando liquidação"""
        try:
            if not os.path.exists(INSTRUCOES_FILE):
                logger.info("Arquivo de instruções não existe ainda")
                return 0
            
            instrucoes_liquidadas = 0
            linhas = []
            
            # Ler todas as linhas
            with open(INSTRUCOES_FILE, 'r') as f:
                linhas = f.readlines()
            
            # Processar apenas novas linhas
            for idx, linha in enumerate(linhas[self.ultima_posicao:], start=self.ultima_posicao):
                if linha.strip():
                    try:
                        instr = json.loads(linha)
                        if instr.get('status') == 'AGUARDANDO_LIQUIDACAO':
                            instr['status'] = 'LIQUIDADO'
                            instr['liquidado_em'] = datetime.now().isoformat()
                            linhas[idx] = json.dumps(instr) + '\n'
                            instrucoes_liquidadas += 1
                            logger.info(f"Instrução liquidada: {instr['id']}")
                    except json.JSONDecodeError as e:
                        logger.error(f"Erro ao decodificar JSON na linha {idx}: {str(e)}")
            
            # Reescrever o arquivo com as instruções atualizadas
            if instrucoes_liquidadas > 0:
                with open(INSTRUCOES_FILE, 'w') as f:
                    f.writelines(linhas)
                logger.info(f"{instrucoes_liquidadas} instruções liquidadas")
            
            self.ultima_posicao = len(linhas)
            self.salva_posicao()
            self.instrucoes_processadas += instrucoes_liquidadas
            
            return instrucoes_liquidadas
        
        except Exception as e:
            logger.error(f"Erro ao processar instruções: {str(e)}")
            return 0

auditoria = AuditoriaService()

@app.route('/health', methods=['GET'])
def health():
    """Endpoint de health check"""
    return jsonify({'status': 'healthy', 'timestamp': datetime.now().isoformat()}), 200

@app.route('/ready', methods=['GET'])
def ready():
    """Endpoint de readiness check"""
    return jsonify({'status': 'ready', 'timestamp': datetime.now().isoformat()}), 200

@app.route('/api/v1/auditoria/status', methods=['GET'])
def status():
    """Retorna o status da auditoria"""
    return jsonify({
        'status': 'operacional',
        'instrucoes_processadas': auditoria.instrucoes_processadas,
        'ultima_posicao': auditoria.ultima_posicao,
        'timestamp': datetime.now().isoformat()
    }), 200

@app.route('/api/v1/auditoria/processar', methods=['POST'])
def processar():
    """Processa instruções aguardando liquidação (pode ser chamado pelo CronJob)"""
    logger.info("Iniciando processamento de instruções...")
    instrucoes_processadas = auditoria.processar_instrucoes()
    
    return jsonify({
        'sucesso': True,
        'instrucoes_processadas': instrucoes_processadas,
        'total_processadas': auditoria.instrucoes_processadas,
        'timestamp': datetime.now().isoformat()
    }), 200

@app.route('/api/v1/auditoria/instrucoes', methods=['GET'])
def listar_instrucoes():
    """Lista todas as instruções com seus status"""
    try:
        instrucoes = []
        if os.path.exists(INSTRUCOES_FILE):
            with open(INSTRUCOES_FILE, 'r') as f:
                for linha in f:
                    if linha.strip():
                        instrucoes.append(json.loads(linha))
        
        aguardando = len([i for i in instrucoes if i.get('status') == 'AGUARDANDO_LIQUIDACAO'])
        liquidadas = len([i for i in instrucoes if i.get('status') == 'LIQUIDADO'])
        
        return jsonify({
            'total': len(instrucoes),
            'aguardando_liquidacao': aguardando,
            'liquidadas': liquidadas,
            'instrucoes': instrucoes
        }), 200
    except Exception as e:
        logger.error(f"Erro ao listar instruções: {str(e)}")
        return jsonify({'erro': 'Erro ao listar instruções'}), 500

if __name__ == '__main__':
    logger.info("Iniciando Serviço de Auditoria PIX")
    app.run(host='0.0.0.0', port=AUDITORIA_PORT, debug=False)

"""
UniFIAP Pay SPB - Auditoria Service
Microsserviço que simula o Sistema de Liquidação (BACEN/STR)
Responsável por monitorar e processar liquidações das instruções PIX
"""

import os
import json
import time
import logging
import datetime
from typing import List, Dict
import signal
import sys
from flask import Flask, jsonify
from prometheus_flask_exporter import PrometheusMetrics
from prometheus_client import Counter, Histogram, Gauge

# Configuração de logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

# Configurar Flask para endpoints de métricas
app = Flask(__name__)
metrics = PrometheusMetrics(app)

# Métricas customizadas para auditoria
liquidations_processed = Counter('unifiap_liquidations_processed_total', 'Total de liquidações processadas')
liquidation_value_total = Counter('unifiap_liquidation_value_total', 'Valor total liquidado')
pending_instructions = Gauge('unifiap_pending_instructions', 'Instruções aguardando liquidação')

class LiquidationProcessor:
    """Processador de liquidações que simula o BACEN/STR"""
    
    def __init__(self):
        self.log_file = '/var/logs/api/instrucoes.log'
        self.running = True
        self.processed_ids = set()  # Cache para evitar reprocessamento
        
        # Configurar handler para sinais
        signal.signal(signal.SIGINT, self._signal_handler)
        signal.signal(signal.SIGTERM, self._signal_handler)
        
        logger.info("Iniciando Auditoria Service - Sistema de Liquidação BACEN/STR")
    
    def _signal_handler(self, signum, frame):
        """Handler para sinais de parada"""
        logger.info(f"Recebido sinal {signum}. Parando processamento...")
        self.running = False
    
    def read_pending_instructions(self) -> List[Dict]:
        """
        Lê instruções pendentes do arquivo de log (Livro-Razão)
        Retorna apenas instruções com status AGUARDANDO_LIQUIDACAO
        """
        pending_instructions = []
        
        if not os.path.exists(self.log_file):
            # Criar arquivo se não existir (primeira execução)
            try:
                os.makedirs(os.path.dirname(self.log_file), exist_ok=True)
                with open(self.log_file, 'w') as f:
                    pass
                logger.info(f"Arquivo de instruções criado: {self.log_file}")
            except Exception as e:
                logger.error(f"Erro ao criar arquivo de instruções: {e}")
                return pending_instructions
            return pending_instructions
        
        try:
            with open(self.log_file, 'r', encoding='utf-8') as f:
                for line_num, line in enumerate(f, 1):
                    line = line.strip()
                    if not line:
                        continue
                    
                    try:
                        instruction = json.loads(line)
                        
                        # Verificar se é uma instrução válida e pendente
                        if (instruction.get('status') == 'AGUARDANDO_LIQUIDACAO' and 
                            instruction.get('id') not in self.processed_ids):
                            pending_instructions.append({
                                'line_number': line_num,
                                'instruction': instruction
                            })
                    
                    except json.JSONDecodeError as e:
                        logger.error(f"Erro ao decodificar JSON na linha {line_num}: {e}")
                        continue
            
            logger.info(f"Encontradas {len(pending_instructions)} instruções pendentes de liquidação")
            return pending_instructions
            
        except Exception as e:
            logger.error(f"Erro ao ler arquivo de instruções: {e}")
            return []
    
    def update_instruction_status(self, instruction_id: str, new_status: str = 'LIQUIDADO'):
        """
        Atualiza o status de uma instrução específica no arquivo de log
        Simula a liquidação pelo BACEN/STR
        """
        if not os.path.exists(self.log_file):
            logger.error("Arquivo de instruções não encontrado para atualização")
            return False
        
        try:
            # Ler todas as linhas
            lines = []
            updated = False
            
            with open(self.log_file, 'r', encoding='utf-8') as f:
                lines = f.readlines()
            
            # Processar cada linha
            for i, line in enumerate(lines):
                line = line.strip()
                if not line:
                    continue
                
                try:
                    instruction = json.loads(line)
                    
                    if instruction.get('id') == instruction_id:
                        # Atualizar status e timestamp de liquidação
                        instruction['status'] = new_status
                        instruction['liquidacao_timestamp'] = datetime.datetime.now().isoformat()
                        instruction['liquidado_por'] = 'BACEN-STR-SIMULATOR'
                        
                        # Atualizar métricas
                        liquidations_processed.inc()
                        liquidation_value_total.inc(float(instruction.get('valor', 0)))
                        
                        lines[i] = json.dumps(instruction) + '\n'
                        updated = True
                        logger.info(f"Instrução {instruction_id} atualizada para {new_status}")
                        break
                
                except json.JSONDecodeError:
                    continue
            
            if updated:
                # Reescrever arquivo com atualização
                with open(self.log_file, 'w', encoding='utf-8') as f:
                    f.writelines(lines)
                
                # Adicionar ao cache de processados
                self.processed_ids.add(instruction_id)
                return True
            else:
                logger.warning(f"Instrução {instruction_id} não encontrada para atualização")
                return False
                
        except Exception as e:
            logger.error(f"Erro ao atualizar status da instrução {instruction_id}: {e}")
            return False
    
    def process_liquidation_batch(self) -> int:
        """
        Processa um lote de liquidações
        Retorna o número de instruções processadas
        """
        pending_instructions = self.read_pending_instructions()
        processed_count = 0
        
        for item in pending_instructions:
            if not self.running:
                logger.info("Parando processamento por solicitação de parada")
                break
            
            instruction = item['instruction']
            instruction_id = instruction.get('id')
            
            if not instruction_id:
                logger.warning("Instrução sem ID encontrada, pulando...")
                continue
            
            logger.info(f"Processando liquidação: ID={instruction_id}, Valor=R$ {instruction.get('valor', 'N/A')}")
            
            # Simular processamento da liquidação (pode incluir validações adicionais)
            try:
                # Simular tempo de processamento do BACEN
                time.sleep(0.5)  # Meio segundo por transação
                
                # Atualizar status para LIQUIDADO
                if self.update_instruction_status(instruction_id, 'LIQUIDADO'):
                    processed_count += 1
                    logger.info(f"✓ Liquidação concluída: {instruction_id}")
                else:
                    logger.error(f"✗ Falha na liquidação: {instruction_id}")
            
            except Exception as e:
                logger.error(f"Erro ao processar liquidação {instruction_id}: {e}")
        
        return processed_count
    
    def run_continuous_monitoring(self, interval_seconds: int = 30):
        """
        Executa monitoramento contínuo das instruções
        Para uso em ambiente de desenvolvimento
        """
        logger.info(f"Iniciando monitoramento contínuo (intervalo: {interval_seconds}s)")
        
        while self.running:
            try:
                processed = self.process_liquidation_batch()
                if processed > 0:
                    logger.info(f"Lote processado: {processed} liquidações concluídas")
                else:
                    logger.info("Nenhuma instrução pendente encontrada")
                
                # Aguardar próximo ciclo
                for _ in range(interval_seconds):
                    if not self.running:
                        break
                    time.sleep(1)
                    
            except KeyboardInterrupt:
                logger.info("Monitoramento interrompido pelo usuário")
                self.running = False
            except Exception as e:
                logger.error(f"Erro no monitoramento contínuo: {e}")
                time.sleep(5)  # Aguardar antes de tentar novamente
        
        logger.info("Monitoramento contínuo finalizado")
    
    def run_single_batch(self):
        """
        Executa um único lote de processamento
        Para uso em CronJob do Kubernetes
        """
        logger.info("Executando processamento de lote único")
        
        try:
            processed = self.process_liquidation_batch()
            logger.info(f"Processamento concluído: {processed} liquidações realizadas")
            
            # Relatório final
            if processed > 0:
                logger.info("✓ Lote de liquidação processado com sucesso")
            else:
                logger.info("ℹ Nenhuma instrução pendente para liquidar")
                
        except Exception as e:
            logger.error(f"Erro no processamento do lote: {e}")
            sys.exit(1)
    
    def generate_liquidation_report(self) -> Dict:
        """Gera relatório de liquidações processadas"""
        try:
            if not os.path.exists(self.log_file):
                return {'error': 'Arquivo de instruções não encontrado'}
            
            total_instructions = 0
            liquidated_count = 0
            pending_count = 0
            
            with open(self.log_file, 'r', encoding='utf-8') as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    
                    try:
                        instruction = json.loads(line)
                        total_instructions += 1
                        
                        if instruction.get('status') == 'LIQUIDADO':
                            liquidated_count += 1
                        elif instruction.get('status') == 'AGUARDANDO_LIQUIDACAO':
                            pending_count += 1
                    
                    except json.JSONDecodeError:
                        continue
            
            return {
                'total_instructions': total_instructions,
                'liquidated': liquidated_count,
                'pending': pending_count,
                'report_timestamp': datetime.datetime.now().isoformat()
            }
            
        except Exception as e:
            logger.error(f"Erro ao gerar relatório: {e}")
            return {'error': str(e)}

# Endpoints Flask para métricas e health check
@app.route('/health', methods=['GET'])
def health_check():
    """Endpoint de health check"""
    return jsonify({'status': 'healthy', 'service': 'auditoria-service'})

@app.route('/metrics', methods=['GET'])
def metrics_endpoint():
    """Endpoint específico para métricas (caso precise de customização)"""
    return jsonify({'message': 'Métricas disponíveis em /metrics via Prometheus'})

def start_flask_server():
    """Inicia o servidor Flask em thread separada"""
    app.run(host='0.0.0.0', port=5001, debug=False)

def main():
    """Função principal"""
    import threading
    
    # Iniciar servidor Flask em thread separada para métricas
    flask_thread = threading.Thread(target=start_flask_server, daemon=True)
    flask_thread.start()
    
    processor = LiquidationProcessor()
    
    # Verificar modo de operação através de variável de ambiente
    mode = os.environ.get('LIQUIDATION_MODE', 'batch').lower()
    
    if mode == 'continuous':
        # Modo contínuo para desenvolvimento
        interval = int(os.environ.get('MONITORING_INTERVAL', 30))
        processor.run_continuous_monitoring(interval)
    else:
        # Modo lote único para CronJob
        processor.run_single_batch()
    
    # Gerar relatório final
    report = processor.generate_liquidation_report()
    logger.info(f"Relatório final: {json.dumps(report, indent=2)}")


if __name__ == '__main__':
    main()
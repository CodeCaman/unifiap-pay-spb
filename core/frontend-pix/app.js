// UniFIAP Pay SPB - Frontend JavaScript
// Sistema de Pagamentos Brasileiro - Simulador PIX

// Configurações da API
const API_BASE_URL = '/api';

// Estado da aplicação
let transacoes = [];
let intervalos = [];

// Inicialização
document.addEventListener('DOMContentLoaded', function() {
    console.log('🚀 UniFIAP Pay SPB iniciado');
    
    // Configurar form de PIX
    document.getElementById('pixForm').addEventListener('submit', enviarPix);
    
    // Carregar dados iniciais
    verificarStatusAPI();
    atualizarSaldo();
    atualizarTransacoes();
    
    // Auto-refresh a cada 10 segundos
    setInterval(() => {
        verificarStatusAPI();
        atualizarTransacoes();
    }, 10000);
    
    // Auto-refresh saldo a cada 30 segundos
    setInterval(atualizarSaldo, 30000);
});

// Verificar status da API
async function verificarStatusAPI() {
    const statusEl = document.getElementById('apiStatus');
    
    try {
        const response = await fetch(`${API_BASE_URL}/health`);
        const data = await response.json();
        
        if (response.ok) {
            statusEl.className = 'badge bg-success';
            statusEl.innerHTML = '<i class="fas fa-circle"></i> API Online';
        } else {
            throw new Error('API retornou erro');
        }
    } catch (error) {
        statusEl.className = 'badge bg-danger';
        statusEl.innerHTML = '<i class="fas fa-circle"></i> API Offline';
        console.error('❌ Erro ao verificar API:', error);
    }
}

// Atualizar saldo da reserva bancária
async function atualizarSaldo() {
    const saldoEl = document.getElementById('saldoReserva');
    
    try {
        const response = await fetch(`${API_BASE_URL}/saldo-reserva`);
        const data = await response.json();
        
        if (response.ok) {
            const saldoFormatado = formatarMoeda(parseFloat(data.reserva_bancaria_saldo));
            saldoEl.textContent = saldoFormatado;
            saldoEl.className = 'h4 text-success';
        } else {
            throw new Error(data.erro || 'Erro ao consultar saldo');
        }
    } catch (error) {
        saldoEl.textContent = 'Erro ao carregar';
        saldoEl.className = 'h4 text-danger';
        console.error('❌ Erro ao consultar saldo:', error);
    }
}

// Enviar PIX
async function enviarPix(event) {
    event.preventDefault();
    
    const formData = {
        valor: parseFloat(document.getElementById('valor').value),
        chave_pix: document.getElementById('chavePix').value,
        banco_destinatario: document.getElementById('bancoDestino').value,
        descricao: document.getElementById('descricao').value || 'PIX via UniFIAP Pay'
    };
    
    // Validações
    if (!formData.valor || formData.valor <= 0) {
        mostrarAlerta('Valor deve ser maior que R$ 0,00', 'danger');
        return;
    }
    
    if (!formData.chave_pix) {
        mostrarAlerta('Chave PIX é obrigatória', 'danger');
        return;
    }
    
    if (!formData.banco_destinatario) {
        mostrarAlerta('Banco destinatário é obrigatório', 'danger');
        return;
    }
    
    const submitBtn = event.target.querySelector('button[type="submit"]');
    const originalText = submitBtn.innerHTML;
    
    try {
        // Desabilitar botão
        submitBtn.disabled = true;
        submitBtn.innerHTML = '<i class="fas fa-spinner fa-spin"></i> Processando...';
        
        const response = await fetch(`${API_BASE_URL}/pix`, {
            method: 'POST',
            headers: {
                'Content-Type': 'application/json'
            },
            body: JSON.stringify(formData)
        });
        
        const data = await response.json();
        
        if (response.ok && data.sucesso) {
            mostrarAlerta(`✅ PIX enviado com sucesso! ID: ${data.instrucao_id}`, 'success');
            
            // Limpar formulário
            document.getElementById('pixForm').reset();
            
            // Atualizar dados
            atualizarSaldo();
            atualizarTransacoes();
        } else {
            const erro = data.erro || 'Erro desconhecido';
            mostrarAlerta(`❌ Erro ao enviar PIX: ${erro}`, 'danger');
        }
    } catch (error) {
        console.error('❌ Erro ao enviar PIX:', error);
        mostrarAlerta('❌ Erro de comunicação com a API', 'danger');
    } finally {
        // Reabilitar botão
        submitBtn.disabled = false;
        submitBtn.innerHTML = originalText;
    }
}

// Atualizar lista de transações
async function atualizarTransacoes() {
    const transacoesEl = document.getElementById('transacoes');
    
    try {
        const response = await fetch(`${API_BASE_URL}/instrucoes`);
        const data = await response.json();
        
        if (response.ok) {
            transacoes = data.instrucoes || [];
            renderizarTransacoes();
            atualizarEstatisticas();
        } else {
            throw new Error(data.erro || 'Erro ao carregar transações');
        }
    } catch (error) {
        console.error('❌ Erro ao carregar transações:', error);
        transacoesEl.innerHTML = `
            <div class="list-group-item text-center text-danger">
                <i class="fas fa-exclamation-triangle fa-2x mb-2"></i>
                <div>Erro ao carregar transações</div>
            </div>
        `;
    }
}

// Renderizar transações na interface
function renderizarTransacoes() {
    const transacoesEl = document.getElementById('transacoes');
    
    if (!transacoes || transacoes.length === 0) {
        transacoesEl.innerHTML = `
            <div class="list-group-item text-center text-muted">
                <i class="fas fa-inbox fa-2x mb-2"></i>
                <div>Nenhuma transação encontrada</div>
            </div>
        `;
        return;
    }
    
    // Ordenar por timestamp (mais recente primeiro)
    const transacoesOrdenadas = [...transacoes].sort((a, b) => 
        new Date(b.timestamp) - new Date(a.timestamp)
    );
    
    const html = transacoesOrdenadas.map(transacao => {
        const status = transacao.status || 'DESCONHECIDO';
        const isLiquidado = status === 'LIQUIDADO';
        const statusClass = isLiquidado ? 'liquidado' : 'aguardando';
        const badgeClass = isLiquidado ? 'bg-success' : 'bg-warning';
        const icon = isLiquidado ? 'fa-check-circle' : 'fa-clock';
        
        const dataFormatada = formatarData(transacao.timestamp);
        const valorFormatado = formatarMoeda(parseFloat(transacao.valor));
        
        return `
            <div class="list-group-item transaction-card ${statusClass}">
                <div class="d-flex justify-content-between align-items-start">
                    <div class="flex-grow-1">
                        <div class="d-flex justify-content-between align-items-center mb-1">
                            <h6 class="mb-0">${valorFormatado}</h6>
                            <span class="badge ${badgeClass} status-badge">
                                <i class="fas ${icon}"></i> ${status}
                            </span>
                        </div>
                        <p class="mb-1 text-muted">
                            <i class="fas fa-key"></i> ${transacao.chave_pix}
                        </p>
                        <div class="d-flex justify-content-between align-items-center">
                            <small class="text-muted">
                                <i class="fas fa-building"></i> Banco ${transacao.banco_destinatario}
                            </small>
                            <small class="text-muted">
                                <i class="fas fa-clock"></i> ${dataFormatada}
                            </small>
                        </div>
                        ${transacao.descricao ? `
                            <small class="text-muted d-block mt-1">
                                <i class="fas fa-comment"></i> ${transacao.descricao}
                            </small>
                        ` : ''}
                        ${transacao.liquidacao_timestamp ? `
                            <small class="text-success d-block mt-1">
                                <i class="fas fa-university"></i> Liquidado: ${formatarData(transacao.liquidacao_timestamp)}
                            </small>
                        ` : ''}
                    </div>
                </div>
            </div>
        `;
    }).join('');
    
    transacoesEl.innerHTML = html;
}

// Atualizar estatísticas do dashboard
function atualizarEstatisticas() {
    if (!transacoes) {
        return;
    }
    
    const total = transacoes.length;
    const liquidadas = transacoes.filter(t => t.status === 'LIQUIDADO').length;
    const pendentes = transacoes.filter(t => t.status === 'AGUARDANDO_LIQUIDACAO').length;
    const volumeTotal = transacoes.reduce((sum, t) => sum + parseFloat(t.valor || 0), 0);
    
    document.getElementById('totalTransacoes').textContent = total;
    document.getElementById('liquidadas').textContent = liquidadas;
    document.getElementById('pendentes').textContent = pendentes;
    document.getElementById('volumeTotal').textContent = formatarMoeda(volumeTotal);
}

// Utilitários de formatação
function formatarMoeda(valor) {
    return new Intl.NumberFormat('pt-BR', {
        style: 'currency',
        currency: 'BRL'
    }).format(valor || 0);
}

function formatarData(timestamp) {
    if (!timestamp) return 'Data inválida';
    
    try {
        const date = new Date(timestamp);
        return new Intl.DateTimeFormat('pt-BR', {
            day: '2-digit',
            month: '2-digit',
            year: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit'
        }).format(date);
    } catch (error) {
        console.error('❌ Erro ao formatar data:', error);
        return 'Data inválida';
    }
}

// Mostrar alerta
function mostrarAlerta(mensagem, tipo = 'info') {
    // Remover alertas existentes
    document.querySelectorAll('.alert-temp').forEach(alert => alert.remove());
    
    const alertDiv = document.createElement('div');
    alertDiv.className = `alert alert-${tipo} alert-dismissible fade show alert-temp`;
    alertDiv.style.position = 'fixed';
    alertDiv.style.top = '80px';
    alertDiv.style.right = '20px';
    alertDiv.style.zIndex = '1050';
    alertDiv.style.maxWidth = '400px';
    
    alertDiv.innerHTML = `
        ${mensagem}
        <button type="button" class="btn-close" data-bs-dismiss="alert"></button>
    `;
    
    document.body.appendChild(alertDiv);
    
    // Auto-remove após 5 segundos
    setTimeout(() => {
        if (alertDiv.parentNode) {
            alertDiv.remove();
        }
    }, 5000);
}

// Função global para atualizar saldo (chamada pelo HTML)
window.atualizarSaldo = atualizarSaldo;
window.atualizarTransacoes = atualizarTransacoes;
# Multi-stage Dockerfile para auditoria-service
# Estágio 1: Build (imagem temporária para instalação)
FROM python:3.11-slim as builder

WORKDIR /app

# Instalar dependências de sistema necessárias para build
RUN apt-get update && apt-get install -y \
    gcc \
    && rm -rf /var/lib/apt/lists/*

# Copiar e instalar dependências Python
COPY requirements.txt .
RUN pip install --no-cache-dir --user -r requirements.txt

# Estágio 2: Runtime (imagem final menor e segura)
FROM python:3.11-slim

# Criar usuário não-root para segurança
RUN groupadd -r appuser && useradd -r -g appuser appuser

WORKDIR /app

# Copiar apenas as dependências instaladas do estágio anterior
COPY --from=builder /root/.local /home/appuser/.local

# Copiar código da aplicação
COPY app.py .

# Criar diretório de logs com permissões adequadas
RUN mkdir -p /var/logs/api && \
    chown -R appuser:appuser /var/logs/api && \
    chown -R appuser:appuser /app

# Configurar PATH para incluir pacotes do usuário
ENV PATH=/home/appuser/.local/bin:$PATH

# Configurações de segurança
USER appuser

# Variáveis de ambiente padrão
ENV LIQUIDATION_MODE=batch
ENV MONITORING_INTERVAL=30
ENV PYTHONUNBUFFERED=1

# Comando padrão (execução em lote único)
CMD ["python", "app.py"]
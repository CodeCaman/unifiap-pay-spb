# Multi-stage Dockerfile para api-pagamentos
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

# Variáveis de ambiente
ENV FLASK_APP=app.py
ENV FLASK_RUN_HOST=0.0.0.0
ENV FLASK_RUN_PORT=5000
ENV PYTHONUNBUFFERED=1

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD python -c "import requests; requests.get('http://localhost:5000/health')" || exit 1

# Expor porta
EXPOSE 5000

# Comando padrão
CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "2", "--timeout", "60", "app:app"]
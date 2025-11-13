# Dockerfile para Frontend PIX
FROM nginx:alpine

# Informações do maintainer
LABEL maintainer="UniFIAP SPB Team"
LABEL description="Frontend PIX - Sistema de Pagamentos Brasileiro"
LABEL version="1.0.0"

# Instalar dependências
RUN apk add --no-cache \
    curl \
    && rm -rf /var/cache/apk/*

# Copiar arquivos do frontend
COPY index.html /usr/share/nginx/html/
COPY app.js /usr/share/nginx/html/
COPY style.css /usr/share/nginx/html/

# Configuração customizada do Nginx
COPY nginx.conf /etc/nginx/nginx.conf

# Criar usuário não-root
RUN addgroup -g 1001 -S nginxuser && \
    adduser -S -D -H -u 1001 -h /var/cache/nginx -s /sbin/nologin -G nginxuser -g nginxuser nginxuser

# Ajustar permissões
RUN chown -R nginxuser:nginxuser /usr/share/nginx/html && \
    chown -R nginxuser:nginxuser /var/cache/nginx && \
    chown -R nginxuser:nginxuser /var/log/nginx && \
    chown -R nginxuser:nginxuser /etc/nginx/conf.d

RUN touch /var/run/nginx.pid && \
    chown -R nginxuser:nginxuser /var/run/nginx.pid

# Expor porta
EXPOSE 80

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:80/ || exit 1

# Executar como usuário não-root
USER nginxuser

# Comando de inicialização
CMD ["nginx", "-g", "daemon off;"]
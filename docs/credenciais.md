# 🔐 Credenciais do Sistema UniFIAP Pay SPB

## 🌐 **RANCHER - Gerenciamento de Containers**
- **URL**: http://localhost
- **Usuário**: admin
- **Senha**: admin123
- **Status**: Inicializando (aguarde alguns minutos)

---

## 🖥️ **Outras Interfaces do Sistema**

### 💳 **Frontend PIX**
- **URL**: http://localhost:8080
- **Descrição**: Interface para simulação de transferências PIX

### 🔧 **API de Pagamentos** 
- **URL**: http://localhost:5000
- **Endpoint Health**: http://localhost:5000/health
- **Descrição**: API REST para processamento SPB

### 📊 **Monitoramento**
- **Prometheus**: http://localhost:9090
- **Grafana**: http://localhost:3000
  - **Usuário**: admin
  - **Senha**: UniFIAP@2024!

---

## ⚡ **Status do Sistema**

Para verificar se todos os serviços estão rodando:
```powershell
docker ps
```

Para ver logs do Rancher:
```powershell
docker logs rancher-server
```

Para acessar o Rancher quando estiver pronto:
```powershell
Start-Process "http://localhost"
```

---

## 🚀 **Próximos Passos**

1. **Aguarde** o Rancher finalizar a inicialização (pode levar 5-10 minutos)
2. **Acesse** http://localhost no navegador
3. **Configure** a senha inicial quando solicitado
4. **Importe** os containers existentes para gerenciamento
5. **Teste** o sistema de pagamentos SPB

---

## 📋 **Informações Técnicas**

- **Versão Rancher**: v2.7.9 (LTS)
- **Modo**: Single Node + Local Cluster
- **Bootstrap Password**: admin123
- **Certificados**: Desabilitados (desenvolvimento)
- **Privilégios**: Habilitados para Docker management
# 📑 Índice do Projeto - UniFIAP Pay SPB

## 🎯 Comece Aqui

Se você é novo no projeto, leia nesta ordem:

1. **[RESUMO_EXECUTIVO.md](RESUMO_EXECUTIVO.md)** ⭐ COMECE AQUI
   - Visão geral do projeto
   - O que foi criado
   - Como começar (5 passos)

2. **[QUICKSTART.md](QUICKSTART.md)** 🚀
   - Início rápido em 5 minutos
   - Comandos essenciais
   - Troubleshooting básico

3. **[INSTRUÇÕES_EXECUÇÃO.md](INSTRUÇÕES_EXECUÇÃO.md)** 📋
   - Guia passo a passo completo
   - Explicação de cada fase
   - Evidências esperadas

4. **[ARQUITETURA.md](ARQUITETURA.md)** 🏗️
   - Análise técnica detalhada
   - Diagramas e modelos
   - Princípios de design

5. **[README.md](README.md)** 📖
   - Descrição geral do desafio
   - Contexto SPB
   - Requisitos técnicos

---

## 📂 Estrutura de Arquivos

### 📚 Documentação
```
RESUMO_EXECUTIVO.md          Visão geral executiva ⭐
QUICKSTART.md                Início rápido (5 min) 🚀
INSTRUÇÕES_EXECUÇÃO.md       Guia passo a passo 📋
ARQUITETURA.md               Análise técnica 🏗️
README.md                    Descrição do projeto 📖
PROJETO_COMPLETO.md          Sumário técnico detalhado
ÍNDICE.md                    Este arquivo (você está aqui)
```

### 🐳 Docker
```
docker/
├── Dockerfile.api           API em Python/Flask
├── Dockerfile.auditoria     Serviço de Auditoria
└── .env                     Variáveis de ambiente
```

### ☸️ Kubernetes (12 manifests)
```
k8s/
├── 00-namespace.yaml        Namespace unifiapay
├── 01-configmap.yaml        ConfigMap
├── 02-secret.yaml           Secrets
├── 03-pvc.yaml              Persistent Volumes
├── 04-serviceaccount.yaml   RBAC
├── 05-api-deployment.yaml   Deploy API
├── 06-api-service.yaml      Services API
├── 07-auditoria-deployment.yaml  Deploy Auditoria
├── 08-auditoria-service.yaml     Service Auditoria
├── 09-cronjob.yaml          CronJob (6h)
├── 10-networkpolicy.yaml    Network Policy
└── 11-hpa.yaml              Auto-scaling
```

### 💻 Código-Fonte
```
src/
├── api/
│   ├── app.py               API de Pagamentos PIX
│   └── requirements.txt     Dependências Python
└── auditoria/
    ├── app.py               Serviço de Auditoria
    └── requirements.txt     Dependências Python
```

### 🔧 Scripts
```
scripts/
├── setup-minikube.sh        Automação Minikube
├── build-and-push.sh        Build e Push Docker
├── deploy-kubernetes.sh     Deploy Kubernetes
├── setup-rancher.sh         Setup Rancher
├── test-api.sh              15 testes automáticos
└── audit-job.sh             Job de auditoria
```

### 📦 Configuração
```
docker-compose.yml           Docker Compose (teste local)
.gitignore                   Git ignore
```

---

## 🎯 Guias Rápidos por Necessidade

### "Quero começar AGORA"
→ [QUICKSTART.md](QUICKSTART.md)

### "Não entendo a arquitetura"
→ [ARQUITETURA.md](ARQUITETURA.md)

### "Quero saber o que foi criado"
→ [PROJETO_COMPLETO.md](PROJETO_COMPLETO.md)

### "Preciso fazer tudo passo a passo"
→ [INSTRUÇÕES_EXECUÇÃO.md](INSTRUÇÕES_EXECUÇÃO.md)

### "Tenho um erro"
→ [QUICKSTART.md](QUICKSTART.md) seção "Troubleshooting"

### "Quero entender tudo"
→ Leia na ordem: RESUMO → QUICKSTART → INSTRUÇÕES → ARQUITETURA

---

## 📊 Navegação por Tópico

### Setup e Deploy
- Início rápido: [QUICKSTART.md](QUICKSTART.md)
- Passo a passo: [INSTRUÇÕES_EXECUÇÃO.md](INSTRUÇÕES_EXECUÇÃO.md)
- Scripts: `scripts/setup-minikube.sh`, `scripts/deploy-kubernetes.sh`

### Código e API
- API de Pagamentos: `src/api/app.py`
- Serviço de Auditoria: `src/auditoria/app.py`
- Documentação: [ARQUITETURA.md](ARQUITETURA.md)

### Infraestrutura Kubernetes
- Todos os manifests: `k8s/` (12 arquivos)
- Análise: [ARQUITETURA.md](ARQUITETURA.md)

### Segurança
- RBAC: `k8s/04-serviceaccount.yaml`
- Network Policy: `k8s/10-networkpolicy.yaml`
- Mais detalhes: [ARQUITETURA.md](ARQUITETURA.md)

### Testes e Validação
- Suite de testes: `scripts/test-api.sh`
- Guia de testes: [INSTRUÇÕES_EXECUÇÃO.md](INSTRUÇÕES_EXECUÇÃO.md)

### Monitoramento
- HPA: `k8s/11-hpa.yaml`
- Rancher: `scripts/setup-rancher.sh`
- Métricas: [QUICKSTART.md](QUICKSTART.md)

---

## 📈 Progressão de Leitura Recomendada

### Para Iniciantes
```
1. RESUMO_EXECUTIVO.md     (5 min)    → Entender o projeto
2. QUICKSTART.md           (10 min)   → Começar
3. INSTRUÇÕES_EXECUÇÃO.md  (30 min)   → Entender cada passo
4. ARQUITETURA.md          (20 min)   → Entender o design
```

### Para Desenvolvedores
```
1. QUICKSTART.md           (5 min)    → Começar rápido
2. ARQUITETURA.md          (20 min)   → Entender design
3. Código em `src/`        (30 min)   → Revisar implementação
4. Manifests em `k8s/`     (15 min)   → Revisar deployment
```

### Para DevOps/SRE
```
1. ARQUITETURA.md          (20 min)   → Visão de negócio
2. `k8s/` manifests        (30 min)   → Infraestrutura
3. `scripts/`              (15 min)   → Automação
4. INSTRUÇÕES_EXECUÇÃO.md  (20 min)   → Procedimentos
```

---

## 🔗 Links Diretos

### Documentação
- [📄 Resumo Executivo](RESUMO_EXECUTIVO.md)
- [🚀 Quick Start](QUICKSTART.md)
- [📋 Instruções Completas](INSTRUÇÕES_EXECUÇÃO.md)
- [🏗️ Arquitetura Técnica](ARQUITETURA.md)
- [📖 README Original](README.md)

### Código
- [💻 API de Pagamentos](src/api/app.py)
- [💻 Serviço de Auditoria](src/auditoria/app.py)

### Infra
- [🐳 Dockerfile API](docker/Dockerfile.api)
- [🐳 Dockerfile Auditoria](docker/Dockerfile.auditoria)
- [⚙️ docker-compose.yml](docker-compose.yml)

### Kubernetes
- [☸️ Namespace](k8s/00-namespace.yaml)
- [☸️ ConfigMap](k8s/01-configmap.yaml)
- [☸️ Secrets](k8s/02-secret.yaml)
- [☸️ PVC](k8s/03-pvc.yaml)
- [☸️ Deployments](k8s/05-api-deployment.yaml)
- [☸️ Services](k8s/06-api-service.yaml)
- [☸️ CronJob](k8s/09-cronjob.yaml)
- [☸️ Network Policy](k8s/10-networkpolicy.yaml)

### Scripts
- [🔧 Setup Minikube](scripts/setup-minikube.sh)
- [🔧 Build e Push](scripts/build-and-push.sh)
- [🔧 Deploy K8s](scripts/deploy-kubernetes.sh)
- [🔧 Setup Rancher](scripts/setup-rancher.sh)
- [🔧 Testes](scripts/test-api.sh)

---

## ❓ Perguntas Frequentes

**P: Por onde começo?**  
R: Leia [RESUMO_EXECUTIVO.md](RESUMO_EXECUTIVO.md), depois [QUICKSTART.md](QUICKSTART.md).

**P: Como faço o deploy?**  
R: Execute os 3 scripts em `scripts/`: `setup-minikube.sh`, `build-and-push.sh`, `deploy-kubernetes.sh`.

**P: Qual versão do Kubernetes?**  
R: Qualquer versão recente do Minikube (testado com Minikube 1.30+).

**P: Preciso de Docker Hub?**  
R: Sim, você precisa fazer push das imagens. Crie uma conta grátis em docker.com.

**P: Posso rodar sem Rancher?**  
R: Sim, Rancher é opcional. Você pode usar apenas `kubectl`.

**P: Como testo a API?**  
R: Execute `bash scripts/test-api.sh` ou use `curl` conforme descrito em [QUICKSTART.md](QUICKSTART.md).

**P: Qual é a reserva bancária inicial?**  
R: R$ 100.000,00 (configurável em ConfigMap).

**P: Como os dados persistem?**  
R: Via PVC compartilhado que armazena `instrucoes.log`.

**P: Quem liquida os PIX?**  
R: O Serviço de Auditoria, automaticamente via CronJob a cada 6 horas.

---

## 🎓 Informações do Aluno

**Nome:** Hugo Griilo Alves  
**RM:** 555354  
**Projeto:** UniFIAP Pay SPB - Sistema de Pagamento PIX  
**Data:** 13 de Novembro de 2025  
**Status:** ✅ Concluído

---

## 📊 Estatísticas do Projeto

| Métrica | Valor |
|---------|-------|
| Arquivos Criados | 30+ |
| Linhas de Código | 2000+ |
| Manifests Kubernetes | 12 |
| Scripts de Automação | 6 |
| Testes Implementados | 15 |
| Endpoints API | 8 |
| Documentação | 7 arquivos |
| Tempo de Setup | 5 minutos |

---

## ✅ Checklist de Leitura

- [ ] Ler RESUMO_EXECUTIVO.md
- [ ] Executar QUICKSTART.md
- [ ] Ler INSTRUÇÕES_EXECUÇÃO.md
- [ ] Estudar ARQUITETURA.md
- [ ] Revisar código em `src/`
- [ ] Revisar manifests em `k8s/`
- [ ] Executar testes
- [ ] Explorar via Rancher (opcional)

---

## 🚀 Próximos Passos

1. **Leitura:** Comece com [RESUMO_EXECUTIVO.md](RESUMO_EXECUTIVO.md)
2. **Execução:** Siga [QUICKSTART.md](QUICKSTART.md)
3. **Aprendizado:** Estude [ARQUITETURA.md](ARQUITETURA.md)
4. **Prática:** Execute todos os scripts e testes

---

**Bem-vindo ao UniFIAP Pay SPB! 🎉**

*Este índice o ajudará a navegar por toda a documentação e código do projeto.*

---

*Última atualização: 13 de Novembro de 2025*

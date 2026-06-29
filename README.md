# Biblioteca API

API REST para gerenciamento de biblioteca digital, desenvolvida como projeto para o **Trabalho Prático 2** da disciplina de Gerência de Configuração e Evolução de Software (PUC Minas).

## Stack

- **Python 3.12** + **FastAPI**
- **pytest** + **pytest-cov** para testes
- **Docker** + **Docker Compose** para implantação
- **Jenkins** + **ngrok** para pipeline CI/CD

---

## Pré-requisitos

- Git, Python 3.12, Make
- Docker + Docker Compose
- [ngrok](https://ngrok.com) com conta gratuita (para webhook)
- `curl` e `jq` (usados pelos scripts de setup)

---

## Início rápido — API local

```bash
# 1. Clonar o repositório
git clone https://github.com/leticiaafigueiredo/tp2-gerencia-conf.git
cd tp2-gerencia-conf

# 2. Criar e ativar ambiente virtual
python -m venv .venv
source .venv/bin/activate

# 3. Instalar dependências
pip install -r requirements.txt

# 4. Subir a API
make run
```

Acesse: **http://localhost:8000/docs** (Swagger interativo)

---

## Testes

```bash
make test-unit          # Testes de unidade
make test-integration   # Testes de integração
make test-acceptance    # Teste de aceitação (fluxo completo)
make test               # Todos + relatório de cobertura
```

---

## Deploy com Docker

```bash
# Build e subida da imagem de produção
make docker-build
make docker-up

# ou usando o script de deploy diretamente:
bash scripts/deploy.sh
```

A API ficará disponível em **http://localhost:8000**.  
O container inclui healthcheck automático em `/api/v1/health`.

---

## Pipeline Jenkins + webhook automático

Execute os passos abaixo **em ordem** para ter o pipeline CI/CD completo funcionando:

### Passo 1 — Subir o Jenkins

```bash
bash scripts/setup-jenkins.sh
```

Aguarde o Jenkins inicializar e acesse: **http://localhost:8080**  
(usuário: `admin` / senha exibida no terminal)

### Passo 2 — Criar o job de pipeline

```bash
bash scripts/create-jenkins-job.sh
```

Cria automaticamente o job `biblioteca-api` apontando para o `Jenkinsfile` do repositório.

### Passo 3 — Habilitar trigger do GitHub

```bash
bash scripts/enable-github-trigger.sh
```

Configura o job para responder a eventos `githubPush()`.

### Passo 4 — Configurar ngrok (uma vez por conta)

```bash
ngrok config add-authtoken SEU_TOKEN
```

Obtenha seu token em: https://dashboard.ngrok.com/get-started/your-authtoken

### Passo 5 — Criar túnel e configurar webhook no GitHub

```bash
bash scripts/setup-ngrok.sh --webhook
```

O script:
1. Inicia o túnel ngrok (`localhost:8080` → URL pública HTTPS)
2. Configura o webhook no repositório GitHub automaticamente (requer `gh` CLI)
3. Se não tiver `gh` CLI, exibe a URL para configurar manualmente em GitHub → Settings → Webhooks

> ⚠️ Mantenha este terminal aberto durante toda a sessão. Para encerrar: `bash scripts/setup-ngrok.sh --stop`

### Passo 6 — Verificar o pipeline

Faça um commit e push na branch `main`:

```bash
git add .
git commit -m "feat: dispara pipeline"
git push origin main
```

Acompanhe o build em: **http://localhost:8080/job/biblioteca-api**

Para disparar manualmente sem push:

```bash
bash scripts/trigger-jenkins-build.sh
```

### Stages do pipeline

| Stage | O que executa |
|-------|---------------|
| **Build** | Cria venv Python, instala `requirements.txt`, executa `make build` |
| **Test** *(paralelo)* | `make test-unit` e `make test-integration` simultaneamente |
| **Acceptance** | `make test-acceptance` — fluxo end-to-end completo |
| **Deploy** | `bash scripts/deploy.sh` — build Docker + health check |

---

## Endpoints

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/v1/health` | Health check |
| POST | `/api/v1/books` | Cadastrar livro |
| GET | `/api/v1/books` | Listar livros |
| GET | `/api/v1/books/{id}` | Detalhar livro |
| PUT | `/api/v1/books/{id}` | Atualizar livro |
| DELETE | `/api/v1/books/{id}` | Remover livro |
| POST | `/api/v1/users` | Cadastrar usuário |
| GET | `/api/v1/users` | Listar usuários |
| GET | `/api/v1/users/{id}` | Detalhar usuário |
| POST | `/api/v1/loans` | Registrar empréstimo |
| GET | `/api/v1/loans` | Listar empréstimos |
| POST | `/api/v1/loans/{id}/return` | Devolver livro |

---

## Estrutura do repositório

```
app/
├── models/       # Book, User, Loan
├── services/     # Regras de negócio
├── repositories/ # Persistência em memória
└── api/          # Endpoints REST (routes.py)
tests/
├── unit/         # Testes de unidade
├── integration/  # Testes de integração (API via httpx)
└── acceptance/   # Teste de aceitação (fluxo completo)
scripts/
├── deploy.sh                   # Implantação em Docker
├── setup-jenkins.sh            # Sobe Jenkins via Docker Compose
├── create-jenkins-job.sh       # Cria o job de pipeline no Jenkins
├── setup-ngrok.sh              # Inicia túnel ngrok + configura webhook
├── configure-github-webhook.sh # Configura webhook no GitHub
├── enable-github-trigger.sh    # Habilita trigger githubPush no job
└── trigger-jenkins-build.sh    # Disparo manual de build
Jenkinsfile                     # Definição do pipeline CI/CD
Dockerfile                      # Multi-stage: base / test / production
docker-compose.yml              # App em Docker
docker-compose.jenkins.yml      # Jenkins em Docker
```

---

## Artefatos de entrega

| Arquivo | Descrição |
|---------|-----------|
| `apresentacao.html` | Apresentação interativa (navegue com ← →) |
| `apresentacao.pdf` | Apresentação em PDF (formato 16:9, 11 slides) |
| `docTP2 (1).pdf` | Plano de Gerenciamento de Configuração |

---

## Equipe

| Papel | Integrante |
|-------|------------|
| Gerente de Configuração | Julia |
| Desenvolvedor / DevOps | Gustavo |
| Desenvolvedor / DevOps | Matheus |
| Desenvolvedor / DevOps | Leticia |
| Desenvolvedor / DevOps | Thiago |

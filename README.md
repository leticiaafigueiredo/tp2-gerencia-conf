# Biblioteca API

API REST para gerenciamento de biblioteca digital, desenvolvida como projeto base para o **Trabalho Prático 1** da disciplina de Gerência de Configuração e Evolução de Software (PUC).

## Objetivo

Sistema minimamente complexo que atende aos requisitos do TP:

| Requisito | Atendimento |
|-----------|-------------|
| ≥ 10 classes/arquivos | Models, services, repository, API, config |
| ≥ 20 métodos/funções | CRUD de livros, usuários e empréstimos |
| Testes automatizados | Unitários, integração e aceitação |
| Pipeline CI/CD | Preparado para Jenkins (próxima etapa) |
| Implantação | Docker + script `scripts/deploy.sh` |

## Stack

- **Python 3.12** + **FastAPI**
- **pytest** para testes
- **Docker** para implantação

## Estrutura

```
app/
├── models/       # Book, User, Loan
├── services/     # Regras de negócio
├── repositories/ # Persistência em memória
└── api/          # Endpoints REST
tests/
├── unit/         # Testes de unidade
├── integration/  # Testes de integração (API)
└── acceptance/   # Teste de aceitação (fluxo completo)
scripts/
└── deploy.sh     # Script de implantação
```

## Executar localmente

```bash
python -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
make run
```

Acesse: http://localhost:8000/docs

## Testes

```bash
make test-unit          # Testes de unidade
make test-integration   # Testes de integração
make test-acceptance    # Teste de aceitação
make test               # Todos + cobertura
```

## Docker

```bash
make docker-build
make docker-up
# ou
bash scripts/deploy.sh
```

## Endpoints principais

| Método | Rota | Descrição |
|--------|------|-----------|
| GET | `/api/v1/health` | Health check |
| POST | `/api/v1/books` | Cadastrar livro |
| GET | `/api/v1/books` | Listar livros |
| POST | `/api/v1/users` | Cadastrar usuário |
| POST | `/api/v1/loans` | Emprestar livro |
| POST | `/api/v1/loans/{id}/return` | Devolver livro |

## Próximos passos (Jenkins)

1. Inicializar repositório Git (`main`)
2. Criar `Jenkinsfile` com estágios: Build → Testes → Aceitação → Deploy
3. Configurar webhook para commits na branch `main`

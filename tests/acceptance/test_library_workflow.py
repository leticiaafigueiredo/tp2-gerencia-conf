"""Testes de aceitação - fluxo completo do sistema."""

from fastapi.testclient import TestClient

from app.main import app


class TestLibraryAcceptance:
    """
    Cenário de aceitação: bibliotecário cadastra acervo, usuário empresta
    e devolve livro, garantindo consistência funcional do sistema.
    """

    def test_library_complete_workflow(self):
        client = TestClient(app)

        # 1. Verificar que o sistema está operacional
        health = client.get("/api/v1/health")
        assert health.status_code == 200
        assert health.json()["service"] == "biblioteca-api"

        # 2. Cadastrar livros no acervo
        books_payload = [
            {"title": "Código Limpo", "author": "Robert Martin", "isbn": "978-0132350884"},
            {"title": "Refactoring", "author": "Martin Fowler", "isbn": "978-0201485677"},
        ]
        book_ids = []
        for payload in books_payload:
            response = client.post("/api/v1/books", json=payload)
            assert response.status_code == 201
            book_ids.append(response.json()["id"])

        # 3. Cadastrar usuário da biblioteca
        user_resp = client.post(
            "/api/v1/users",
            json={"name": "Estudante PUC", "email": "estudante@puc.br"},
        )
        assert user_resp.status_code == 201
        user_id = user_resp.json()["id"]

        # 4. Realizar empréstimo do primeiro livro
        loan_resp = client.post(
            "/api/v1/loans",
            json={"book_id": book_ids[0], "user_id": user_id},
        )
        assert loan_resp.status_code == 201
        loan_id = loan_resp.json()["id"]
        assert loan_resp.json()["active"] is True

        # 5. Validar regra de negócio: livro emprestado fica indisponível
        borrowed_book = client.get(f"/api/v1/books/{book_ids[0]}").json()
        assert borrowed_book["available"] is False

        available_books = client.get("/api/v1/books?available_only=true").json()
        available_ids = [b["id"] for b in available_books]
        assert book_ids[0] not in available_ids
        assert book_ids[1] in available_ids

        # 6. Tentativa de emprestar livro indisponível deve falhar
        duplicate_loan = client.post(
            "/api/v1/loans",
            json={"book_id": book_ids[0], "user_id": user_id},
        )
        assert duplicate_loan.status_code == 400

        # 7. Devolver livro e confirmar disponibilidade restaurada
        return_resp = client.post(f"/api/v1/loans/{loan_id}/return")
        assert return_resp.status_code == 200

        returned_book = client.get(f"/api/v1/books/{book_ids[0]}").json()
        assert returned_book["available"] is True

        # 8. Requisito não funcional: resposta da listagem em tempo aceitável (< 1s)
        import time

        start = time.time()
        list_resp = client.get("/api/v1/loans")
        elapsed = time.time() - start
        assert list_resp.status_code == 200
        assert elapsed < 1.0

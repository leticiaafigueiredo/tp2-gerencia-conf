"""Testes de integração da API."""

import pytest
from fastapi.testclient import TestClient

from app.main import app


@pytest.fixture
def client():
    return TestClient(app)


class TestHealthEndpoint:
    def test_health_returns_ok(self, client):
        response = client.get("/api/v1/health")
        assert response.status_code == 200
        assert response.json()["status"] == "ok"


class TestBooksAPI:
    def test_create_and_list_books(self, client):
        payload = {"title": "O Hobbit", "author": "Tolkien", "isbn": "978-0547928227"}
        create = client.post("/api/v1/books", json=payload)
        assert create.status_code == 201
        book_id = create.json()["id"]

        get_resp = client.get(f"/api/v1/books/{book_id}")
        assert get_resp.status_code == 200
        assert get_resp.json()["title"] == "O Hobbit"

        list_resp = client.get("/api/v1/books")
        assert list_resp.status_code == 200
        assert len(list_resp.json()) >= 1

    def test_update_book(self, client):
        create = client.post(
            "/api/v1/books",
            json={"title": "Original", "author": "Autor", "isbn": "111"},
        )
        book_id = create.json()["id"]
        update = client.put(f"/api/v1/books/{book_id}", json={"title": "Atualizado"})
        assert update.status_code == 200
        assert update.json()["title"] == "Atualizado"

    def test_delete_book_not_found(self, client):
        response = client.delete("/api/v1/books/99999")
        assert response.status_code == 404


class TestUsersAPI:
    def test_create_user(self, client):
        response = client.post(
            "/api/v1/users",
            json={"name": "Pedro", "email": "pedro@email.com"},
        )
        assert response.status_code == 201
        assert response.json()["name"] == "Pedro"

    def test_invalid_email_returns_422(self, client):
        response = client.post(
            "/api/v1/users",
            json={"name": "Pedro", "email": "email-invalido"},
        )
        assert response.status_code == 422


class TestLoansAPI:
    def test_full_loan_cycle(self, client):
        book = client.post(
            "/api/v1/books",
            json={"title": "Senhor dos Anéis", "author": "Tolkien", "isbn": "978-0544003415"},
        ).json()
        user = client.post(
            "/api/v1/users",
            json={"name": "Frodo", "email": "frodo@email.com"},
        ).json()

        loan_resp = client.post(
            "/api/v1/loans",
            json={"book_id": book["id"], "user_id": user["id"]},
        )
        assert loan_resp.status_code == 201
        loan_id = loan_resp.json()["id"]

        book_after = client.get(f"/api/v1/books/{book['id']}").json()
        assert book_after["available"] is False

        return_resp = client.post(f"/api/v1/loans/{loan_id}/return")
        assert return_resp.status_code == 200
        assert return_resp.json()["active"] is False

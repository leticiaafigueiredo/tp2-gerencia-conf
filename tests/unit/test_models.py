"""Testes unitários dos modelos."""

from datetime import datetime, timedelta

import pytest

from app.models.book import Book
from app.models.loan import Loan
from app.models.user import User


class TestBook:
    def test_create_book_defaults(self):
        book = Book(title="Clean Code", author="Robert Martin", isbn="978-0132350884")
        assert book.title == "Clean Code"
        assert book.available is True
        assert isinstance(book.created_at, datetime)

    def test_mark_as_borrowed(self):
        book = Book(title="Título", author="Autor", isbn="123")
        book.mark_as_borrowed()
        assert book.available is False

    def test_mark_as_borrowed_unavailable_raises(self):
        book = Book(title="Título", author="Autor", isbn="123", available=False)
        with pytest.raises(ValueError, match="não está disponível"):
            book.mark_as_borrowed()

    def test_mark_as_returned(self):
        book = Book(title="Título", author="Autor", isbn="123", available=False)
        book.mark_as_returned()
        assert book.available is True

    def test_to_dict(self):
        book = Book(id=1, title="Título", author="Autor", isbn="123")
        data = book.to_dict()
        assert data["id"] == 1
        assert data["available"] is True


class TestUser:
    def test_create_user(self):
        user = User(name="Maria", email="maria@email.com")
        assert user.active is True

    def test_deactivate_and_activate(self):
        user = User(name="João", email="joao@email.com")
        user.deactivate()
        assert user.active is False
        user.activate()
        assert user.active is True

    def test_to_dict(self):
        user = User(id=2, name="Ana", email="ana@email.com")
        assert user.to_dict()["email"] == "ana@email.com"


class TestLoan:
    def test_is_active(self):
        loan = Loan(book_id=1, user_id=1)
        assert loan.is_active() is True

    def test_close_loan(self):
        loan = Loan(book_id=1, user_id=1)
        loan.close()
        assert loan.is_active() is False
        assert loan.return_date is not None

    def test_is_overdue(self):
        loan = Loan(
            book_id=1,
            user_id=1,
            due_date=datetime.utcnow() - timedelta(days=1),
        )
        assert loan.is_overdue() is True

    def test_close_already_returned_raises(self):
        loan = Loan(book_id=1, user_id=1, return_date=datetime.utcnow())
        with pytest.raises(ValueError, match="já foi devolvido"):
            loan.close()

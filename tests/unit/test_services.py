"""Testes unitários dos serviços."""

import pytest

from app.models.book import Book
from app.models.loan import Loan
from app.models.user import User
from app.repositories.memory_repository import MemoryRepository
from app.services.book_service import BookService
from app.services.loan_service import LoanService
from app.services.user_service import UserService


class TestBookService:
    def setup_method(self):
        self.repo = MemoryRepository[Book]()
        self.service = BookService(self.repo)

    def test_create_and_get_book(self):
        book = self.service.create_book("Dom Casmurro", "Machado de Assis", "978-8535910557")
        assert book.id == 1
        assert self.service.get_book(1).title == "Dom Casmurro"

    def test_create_book_missing_fields_raises(self):
        with pytest.raises(ValueError):
            self.service.create_book("", "Autor", "123")

    def test_list_available_books(self):
        self.service.create_book("Livro A", "Autor A", "111")
        book_b = self.service.create_book("Livro B", "Autor B", "222")
        book_b.mark_as_borrowed()
        self.repo.save(book_b)
        available = self.service.list_books(available_only=True)
        assert len(available) == 1

    def test_delete_book(self):
        self.service.create_book("Livro", "Autor", "999")
        self.service.delete_book(1)
        with pytest.raises(LookupError):
            self.service.get_book(1)


class TestUserService:
    def setup_method(self):
        self.repo = MemoryRepository[User]()
        self.service = UserService(self.repo)

    def test_create_user(self):
        user = self.service.create_user("Carlos", "carlos@email.com")
        assert user.email == "carlos@email.com"

    def test_invalid_email_raises(self):
        with pytest.raises(ValueError, match="E-mail inválido"):
            self.service.create_user("Carlos", "email-invalido")

    def test_deactivate_user(self):
        self.service.create_user("Carlos", "carlos@email.com")
        user = self.service.deactivate_user(1)
        assert user.active is False


class TestLoanService:
    def setup_method(self):
        self.book_repo = MemoryRepository[Book]()
        self.user_repo = MemoryRepository[User]()
        self.loan_repo = MemoryRepository[Loan]()
        self.book_service = BookService(self.book_repo)
        self.user_service = UserService(self.user_repo)
        self.loan_service = LoanService(self.loan_repo, self.book_service, self.user_service)

        self.book = self.book_service.create_book("1984", "George Orwell", "978-0451524935")
        self.user = self.user_service.create_user("Leitor", "leitor@email.com")

    def test_borrow_book(self):
        loan = self.loan_service.borrow_book(self.book.id, self.user.id)
        assert loan.is_active() is True
        assert self.book_service.get_book(self.book.id).available is False

    def test_return_book(self):
        loan = self.loan_service.borrow_book(self.book.id, self.user.id)
        returned = self.loan_service.return_book(loan.id)
        assert returned.is_active() is False
        assert self.book_service.get_book(self.book.id).available is True

    def test_borrow_limit_exceeded(self):
        for i in range(3):
            book = self.book_service.create_book(f"Livro {i}", "Autor", f"isbn-{i}")
            self.loan_service.borrow_book(book.id, self.user.id)
        extra = self.book_service.create_book("Extra", "Autor", "extra")
        with pytest.raises(ValueError, match="limite"):
            self.loan_service.borrow_book(extra.id, self.user.id)

    def test_inactive_user_cannot_borrow(self):
        self.user_service.deactivate_user(self.user.id)
        with pytest.raises(ValueError, match="inativo"):
            self.loan_service.borrow_book(self.book.id, self.user.id)

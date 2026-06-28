"""Testes unitários do repositório."""

import pytest

from app.models.book import Book
from app.repositories.memory_repository import MemoryRepository


class TestMemoryRepository:
    def setup_method(self):
        self.repo = MemoryRepository[Book]()

    def test_save_assigns_id(self):
        book = Book(title="Título", author="Autor", isbn="123")
        saved = self.repo.save(book)
        assert saved.id == 1

    def test_find_by_id(self):
        book = Book(title="Título", author="Autor", isbn="123")
        self.repo.save(book)
        found = self.repo.find_by_id(1)
        assert found is not None
        assert found.title == "Título"

    def test_find_by_id_not_found(self):
        assert self.repo.find_by_id(999) is None

    def test_delete(self):
        book = Book(title="Título", author="Autor", isbn="123")
        self.repo.save(book)
        assert self.repo.delete(1) is True
        assert self.repo.count() == 0

    def test_clear(self):
        self.repo.save(Book(title="A", author="B", isbn="1"))
        self.repo.clear()
        assert self.repo.count() == 0

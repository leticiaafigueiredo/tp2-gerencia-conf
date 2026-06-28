"""Serviço de gerenciamento de livros."""

from app.models.book import Book
from app.repositories.memory_repository import MemoryRepository


class BookService:
    def __init__(self, repository: MemoryRepository[Book] | None = None) -> None:
        self._repository = repository or MemoryRepository[Book]()

    def create_book(self, title: str, author: str, isbn: str) -> Book:
        if not title or not author or not isbn:
            raise ValueError("Título, autor e ISBN são obrigatórios")
        book = Book(title=title.strip(), author=author.strip(), isbn=isbn.strip())
        return self._repository.save(book)

    def get_book(self, book_id: int) -> Book:
        book = self._repository.find_by_id(book_id)
        if book is None:
            raise LookupError(f"Livro {book_id} não encontrado")
        return book

    def list_books(self, available_only: bool = False) -> list[Book]:
        books = self._repository.find_all()
        if available_only:
            return [b for b in books if b.available]
        return books

    def update_book(self, book_id: int, title: str | None = None, author: str | None = None) -> Book:
        book = self.get_book(book_id)
        if title:
            book.title = title.strip()
        if author:
            book.author = author.strip()
        return self._repository.save(book)

    def delete_book(self, book_id: int) -> None:
        if not self._repository.delete(book_id):
            raise LookupError(f"Livro {book_id} não encontrado")

    def count_books(self) -> int:
        return self._repository.count()

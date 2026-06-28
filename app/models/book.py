"""Modelo de livro."""

from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class Book:
    title: str
    author: str
    isbn: str
    id: int | None = None
    available: bool = True
    created_at: datetime = field(default_factory=datetime.utcnow)

    def mark_as_borrowed(self) -> None:
        if not self.available:
            raise ValueError(f"Livro '{self.title}' não está disponível")
        self.available = False

    def mark_as_returned(self) -> None:
        if self.available:
            raise ValueError(f"Livro '{self.title}' já está disponível")
        self.available = True

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "title": self.title,
            "author": self.author,
            "isbn": self.isbn,
            "available": self.available,
            "created_at": self.created_at.isoformat(),
        }

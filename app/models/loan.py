"""Modelo de empréstimo."""

from dataclasses import dataclass, field
from datetime import datetime, timedelta


@dataclass
class Loan:
    book_id: int
    user_id: int
    id: int | None = None
    loan_date: datetime = field(default_factory=datetime.utcnow)
    return_date: datetime | None = None
    due_date: datetime = field(default_factory=lambda: datetime.utcnow() + timedelta(days=14))

    def is_active(self) -> bool:
        return self.return_date is None

    def is_overdue(self) -> bool:
        if not self.is_active():
            return False
        return datetime.utcnow() > self.due_date

    def close(self) -> None:
        if self.return_date is not None:
            raise ValueError("Empréstimo já foi devolvido")
        self.return_date = datetime.utcnow()

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "book_id": self.book_id,
            "user_id": self.user_id,
            "loan_date": self.loan_date.isoformat(),
            "return_date": self.return_date.isoformat() if self.return_date else None,
            "due_date": self.due_date.isoformat(),
            "active": self.is_active(),
            "overdue": self.is_overdue(),
        }

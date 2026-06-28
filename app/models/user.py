"""Modelo de usuário."""

from dataclasses import dataclass, field
from datetime import datetime


@dataclass
class User:
    name: str
    email: str
    id: int | None = None
    active: bool = True
    created_at: datetime = field(default_factory=datetime.utcnow)

    def deactivate(self) -> None:
        self.active = False

    def activate(self) -> None:
        self.active = True

    def to_dict(self) -> dict:
        return {
            "id": self.id,
            "name": self.name,
            "email": self.email,
            "active": self.active,
            "created_at": self.created_at.isoformat(),
        }

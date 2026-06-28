"""Serviço de gerenciamento de usuários."""

from app.models.user import User
from app.repositories.memory_repository import MemoryRepository


class UserService:
    def __init__(self, repository: MemoryRepository[User] | None = None) -> None:
        self._repository = repository or MemoryRepository[User]()

    def create_user(self, name: str, email: str) -> User:
        if not name or not email:
            raise ValueError("Nome e e-mail são obrigatórios")
        if "@" not in email:
            raise ValueError("E-mail inválido")
        user = User(name=name.strip(), email=email.strip().lower())
        return self._repository.save(user)

    def get_user(self, user_id: int) -> User:
        user = self._repository.find_by_id(user_id)
        if user is None:
            raise LookupError(f"Usuário {user_id} não encontrado")
        return user

    def list_users(self, active_only: bool = False) -> list[User]:
        users = self._repository.find_all()
        if active_only:
            return [u for u in users if u.active]
        return users

    def deactivate_user(self, user_id: int) -> User:
        user = self.get_user(user_id)
        user.deactivate()
        return self._repository.save(user)

    def delete_user(self, user_id: int) -> None:
        if not self._repository.delete(user_id):
            raise LookupError(f"Usuário {user_id} não encontrado")

    def count_users(self) -> int:
        return self._repository.count()

"""Repositório em memória para entidades da biblioteca."""

from typing import Generic, TypeVar

T = TypeVar("T")


class MemoryRepository(Generic[T]):
    def __init__(self) -> None:
        self._storage: dict[int, T] = {}
        self._next_id: int = 1

    def save(self, entity: T) -> T:
        entity_id = getattr(entity, "id", None)
        if entity_id is None:
            entity.id = self._next_id
            self._next_id += 1
        self._storage[entity.id] = entity
        return entity

    def find_by_id(self, entity_id: int) -> T | None:
        return self._storage.get(entity_id)

    def find_all(self) -> list[T]:
        return list(self._storage.values())

    def delete(self, entity_id: int) -> bool:
        if entity_id in self._storage:
            del self._storage[entity_id]
            return True
        return False

    def count(self) -> int:
        return len(self._storage)

    def clear(self) -> None:
        self._storage.clear()
        self._next_id = 1

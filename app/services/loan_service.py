"""Serviço de gerenciamento de empréstimos."""

from app.models.loan import Loan
from app.repositories.memory_repository import MemoryRepository
from app.services.book_service import BookService
from app.services.user_service import UserService


class LoanService:
    def __init__(
        self,
        repository: MemoryRepository[Loan] | None = None,
        book_service: BookService | None = None,
        user_service: UserService | None = None,
    ) -> None:
        self._repository = repository or MemoryRepository[Loan]()
        self._book_service = book_service or BookService()
        self._user_service = user_service or UserService()

    def borrow_book(self, book_id: int, user_id: int) -> Loan:
        book = self._book_service.get_book(book_id)
        user = self._user_service.get_user(user_id)

        if not user.active:
            raise ValueError("Usuário inativo não pode realizar empréstimos")

        active_loans = self.list_active_loans_by_user(user_id)
        if len(active_loans) >= 3:
            raise ValueError("Usuário atingiu o limite de 3 empréstimos ativos")

        book.mark_as_borrowed()
        loan = Loan(book_id=book.id, user_id=user.id)
        return self._repository.save(loan)

    def return_book(self, loan_id: int) -> Loan:
        loan = self.get_loan(loan_id)
        if not loan.is_active():
            raise ValueError("Empréstimo já foi devolvido")

        book = self._book_service.get_book(loan.book_id)
        book.mark_as_returned()
        loan.close()
        return self._repository.save(loan)

    def get_loan(self, loan_id: int) -> Loan:
        loan = self._repository.find_by_id(loan_id)
        if loan is None:
            raise LookupError(f"Empréstimo {loan_id} não encontrado")
        return loan

    def list_loans(self) -> list[Loan]:
        return self._repository.find_all()

    def list_active_loans_by_user(self, user_id: int) -> list[Loan]:
        return [l for l in self._repository.find_all() if l.user_id == user_id and l.is_active()]

    def count_overdue_loans(self) -> int:
        return sum(1 for l in self._repository.find_all() if l.is_overdue())

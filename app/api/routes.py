"""Definição das rotas HTTP da biblioteca."""

from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, EmailStr

from app.services.book_service import BookService
from app.services.loan_service import LoanService
from app.services.user_service import UserService

router = APIRouter()

book_service = BookService()
user_service = UserService()
loan_service = LoanService(book_service=book_service, user_service=user_service)


class BookCreate(BaseModel):
    title: str
    author: str
    isbn: str


class BookUpdate(BaseModel):
    title: str | None = None
    author: str | None = None


class UserCreate(BaseModel):
    name: str
    email: EmailStr


class LoanCreate(BaseModel):
    book_id: int
    user_id: int


@router.get("/health")
def health_check() -> dict:
    return {"status": "ok", "service": "biblioteca-api"}


@router.post("/books", status_code=201)
def create_book(payload: BookCreate) -> dict:
    try:
        book = book_service.create_book(payload.title, payload.author, payload.isbn)
        return book.to_dict()
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/books")
def list_books(available_only: bool = False) -> list[dict]:
    return [b.to_dict() for b in book_service.list_books(available_only=available_only)]


@router.get("/books/{book_id}")
def get_book(book_id: int) -> dict:
    try:
        return book_service.get_book(book_id).to_dict()
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.put("/books/{book_id}")
def update_book(book_id: int, payload: BookUpdate) -> dict:
    try:
        book = book_service.update_book(book_id, payload.title, payload.author)
        return book.to_dict()
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.delete("/books/{book_id}", status_code=204)
def delete_book(book_id: int) -> None:
    try:
        book_service.delete_book(book_id)
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/users", status_code=201)
def create_user(payload: UserCreate) -> dict:
    try:
        user = user_service.create_user(payload.name, payload.email)
        return user.to_dict()
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.get("/users")
def list_users(active_only: bool = False) -> list[dict]:
    return [u.to_dict() for u in user_service.list_users(active_only=active_only)]


@router.get("/users/{user_id}")
def get_user(user_id: int) -> dict:
    try:
        return user_service.get_user(user_id).to_dict()
    except LookupError as exc:
        raise HTTPException(status_code=404, detail=str(exc)) from exc


@router.post("/loans", status_code=201)
def create_loan(payload: LoanCreate) -> dict:
    try:
        loan = loan_service.borrow_book(payload.book_id, payload.user_id)
        return loan.to_dict()
    except (LookupError, ValueError) as exc:
        status = 404 if isinstance(exc, LookupError) else 400
        raise HTTPException(status_code=status, detail=str(exc)) from exc


@router.get("/loans")
def list_loans() -> list[dict]:
    return [l.to_dict() for l in loan_service.list_loans()]


@router.post("/loans/{loan_id}/return")
def return_loan(loan_id: int) -> dict:
    try:
        loan = loan_service.return_book(loan_id)
        return loan.to_dict()
    except (LookupError, ValueError) as exc:
        status = 404 if isinstance(exc, LookupError) else 400
        raise HTTPException(status_code=status, detail=str(exc)) from exc

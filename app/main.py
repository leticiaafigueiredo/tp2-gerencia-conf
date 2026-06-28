"""Ponto de entrada da aplicação."""

from fastapi import FastAPI

from app.api.routes import router
from app.config import settings

app = FastAPI(
    title=settings.app_name,
    version=settings.app_version,
    description="API REST para gerenciamento de biblioteca digital",
)

app.include_router(router, prefix="/api/v1")


@app.get("/")
def root() -> dict:
    return {
        "message": "Biblioteca API",
        "version": settings.app_version,
        "docs": "/docs",
    }


def run() -> None:
    import uvicorn

    uvicorn.run(
        "app.main:app",
        host=settings.host,
        port=settings.port,
        reload=settings.debug,
    )


if __name__ == "__main__":
    run()

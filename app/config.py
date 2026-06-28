"""Configurações da aplicação."""

import os


class Settings:
    app_name: str = "Biblioteca API"
    app_version: str = "1.0.0"
    debug: bool = os.getenv("BIB_DEBUG", "false").lower() == "true"
    host: str = os.getenv("BIB_HOST", "0.0.0.0")
    port: int = int(os.getenv("BIB_PORT", "8000"))


settings = Settings()

# __init__.py para app

from app.config import settings
from app.database import Database

__all__ = ["settings", "Database"]

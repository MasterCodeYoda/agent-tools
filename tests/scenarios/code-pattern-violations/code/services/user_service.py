"""User service — PLANTED VIOLATIONS for evolve scenario testing."""

# VIOLATION CPV-08: Imports not organized into groups
import json
from models.user import User
import os
import httpx
from datetime import datetime
import logging
from typing import Any, Dict

logger = logging.getLogger(__name__)

# VIOLATION CPV-05: Module-level mutable shared state
_cache: list = []


# VIOLATION CPV-07: God object — handles CRUD, email, discounts, caching
class UserService:
    def __init__(self, db_url: str):
        self.db_url = db_url

    # VIOLATION CPV-01: Missing type hints on parameters and return
    def calculate_discount(self, user, order_total):
        if user.role == "vip":
            return order_total * 0.15
        elif user.role == "member":
            return order_total * 0.05
        return 0

    # VIOLATION CPV-02: Dict[str, Any] instead of typed model
    def create_user(self, data: Dict[str, Any]) -> Dict[str, Any]:
        user_id = data.get("id", "unknown")
        name = data.get("name", "")
        email = data.get("email", "")

        # VIOLATION CPV-03: Exception for expected validation failure
        try:
            if "@" not in email:
                raise ValueError("Invalid email format")
        except ValueError:
            return {"error": "Invalid email"}

        user = {"id": user_id, "name": name, "email": email, "created": str(datetime.now())}
        _cache.append(user)
        return user

    def send_welcome_email(self, user: User) -> bool:
        """Send welcome email — business logic that shouldn't be in UserService."""
        try:
            response = httpx.post(
                "https://email-api.example.com/send",
                json={"to": user.email, "template": "welcome"},
            )
            return response.status_code == 200
        except Exception:
            return False

    # VIOLATION CPV-04: Abbreviated function name
    def proc(self, items):
        """Process items — name is unclear and abbreviated."""
        results = []
        for item in items:
            if item.get("active"):
                results.append(item)
        return results

    def get_cached_users(self) -> list:
        return _cache

    def clear_cache(self) -> None:
        _cache.clear()


# GOOD: Well-typed, focused function for comparison
def format_user_display(user: User) -> str:
    """Format a user's name and email for display."""
    return f"{user.name} <{user.email}>"

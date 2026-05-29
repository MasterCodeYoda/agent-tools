"""User model — PLANTED VIOLATIONS for evolve scenario testing."""


# VIOLATION CPV-06: String typing / primitive obsession
# Uses raw strings for email and user_id instead of value objects
class User:
    def __init__(self, user_id: str, name: str, email: str, role: str):
        self.user_id = user_id  # should be UserId value object
        self.name = name
        self.email = email  # should be Email value object with validation
        self.role = role  # should be Role enum, not raw string


# GOOD: Properly typed model for comparison
class Address:
    def __init__(self, street: str, city: str, zip_code: str, country: str):
        self.street = street
        self.city = city
        self.zip_code = zip_code
        self.country = country

    def format(self) -> str:
        return f"{self.street}, {self.city}, {self.zip_code}, {self.country}"

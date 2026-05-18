# Python Clean Architecture Examples

## Complete Feature Example: User Registration

This example shows a complete feature implementation across all layers.

### Domain Layer

```python
# domain/entities/user.py
from dataclasses import dataclass, field
from datetime import datetime
from typing import Optional
import uuid
import hashlib

@dataclass
class User:
    """User entity with business rules."""

    email: str
    _id: str = field(default_factory=lambda: str(uuid.uuid4()))
    _password_hash: Optional[str] = field(default=None, repr=False)
    _verified: bool = field(default=False)
    _created_at: datetime = field(default_factory=datetime.now)
    _verification_token: Optional[str] = field(default=None, repr=False)

    def __post_init__(self):
        """Validate email on creation."""
        if not self._is_valid_email(self.email):
            raise ValueError(f"Invalid email format: {self.email}")
        self.email = self.email.lower()

    @property
    def id(self) -> str:
        return self._id

    @property
    def is_verified(self) -> bool:
        return self._verified

    @staticmethod
    def _is_valid_email(email: str) -> bool:
        """Basic email validation."""
        return "@" in email and "." in email.split("@")[1]

    def set_password(self, plain_password: str) -> None:
        """Set user password with validation."""
        if len(plain_password) < 8:
            raise ValueError("Password must be at least 8 characters")
        if not any(c.isdigit() for c in plain_password):
            raise ValueError("Password must contain at least one digit")

        self._password_hash = self._hash_password(plain_password)

    def verify_password(self, plain_password: str) -> bool:
        """Check if password matches."""
        if not self._password_hash:
            return False
        return self._password_hash == self._hash_password(plain_password)

    def generate_verification_token(self) -> str:
        """Generate token for email verification."""
        token = str(uuid.uuid4())
        self._verification_token = token
        return token

    def verify_email(self, token: str) -> None:
        """Verify user's email with token."""
        if self._verified:
            raise ValueError("Email already verified")
        if self._verification_token != token:
            raise ValueError("Invalid verification token")

        self._verified = True
        self._verification_token = None

    @staticmethod
    def _hash_password(password: str) -> str:
        """Simple password hashing (use bcrypt in production)."""
        return hashlib.sha256(password.encode()).hexdigest()
```

```python
# domain/value_objects/email_address.py
from dataclasses import dataclass
import re

@dataclass(frozen=True)
class EmailAddress:
    """Email value object with validation."""

    value: str

    def __post_init__(self):
        pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
        if not re.match(pattern, self.value):
            raise ValueError(f"Invalid email: {self.value}")

        # Normalize to lowercase
        object.__setattr__(self, 'value', self.value.lower())

    def domain(self) -> str:
        """Get email domain."""
        return self.value.split('@')[1]

    def __str__(self) -> str:
        return self.value
```

```python
# domain/repositories/user_repository.py
from typing import Protocol, Optional
from ..entities import User

class UserRepository(Protocol):
    """User repository interface."""

    async def find_by_id(self, user_id: str) -> Optional[User]:
        """Find user by ID."""
        ...

    async def find_by_email(self, email: str) -> Optional[User]:
        """Find user by email."""
        ...

    async def save(self, user: User) -> None:
        """Save user."""
        ...

    async def exists_by_email(self, email: str) -> bool:
        """Check if email already exists."""
        ...
```

### Application Layer

```python
# application/users/register_user.py
from pydantic import BaseModel, Field, EmailStr
from typing import Optional
from dataclasses import dataclass

from domain.entities import User
from domain.repositories import UserRepository
from application.services import EmailService

# Request model
class RegisterUserRequest(BaseModel):
    email: EmailStr
    password: str = Field(..., min_length=8)

    class Config:
        str_strip_whitespace = True

# Response model
class RegisterUserResponse(BaseModel):
    user_id: str
    email: str
    verification_required: bool
    message: str

# Use case
class RegisterUserUseCase:
    """Register new user use case."""

    def __init__(
        self,
        user_repository: UserRepository,
        email_service: EmailService
    ):
        self._user_repo = user_repository
        self._email_service = email_service

    async def execute(self, request: RegisterUserRequest) -> RegisterUserResponse:
        """Register a new user."""

        # Check if email already exists
        if await self._user_repo.exists_by_email(request.email):
            raise EmailAlreadyExistsError(request.email)

        # Create user entity
        user = User(email=request.email)
        user.set_password(request.password)

        # Generate verification token
        token = user.generate_verification_token()

        # Save user
        await self._user_repo.save(user)

        # Send verification email
        await self._email_service.send_verification_email(
            email=user.email,
            token=token
        )

        # Return response
        return RegisterUserResponse(
            user_id=user.id,
            email=user.email,
            verification_required=True,
            message="Registration successful. Please check your email to verify your account."
        )

# Exceptions
class EmailAlreadyExistsError(Exception):
    def __init__(self, email: str):
        super().__init__(f"Email already registered: {email}")
        self.email = email
```

```python
# application/users/verify_email.py
from pydantic import BaseModel

class VerifyEmailRequest(BaseModel):
    email: str
    token: str

class VerifyEmailResponse(BaseModel):
    success: bool
    message: str

class VerifyEmailUseCase:
    """Verify user email use case."""

    def __init__(self, user_repository: UserRepository):
        self._user_repo = user_repository

    async def execute(self, request: VerifyEmailRequest) -> VerifyEmailResponse:
        """Verify user's email."""

        # Find user
        user = await self._user_repo.find_by_email(request.email)
        if not user:
            raise UserNotFoundError(request.email)

        # Verify email
        try:
            user.verify_email(request.token)
        except ValueError as e:
            return VerifyEmailResponse(
                success=False,
                message=str(e)
            )

        # Save updated user
        await self._user_repo.save(user)

        return VerifyEmailResponse(
            success=True,
            message="Email verified successfully"
        )
```

### Infrastructure Layer

```python
# infrastructure/repositories/sqlalchemy_user_repository.py
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from typing import Optional

from domain.entities import User
from domain.repositories import UserRepository
from .models import UserModel

class SqlAlchemyUserRepository(UserRepository):
    """SQLAlchemy implementation of UserRepository."""

    def __init__(self, session: AsyncSession):
        self._session = session

    async def find_by_id(self, user_id: str) -> Optional[User]:
        """Find user by ID."""
        stmt = select(UserModel).where(UserModel.id == user_id)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()

        if not model:
            return None

        return self._to_domain(model)

    async def find_by_email(self, email: str) -> Optional[User]:
        """Find user by email."""
        stmt = select(UserModel).where(UserModel.email == email.lower())
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()

        if not model:
            return None

        return self._to_domain(model)

    async def save(self, user: User) -> None:
        """Save user."""
        model = await self._get_or_create_model(user.id)
        self._update_model(model, user)

        self._session.add(model)
        await self._session.commit()

    async def exists_by_email(self, email: str) -> bool:
        """Check if email exists."""
        stmt = select(UserModel.id).where(UserModel.email == email.lower())
        result = await self._session.execute(stmt)
        return result.scalar_one_or_none() is not None

    async def _get_or_create_model(self, user_id: str) -> UserModel:
        """Get existing model or create new."""
        stmt = select(UserModel).where(UserModel.id == user_id)
        result = await self._session.execute(stmt)
        model = result.scalar_one_or_none()

        if not model:
            model = UserModel(id=user_id)

        return model

    def _to_domain(self, model: UserModel) -> User:
        """Convert database model to domain entity."""
        user = User(email=model.email)
        user._id = model.id
        user._password_hash = model.password_hash
        user._verified = model.verified
        user._created_at = model.created_at
        user._verification_token = model.verification_token
        return user

    def _update_model(self, model: UserModel, user: User) -> None:
        """Update model from domain entity."""
        model.email = user.email
        model.password_hash = user._password_hash
        model.verified = user._verified
        model.created_at = user._created_at
        model.verification_token = user._verification_token
```

```python
# infrastructure/services/smtp_email_service.py
import smtplib
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart

from application.services import EmailService

class SmtpEmailService(EmailService):
    """SMTP implementation of email service."""

    def __init__(self, host: str, port: int, username: str, password: str):
        self._host = host
        self._port = port
        self._username = username
        self._password = password

    async def send_verification_email(self, email: str, token: str) -> None:
        """Send verification email."""
        subject = "Verify Your Email"
        body = f"""
        Please verify your email by clicking the link below:

        http://localhost:8000/verify?email={email}&token={token}

        This link will expire in 24 hours.
        """

        await self._send_email(email, subject, body)

    async def _send_email(self, to_email: str, subject: str, body: str) -> None:
        """Send email via SMTP."""
        message = MIMEMultipart()
        message["From"] = self._username
        message["To"] = to_email
        message["Subject"] = subject

        message.attach(MIMEText(body, "plain"))

        with smtplib.SMTP(self._host, self._port) as server:
            server.starttls()
            server.login(self._username, self._password)
            server.send_message(message)
```

### Frameworks Layer

```python
# frameworks/fastapi/routers/users.py
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel

from application.users import (
    RegisterUserUseCase,
    RegisterUserRequest,
    VerifyEmailUseCase,
    VerifyEmailRequest,
    EmailAlreadyExistsError,
    UserNotFoundError
)
from ..dependencies import get_register_user_use_case, get_verify_email_use_case

router = APIRouter(prefix="/users", tags=["users"])

class RegisterDTO(BaseModel):
    """HTTP request DTO for registration."""
    email: str
    password: str

class VerifyDTO(BaseModel):
    """HTTP request DTO for verification."""
    email: str
    token: str

@router.post("/register", status_code=status.HTTP_201_CREATED)
async def register_user(
    dto: RegisterDTO,
    use_case: RegisterUserUseCase = Depends(get_register_user_use_case)
):
    """Register new user endpoint."""
    try:
        request = RegisterUserRequest(
            email=dto.email,
            password=dto.password
        )
        response = await use_case.execute(request)

        return {
            "user_id": response.user_id,
            "message": response.message
        }

    except EmailAlreadyExistsError:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Email already registered"
        )
    except ValueError as e:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e)
        )

@router.post("/verify-email")
async def verify_email(
    dto: VerifyDTO,
    use_case: VerifyEmailUseCase = Depends(get_verify_email_use_case)
):
    """Verify email endpoint."""
    try:
        request = VerifyEmailRequest(
            email=dto.email,
            token=dto.token
        )
        response = await use_case.execute(request)

        if not response.success:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=response.message
            )

        return {"message": response.message}

    except UserNotFoundError:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="User not found"
        )
```

```python
# frameworks/fastapi/dependencies.py
from functools import lru_cache
from sqlalchemy.ext.asyncio import AsyncSession
from fastapi import Depends

from application.users import RegisterUserUseCase, VerifyEmailUseCase
from infrastructure.repositories import SqlAlchemyUserRepository
from infrastructure.services import SmtpEmailService
from .database import get_db_session
from .config import Settings, get_settings

@lru_cache()
def get_user_repository(
    session: AsyncSession = Depends(get_db_session)
) -> UserRepository:
    return SqlAlchemyUserRepository(session)

@lru_cache()
def get_email_service(
    settings: Settings = Depends(get_settings)
) -> EmailService:
    return SmtpEmailService(
        host=settings.smtp_host,
        port=settings.smtp_port,
        username=settings.smtp_username,
        password=settings.smtp_password
    )

def get_register_user_use_case(
    user_repo: UserRepository = Depends(get_user_repository),
    email_service: EmailService = Depends(get_email_service)
) -> RegisterUserUseCase:
    return RegisterUserUseCase(user_repo, email_service)

def get_verify_email_use_case(
    user_repo: UserRepository = Depends(get_user_repository)
) -> VerifyEmailUseCase:
    return VerifyEmailUseCase(user_repo)
```

## Testing Examples

### Unit Test Example

```python
# tests/domain/test_user.py
import pytest
from domain.entities import User

class TestUser:
    """Test User entity."""

    def test_create_user_with_valid_email(self):
        """Test creating user with valid email."""
        user = User(email="john@example.com")
        assert user.email == "john@example.com"
        assert user.id is not None
        assert not user.is_verified

    def test_create_user_with_invalid_email(self):
        """Test creating user with invalid email."""
        with pytest.raises(ValueError, match="Invalid email"):
            User(email="invalid-email")

    def test_set_password(self):
        """Test setting password."""
        user = User(email="john@example.com")
        user.set_password("SecurePass123")
        assert user._password_hash is not None
        assert user.verify_password("SecurePass123")

    def test_password_too_short(self):
        """Test password validation."""
        user = User(email="john@example.com")
        with pytest.raises(ValueError, match="at least 8 characters"):
            user.set_password("short")

    def test_verify_email(self):
        """Test email verification."""
        user = User(email="john@example.com")
        token = user.generate_verification_token()

        user.verify_email(token)
        assert user.is_verified
        assert user._verification_token is None
```

### Integration Test Example

```python
# tests/application/test_register_user.py
import pytest
from unittest.mock import AsyncMock
from application.users import RegisterUserUseCase, RegisterUserRequest

@pytest.mark.asyncio
async def test_register_user_success():
    """Test successful user registration."""
    # Arrange
    mock_repo = AsyncMock()
    mock_repo.exists_by_email.return_value = False

    mock_email_service = AsyncMock()

    use_case = RegisterUserUseCase(mock_repo, mock_email_service)
    request = RegisterUserRequest(
        email="new@example.com",
        password="SecurePass123"
    )

    # Act
    response = await use_case.execute(request)

    # Assert
    assert response.email == "new@example.com"
    assert response.verification_required is True
    mock_repo.save.assert_called_once()
    mock_email_service.send_verification_email.assert_called_once()

@pytest.mark.asyncio
async def test_register_user_email_exists():
    """Test registration with existing email."""
    # Arrange
    mock_repo = AsyncMock()
    mock_repo.exists_by_email.return_value = True

    mock_email_service = AsyncMock()

    use_case = RegisterUserUseCase(mock_repo, mock_email_service)
    request = RegisterUserRequest(
        email="existing@example.com",
        password="SecurePass123"
    )

    # Act & Assert
    with pytest.raises(EmailAlreadyExistsError):
        await use_case.execute(request)

    mock_repo.save.assert_not_called()
    mock_email_service.send_verification_email.assert_not_called()
```

## Summary

This example demonstrates:
- **Domain layer** with rich entities and value objects
- **Application layer** with use cases and DTOs
- **Infrastructure layer** with repository and service implementations
- **Frameworks layer** with API endpoints and dependency injection
- **Testing** at multiple levels

Key patterns shown:
- Encapsulation with private fields
- Business rule validation in domain
- Use case orchestration
- Repository pattern
- Dependency injection
- Error handling across layers
- Comprehensive testing strategy
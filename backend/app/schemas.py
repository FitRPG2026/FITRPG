from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, field_validator


# ─────────────────────────────────────────────
# AUTH
# ─────────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: str
    password: str

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str):
        if len(v) < 6:
            raise ValueError("Hasło musi mieć min. 6 znaków")
        return v


class LoginRequest(BaseModel):
    email: str
    password: str


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user_id: int
    email: Optional[str] = None
    display_name: Optional[str] = None
    username: Optional[str] = None 

class MeResponse(BaseModel):
    user_id: int
    email: str
    username: Optional[str] = None
    display_name: Optional[str] = None
    status: str

# ─────────────────────────────────────────────
# ERROR 
# ─────────────────────────────────────────────

class ErrorResponse(BaseModel):
    detail: str
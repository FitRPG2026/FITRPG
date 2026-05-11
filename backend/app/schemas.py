from datetime import datetime
from typing import Optional, List
from pydantic import BaseModel, field_validator, Field


# ─────────────────────────────────────────────
# AUTH
# ─────────────────────────────────────────────

class RegisterRequest(BaseModel):
    email: str = Field(..., description="Adres e-mail użytkownika", example="gracz@fitrpg.pl")
    password: str = Field(..., description="Hasło użytkownika", example="SilneHaslo123!")

    @field_validator("password")
    @classmethod
    def validate_password(cls, v: str):
        if len(v) < 6:
            raise ValueError("Hasło musi mieć min. 6 znaków")
        return v


class LoginRequest(BaseModel):
    email: str = Field(..., description="Adres e-mail", example="gracz@fitrpg.pl")
    password: str = Field(..., description="Hasło", example="SilneHaslo123!")

class TokenResponse(BaseModel):
    access_token: str = Field(..., description="Zalogowany token JWT")
    token_type: str = Field(default="bearer", description="Typ tokenu")
    user_id: int = Field(..., description="ID użytkownika w bazie")
    email: Optional[str] = Field(None, description="Adres e-mail")
    display_name: Optional[str] = Field(None, description="Nazwa wyświetlana gracza")
    username: Optional[str] = Field(None, description="Unikalna nazwa użytkownika")
    
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
    detail: str = Field(..., description="Szczegóły błędu")
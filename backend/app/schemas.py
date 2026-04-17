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
    
# ─────────────────────────────────────────────────────────────
# EXERCISE
# ─────────────────────────────────────────────────────────────

class WorkoutBase(BaseModel):
    title: str
    workout_type: str
    duration_min: int

class WorkoutResponse(WorkoutBase):
    id: int
    class Config:
        from_attributes = True
        
class ExerciseResponse(BaseModel):
    exercise_name: str
    sets: int
    reps: int
    weight_kg: float

    class Config:
        from_attributes = True

class WorkoutHistoryResponse(BaseModel):
    id: int
    workout_type: str
    title: str
    duration_min: int
    performed_at: datetime
    exercises: List[ExerciseResponse] = []

    class Config:
        from_attributes = True
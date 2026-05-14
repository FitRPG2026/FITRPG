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
# WORKOUT
# ─────────────────────────────────────────────

class ExerciseRowRequest(BaseModel):
    exercise_name: str
    exercise_order: Optional[int] = None
    exercise_group: Optional[str] = None
    sets: Optional[int] = None
    reps: Optional[int] = None
    weight_kg: Optional[float] = None
    notes: Optional[str] = None

class WorkoutRequest(BaseModel):
    title: Optional[str] = None
    workout_type: Optional[str] = None
    activity_category: Optional[str] = None
    duration_min: Optional[int] = None
    performed_at: Optional[datetime] = None
    notes: Optional[str] = None
    exercises: List[ExerciseRowRequest] = []

class ChallengeRewardItem(BaseModel):
    challenge_id: int
    title: str
    points_earned: int

class WorkoutResponse(BaseModel):
    status: str = "success"
    workout_id: int
    exp_granted: int
    rewards: List[ChallengeRewardItem] = []

# ─────────────────────────────────────────────
# MEAL
# ─────────────────────────────────────────────

class MealRequest(BaseModel):
    title: Optional[str] = None
    meal_type: Optional[str] = None
    eaten_at: Optional[datetime] = None
    notes: Optional[str] = None
    health_score: int = 7

class MealResponse(BaseModel):
    status: str = "success"
    meal_id: int
    exp_granted: int
    rewards: List[ChallengeRewardItem] = []

# ─────────────────────────────────────────────
# PROFILE
# ─────────────────────────────────────────────

class UserProfileResponse(BaseModel):
    user_id: int
    username: Optional[str] = None
    display_name: Optional[str] = None
    birth_date: Optional[str] = None
    sex: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    goal: Optional[str] = None
    activity_level: Optional[str] = None
    total_exp: int = 0
    level: int = 1
    xp_in_level: int = 0
    xp_to_next_level: int = 100
    current_streak_days: int = 0
    longest_streak_days: int = 0

class UpdateProfileRequest(BaseModel):
    username: Optional[str] = None
    display_name: Optional[str] = None
    birth_date: Optional[str] = None
    sex: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    goal: Optional[str] = None
    activity_level: Optional[str] = None

# ─────────────────────────────────────────────
# SETTINGS
# ─────────────────────────────────────────────

class UserSettingsResponse(BaseModel):
    data_processing_consent: bool = False
    profile_public: bool = False

class UpdateSettingsRequest(BaseModel):
    data_processing_consent: bool
    profile_public: bool

# ─────────────────────────────────────────────
# ERROR
# ─────────────────────────────────────────────

class ErrorResponse(BaseModel):
    detail: str = Field(..., description="Szczegóły błędu")
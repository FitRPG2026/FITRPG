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


# ─────────────────────────────────────────────
# USER / PROGRESS
# ─────────────────────────────────────────────

class UserProgressResponse(BaseModel):
    user_id: int
    email: Optional[str] = None
    display_name: Optional[str] = None

    total_exp: int = 0
    current_level: int = 1
    current_streak_days: int = 0
    longest_streak_days: int = 0
    last_activity_at: Optional[datetime] = None


# ─────────────────────────────────────────────
# MEALS
# ─────────────────────────────────────────────

class MealItemInput(BaseModel):
    item_name: str
    quantity: Optional[float] = None
    unit: Optional[str] = None

    grams: Optional[float] = None
    calories: Optional[float] = None
    protein_g: Optional[float] = None
    carbs_g: Optional[float] = None
    fat_g: Optional[float] = None

    health_score: Optional[int] = None
    
    @field_validator("health_score")
    @classmethod
    def validate_health_score(cls, v):
        if v is not None and not (1 <= v <= 10):
            raise ValueError("health_score musi być między 1 a 10")
        return v

class LogMealRequest(BaseModel):
    meal_type: str  # breakfast | lunch | dinner | snack | other
    title: Optional[str] = None
    eaten_at: Optional[datetime] = None
    notes: Optional[str] = None
    health_score: Optional[int] = None

    ai_confidence: Optional[float] = None
    items: List[MealItemInput] = []

    grant_exp: bool = True
    exp_amount: int = 10
    exp_reason: Optional[str] = "Logged meal"

    @field_validator("meal_type")
    @classmethod
    def validate_meal_type(cls, v: str):
        allowed = {"breakfast", "lunch", "dinner", "snack", "other"}
        if v not in allowed:
            raise ValueError(f"meal_type must be one of {allowed}")
        return v
    
    @field_validator("health_score")
    @classmethod
    def validate_health_score(cls, v):
        if v is not None and not (1 <= v <= 10):
            raise ValueError("health_score musi być między 1 a 10")
        return v

    @field_validator("ai_confidence")
    @classmethod
    def validate_ai_confidence(cls, v):
        if v is not None and not (0.0 <= v <= 1.0):
            raise ValueError("ai_confidence musi być między 0 a 1")
        return v


class MealResponse(BaseModel):
    id: int
    meal_type: Optional[str]
    title: Optional[str]
    eaten_at: datetime

    total_calories: Optional[float]
    total_protein_g: Optional[float]
    total_carbs_g: Optional[float]
    total_fat_g: Optional[float]


class MealDetailResponse(MealResponse):
    notes: Optional[str]
    health_score: Optional[int]
    items: List[dict] = []


class LogMealResponse(BaseModel):
    message: str
    meal_id: int


# ─────────────────────────────────────────────
# WORKOUTS
# ─────────────────────────────────────────────

class WorkoutExerciseInput(BaseModel):
    exercise_name: str
    exercise_order: Optional[int] = None

    sets: Optional[int] = None
    reps: Optional[int] = None

    weight_kg: Optional[float] = None
    duration_sec: Optional[int] = None
    distance_m: Optional[float] = None

    calories_burned: Optional[float] = None
    notes: Optional[str] = None


class LogWorkoutRequest(BaseModel):
    workout_type: str  # strength | cardio | mobility | sport | other
    title: Optional[str] = None
    performed_at: Optional[datetime] = None

    duration_min: Optional[int] = None
    health_score: Optional[int] = None
    notes: Optional[str] = None

    exercises: List[WorkoutExerciseInput] = []

    grant_exp: bool = True
    exp_amount: int = 20
    exp_reason: Optional[str] = "Logged workout"

    @field_validator("workout_type")
    @classmethod
    def validate_workout_type(cls, v: str):
        allowed = {"strength", "cardio", "mobility", "sport", "other"}
        if v not in allowed:
            raise ValueError(f"workout_type must be one of {allowed}")
        return v

    @field_validator("health_score")
    @classmethod
    def validate_health_score(cls, v):
        if v is not None and not (1 <= v <= 10):
            raise ValueError("health_score musi być między 1 a 10")
        return v


    @field_validator("duration_min")
    @classmethod
    def validate_duration(cls, v):
        if v is not None and v <= 0:
            raise ValueError("duration_min musi być większe od 0")
        return v

class WorkoutResponse(BaseModel):
    id: int
    workout_type: Optional[str]
    title: Optional[str]
    performed_at: datetime

    duration_min: Optional[int]
    calories_burned: Optional[float]


class WorkoutDetailResponse(WorkoutResponse):
    health_score: Optional[int]
    notes: Optional[str]
    exercises: List[dict] = []


class LogWorkoutResponse(BaseModel):
    message: str
    workout_id: int


# ─────────────────────────────────────────────
# GENERIC XP / ACTIONS (future-proof pod questy)
# ─────────────────────────────────────────────

class XPResponse(BaseModel):
    gained: int
    total: int
    level: int


# ─────────────────────────────────────────────
# ERROR (opcjonalnie ale polecam)
# ─────────────────────────────────────────────

class ErrorResponse(BaseModel):
    detail: str
from datetime import datetime, date
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
# PROFILE
# ─────────────────────────────────────────────

class UpsertProfileRequest(BaseModel):
    username: Optional[str] = None
    display_name: Optional[str] = None
    birth_date: Optional[str] = None        # "YYYY-MM-DD"
    gender: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    goal: Optional[str] = None
    activity_level: Optional[str] = None


class ProfileResponse(BaseModel):
    user_id: int
    email: str
    username: Optional[str] = None
    display_name: Optional[str] = None
    birth_date: Optional[str] = None
    gender: Optional[str] = None
    height_cm: Optional[float] = None
    weight_kg: Optional[float] = None
    goal: Optional[str] = None
    activity_level: Optional[str] = None
    total_exp: int = 0
    level: int = 1
    current_streak_days: int = 0


# ─────────────────────────────────────────────
# WORKOUTS
# ─────────────────────────────────────────────

_WORKOUT_TYPES = {"strength", "cardio", "mobility", "sport", "other"}
_ACTIVITY_CATEGORIES = {"gym", "sport", "general", "other"}
_EXERCISE_GROUPS = {
    "chest", "back", "legs", "glutes", "shoulders",
    "biceps", "triceps", "calves", "core",
    "cardio_conditioning", "calisthenics", "other",
}


class ExerciseInput(BaseModel):
    exercise_name: str
    exercise_order: Optional[int] = None
    exercise_group: Optional[str] = None
    exercise_code: Optional[str] = None
    sets: Optional[int] = None
    reps: Optional[int] = None
    weight_kg: Optional[float] = None
    duration_sec: Optional[int] = None
    distance_m: Optional[float] = None
    notes: Optional[str] = None

    @field_validator("exercise_group")
    @classmethod
    def validate_exercise_group(cls, v):
        if v is not None and v not in _EXERCISE_GROUPS:
            raise ValueError(f"exercise_group musi być jednym z: {', '.join(sorted(_EXERCISE_GROUPS))}")
        return v


class LogWorkoutRequest(BaseModel):
    workout_type: Optional[str] = None
    title: Optional[str] = None
    performed_at: Optional[datetime] = None
    duration_min: Optional[int] = None
    health_score: Optional[int] = None
    notes: Optional[str] = None
    exercises: Optional[List[ExerciseInput]] = []
    activity_category: Optional[str] = None
    activity_code: Optional[str] = None
    activity_name: Optional[str] = None

    @field_validator("workout_type")
    @classmethod
    def validate_workout_type(cls, v):
        if v is not None and v not in _WORKOUT_TYPES:
            raise ValueError(f"workout_type musi być jednym z: {', '.join(sorted(_WORKOUT_TYPES))}")
        return v

    @field_validator("activity_category")
    @classmethod
    def validate_activity_category(cls, v):
        if v is not None and v not in _ACTIVITY_CATEGORIES:
            raise ValueError(f"activity_category musi być jednym z: {', '.join(sorted(_ACTIVITY_CATEGORIES))}")
        return v

    @field_validator("health_score")
    @classmethod
    def validate_health_score(cls, v):
        if v is not None and not (1 <= v <= 10):
            raise ValueError("health_score musi być w zakresie 1–10")
        return v

    @field_validator("duration_min")
    @classmethod
    def validate_duration(cls, v):
        if v is not None and v <= 0:
            raise ValueError("duration_min musi być większe od 0")
        return v


class WorkoutLoggedResponse(BaseModel):
    message: str
    exp_granted: int
    total_exp: int


# ─────────────────────────────────────────────
# MEALS
# ─────────────────────────────────────────────

_MEAL_TYPES = {"breakfast", "lunch", "dinner", "snack", "other"}


class LogMealRequest(BaseModel):
    meal_type: Optional[str] = None
    eaten_at: Optional[datetime] = None
    title: Optional[str] = None
    photo_url: Optional[str] = None
    notes: Optional[str] = None
    health_score: Optional[int] = None
    ai_confidence: Optional[float] = None

    @field_validator("meal_type")
    @classmethod
    def validate_meal_type(cls, v):
        if v is not None and v not in _MEAL_TYPES:
            raise ValueError(f"meal_type musi być jednym z: {', '.join(sorted(_MEAL_TYPES))}")
        return v

    @field_validator("health_score")
    @classmethod
    def validate_health_score(cls, v):
        if v is not None and not (1 <= v <= 10):
            raise ValueError("health_score musi być w zakresie 1–10")
        return v

    @field_validator("ai_confidence")
    @classmethod
    def validate_ai_confidence(cls, v):
        if v is not None and not (0.0 <= v <= 1.0):
            raise ValueError("ai_confidence musi być w zakresie 0–1")
        return v


class MealLoggedResponse(BaseModel):
    message: str
    exp_granted: int
    total_exp: int


# ─────────────────────────────────────────────
# ERROR
# ─────────────────────────────────────────────

class ErrorResponse(BaseModel):
    detail: str
from typing import Optional

_WORKOUT_MULTIPLIER = {
    "strength": 1.2,
    "cardio":   1.1,
    "sport":    1.1,
    "mobility": 0.9,
    "other":    1.0,
}


def calculate_workout_exp(
    workout_type: Optional[str],
    duration_min: Optional[int],
    health_score: Optional[int],
):
    base          = 50
    duration_bonus = (duration_min or 0) * 1
    health_bonus   = (health_score or 0) * 5
    multiplier     = _WORKOUT_MULTIPLIER.get(workout_type or "other", 1.0)
    return max(int(round((base + duration_bonus + health_bonus) * multiplier)), 10)


def calculate_meal_exp(health_score: Optional[int]) -> int:
    return 20 + (health_score or 0) * 8
import math


def compute_level(total_exp: int) -> dict:
    """
    Level n starts at 100 * n*(n-1)/2 XP and requires 100*n XP to advance.
    Inverse formula: n = floor((-1 + sqrt(1 + 8*total_exp/100)) / 2) + 1
    """
    if total_exp < 0:
        total_exp = 0
    level = int((-1 + math.sqrt(1 + 8 * total_exp / 100)) / 2) + 1
    xp_current_level_start = 100 * (level - 1) * level // 2
    xp_next_level_start = 100 * level * (level + 1) // 2
    return {
        "level": level,
        "xp_in_level": total_exp - xp_current_level_start,
        "xp_to_next_level": xp_next_level_start - xp_current_level_start,
    }


def compute_workout_exp(duration_min: int | None, workout_type: str | None) -> int:
    duration = max(duration_min or 0, 0)
    base = 30 + duration
    if workout_type == "strength":
        return round(base * 1.2)
    return base


def compute_meal_exp(health_score: int | None) -> int:
    score = health_score if health_score is not None else 7
    return max(score, 1) * 3

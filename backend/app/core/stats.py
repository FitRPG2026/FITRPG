"""
Moduł statystyk użytkownika.
"""
from datetime import datetime, timezone, timedelta
from typing import Optional
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text


async def get_user_stats(
    db: AsyncSession,
    user_id: int,
    days: int = 7,
) -> dict:
    """
    Pobiera statystyki użytkownika za ostatnie N dni.
    
    Zwraca:
    - total_workouts: liczba treningów
    - total_meals: liczba posiłków
    - total_exp: całkowity EXP
    - level: poziom
    - current_streak_days: aktualna seria logowań
    - longest_streak_days: najdłuższa seria logowań
    - avg_workout_duration_min: średni czas treningu
    - avg_meal_health_score: średnia ocena zdrowotna posiłków
    - workouts_by_type: rozkład treningów według typu
    - meals_by_type: rozkład posiłków według typu
    - workouts_by_day: treningi per dzień (ostatnie N dni)
    - meals_by_day: posiłki per dzień (ostatnie N dni)
    """
    cutoff_date = (datetime.now(timezone.utc) - timedelta(days=days)).date()
    
    # Pobieramy podstawowe dane z user_progress
    progress_row = await db.execute(
        text("""
            SELECT 
                total_exp,
                current_streak_days,
                longest_streak_days,
                level
            FROM user_progress
            WHERE user_id = :user_id
        """),
        {"user_id": user_id},
    )
    progress = progress_row.mappings().one_or_none()
    
    if not progress:
        return {
            "total_workouts": 0,
            "total_meals": 0,
            "total_exp": 0,
            "level": 1,
            "current_streak_days": 0,
            "longest_streak_days": 0,
            "avg_workout_duration_min": 0,
            "avg_meal_health_score": 0,
            "workouts_by_type": {},
            "meals_by_type": {},
            "workouts_by_day": {},
            "meals_by_day": {},
        }
    
    # Pobieramy statystyki treningów
    workouts_row = await db.execute(
        text("""
            SELECT 
                COUNT(*) as total,
                COALESCE(AVG(duration_min), 0) as avg_duration,
                COUNT(CASE WHEN workout_type = 'strength' THEN 1 END) as strength,
                COUNT(CASE WHEN workout_type = 'cardio' THEN 1 END) as cardio,
                COUNT(CASE WHEN workout_type = 'sport' THEN 1 END) as sport,
                COUNT(CASE WHEN workout_type = 'mobility' THEN 1 END) as mobility
            FROM workouts
            WHERE user_id = :user_id 
            AND performed_at >= :cutoff
        """),
        {"user_id": user_id, "cutoff": cutoff_date},
    )
    workouts = workouts_row.mappings().one()
    
    # Pobieramy statystyki posiłków
    meals_row = await db.execute(
        text("""
            SELECT 
                COUNT(*) as total,
                COALESCE(AVG(health_score), 0) as avg_health_score,
                COUNT(CASE WHEN meal_type = 'breakfast' THEN 1 END) as breakfast,
                COUNT(CASE WHEN meal_type = 'lunch' THEN 1 END) as lunch,
                COUNT(CASE WHEN meal_type = 'dinner' THEN 1 END) as dinner,
                COUNT(CASE WHEN meal_type = 'snack' THEN 1 END) as snack
            FROM meals
            WHERE user_id = :user_id 
            AND eaten_at >= :cutoff
        """),
        {"user_id": user_id, "cutoff": cutoff_date},
    )
    meals = meals_row.mappings().one()
    
    # Pobieramy treningi per dzień
    workouts_by_day_row = await db.execute(
        text("""
            SELECT 
                performed_at::date as date,
                COUNT(*) as count
            FROM workouts
            WHERE user_id = :user_id 
            AND performed_at >= :cutoff
            GROUP BY performed_at::date
            ORDER BY performed_at::date DESC
        """),
        {"user_id": user_id, "cutoff": cutoff_date},
    )
    workouts_by_day = {str(row["date"]): row["count"] for row in workouts_by_day_row.mappings()}
    meals_by_day = {str(row["date"]): row["count"] for row in meals_by_day_row.mappings()}   
     
    # Pobieramy posiłki per dzień
    meals_by_day_row = await db.execute(
        text("""
            SELECT 
                eaten_at::date as date,
                COUNT(*) as count
            FROM meals
            WHERE user_id = :user_id 
            AND eaten_at >= :cutoff
            GROUP BY eaten_at::date
            ORDER BY eaten_at::date DESC
        """),
        {"user_id": user_id, "cutoff": cutoff_date},
    )
    meals_by_day = {str(row["date"]): row["count"] for row in meals_by_day_row}
    
    # Formatujemy workouts_by_type
    workouts_by_type = {
        "strength": workouts["strength"],
        "cardio": workouts["cardio"],
        "sport": workouts["sport"],
        "mobility": workouts["mobility"],
    }
    
    # Formatujemy meals_by_type
    meals_by_type = {
        "breakfast": meals["breakfast"],
        "lunch": meals["lunch"],
        "dinner": meals["dinner"],
        "snack": meals["snack"],
    }
    
    return {
        "total_workouts": workouts["total"],
        "total_meals": meals["total"],
        "total_exp": progress["total_exp"],
        "level": progress["level"],
        "current_streak_days": progress["current_streak_days"],
        "longest_streak_days": progress["longest_streak_days"],
        "avg_workout_duration_min": workouts["avg_duration"],
        "avg_meal_health_score": meals["avg_health_score"],
        "workouts_by_type": workouts_by_type,
        "meals_by_type": meals_by_type,
        "workouts_by_day": workouts_by_day,
        "meals_by_day": meals_by_day,
    }

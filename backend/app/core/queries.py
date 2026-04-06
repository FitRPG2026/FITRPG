import json
from datetime import datetime, timezone
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncConnection


# ─────────────────────────────────────────────────────────────
# AUTH
# ─────────────────────────────────────────────────────────────

async def get_user_by_email(conn: AsyncConnection, email: str) -> dict | None:
    """Zwraca usera + hash hasła w jednym joinie."""
    row = await conn.execute(
        text("""
            SELECT
                u.id,
                u.email,
                u.status,
                ua.password_hash,
                up.display_name,
                up.username
            FROM users u
            JOIN user_auth ua ON ua.user_id = u.id
            LEFT JOIN user_profiles up ON up.user_id = u.id
            WHERE LOWER(u.email) = LOWER(:email)
        """),
        {"email": email},
    )
    row = row.mappings().one_or_none()
    return dict(row) if row else None


async def call_mark_login(conn: AsyncConnection, user_id: int, login_at: datetime) -> None:
    await conn.execute(
        text("CALL proc_mark_login(:user_id, :login_at)"),
        {"user_id": user_id, "login_at": login_at},
    )


# ─────────────────────────────────────────────────────────────
# USER PROGRESS / EXP
# ─────────────────────────────────────────────────────────────

async def get_user_progress(conn: AsyncConnection, user_id: int) -> dict | None:
    row = await conn.execute(
        text("""
            SELECT
                user_id,
                total_exp,
                current_streak_days,
                longest_streak_days,
                last_activity_at,
                updated_at
            FROM user_progress
            WHERE user_id = :user_id
        """),
        {"user_id": user_id},
    )
    row = row.mappings().one_or_none()
    return dict(row) if row else None


# ─────────────────────────────────────────────────────────────
# MEALS
# ─────────────────────────────────────────────────────────────

async def call_log_meal(conn: AsyncConnection, user_id: int, payload: dict) -> None:
    """
    Wywołuje proc_log_meal.
    payload to zdeserializowany LogMealRequest (dict).
    """
    items_json = json.dumps(
        [item for item in payload["items"]]
    )
    await conn.execute(
        text("""
            CALL proc_log_meal(
                p_user_id        => :user_id,
                p_meal_type      => :meal_type,
                p_eaten_at       => :eaten_at,
                p_title          => :title,
                p_notes          => :notes,
                p_health_score   => :health_score,
                p_items          => :items,
                p_grant_exp      => :grant_exp,
                p_exp_amount     => :exp_amount,
                p_exp_reason     => :exp_reason,
                p_exp_created_at => :exp_created_at
            )
        """),
        {
            "user_id":        user_id,
            "meal_type":      payload["meal_type"],
            "eaten_at":       payload["eaten_at"],
            "title":          payload.get("title"),
            "notes":          payload.get("notes"),
            "health_score":   payload.get("health_score"),
            "items":          items_json,
            "grant_exp":      payload.get("grant_exp", False),
            "exp_amount":     payload.get("exp_amount"),
            "exp_reason":     payload.get("exp_reason"),
            "exp_created_at": datetime.now(timezone.utc) if payload.get("grant_exp") else None,
        },
    )


async def get_meals(conn: AsyncConnection, user_id: int, limit: int = 20) -> list[dict]:
    result = await conn.execute(
        text("""
            SELECT
                id,
                meal_type,
                eaten_at,
                title,
                notes,
                health_score,
                total_calories,
                total_protein_g,
                total_carbs_g,
                total_fat_g
            FROM meals
            WHERE user_id = :user_id
            ORDER BY eaten_at DESC
            LIMIT :limit
        """),
        {"user_id": user_id, "limit": limit},
    )
    return [dict(row) for row in result.mappings()]


async def get_meal_with_items(conn: AsyncConnection, meal_id: int, user_id: int) -> dict | None:
    """Zwraca posiłek razem z listą składników."""
    meal_row = await conn.execute(
        text("""
            SELECT
                id, meal_type, eaten_at, title, notes, health_score,
                total_calories, total_protein_g, total_carbs_g, total_fat_g
            FROM meals
            WHERE id = :meal_id AND user_id = :user_id
        """),
        {"meal_id": meal_id, "user_id": user_id},
    )
    meal = meal_row.mappings().one_or_none()
    if not meal:
        return None

    items_row = await conn.execute(
        text("""
            SELECT item_name, quantity, unit, grams,
                   calories, protein_g, carbs_g, fat_g, health_score
            FROM meal_items
            WHERE meal_id = :meal_id
            ORDER BY id
        """),
        {"meal_id": meal_id},
    )
    return {**dict(meal), "items": [dict(r) for r in items_row.mappings()]}


async def get_last_meal(conn: AsyncConnection, user_id: int) -> dict | None:
    result = await conn.execute(
        text("""
            SELECT id, meal_type, eaten_at, title,
                   total_calories, total_protein_g, total_carbs_g, total_fat_g
            FROM meals
            WHERE user_id = :user_id
            ORDER BY created_at DESC
            LIMIT 1
        """),
        {"user_id": user_id},
    )
    row = result.mappings().one_or_none()
    return dict(row) if row else None


# ─────────────────────────────────────────────────────────────
# WORKOUTS
# ─────────────────────────────────────────────────────────────

async def call_log_workout(conn: AsyncConnection, user_id: int, payload: dict) -> None:
    exercises_json = json.dumps(payload["exercises"])
    await conn.execute(
        text("""
            CALL proc_log_workout(
                p_user_id        => :user_id,
                p_workout_type   => :workout_type,
                p_title          => :title,
                p_performed_at   => :performed_at,
                p_duration_min   => :duration_min,
                p_health_score   => :health_score,
                p_notes          => :notes,
                p_exercises      => :exercises,
                p_grant_exp      => :grant_exp,
                p_exp_amount     => :exp_amount,
                p_exp_reason     => :exp_reason,
                p_exp_created_at => :exp_created_at
            )
        """),
        {
            "user_id":        user_id,
            "workout_type":   payload["workout_type"],
            "title":          payload.get("title"),
            "performed_at":   payload["performed_at"],
            "duration_min":   payload.get("duration_min"),
            "health_score":   payload.get("health_score"),
            "notes":          payload.get("notes"),
            "exercises":      exercises_json,
            "grant_exp":      payload.get("grant_exp", False),
            "exp_amount":     payload.get("exp_amount"),
            "exp_reason":     payload.get("exp_reason"),
            "exp_created_at": datetime.now(timezone.utc) if payload.get("grant_exp") else None,
        },
    )


async def get_workouts(conn: AsyncConnection, user_id: int, limit: int = 20) -> list[dict]:
    result = await conn.execute(
        text("""
            SELECT
                id,
                workout_type,
                title,
                performed_at,
                duration_min,
                calories_burned,
                health_score,
                notes
            FROM workouts
            WHERE user_id = :user_id
            ORDER BY performed_at DESC
            LIMIT :limit
        """),
        {"user_id": user_id, "limit": limit},
    )
    return [dict(row) for row in result.mappings()]


async def get_workout_with_exercises(conn: AsyncConnection, workout_id: int, user_id: int) -> dict | None:
    workout_row = await conn.execute(
        text("""
            SELECT id, workout_type, title, performed_at,
                   duration_min, calories_burned, health_score, notes
            FROM workouts
            WHERE id = :workout_id AND user_id = :user_id
        """),
        {"workout_id": workout_id, "user_id": user_id},
    )
    workout = workout_row.mappings().one_or_none()
    if not workout:
        return None

    ex_row = await conn.execute(
        text("""
            SELECT exercise_name, exercise_order, sets, reps,
                   weight_kg, duration_sec, distance_m, calories_burned, notes
            FROM workout_exercises
            WHERE workout_id = :workout_id
            ORDER BY exercise_order NULLS LAST
        """),
        {"workout_id": workout_id},
    )
    return {**dict(workout), "exercises": [dict(r) for r in ex_row.mappings()]}


async def get_last_workout(conn: AsyncConnection, user_id: int) -> dict | None:
    result = await conn.execute(
        text("""
            SELECT id, workout_type, title, performed_at, duration_min, calories_burned
            FROM workouts
            WHERE user_id = :user_id
            ORDER BY created_at DESC
            LIMIT 1
        """),
        {"user_id": user_id},
    )
    row = result.mappings().one_or_none()
    return dict(row) if row else None

import json
from datetime import datetime, timezone
from typing import Optional
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncConnection


# ─────────────────────────────────────────────────────────────
# AUTH
# ─────────────────────────────────────────────────────────────

async def get_user_by_email(conn: AsyncConnection, email: str) -> dict | None:
    row = await conn.execute(
        text("""
            SELECT
                u.id,
                u.email,
                u.status,
                u.password_hash,
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
# PROFILE
# ─────────────────────────────────────────────────────────────

async def call_upsert_profile(
    conn: AsyncConnection,
    user_id: int,
    username: Optional[str],
    display_name: Optional[str],
    birth_date: Optional[str],
    sex: Optional[str],
    height_cm: Optional[float],
    weight_kg: Optional[float],
    goal: Optional[str],
    activity_level: Optional[str],
) -> None:
    await conn.execute(
        text("""
            CALL proc_upsert_user_profile(
                p_user_id      => :user_id,
                p_username     => :username,
                p_display_name => :display_name,
                p_birth_date   => CAST(:birth_date AS date),
                p_sex          => :sex,
                p_height_cm    => :height_cm,
                p_weight_kg    => :weight_kg,
                p_goal         => :goal,
                p_activity_level => :activity_level
            )
        """),
        {
            "user_id": user_id,
            "username": username,
            "display_name": display_name,
            "birth_date": birth_date,
            "sex": sex,
            "height_cm": height_cm,
            "weight_kg": weight_kg,
            "goal": goal,
            "activity_level": activity_level,
        },
    )


# ─────────────────────────────────────────────────────────────
# WORKOUTS
# ─────────────────────────────────────────────────────────────

async def call_log_workout(
    conn: AsyncConnection,
    user_id: int,
    workout_type: Optional[str],
    title: Optional[str],
    performed_at: datetime,
    duration_min: Optional[int],
    health_score: Optional[int],
    notes: Optional[str],
    exercises_json: str,
    exp_amount: int,
    activity_category: Optional[str],
    activity_code: Optional[str],
    activity_name: Optional[str],
) -> None:
    await conn.execute(
        text("""
            CALL proc_log_workout(
                p_user_id           => :user_id,
                p_workout_type      => :workout_type,
                p_title             => :title,
                p_performed_at      => :performed_at,
                p_duration_min      => :duration_min,
                p_health_score      => CAST(:health_score AS smallint),
                p_notes             => :notes,
                p_exercises         => CAST(:exercises AS jsonb),
                p_grant_exp         => true,
                p_exp_amount        => :exp_amount,
                p_exp_reason        => 'Workout logged',
                p_exp_created_at    => :performed_at,
                p_activity_category => :activity_category,
                p_activity_code     => :activity_code,
                p_activity_name     => :activity_name
            )
        """),
        {
            "user_id": user_id,
            "workout_type": workout_type,
            "title": title,
            "performed_at": performed_at,
            "duration_min": duration_min,
            "health_score": health_score,
            "notes": notes,
            "exercises": exercises_json,
            "exp_amount": exp_amount,
            "activity_category": activity_category,
            "activity_code": activity_code,
            "activity_name": activity_name,
        },
    )


# ─────────────────────────────────────────────────────────────
# MEALS
# ─────────────────────────────────────────────────────────────

async def call_log_meal(
    conn: AsyncConnection,
    user_id: int,
    meal_type: Optional[str],
    eaten_at: datetime,
    title: Optional[str],
    photo_url: Optional[str],
    notes: Optional[str],
    health_score: Optional[int],
    ai_confidence: Optional[float],
    exp_amount: int,
) -> None:
    await conn.execute(
        text("""
            CALL proc_log_meal(
                p_user_id       => :user_id,
                p_meal_type     => :meal_type,
                p_eaten_at      => :eaten_at,
                p_title         => :title,
                p_photo_url     => :photo_url,
                p_notes         => :notes,
                p_health_score  => CAST(:health_score AS smallint),
                p_ai_confidence => :ai_confidence,
                p_grant_exp     => true,
                p_exp_amount    => :exp_amount,
                p_exp_reason    => 'Meal logged',
                p_exp_created_at => :eaten_at
            )
        """),
        {
            "user_id": user_id,
            "meal_type": meal_type,
            "eaten_at": eaten_at,
            "title": title,
            "photo_url": photo_url,
            "notes": notes,
            "health_score": health_score,
            "ai_confidence": ai_confidence,
            "exp_amount": exp_amount,
        },
    )


# ─────────────────────────────────────────────────────────────
# PROGRESS
# ─────────────────────────────────────────────────────────────

async def get_user_progress(conn: AsyncConnection, user_id: int) -> dict | None:
    row = await conn.execute(
        text("SELECT total_exp, current_streak_days FROM user_progress WHERE user_id = :user_id"),
        {"user_id": user_id},
    )
    row = row.mappings().one_or_none()
    return dict(row) if row else None
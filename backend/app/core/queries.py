from datetime import datetime, timedelta
from typing import Optional
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


# ─────────────────────────────────────────────────────────────
# AUTH
# ─────────────────────────────────────────────────────────────

async def get_user_by_email(conn: AsyncSession, email: str) -> dict | None:
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
            LEFT JOIN user_auth ua ON ua.user_id = u.id
            LEFT JOIN user_profiles up ON up.user_id = u.id
            WHERE LOWER(u.email) = LOWER(:email)
        """),
        {"email": email},
    )
    row = row.mappings().one_or_none()
    return dict(row) if row else None


async def call_mark_login(conn: AsyncSession, user_id: int, login_at: datetime) -> None:
    row = await conn.execute(
        text("""
            SELECT last_login_at, current_login_streak_days
            FROM user_auth WHERE user_id = :uid FOR UPDATE
        """),
        {"uid": user_id},
    )
    auth = row.mappings().one_or_none()
    if not auth:
        return

    prev = auth["last_login_at"]
    streak = auth["current_login_streak_days"] or 0
    today = login_at.date()

    if prev is None:
        new_streak = 1
    elif today == prev.date():
        new_streak = max(streak, 1)
    elif today == prev.date() + timedelta(days=1):
        new_streak = streak + 1
    else:
        new_streak = 1

    await conn.execute(
        text("""
            UPDATE user_auth SET
                last_login_at             = :at,
                login_count               = login_count + 1,
                current_login_streak_days = :streak,
                updated_at                = NOW()
            WHERE user_id = :uid
        """),
        {"uid": user_id, "at": login_at, "streak": new_streak},
    )


# ─────────────────────────────────────────────────────────────
# PROFILE
# ─────────────────────────────────────────────────────────────

async def get_profile(conn: AsyncSession, user_id: int) -> dict | None:
    row = await conn.execute(
        text("""
            SELECT
                u.id                                    AS user_id,
                u.email,
                up.username,
                up.display_name,
                up.birth_date::text,
                up.gender,
                up.height_cm,
                up.weight_kg,
                up.goal,
                up.activity_level,
                COALESCE(pr.total_exp, 0)               AS total_exp,
                COALESCE(pr.level, 1)                   AS level,
                COALESCE(pr.current_streak_days, 0)     AS current_streak_days,
                COALESCE(pr.longest_streak_days, 0)     AS longest_streak_days
            FROM users u
            LEFT JOIN user_profiles up ON up.user_id = u.id
            LEFT JOIN user_progress pr ON pr.user_id = u.id
            WHERE u.id = :user_id
        """),
        {"user_id": user_id},
    )
    row = row.mappings().one_or_none()
    return dict(row) if row else None


async def upsert_profile(
    conn: AsyncSession,
    user_id: int,
    username: Optional[str],
    display_name: Optional[str],
    birth_date: Optional[str],
    gender: Optional[str],
    height_cm: Optional[float],
    weight_kg: Optional[float],
    goal: Optional[str],
    activity_level: Optional[str],
) -> None:
    await conn.execute(
        text("""
            INSERT INTO user_profiles
                (user_id, username, display_name, birth_date, gender,
                 height_cm, weight_kg, goal, activity_level)
            VALUES
                (:user_id, :username, :display_name,
                 :birth_date, :gender,
                 :height_cm, :weight_kg, :goal, :activity_level)
            ON CONFLICT (user_id) DO UPDATE SET
                username       = EXCLUDED.username,
                display_name   = EXCLUDED.display_name,
                birth_date     = EXCLUDED.birth_date,
                gender         = EXCLUDED.gender,
                height_cm      = EXCLUDED.height_cm,
                weight_kg      = EXCLUDED.weight_kg,
                goal           = EXCLUDED.goal,
                activity_level = EXCLUDED.activity_level,
                updated_at     = NOW()
        """),
        {
            "user_id": user_id,
            "username": username,
            "display_name": display_name,
            "birth_date": birth_date,
            "gender": gender,
            "height_cm": height_cm,
            "weight_kg": weight_kg,
            "goal": goal,
            "activity_level": activity_level,
        },
    )


# ─────────────────────────────────────────────────────────────
# SETTINGS
# ─────────────────────────────────────────────────────────────

async def get_user_settings(conn: AsyncSession, user_id: int) -> dict:
    row = await conn.execute(
        text("""
            SELECT data_processing_consent, profile_public
            FROM user_settings
            WHERE user_id = :user_id
        """),
        {"user_id": user_id},
    )
    row = row.mappings().one_or_none()
    return dict(row) if row else {"data_processing_consent": False, "profile_public": False}


async def upsert_user_settings(
    conn: AsyncSession, user_id: int, consent: bool, public: bool
) -> None:
    await conn.execute(
        text("""
            INSERT INTO user_settings (user_id, data_processing_consent, profile_public)
            VALUES (:user_id, :consent, :public)
            ON CONFLICT (user_id) DO UPDATE SET
                data_processing_consent = EXCLUDED.data_processing_consent,
                profile_public          = EXCLUDED.profile_public,
                updated_at              = NOW()
        """),
        {"user_id": user_id, "consent": consent, "public": public},
    )


# ─────────────────────────────────────────────────────────────
# WORKOUTS
# ─────────────────────────────────────────────────────────────

async def call_log_workout(
    conn: AsyncSession,
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
    conn: AsyncSession,
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
                p_user_id        => :user_id,
                p_meal_type      => :meal_type,
                p_eaten_at       => :eaten_at,
                p_title          => :title,
                p_photo_url      => :photo_url,
                p_notes          => :notes,
                p_health_score   => CAST(:health_score AS smallint),
                p_ai_confidence  => :ai_confidence,
                p_grant_exp      => true,
                p_exp_amount     => :exp_amount,
                p_exp_reason     => 'Meal logged',
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

async def get_user_progress(conn: AsyncSession, user_id: int) -> dict | None:
    row = await conn.execute(
        text("SELECT total_exp, current_streak_days FROM user_progress WHERE user_id = :user_id"),
        {"user_id": user_id},
    )
    row = row.mappings().one_or_none()
    return dict(row) if row else None


# ─────────────────────────────────────────────────────────────
# CHALLENGES
# ─────────────────────────────────────────────────────────────

async def get_active_challenges_for_trigger(
    conn: AsyncSession, user_id: int, trigger: str
) -> list[dict]:
    result = await conn.execute(
        text("""
            SELECT uc.challenge_id, c.title, c.reward_exp
            FROM user_challenges uc
            JOIN challenges c ON c.id = uc.challenge_id
            WHERE uc.user_id = :user_id
              AND uc.status = 'active'
              AND c.event_trigger = :trigger
        """),
        {"user_id": user_id, "trigger": trigger},
    )
    return [dict(r) for r in result.mappings().all()]


async def get_newly_completed_challenges(
    conn: AsyncSession, user_id: int, challenge_ids: list[int]
) -> list[dict]:
    if not challenge_ids:
        return []
    result = await conn.execute(
        text("""
            SELECT uc.challenge_id, c.title, c.reward_exp
            FROM user_challenges uc
            JOIN challenges c ON c.id = uc.challenge_id
            WHERE uc.user_id = :user_id
              AND uc.challenge_id = ANY(:ids)
              AND uc.status = 'completed'
        """),
        {"user_id": user_id, "ids": challenge_ids},
    )
    return [dict(r) for r in result.mappings().all()]
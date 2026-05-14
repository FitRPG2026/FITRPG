import json
from datetime import datetime, timezone
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncConnection


# ─────────────────────────────────────────────────────────────
# AUTH
# ─────────────────────────────────────────────────────────────

async def get_user_by_email(conn: AsyncConnection, email: str) -> dict | None:
    """
    Pobiera pełne dane użytkownika na podstawie jego adresu e-mail.
    Łączy tabele:
    - users (dane podstawowe)
    - user_auth (hash hasła)
    - user_profiles (nazwa wyświetlana)
    """
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
    """
    Wywołuje procedurę bazodanową rejestrującą datę i czas logowania użytkownika.
    Pamiętaj o wykonaniu db.commit() po wywołaniu tej funkcji.
    """
    await conn.execute(
        text("CALL proc_mark_login(:user_id, :login_at)"),
        {"user_id": user_id, "login_at": login_at},
    )


# ─────────────────────────────────────────────────────────────
# PROFILE
# ─────────────────────────────────────────────────────────────

async def get_user_profile(conn: AsyncConnection, user_id: int) -> dict | None:
    row = await conn.execute(
        text("""
            SELECT
                u.id AS user_id,
                up.username,
                up.display_name,
                up.birth_date,
                up.sex,
                up.height_cm,
                up.weight_kg,
                up.goal,
                up.activity_level,
                COALESCE(upr.total_exp, 0) AS total_exp,
                COALESCE(upr.current_streak_days, 0) AS current_streak_days,
                COALESCE(upr.longest_streak_days, 0) AS longest_streak_days
            FROM users u
            LEFT JOIN user_profiles up ON up.user_id = u.id
            LEFT JOIN user_progress upr ON upr.user_id = u.id
            WHERE u.id = :user_id
        """),
        {"user_id": user_id},
    )
    row = row.mappings().one_or_none()
    return dict(row) if row else None


# ─────────────────────────────────────────────────────────────
# SETTINGS
# ─────────────────────────────────────────────────────────────

async def get_user_settings(conn: AsyncConnection, user_id: int) -> dict:
    row = await conn.execute(
        text("""
            SELECT data_processing_consent, profile_public
            FROM user_settings
            WHERE user_id = :user_id
        """),
        {"user_id": user_id},
    )
    row = row.mappings().one_or_none()
    if row:
        return dict(row)
    return {"data_processing_consent": False, "profile_public": False}


async def upsert_user_settings(
    conn: AsyncConnection, user_id: int, consent: bool, public: bool
) -> None:
    await conn.execute(
        text("""
            INSERT INTO user_settings (user_id, data_processing_consent, profile_public)
            VALUES (:user_id, :consent, :public)
            ON CONFLICT (user_id) DO UPDATE
            SET data_processing_consent = EXCLUDED.data_processing_consent,
                profile_public = EXCLUDED.profile_public,
                updated_at = NOW()
        """),
        {"user_id": user_id, "consent": consent, "public": public},
    )


# ─────────────────────────────────────────────────────────────
# CHALLENGES
# ─────────────────────────────────────────────────────────────

async def get_active_challenges_for_trigger(
    conn: AsyncConnection, user_id: int, trigger: str
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
    conn: AsyncConnection, user_id: int, challenge_ids: list[int]
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


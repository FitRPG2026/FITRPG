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


from datetime import datetime
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncSession


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
    await conn.execute(
        text("CALL proc_mark_login(:user_id, :login_at)"),
        {"user_id": user_id, "login_at": login_at},
    )
    await conn.commit()
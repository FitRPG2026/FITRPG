import json
from datetime import datetime, timezone
from sqlalchemy import text
from sqlalchemy.ext.asyncio import AsyncConnection
from ..core.db import Base
from sqlalchemy import Column, BigInteger, String, Integer, Numeric, ForeignKey, DateTime, Text
from sqlalchemy.sql import func
from sqlalchemy.orm import relationship

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
# EXERCISE
# ─────────────────────────────────────────────────────────────

class Workout(Base):
    __tablename__ = "workouts"

    id = Column(BigInteger, primary_key=True, index=True)
    user_id = Column(BigInteger, ForeignKey("users.id", ondelete="CASCADE"), nullable=False)
    workout_type = Column(Text)
    title = Column(String(100))
    duration_min = Column(Integer)
    performed_at = Column(DateTime(timezone=True), server_default=func.now())
    
    exercises = relationship("WorkoutExercise", back_populates="workout", cascade="all, delete")

class WorkoutExercise(Base):
    __tablename__ = "workout_exercises"

    id = Column(BigInteger, primary_key=True, index=True)
    workout_id = Column(BigInteger, ForeignKey("workouts.id", ondelete="CASCADE"), nullable=False)
    exercise_name = Column(String(100), nullable=False)
    sets = Column(Integer)
    reps = Column(Integer)
    weight_kg = Column(Numeric(8, 2))
    
    workout = relationship("Workout", back_populates="exercises")
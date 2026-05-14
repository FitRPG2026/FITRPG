"""Initial schema – FitRPG

Revision ID: 001
Create Date: 2026-04-18
"""

# ── Usage ──────────────────────────────────────────────────────────────────
#
#  1. Install deps:
#       pip install alembic sqlalchemy psycopg2-binary python-dotenv
#
#  2. Set env vars (or put them in a .env file):
#       NEON_URL=postgresql://user:pass@host/db?sslmode=require&channel_binding=require
#
#  3. Bootstrap Alembic once (skip if you already have alembic.ini):
#       alembic init alembic
#
#     Then set in alembic.ini:
#       sqlalchemy.url = %(NEON_URL)s
#
#     And replace alembic/env.py content with the env.py snippet at
#     the bottom of this file.
#
#  4. Place this file in:
#       alembic/versions/001_initial_schema.py
#
#  5. Run:
#       alembic upgrade head
#
#  6. Roll back:
#       alembic downgrade base
#
# ───────────────────────────────────────────────────────────────────────────

from alembic import op
import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB

# Alembic metadata
revision = "001"
down_revision = None
branch_labels = None
depends_on = None


# ══════════════════════════════════════════════════════════════════════════
# UPGRADE
# ══════════════════════════════════════════════════════════════════════════

def upgrade() -> None:

    # ── users ──────────────────────────────────────────────────────────────
    op.create_table(
        "users",
        sa.Column("id",            sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("email",         sa.String(255), nullable=False, unique=True),
        sa.Column("password_hash", sa.String(255), nullable=False),
        sa.Column("status",        sa.String(20),  nullable=False, server_default="active"),
        sa.Column("created_at",    sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.text("NOW()")),
        sa.Column("updated_at",    sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.text("NOW()")),
    )
    op.create_index("ix_users_email", "users", ["email"], unique=True)

    # ── user_auth ──────────────────────────────────────────────────────────
    op.create_table(
        "user_auth",
        sa.Column("user_id",               sa.BigInteger,
                  sa.ForeignKey("users.id", ondelete="CASCADE"),
                  primary_key=True),
        sa.Column("refresh_token_hash",    sa.String(512), nullable=True),
        sa.Column("last_login_at",         sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column("login_count",           sa.Integer, nullable=False, server_default="0"),
        sa.Column("current_login_streak_days", sa.Integer, nullable=False, server_default="0"),
        sa.Column("updated_at",            sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.text("NOW()")),
    )

    # ── user_profiles ──────────────────────────────────────────────────────
    op.create_table(
        "user_profiles",
        sa.Column("user_id",       sa.BigInteger,
                  sa.ForeignKey("users.id", ondelete="CASCADE"),
                  primary_key=True),
        sa.Column("username",      sa.String(100), nullable=True, unique=True),
        sa.Column("display_name",  sa.String(100), nullable=True),
        sa.Column("birth_date",    sa.Date,        nullable=True),
        sa.Column("gender",        sa.String(20),  nullable=True),
        sa.Column("height_cm",     sa.Numeric(5, 2), nullable=True),
        sa.Column("weight_kg",     sa.Numeric(5, 2), nullable=True),
        sa.Column("goal",          sa.String(50),  nullable=True),
        sa.Column("activity_level", sa.String(30), nullable=True),
        sa.Column("updated_at",    sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.text("NOW()")),
    )
    op.create_index("ix_user_profiles_username", "user_profiles", ["username"], unique=True)

    # ── user_progress ──────────────────────────────────────────────────────
    op.create_table(
        "user_progress",
        sa.Column("user_id",               sa.BigInteger,
                  sa.ForeignKey("users.id", ondelete="CASCADE"),
                  primary_key=True),
        sa.Column("total_exp",             sa.Integer, nullable=False, server_default="0"),
        sa.Column("level",                 sa.Integer, nullable=False, server_default="1"),
        sa.Column("current_streak_days",   sa.Integer, nullable=False, server_default="0"),
        sa.Column("longest_streak_days",   sa.Integer, nullable=False, server_default="0"),
        sa.Column("current_login_streak_days", sa.Integer, nullable=False, server_default="0"),
        sa.Column("longest_login_streak_days", sa.Integer, nullable=False, server_default="0"),
        sa.Column("last_activity_date",    sa.Date, nullable=True),
        sa.Column("updated_at",            sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.text("NOW()")),
    )

    # ── challenges ─────────────────────────────────────────────────────────
    op.create_table(
        "challenges",
        sa.Column("id",             sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("title",          sa.String(255), nullable=False),
        sa.Column("description",    sa.Text,        nullable=True),
        sa.Column("challenge_type", sa.String(60),  nullable=False),
        sa.Column("goal_value",     sa.Numeric(12, 2), nullable=False),
        sa.Column("reward_exp",     sa.Integer,     nullable=False, server_default="0"),
        sa.Column("start_date",     sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column("end_date",       sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column("mechanic_type",  sa.String(30),  nullable=False),
        sa.Column("event_trigger",  sa.String(60),  nullable=False),
        sa.Column("conditions",     JSONB,          nullable=False, server_default="'{}'"),
        sa.Column("created_at",     sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.text("NOW()")),
    )

    # ── user_challenges ────────────────────────────────────────────────────
    op.create_table(
        "user_challenges",
        sa.Column("id",           sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("user_id",      sa.BigInteger,
                  sa.ForeignKey("users.id",      ondelete="CASCADE"), nullable=False),
        sa.Column("challenge_id", sa.BigInteger,
                  sa.ForeignKey("challenges.id", ondelete="CASCADE"), nullable=False),
        sa.Column("progress_value", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("status",       sa.String(20),  nullable=False, server_default="active"),
        sa.Column("started_at",   sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column("completed_at", sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column("claimed_at",   sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column("failed_at",    sa.TIMESTAMP(timezone=True), nullable=True),
        sa.UniqueConstraint("user_id", "challenge_id", name="uq_user_challenge"),
    )
    op.create_index("ix_user_challenges_user",      "user_challenges", ["user_id"])
    op.create_index("ix_user_challenges_challenge", "user_challenges", ["challenge_id"])

    # ── achievements ───────────────────────────────────────────────────────
    op.create_table(
        "achievements",
        sa.Column("id",               sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("code",             sa.String(80),  nullable=False, unique=True),
        sa.Column("title",            sa.String(255), nullable=False),
        sa.Column("description",      sa.Text,        nullable=True),
        sa.Column("achievement_type", sa.String(60),  nullable=False),
        sa.Column("target_value",     sa.Numeric(12, 2), nullable=False),
        sa.Column("reward_exp",       sa.Integer,     nullable=False, server_default="0"),
        sa.Column("icon_url",         sa.String(512), nullable=True),
        sa.Column("mechanic_type",    sa.String(30),  nullable=False),
        sa.Column("event_trigger",    sa.String(60),  nullable=False),
        sa.Column("conditions",       JSONB,          nullable=False, server_default="'{}'"),
        sa.Column("created_at",       sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.text("NOW()")),
    )
    op.create_index("ix_achievements_code", "achievements", ["code"], unique=True)

    # ── user_achievements ──────────────────────────────────────────────────
    op.create_table(
        "user_achievements",
        sa.Column("id",             sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("user_id",        sa.BigInteger,
                  sa.ForeignKey("users.id",       ondelete="CASCADE"), nullable=False),
        sa.Column("achievement_id", sa.BigInteger,
                  sa.ForeignKey("achievements.id", ondelete="CASCADE"), nullable=False),
        sa.Column("progress_value", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("status",         sa.String(20),  nullable=False, server_default="active"),
        sa.Column("started_at",     sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column("completed_at",   sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column("claimed_at",     sa.TIMESTAMP(timezone=True), nullable=True),
        sa.UniqueConstraint("user_id", "achievement_id", name="uq_user_achievement"),
    )
    op.create_index("ix_user_achievements_user",        "user_achievements", ["user_id"])
    op.create_index("ix_user_achievements_achievement", "user_achievements", ["achievement_id"])

    # ── quests ─────────────────────────────────────────────────────────────
    op.create_table(
        "quests",
        sa.Column("id",               sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("code",             sa.String(80),  nullable=False, unique=True),
        sa.Column("title",            sa.String(255), nullable=False),
        sa.Column("description",      sa.Text,        nullable=True),
        sa.Column("quest_type",       sa.String(60),  nullable=False),
        sa.Column("progression_mode", sa.String(30),  nullable=False, server_default="standalone"),
        sa.Column("quest_series_code", sa.String(80), nullable=True),
        sa.Column("sequence_order",   sa.Integer,     nullable=True),
        sa.Column("target_value",     sa.Numeric(12, 2), nullable=False),
        sa.Column("reward_exp",       sa.Integer,     nullable=False, server_default="0"),
        sa.Column("mechanic_type",    sa.String(30),  nullable=False),
        sa.Column("event_trigger",    sa.String(60),  nullable=False),
        sa.Column("conditions",       JSONB,          nullable=False, server_default="'{}'"),
        sa.Column("created_at",       sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.text("NOW()")),
    )
    op.create_index("ix_quests_code",        "quests", ["code"],             unique=True)
    op.create_index("ix_quests_series_code", "quests", ["quest_series_code"])

    # ── user_quests ────────────────────────────────────────────────────────
    op.create_table(
        "user_quests",
        sa.Column("id",             sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("user_id",        sa.BigInteger,
                  sa.ForeignKey("users.id",  ondelete="CASCADE"), nullable=False),
        sa.Column("quest_id",       sa.BigInteger,
                  sa.ForeignKey("quests.id", ondelete="CASCADE"), nullable=False),
        sa.Column("progress_value", sa.Numeric(12, 2), nullable=False, server_default="0"),
        sa.Column("status",         sa.String(20),  nullable=False, server_default="active"),
        sa.Column("started_at",     sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column("completed_at",   sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column("claimed_at",     sa.TIMESTAMP(timezone=True), nullable=True),
        sa.Column("abandoned_at",   sa.TIMESTAMP(timezone=True), nullable=True),
        sa.UniqueConstraint("user_id", "quest_id", name="uq_user_quest"),
    )
    op.create_index("ix_user_quests_user",  "user_quests", ["user_id"])
    op.create_index("ix_user_quests_quest", "user_quests", ["quest_id"])

    # ── meals ──────────────────────────────────────────────────────────────
    op.create_table(
        "meals",
        sa.Column("id",            sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("user_id",       sa.BigInteger,
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("meal_type",     sa.String(30),  nullable=False),
        sa.Column("title",         sa.String(255), nullable=True),
        sa.Column("eaten_at",      sa.TIMESTAMP(timezone=True), nullable=False),
        sa.Column("photo_url",     sa.String(512), nullable=True),
        sa.Column("notes",         sa.Text,        nullable=True),
        sa.Column("health_score",  sa.SmallInteger, nullable=True),
        sa.Column("ai_confidence", sa.Numeric(4, 3), nullable=True),
        sa.Column("created_at",    sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.text("NOW()")),
    )
    op.create_index("ix_meals_user_id", "meals", ["user_id"])
    op.create_index("ix_meals_eaten_at", "meals", ["eaten_at"])

    # ── workouts ───────────────────────────────────────────────────────────
    op.create_table(
        "workouts",
        sa.Column("id",                sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("user_id",           sa.BigInteger,
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("workout_type",      sa.String(30),  nullable=False),
        sa.Column("title",             sa.String(255), nullable=True),
        sa.Column("performed_at",      sa.TIMESTAMP(timezone=True), nullable=False),
        sa.Column("duration_min",      sa.Integer,     nullable=True),
        sa.Column("health_score",      sa.SmallInteger, nullable=True),
        sa.Column("notes",             sa.Text,        nullable=True),
        sa.Column("activity_category", sa.String(30),  nullable=True),
        sa.Column("activity_code",     sa.String(80),  nullable=True),
        sa.Column("activity_name",     sa.String(255), nullable=True),
        sa.Column("created_at",        sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.text("NOW()")),
    )
    op.create_index("ix_workouts_user_id",      "workouts", ["user_id"])
    op.create_index("ix_workouts_performed_at", "workouts", ["performed_at"])
    op.create_index("ix_workouts_activity",     "workouts", ["activity_category", "activity_code"])

    # ── gym_workout_exercises ──────────────────────────────────────────────
    op.create_table(
        "gym_workout_exercises",
        sa.Column("id",             sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("workout_id",     sa.BigInteger,
                  sa.ForeignKey("workouts.id", ondelete="CASCADE"), nullable=False),
        sa.Column("exercise_name",  sa.String(255), nullable=False),
        sa.Column("exercise_order", sa.Integer,     nullable=False),
        sa.Column("exercise_group", sa.String(60),  nullable=True),
        sa.Column("sets",           sa.Integer,     nullable=True),
        sa.Column("reps",           sa.Integer,     nullable=True),
        sa.Column("weight_kg",      sa.Numeric(6, 2), nullable=True),
        sa.Column("duration_sec",   sa.Integer,     nullable=True),
        sa.Column("distance_m",     sa.Numeric(8, 2), nullable=True),
        sa.Column("notes",          sa.Text,        nullable=True),
    )
    op.create_index("ix_gym_exercises_workout", "gym_workout_exercises", ["workout_id"])

    # ── exp_events ─────────────────────────────────────────────────────────
    op.create_table(
        "exp_events",
        sa.Column("id",          sa.BigInteger, primary_key=True, autoincrement=True),
        sa.Column("user_id",     sa.BigInteger,
                  sa.ForeignKey("users.id", ondelete="CASCADE"), nullable=False),
        sa.Column("source_type", sa.String(30),  nullable=False),
        sa.Column("source_id",   sa.BigInteger,  nullable=True),
        sa.Column("amount",      sa.Integer,     nullable=False),
        sa.Column("reason",      sa.Text,        nullable=True),
        sa.Column("granted_at",  sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.text("NOW()")),
        sa.Column("created_at",  sa.TIMESTAMP(timezone=True), nullable=False,
                  server_default=sa.text("NOW()")),
    )
    op.create_index("ix_exp_events_user_id",   "exp_events", ["user_id"])
    op.create_index("ix_exp_events_granted_at", "exp_events", ["granted_at"])


# ══════════════════════════════════════════════════════════════════════════
# DOWNGRADE
# ══════════════════════════════════════════════════════════════════════════

def downgrade() -> None:
    # Drop in reverse FK-dependency order
    op.drop_table("exp_events")
    op.drop_table("gym_workout_exercises")
    op.drop_table("workouts")
    op.drop_table("meals")
    op.drop_table("user_quests")
    op.drop_table("quests")
    op.drop_table("user_achievements")
    op.drop_table("achievements")
    op.drop_table("user_challenges")
    op.drop_table("challenges")
    op.drop_table("user_progress")
    op.drop_table("user_profiles")
    op.drop_table("user_auth")
    op.drop_table("users")


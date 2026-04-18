"""
FitRPG – complete seed script
Inserts all data directly via SQLAlchemy (no stored procedures needed).

Usage:
    pip install sqlalchemy psycopg2-binary python-dotenv bcrypt
    python seed.py

Requires NEON_URL in your .env or environment:
    NEON_URL=postgresql://user:pass@host/db?sslmode=require&channel_binding=require
"""

import os
import sys
from datetime import datetime, timezone, date
from decimal import Decimal

import bcrypt
from dotenv import load_dotenv
from sqlalchemy import create_engine, text

load_dotenv()

DATABASE_URL = os.environ.get("NEON_URL") or os.environ.get("DATABASE_URL")
if not DATABASE_URL:
    sys.exit("ERROR: set NEON_URL (or DATABASE_URL) in your .env file.")

# asyncpg prefix is not needed for this sync seed script
SYNC_URL = DATABASE_URL.replace("postgresql+asyncpg://", "postgresql://")

engine = create_engine(SYNC_URL, echo=False)


# ── helpers ────────────────────────────────────────────────────────────────

def hash_pw(plain: str) -> str:
    return bcrypt.hashpw(plain.encode(), bcrypt.gensalt(rounds=12)).decode()

def ts(s: str) -> datetime:
    return datetime.fromisoformat(s).replace(tzinfo=timezone.utc)

def now() -> datetime:
    return datetime.now(timezone.utc)


# ══════════════════════════════════════════════════════════════════════════
# SEED FUNCTIONS
# ══════════════════════════════════════════════════════════════════════════

def seed_users(conn) -> dict:
    """Returns {email: id}"""
    rows = [
        ("anna.nowak@fitrpg.dev",       hash_pw("demo_password"), "active"),
        ("bartek.kowalski@fitrpg.dev",  hash_pw("demo_password"), "active"),
        ("clara.zielinska@fitrpg.dev",  hash_pw("demo_password"), "active"),
        ("diego.santos@fitrpg.dev",     hash_pw("demo_password"), "inactive"),
        ("emilia.wisniewska@fitrpg.dev",hash_pw("demo_password"), "active"),
        ("filip.mazur@fitrpg.dev",      hash_pw("demo_password"), "active"),
        ("grace.demo@fitrpg.dev",       hash_pw("demo_password"), "banned"),
    ]
    result = {}
    for email, pw_hash, status in rows:
        row = conn.execute(
            text("""
                INSERT INTO users (email, password_hash, status, created_at, updated_at)
                VALUES (:e, :p, :s, NOW(), NOW())
                ON CONFLICT (email) DO UPDATE SET updated_at = NOW()
                RETURNING id
            """),
            {"e": email, "p": pw_hash, "s": status},
        ).fetchone()
        result[email] = row[0]
    print(f"  ✓ users ({len(result)})")
    return result


def seed_user_auth(conn, uid: dict):
    logins = {
        "anna.nowak@fitrpg.dev":        ("2026-03-22 07:15:00", 3),
        "bartek.kowalski@fitrpg.dev":   ("2026-03-20 06:50:00", 2),
        "clara.zielinska@fitrpg.dev":   ("2026-03-22 19:05:00", 5),
        "diego.santos@fitrpg.dev":      ("2026-03-14 17:40:00", 1),
        "emilia.wisniewska@fitrpg.dev": ("2026-03-22 15:30:00", 4),
        "filip.mazur@fitrpg.dev":       ("2026-03-22 20:10:00", 3),
        "grace.demo@fitrpg.dev":        ("2026-03-10 09:20:00", 0),
    }
    for email, (last_login, streak) in logins.items():
        conn.execute(
            text("""
                INSERT INTO user_auth
                    (user_id, last_login_at, login_count, current_login_streak_days, updated_at)
                VALUES (:uid, :ll, :lc, :streak, NOW())
                ON CONFLICT (user_id) DO UPDATE
                    SET last_login_at = EXCLUDED.last_login_at,
                        login_count   = EXCLUDED.login_count,
                        current_login_streak_days = EXCLUDED.current_login_streak_days,
                        updated_at    = NOW()
            """),
            {"uid": uid[email], "ll": ts(last_login), "lc": streak, "streak": streak},
        )
    print(f"  ✓ user_auth ({len(logins)})")


def seed_user_profiles(conn, uid: dict):
    profiles = [
        # (email,                         username,        display_name, birth_date,   gender,   height, weight,  goal,               activity_level)
        ("anna.nowak@fitrpg.dev",        "anna_nowak",    "Anna",       "1998-05-14", "female", 168.00, 62.50,  "build_strength",   "moderate"),
        ("bartek.kowalski@fitrpg.dev",   "bartek_fit",    "Bartek",     "1995-09-02", "male",   182.00, 86.20,  "lose_weight",      "light"),
        ("clara.zielinska@fitrpg.dev",   "clara_runs",    "Clara Z.",   "2000-01-19", "female", 171.00, 59.40,  "improve_endurance","very_active"),
        ("diego.santos@fitrpg.dev",      "diego_s",       "Diego",      "1992-12-11", "male",   176.00, 91.00,  "restart_habits",   "sedentary"),
        ("emilia.wisniewska@fitrpg.dev", "emi_balance",   "Emilia",     "1997-07-23", "female", 165.00, 57.80,  "maintain_balance", "moderate"),
        ("filip.mazur@fitrpg.dev",       "filip_lifts",   "Filip",      None,         None,     188.00, 95.50,  "gain_muscle",      "active"),
    ]
    for email, username, display_name, birth_date, gender, height, weight, goal, activity in profiles:
        conn.execute(
            text("""
                INSERT INTO user_profiles
                    (user_id, username, display_name, birth_date, gender,
                     height_cm, weight_kg, goal, activity_level, updated_at)
                VALUES (:uid, :un, :dn, :bd, :gender,
                        :h, :w, :goal, :al, NOW())
                ON CONFLICT (user_id) DO UPDATE
                    SET username = EXCLUDED.username,
                        display_name = EXCLUDED.display_name,
                        updated_at = NOW()
            """),
            {
                "uid": uid[email], "un": username, "dn": display_name,
                "bd": date.fromisoformat(birth_date) if birth_date else None,
                "gender": gender, "h": height, "w": weight,
                "goal": goal, "al": activity,
            },
        )
    print(f"  ✓ user_profiles ({len(profiles)})")


def seed_user_progress(conn, uid: dict):
    progress = [
        # (email,                          streak, login_streak)
        ("anna.nowak@fitrpg.dev",         7, 9),
        ("bartek.kowalski@fitrpg.dev",    2, 4),
        ("clara.zielinska@fitrpg.dev",    5, 8),
        ("diego.santos@fitrpg.dev",       1, 3),
        ("emilia.wisniewska@fitrpg.dev",  4, 6),
        ("filip.mazur@fitrpg.dev",        3, 5),
        ("grace.demo@fitrpg.dev",         0, 0),
    ]
    for email, streak, login_streak in progress:
        conn.execute(
            text("""
                INSERT INTO user_progress
                    (user_id, total_exp, level, current_streak_days, longest_streak_days,
                     current_login_streak_days, longest_login_streak_days, updated_at)
                VALUES (:uid, 0, 1, :streak, :streak, :ls, :ls, NOW())
                ON CONFLICT (user_id) DO UPDATE
                    SET current_streak_days = EXCLUDED.current_streak_days,
                        longest_streak_days = EXCLUDED.longest_streak_days,
                        current_login_streak_days = EXCLUDED.current_login_streak_days,
                        updated_at = NOW()
            """),
            {"uid": uid[email], "streak": streak, "ls": login_streak},
        )
    print(f"  ✓ user_progress ({len(progress)})")


def seed_challenges(conn) -> dict:
    """Returns {title: id}"""
    challenges = [
        {
            "title": "7-Day Logging Streak",
            "description": "Log at least one meal or workout for seven consecutive days.",
            "challenge_type": "streak_days", "goal_value": 7.00, "reward_exp": 40,
            "start_date": ts("2026-03-10 00:00:00"), "end_date": ts("2026-03-31 23:59:59"),
            "mechanic_type": "streak", "event_trigger": "activity_logged",
            "conditions": '{"requires_daily_activity": true}',
        },
        {
            "title": "Three Strength Sessions",
            "description": "Complete three strength workouts during the challenge window.",
            "challenge_type": "strength_sessions", "goal_value": 3.00, "reward_exp": 80,
            "start_date": ts("2026-03-10 00:00:00"), "end_date": ts("2026-03-31 23:59:59"),
            "mechanic_type": "accumulation", "event_trigger": "workout_logged",
            "conditions": '{"activity_category": "gym", "workout_type": "strength", "progress_delta": 1}',
        },
        {
            "title": "10K Run Distance",
            "description": "Accumulate ten kilometers of running workouts.",
            "challenge_type": "distance_m", "goal_value": 10000.00, "reward_exp": 60,
            "start_date": ts("2026-03-12 00:00:00"), "end_date": ts("2026-03-31 23:59:59"),
            "mechanic_type": "accumulation", "event_trigger": "workout_logged",
            "conditions": '{"activity_category": "general", "activity_code": "running", "workout_type": "cardio", "progress_field": "distance_m"}',
        },
        {
            "title": "Colorful Plate Week",
            "description": "Eat five meals with vegetables or fruit across one week.",
            "challenge_type": "healthy_meals", "goal_value": 5.00, "reward_exp": 50,
            "start_date": ts("2026-03-14 00:00:00"), "end_date": ts("2026-03-28 23:59:59"),
            "mechanic_type": "accumulation", "event_trigger": "meal_logged",
            "conditions": '{"min_health_score": 8, "requires_fruit_or_vegetables": true, "progress_delta": 1}',
        },
        {
            "title": "Weekend Warrior",
            "description": "Log two workouts over the weekend.",
            "challenge_type": "weekend_workouts", "goal_value": 2.00, "reward_exp": 50,
            "start_date": ts("2026-03-20 00:00:00"), "end_date": ts("2026-03-22 23:59:59"),
            "mechanic_type": "accumulation", "event_trigger": "workout_logged",
            "conditions": '{"day_of_week": ["saturday", "sunday"], "progress_delta": 1}',
        },
        {
            "title": "Hydration Habit",
            "description": "Hit your hydration target on five separate days.",
            "challenge_type": "hydration_days", "goal_value": 5.00, "reward_exp": 30,
            "start_date": ts("2026-03-01 00:00:00"), "end_date": None,
            "mechanic_type": "accumulation", "event_trigger": "hydration_logged",
            "conditions": '{"daily_target_required": true, "progress_delta": 1}',
        },
        {
            "title": "Green Master",
            "description": "Log one meal with a high health score and vegetables.",
            "challenge_type": "healthy_meals", "goal_value": 1.00, "reward_exp": 35,
            "start_date": ts("2026-03-20 00:00:00"), "end_date": ts("2026-03-27 23:59:59"),
            "mechanic_type": "threshold", "event_trigger": "meal_logged",
            "conditions": '{"min_health_score": 9, "requires_vegetables": true}',
        },
        {
            "title": "100-Minute Cardio Week",
            "description": "Complete one hundred minutes of cardio workouts during the week.",
            "challenge_type": "duration_min", "goal_value": 100.00, "reward_exp": 70,
            "start_date": ts("2026-03-16 00:00:00"), "end_date": ts("2026-03-22 23:59:59"),
            "mechanic_type": "accumulation", "event_trigger": "workout_logged",
            "conditions": '{"workout_type": "cardio", "progress_field": "duration_min"}',
        },
        {
            "title": "Three Login Streak",
            "description": "Log in three days in a row.",
            "challenge_type": "login_streak_days", "goal_value": 3.00, "reward_exp": 20,
            "start_date": ts("2026-03-01 00:00:00"), "end_date": None,
            "mechanic_type": "streak", "event_trigger": "login",
            "conditions": '{"streak_field": "current_login_streak_days"}',
        },
        {
            "title": "Gym Group Tour",
            "description": "Log exercises from each main gym exercise group.",
            "challenge_type": "exercise_group_coverage", "goal_value": 11.00, "reward_exp": 120,
            "start_date": ts("2026-03-01 00:00:00"), "end_date": None,
            "mechanic_type": "accumulation", "event_trigger": "workout_logged",
            "conditions": '{"activity_category": "gym", "distinct_exercise_groups": ["chest","back","legs","glutes","shoulders","biceps","triceps","calves","core","cardio_conditioning","calisthenics"]}',
        },
        {
            "title": "Team Sport Pair",
            "description": "Log both football and handball during the challenge window.",
            "challenge_type": "sport_combo", "goal_value": 2.00, "reward_exp": 60,
            "start_date": ts("2026-03-01 00:00:00"), "end_date": None,
            "mechanic_type": "accumulation", "event_trigger": "workout_logged",
            "conditions": '{"activity_category": "sport", "required_activity_codes": ["football","handball"], "distinct_activity_codes": true}',
        },
        {
            "title": "Basketball Regular",
            "description": "Log basketball three times.",
            "challenge_type": "sport_sessions", "goal_value": 3.00, "reward_exp": 45,
            "start_date": ts("2026-03-01 00:00:00"), "end_date": None,
            "mechanic_type": "accumulation", "event_trigger": "workout_logged",
            "conditions": '{"activity_category": "sport", "activity_code": "basketball", "progress_delta": 1}',
        },
        {
            "title": "Sport Explorer",
            "description": "Log three sessions for each tracked sport activity.",
            "challenge_type": "sport_collection", "goal_value": 3.00, "reward_exp": 100,
            "start_date": ts("2026-03-01 00:00:00"), "end_date": None,
            "mechanic_type": "accumulation", "event_trigger": "workout_logged",
            "conditions": '{"activity_category": "sport", "per_activity_code_target": 3}',
        },
        {
            "title": "Training Plus Gym Day",
            "description": "Log a general workout and a gym workout on the same day.",
            "challenge_type": "same_day_combo", "goal_value": 1.00, "reward_exp": 50,
            "start_date": ts("2026-03-01 00:00:00"), "end_date": None,
            "mechanic_type": "threshold", "event_trigger": "activity_logged",
            "conditions": '{"same_day_activity_categories": ["general","gym"]}',
        },
        {
            "title": "Back-to-Back Training",
            "description": "Log training on two consecutive days.",
            "challenge_type": "training_streak_days", "goal_value": 2.00, "reward_exp": 35,
            "start_date": ts("2026-03-01 00:00:00"), "end_date": None,
            "mechanic_type": "streak", "event_trigger": "activity_logged",
            "conditions": '{"requires_daily_workout": true}',
        },
    ]
    result = {}
    for c in challenges:
        row = conn.execute(
            text("""
                INSERT INTO challenges
                    (title, description, challenge_type, goal_value, reward_exp,
                     start_date, end_date, mechanic_type, event_trigger, conditions, created_at)
                VALUES
                    (:title, :desc, :ct, :gv, :re,
                     :sd, :ed, :mt, :et, :cond::jsonb, NOW())
                ON CONFLICT DO NOTHING
                RETURNING id
            """),
            {
                "title": c["title"], "desc": c["description"], "ct": c["challenge_type"],
                "gv": c["goal_value"], "re": c["reward_exp"],
                "sd": c["start_date"], "ed": c["end_date"],
                "mt": c["mechanic_type"], "et": c["event_trigger"],
                "cond": c["conditions"],
            },
        ).fetchone()
        if row:
            result[c["title"]] = row[0]
        else:
            existing = conn.execute(
                text("SELECT id FROM challenges WHERE title = :t"), {"t": c["title"]}
            ).fetchone()
            if existing:
                result[c["title"]] = existing[0]
    print(f"  ✓ challenges ({len(result)})")
    return result


def seed_achievements(conn) -> dict:
    """Returns {code: id}"""
    achievements = [
        {
            "code": "FIRST_MEAL", "title": "First Meal Logged",
            "description": "Log your first meal in the app.",
            "achievement_type": "meal_count", "target_value": 1.00, "reward_exp": 20,
            "icon_url": "https://cdn.fitrpg.dev/icons/first_meal.svg",
            "mechanic_type": "threshold", "event_trigger": "meal_logged", "conditions": "{}",
        },
        {
            "code": "FIRST_WORKOUT", "title": "First Workout Logged",
            "description": "Log your first workout in the app.",
            "achievement_type": "workout_count", "target_value": 1.00, "reward_exp": 25,
            "icon_url": "https://cdn.fitrpg.dev/icons/first_workout.svg",
            "mechanic_type": "threshold", "event_trigger": "workout_logged", "conditions": "{}",
        },
        {
            "code": "STREAK_7", "title": "Seven Day Streak",
            "description": "Stay active for seven consecutive days.",
            "achievement_type": "streak_days", "target_value": 7.00, "reward_exp": 35,
            "icon_url": "https://cdn.fitrpg.dev/icons/streak_7.svg",
            "mechanic_type": "streak", "event_trigger": "activity_logged",
            "conditions": '{"streak_field": "current_streak_days"}',
        },
        {
            "code": "MEAL_LOGGER_10", "title": "Meal Logger",
            "description": "Log ten meals.",
            "achievement_type": "meal_count", "target_value": 10.00, "reward_exp": 45,
            "icon_url": "https://cdn.fitrpg.dev/icons/meal_logger_10.svg",
            "mechanic_type": "accumulation", "event_trigger": "meal_logged",
            "conditions": '{"progress_delta": 1}',
        },
        {
            "code": "RUNNER_10K", "title": "10K Runner",
            "description": "Reach ten kilometers of running distance.",
            "achievement_type": "distance_m", "target_value": 10000.00, "reward_exp": 25,
            "icon_url": "https://cdn.fitrpg.dev/icons/runner_10k.svg",
            "mechanic_type": "accumulation", "event_trigger": "workout_logged",
            "conditions": '{"activity_category": "general", "activity_code": "running", "workout_type": "cardio", "progress_field": "distance_m"}',
        },
        {
            "code": "STRENGTH_5", "title": "Strength Builder",
            "description": "Complete five strength workouts.",
            "achievement_type": "strength_sessions", "target_value": 5.00, "reward_exp": 30,
            "icon_url": "https://cdn.fitrpg.dev/icons/strength_5.svg",
            "mechanic_type": "accumulation", "event_trigger": "workout_logged",
            "conditions": '{"activity_category": "gym", "workout_type": "strength", "progress_delta": 1}',
        },
        {
            "code": "SPORT_SAMPLER", "title": "Sport Sampler",
            "description": "Log three different sport activities.",
            "achievement_type": "sport_collection", "target_value": 3.00, "reward_exp": 40,
            "icon_url": "https://cdn.fitrpg.dev/icons/sport_sampler.svg",
            "mechanic_type": "accumulation", "event_trigger": "workout_logged",
            "conditions": '{"activity_category": "sport", "distinct_activity_codes": true}',
        },
        {
            "code": "EXERCISE_DETAIL_2", "title": "Detailed Session",
            "description": "Log a gym workout with at least two exercises.",
            "achievement_type": "exercise_count", "target_value": 1.00, "reward_exp": 25,
            "icon_url": "https://cdn.fitrpg.dev/icons/exercise_detail_2.svg",
            "mechanic_type": "threshold", "event_trigger": "workout_logged",
            "conditions": '{"activity_category": "gym", "min_exercise_count": 2}',
        },
    ]
    result = {}
    for a in achievements:
        row = conn.execute(
            text("""
                INSERT INTO achievements
                    (code, title, description, achievement_type, target_value, reward_exp,
                     icon_url, mechanic_type, event_trigger, conditions, created_at)
                VALUES
                    (:code, :title, :desc, :at, :tv, :re,
                     :icon, :mt, :et, :cond::jsonb, NOW())
                ON CONFLICT (code) DO NOTHING
                RETURNING id
            """),
            {
                "code": a["code"], "title": a["title"], "desc": a["description"],
                "at": a["achievement_type"], "tv": a["target_value"], "re": a["reward_exp"],
                "icon": a["icon_url"], "mt": a["mechanic_type"], "et": a["event_trigger"],
                "cond": a["conditions"],
            },
        ).fetchone()
        if row:
            result[a["code"]] = row[0]
        else:
            existing = conn.execute(
                text("SELECT id FROM achievements WHERE code = :c"), {"c": a["code"]}
            ).fetchone()
            if existing:
                result[a["code"]] = existing[0]
    print(f"  ✓ achievements ({len(result)})")
    return result


def seed_quests(conn) -> dict:
    """Returns {code: id}"""
    quests = [
        {
            "code": "ONBOARD_PROFILE", "title": "Profile Apprentice",
            "description": "Complete your first profile setup.",
            "quest_type": "onboarding", "progression_mode": "standalone",
            "series_code": None, "seq": None,
            "target_value": 1.00, "reward_exp": 15,
            "mechanic_type": "threshold", "event_trigger": "profile_completed", "conditions": "{}",
        },
        {
            "code": "FIRST_3_MEALS", "title": "Meal Habit Starter",
            "description": "Log your first three meals.",
            "quest_type": "meal_count", "progression_mode": "standalone",
            "series_code": None, "seq": None,
            "target_value": 3.00, "reward_exp": 20,
            "mechanic_type": "accumulation", "event_trigger": "meal_logged",
            "conditions": '{"progress_delta": 1}',
        },
        {
            "code": "CORE_RESET", "title": "Core Reset",
            "description": "Finish four mobility-focused sessions.",
            "quest_type": "mobility_sessions", "progression_mode": "standalone",
            "series_code": None, "seq": None,
            "target_value": 4.00, "reward_exp": 20,
            "mechanic_type": "accumulation", "event_trigger": "workout_logged",
            "conditions": '{"activity_category": "general", "workout_type": "mobility", "progress_delta": 1}',
        },
        {
            "code": "RUN_FOUNDATIONS_01", "title": "Run Foundations I",
            "description": "Finish the first run foundation step.",
            "quest_type": "program_step", "progression_mode": "linear",
            "series_code": "RUN_FOUNDATIONS", "seq": 1,
            "target_value": 1.00, "reward_exp": 15,
            "mechanic_type": "threshold", "event_trigger": "quest_step_completed",
            "conditions": '{"program_code": "run_foundations", "step": 1}',
        },
        {
            "code": "RUN_FOUNDATIONS_02", "title": "Run Foundations II",
            "description": "Finish the second run foundation step.",
            "quest_type": "program_step", "progression_mode": "linear",
            "series_code": "RUN_FOUNDATIONS", "seq": 2,
            "target_value": 1.00, "reward_exp": 20,
            "mechanic_type": "threshold", "event_trigger": "quest_step_completed",
            "conditions": '{"program_code": "run_foundations", "step": 2}',
        },
    ]
    result = {}
    for q in quests:
        row = conn.execute(
            text("""
                INSERT INTO quests
                    (code, title, description, quest_type, progression_mode,
                     quest_series_code, sequence_order, target_value, reward_exp,
                     mechanic_type, event_trigger, conditions, created_at)
                VALUES
                    (:code, :title, :desc, :qt, :pm,
                     :sc, :seq, :tv, :re,
                     :mt, :et, :cond::jsonb, NOW())
                ON CONFLICT (code) DO NOTHING
                RETURNING id
            """),
            {
                "code": q["code"], "title": q["title"], "desc": q["description"],
                "qt": q["quest_type"], "pm": q["progression_mode"],
                "sc": q["series_code"], "seq": q["seq"],
                "tv": q["target_value"], "re": q["reward_exp"],
                "mt": q["mechanic_type"], "et": q["event_trigger"],
                "cond": q["conditions"],
            },
        ).fetchone()
        if row:
            result[q["code"]] = row[0]
        else:
            existing = conn.execute(
                text("SELECT id FROM quests WHERE code = :c"), {"c": q["code"]}
            ).fetchone()
            if existing:
                result[q["code"]] = existing[0]
    print(f"  ✓ quests ({len(result)})")
    return result


def seed_meals(conn, uid: dict):
    meals = [
        # Anna
        {"uid": uid["anna.nowak@fitrpg.dev"],        "type": "breakfast", "eaten_at": "2026-03-20 07:35:00", "title": "High Protein Oats",       "photo": "https://cdn.fitrpg.dev/meals/high_protein_oats.jpg",       "notes": "Added berries after training.",                   "score": 9,  "ai": 0.962},
        {"uid": uid["anna.nowak@fitrpg.dev"],        "type": "lunch",     "eaten_at": "2026-03-20 13:10:00", "title": "Chicken Power Bowl",       "photo": "https://cdn.fitrpg.dev/meals/chicken_power_bowl.jpg",       "notes": "Meal-prepped bowl with rice and avocado.",         "score": 8,  "ai": 0.911},
        {"uid": uid["anna.nowak@fitrpg.dev"],        "type": "snack",     "eaten_at": "2026-03-21 16:20:00", "title": "Greek Yogurt Snack",       "photo": None,                                                        "notes": "Fast snack between meetings.",                     "score": 8,  "ai": None},
        # Bartek
        {"uid": uid["bartek.kowalski@fitrpg.dev"],   "type": "breakfast", "eaten_at": "2026-03-19 06:55:00", "title": "Office Breakfast Wrap",    "photo": None,                                                        "notes": "Grabbed on the way to work.",                      "score": 6,  "ai": 0.702},
        {"uid": uid["bartek.kowalski@fitrpg.dev"],   "type": "dinner",    "eaten_at": "2026-03-20 19:15:00", "title": "Salmon Rice Plate",        "photo": "https://cdn.fitrpg.dev/meals/salmon_rice_plate.jpg",        "notes": "Restaurant dinner, estimate adjusted manually.",   "score": 8,  "ai": 0.834},
        # Clara
        {"uid": uid["clara.zielinska@fitrpg.dev"],   "type": "snack",     "eaten_at": "2026-03-21 17:45:00", "title": "Post Run Smoothie",        "photo": "https://cdn.fitrpg.dev/meals/post_run_smoothie.jpg",        "notes": "Recovery smoothie after tempo run.",               "score": 9,  "ai": 0.955},
        {"uid": uid["clara.zielinska@fitrpg.dev"],   "type": "dinner",    "eaten_at": "2026-03-21 20:15:00", "title": "Veggie Pasta Dinner",      "photo": None,                                                        "notes": "Homemade whole-grain pasta.",                      "score": 8,  "ai": None},
        # Diego
        {"uid": uid["diego.santos@fitrpg.dev"],      "type": "lunch",     "eaten_at": "2026-03-15 12:30:00", "title": "Quick Convenience Lunch",  "photo": None,                                                        "notes": "Logged to restart tracking habit.",                "score": 4,  "ai": None},
        # Emilia
        {"uid": uid["emilia.wisniewska@fitrpg.dev"], "type": "breakfast", "eaten_at": "2026-03-22 09:10:00", "title": "Weekend Pancakes",         "photo": "https://cdn.fitrpg.dev/meals/weekend_pancakes.jpg",         "notes": "Shared breakfast, estimated half portion.",        "score": 6,  "ai": 0.821},
        {"uid": uid["emilia.wisniewska@fitrpg.dev"], "type": "lunch",     "eaten_at": "2026-03-22 13:05:00", "title": "Mediterranean Salad",      "photo": "https://cdn.fitrpg.dev/meals/mediterranean_salad.jpg",      "notes": "Mostly manual corrections after scan.",            "score": 9,  "ai": 0.943},
        {"uid": uid["emilia.wisniewska@fitrpg.dev"], "type": "snack",     "eaten_at": "2026-03-22 16:05:00", "title": "Apple Peanut Snack",       "photo": None,                                                        "notes": None,                                               "score": 7,  "ai": None},
        # Filip
        {"uid": uid["filip.mazur@fitrpg.dev"],       "type": "snack",     "eaten_at": "2026-03-22 14:40:00", "title": "Protein Shake",            "photo": None,                                                        "notes": "Post leg day shake.",                              "score": 8,  "ai": None},
        {"uid": uid["filip.mazur@fitrpg.dev"],       "type": "dinner",    "eaten_at": "2026-03-22 20:45:00", "title": "Sushi Dinner",             "photo": "https://cdn.fitrpg.dev/meals/sushi_dinner.jpg",             "notes": "Dinner after basketball with friends.",            "score": 7,  "ai": 0.776},
    ]
    for m in meals:
        conn.execute(
            text("""
                INSERT INTO meals
                    (user_id, meal_type, title, eaten_at, photo_url,
                     notes, health_score, ai_confidence, created_at)
                VALUES
                    (:uid, :type, :title, :eaten_at, :photo,
                     :notes, :score, :ai, NOW())
            """),
            {
                "uid": m["uid"], "type": m["type"], "title": m["title"],
                "eaten_at": ts(m["eaten_at"]), "photo": m["photo"],
                "notes": m["notes"], "score": m["score"], "ai": m["ai"],
            },
        )
    print(f"  ✓ meals ({len(meals)})")


def seed_workouts(conn, uid: dict) -> dict:
    """Returns {(user_email, title): workout_id} for exercise linking"""
    workouts = [
        # Anna
        {
            "uid": uid["anna.nowak@fitrpg.dev"], "type": "strength",
            "title": "Upper Body Strength", "performed_at": "2026-03-20 18:00:00",
            "duration_min": 58, "score": 9, "notes": "Focused on progressive overload.",
            "activity_category": "gym", "activity_code": "upper_body_strength",
            "activity_name": "Upper Body Strength",
            "exercises": [
                {"name": "Bench Press",            "order": 1, "group": "chest",              "sets": 4, "reps": 8,  "weight_kg": 42.50, "duration_sec": None, "distance_m": None, "notes": "Last set close to failure."},
                {"name": "One-Arm Dumbbell Row",   "order": 2, "group": "back",               "sets": 4, "reps": 10, "weight_kg": 20.00, "duration_sec": None, "distance_m": None, "notes": None},
                {"name": "Seated Shoulder Press",  "order": 3, "group": "shoulders",          "sets": 3, "reps": 10, "weight_kg": 14.00, "duration_sec": None, "distance_m": None, "notes": None},
                {"name": "Plank",                  "order": 4, "group": "core",               "sets": 3, "reps": None,"weight_kg": None, "duration_sec": 180,  "distance_m": None, "notes": "Three sixty-second holds."},
            ],
        },
        {
            "uid": uid["anna.nowak@fitrpg.dev"], "type": "mobility",
            "title": "Morning Mobility Flow", "performed_at": "2026-03-21 06:40:00",
            "duration_min": 22, "score": 8, "notes": "Short recovery-focused session.",
            "activity_category": "general", "activity_code": "mobility",
            "activity_name": "Morning Mobility Flow", "exercises": [],
        },
        # Bartek
        {
            "uid": uid["bartek.kowalski@fitrpg.dev"], "type": "cardio",
            "title": "Lunch Break Walk", "performed_at": "2026-03-20 12:15:00",
            "duration_min": 35, "score": 7, "notes": "Walked around the office district.",
            "activity_category": "general", "activity_code": "walking",
            "activity_name": "Outdoor brisk walk", "exercises": [],
        },
        # Clara
        {
            "uid": uid["clara.zielinska@fitrpg.dev"], "type": "cardio",
            "title": "5K Tempo Run", "performed_at": "2026-03-21 16:50:00",
            "duration_min": 31, "score": 9, "notes": "Sustained race-pace effort.",
            "activity_category": "general", "activity_code": "running",
            "activity_name": "5K Tempo Run", "exercises": [],
        },
        {
            "uid": uid["clara.zielinska@fitrpg.dev"], "type": "mobility",
            "title": "Recovery Stretch", "performed_at": "2026-03-22 08:10:00",
            "duration_min": 18, "score": 8, "notes": "Mobility and foam rolling.",
            "activity_category": "general", "activity_code": "stretching",
            "activity_name": "Recovery Stretch", "exercises": [],
        },
        # Diego
        {
            "uid": uid["diego.santos@fitrpg.dev"], "type": "strength",
            "title": "Beginner Gym Session", "performed_at": "2026-03-16 18:10:00",
            "duration_min": 42, "score": 6, "notes": "First gym visit in a while.",
            "activity_category": "gym", "activity_code": "beginner_gym",
            "activity_name": "Beginner Gym Session",
            "exercises": [
                {"name": "Leg Press",     "order": 1, "group": "legs",               "sets": 3, "reps": 12, "weight_kg": 80.00, "duration_sec": None, "distance_m": None,   "notes": "Conservative weight selection."},
                {"name": "Lat Pulldown",  "order": 2, "group": "back",               "sets": 3, "reps": 10, "weight_kg": 35.00, "duration_sec": None, "distance_m": None,   "notes": None},
                {"name": "Bike warm-up",  "order": 3, "group": "cardio_conditioning","sets": None,"reps": None,"weight_kg": None,"duration_sec": 600, "distance_m": 3800.00, "notes": None},
            ],
        },
        # Emilia
        {
            "uid": uid["emilia.wisniewska@fitrpg.dev"], "type": "cardio",
            "title": "Saturday Bike Ride", "performed_at": "2026-03-22 10:30:00",
            "duration_min": 74, "score": 9, "notes": "Long outdoor ride with friends.",
            "activity_category": "sport", "activity_code": "cycling",
            "activity_name": "Outdoor cycling", "exercises": [],
        },
        {
            "uid": uid["emilia.wisniewska@fitrpg.dev"], "type": "mobility",
            "title": "Pilates Core Session", "performed_at": "2026-03-22 17:20:00",
            "duration_min": 41, "score": 8, "notes": "Studio pilates class.",
            "activity_category": "general", "activity_code": "pilates",
            "activity_name": "Pilates", "exercises": [],
        },
        # Filip
        {
            "uid": uid["filip.mazur@fitrpg.dev"], "type": "strength",
            "title": "Leg Day", "performed_at": "2026-03-22 12:50:00",
            "duration_min": 67, "score": 9, "notes": "Heavy lower-body workout.",
            "activity_category": "gym", "activity_code": "leg_day",
            "activity_name": "Leg Day",
            "exercises": [
                {"name": "Back Squat",        "order": 1, "group": "legs",               "sets": 5, "reps": 5,  "weight_kg": 120.00, "duration_sec": None, "distance_m": None,   "notes": "Top set felt strong."},
                {"name": "Romanian Deadlift", "order": 2, "group": "glutes",             "sets": 4, "reps": 8,  "weight_kg": 90.00,  "duration_sec": None, "distance_m": None,   "notes": None},
                {"name": "Walking Lunges",    "order": 3, "group": "legs",               "sets": 3, "reps": 12, "weight_kg": 22.00,  "duration_sec": None, "distance_m": None,   "notes": "Per leg."},
                {"name": "Sled Push",         "order": 4, "group": "cardio_conditioning","sets": 4, "reps": None,"weight_kg": 140.00,"duration_sec": 300,  "distance_m": 120.00, "notes": "Heavy finishers."},
            ],
        },
        {
            "uid": uid["filip.mazur@fitrpg.dev"], "type": "sport",
            "title": "Basketball Scrimmage", "performed_at": "2026-03-22 18:30:00",
            "duration_min": 53, "score": 8, "notes": "Competitive full-court game.",
            "activity_category": "sport", "activity_code": "basketball",
            "activity_name": "Basketball", "exercises": [],
        },
    ]

    workout_count = 0
    exercise_count = 0
    for w in workouts:
        row = conn.execute(
            text("""
                INSERT INTO workouts
                    (user_id, workout_type, title, performed_at, duration_min,
                     health_score, notes, activity_category, activity_code,
                     activity_name, created_at)
                VALUES
                    (:uid, :type, :title, :pa, :dur,
                     :score, :notes, :ac, :acode,
                     :aname, NOW())
                RETURNING id
            """),
            {
                "uid": w["uid"], "type": w["type"], "title": w["title"],
                "pa": ts(w["performed_at"]), "dur": w["duration_min"],
                "score": w["score"], "notes": w["notes"],
                "ac": w["activity_category"], "acode": w["activity_code"],
                "aname": w["activity_name"],
            },
        ).fetchone()
        workout_id = row[0]
        workout_count += 1

        for ex in w.get("exercises", []):
            conn.execute(
                text("""
                    INSERT INTO gym_workout_exercises
                        (workout_id, exercise_name, exercise_order, exercise_group,
                         sets, reps, weight_kg, duration_sec, distance_m, notes)
                    VALUES
                        (:wid, :name, :order, :group,
                         :sets, :reps, :weight, :dur, :dist, :notes)
                """),
                {
                    "wid": workout_id, "name": ex["name"], "order": ex["order"],
                    "group": ex["group"], "sets": ex["sets"], "reps": ex["reps"],
                    "weight": ex["weight_kg"], "dur": ex["duration_sec"],
                    "dist": ex["distance_m"], "notes": ex["notes"],
                },
            )
            exercise_count += 1

    print(f"  ✓ workouts ({workout_count}), gym_workout_exercises ({exercise_count})")


def seed_user_challenges(conn, uid: dict, cid: dict):
    rows = [
        # (email, challenge_title, progress, status, completed_at, claimed_at, failed_at)
        ("anna.nowak@fitrpg.dev",        "Three Strength Sessions", 3.00, "claimed",   ts("2026-03-20 19:05:00"), ts("2026-03-20 19:10:00"), None),
        ("anna.nowak@fitrpg.dev",        "Colorful Plate Week",     4.00, "active",    None,                      None,                      None),
        ("bartek.kowalski@fitrpg.dev",   "7-Day Logging Streak",    2.00, "active",    None,                      None,                      None),
        ("clara.zielinska@fitrpg.dev",   "10K Run Distance",     10000.00, "claimed",  ts("2026-03-21 17:32:00"), ts("2026-03-21 17:40:00"), None),
        ("clara.zielinska@fitrpg.dev",   "7-Day Logging Streak",    6.00, "active",    None,                      None,                      None),
        ("diego.santos@fitrpg.dev",      "Weekend Warrior",         1.00, "failed",    None,                      None,                      ts("2026-03-22 21:00:00")),
        ("emilia.wisniewska@fitrpg.dev", "Colorful Plate Week",     5.00, "active",    None,                      None,                      None),
        ("emilia.wisniewska@fitrpg.dev", "Weekend Warrior",         2.00, "claimed",   ts("2026-03-22 18:15:00"), ts("2026-03-22 18:20:00"), None),
        ("filip.mazur@fitrpg.dev",       "Three Strength Sessions",  2.00, "active",   None,                      None,                      None),
        ("filip.mazur@fitrpg.dev",       "Hydration Habit",         4.00, "active",    None,                      None,                      None),
    ]
    for email, challenge_title, progress, status, completed_at, claimed_at, failed_at in rows:
        if challenge_title not in cid:
            continue
        conn.execute(
            text("""
                INSERT INTO user_challenges
                    (user_id, challenge_id, progress_value, status,
                     started_at, completed_at, claimed_at, failed_at)
                VALUES
                    (:uid, :cid, :progress, :status,
                     NOW(), :completed, :claimed, :failed)
                ON CONFLICT (user_id, challenge_id) DO NOTHING
            """),
            {
                "uid": uid[email], "cid": cid[challenge_title],
                "progress": progress, "status": status,
                "completed": completed_at, "claimed": claimed_at, "failed": failed_at,
            },
        )
    print(f"  ✓ user_challenges ({len(rows)})")


def seed_user_achievements(conn, uid: dict, aid: dict):
    rows = [
        # (email, code, progress, status, completed_at, claimed_at)
        ("anna.nowak@fitrpg.dev",        "FIRST_MEAL",     1.00, "claimed", ts("2026-03-20 07:37:00"), ts("2026-03-20 07:38:00")),
        ("anna.nowak@fitrpg.dev",        "FIRST_WORKOUT",  1.00, "claimed", ts("2026-03-20 19:02:00"), ts("2026-03-20 19:03:00")),
        ("anna.nowak@fitrpg.dev",        "MEAL_LOGGER_10", 3.00, "active",  None,                      None),
        ("bartek.kowalski@fitrpg.dev",   "FIRST_MEAL",     1.00, "active",  None,                      None),
        ("bartek.kowalski@fitrpg.dev",   "STREAK_7",       2.00, "active",  None,                      None),
        ("clara.zielinska@fitrpg.dev",   "FIRST_WORKOUT",  1.00, "claimed", ts("2026-03-21 17:31:00"), ts("2026-03-21 17:31:30")),
        ("clara.zielinska@fitrpg.dev",   "RUNNER_10K",  10000.00, "claimed", ts("2026-03-21 17:33:00"), ts("2026-03-21 17:45:00")),
        ("diego.santos@fitrpg.dev",      "FIRST_WORKOUT",  1.00, "active",  None,                      None),
        ("emilia.wisniewska@fitrpg.dev", "FIRST_MEAL",     1.00, "claimed", ts("2026-03-22 09:17:00"), ts("2026-03-22 09:18:00")),
        ("emilia.wisniewska@fitrpg.dev", "MEAL_LOGGER_10", 4.00, "active",  None,                      None),
        ("filip.mazur@fitrpg.dev",       "FIRST_WORKOUT",  1.00, "active",  None,                      None),
        ("filip.mazur@fitrpg.dev",       "STRENGTH_5",     5.00, "claimed", ts("2026-03-22 14:12:00"), ts("2026-03-22 14:20:00")),
    ]
    for email, code, progress, status, completed_at, claimed_at in rows:
        if code not in aid:
            continue
        conn.execute(
            text("""
                INSERT INTO user_achievements
                    (user_id, achievement_id, progress_value, status,
                     started_at, completed_at, claimed_at)
                VALUES
                    (:uid, :aid, :progress, :status,
                     NOW(), :completed, :claimed)
                ON CONFLICT (user_id, achievement_id) DO NOTHING
            """),
            {
                "uid": uid[email], "aid": aid[code],
                "progress": progress, "status": status,
                "completed": completed_at, "claimed": claimed_at,
            },
        )
    print(f"  ✓ user_achievements ({len(rows)})")


def seed_user_quests(conn, uid: dict, qid: dict):
    rows = [
        # (email, code, progress, status, completed_at, claimed_at, abandoned_at)
        ("anna.nowak@fitrpg.dev",        "ONBOARD_PROFILE",    1.00, "claimed", ts("2026-03-20 08:00:00"), ts("2026-03-20 08:05:00"), None),
        ("anna.nowak@fitrpg.dev",        "FIRST_3_MEALS",      3.00, "active",  None,                      None,                      None),
        ("clara.zielinska@fitrpg.dev",   "RUN_FOUNDATIONS_01", 1.00, "claimed", ts("2026-03-20 09:00:00"), ts("2026-03-20 09:05:00"), None),
        ("clara.zielinska@fitrpg.dev",   "RUN_FOUNDATIONS_02", 1.00, "active",  None,                      None,                      None),
        ("diego.santos@fitrpg.dev",      "FIRST_3_MEALS",      1.00, "active",  None,                      None,                      None),
        ("diego.santos@fitrpg.dev",      "CORE_RESET",         0.00, "abandoned", None,                    None,                      ts("2026-03-17 18:00:00")),
        ("emilia.wisniewska@fitrpg.dev", "CORE_RESET",         4.00, "active",  None,                      None,                      None),
        ("filip.mazur@fitrpg.dev",       "FIRST_3_MEALS",      2.00, "active",  None,                      None,                      None),
    ]
    for email, code, progress, status, completed_at, claimed_at, abandoned_at in rows:
        if code not in qid:
            continue
        conn.execute(
            text("""
                INSERT INTO user_quests
                    (user_id, quest_id, progress_value, status,
                     started_at, completed_at, claimed_at, abandoned_at)
                VALUES
                    (:uid, :qid, :progress, :status,
                     NOW(), :completed, :claimed, :abandoned)
                ON CONFLICT (user_id, quest_id) DO NOTHING
            """),
            {
                "uid": uid[email], "qid": qid[code],
                "progress": progress, "status": status,
                "completed": completed_at, "claimed": claimed_at, "abandoned": abandoned_at,
            },
        )
    print(f"  ✓ user_quests ({len(rows)})")


def seed_exp_events(conn, uid: dict):
    events = [
        # (email, source_type, amount, reason, granted_at)
        ("anna.nowak@fitrpg.dev",       "streak", 30,  "Seven-day activity streak reward.",              "2026-03-21 06:45:00"),
        ("anna.nowak@fitrpg.dev",       "meal",   10,  "Logged a high-quality breakfast.",               "2026-03-20 07:37:00"),
        ("anna.nowak@fitrpg.dev",       "meal",   15,  "Logged a balanced lunch.",                       "2026-03-20 13:13:00"),
        ("anna.nowak@fitrpg.dev",       "workout",40,  "Completed a strength workout.",                  "2026-03-20 19:01:00"),
        ("anna.nowak@fitrpg.dev",       "challenge",80,"Three Strength Sessions challenge reward.",       "2026-03-20 19:10:00"),
        ("bartek.kowalski@fitrpg.dev",  "manual", 15,  "Welcome bonus from onboarding campaign.",        "2026-03-18 08:00:00"),
        ("bartek.kowalski@fitrpg.dev",  "meal",   10,  "Logged breakfast during workday.",               "2026-03-19 06:57:00"),
        ("bartek.kowalski@fitrpg.dev",  "workout",20,  "Completed lunchtime walk.",                      "2026-03-20 12:56:00"),
        ("clara.zielinska@fitrpg.dev",  "streak", 20,  "Short consistency streak reward.",               "2026-03-22 08:40:00"),
        ("clara.zielinska@fitrpg.dev",  "meal",   12,  "Recovery meal logged after training.",           "2026-03-21 17:48:00"),
        ("clara.zielinska@fitrpg.dev",  "workout",45,  "Completed tempo run.",                           "2026-03-21 17:31:00"),
        ("clara.zielinska@fitrpg.dev",  "challenge",60,"10K Run Distance challenge reward.",             "2026-03-21 17:40:00"),
        ("diego.santos@fitrpg.dev",     "manual", -5,  "Manual correction after duplicate sync.",        "2026-03-16 19:10:00"),
        ("diego.santos@fitrpg.dev",     "meal",    5,  "Logged a meal after a long gap.",                "2026-03-15 12:36:00"),
        ("diego.santos@fitrpg.dev",     "workout",25,  "Completed return-to-gym session.",               "2026-03-16 19:01:00"),
        ("emilia.wisniewska@fitrpg.dev","meal",   14,  "Logged nutrient-dense lunch.",                   "2026-03-22 13:10:00"),
        ("emilia.wisniewska@fitrpg.dev","workout",35,  "Completed long bike ride.",                      "2026-03-22 11:56:00"),
        ("emilia.wisniewska@fitrpg.dev","challenge",50,"Weekend Warrior challenge reward.",               "2026-03-22 18:20:00"),
        ("filip.mazur@fitrpg.dev",      "meal",    8,  "Logged post-workout snack.",                     "2026-03-22 14:42:00"),
        ("filip.mazur@fitrpg.dev",      "workout",50,  "Completed heavy strength session.",              "2026-03-22 14:11:00"),
        ("filip.mazur@fitrpg.dev",      "achievement",30,"Strength Builder achievement reward.",         "2026-03-22 14:20:00"),
    ]
    for email, source_type, amount, reason, granted_at in events:
        conn.execute(
            text("""
                INSERT INTO exp_events
                    (user_id, source_type, amount, reason, granted_at, created_at)
                VALUES
                    (:uid, :st, :amount, :reason, :granted_at, NOW())
            """),
            {
                "uid": uid[email], "st": source_type,
                "amount": amount, "reason": reason,
                "granted_at": ts(granted_at),
            },
        )
    # Recompute total_exp from exp_events for each user
    conn.execute(text("""
        UPDATE user_progress up
        SET total_exp = sub.total,
            updated_at = NOW()
        FROM (
            SELECT user_id, COALESCE(SUM(amount), 0) AS total
            FROM exp_events
            GROUP BY user_id
        ) sub
        WHERE up.user_id = sub.user_id
    """))
    print(f"  ✓ exp_events ({len(events)}) + user_progress totals recalculated")


# ══════════════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════════════

def main():
    print("\n🌱 Starting FitRPG seed...\n")
    with engine.begin() as conn:
        uid  = seed_users(conn)
        seed_user_auth(conn, uid)
        seed_user_profiles(conn, uid)
        seed_user_progress(conn, uid)
        cid  = seed_challenges(conn)
        aid  = seed_achievements(conn)
        qid  = seed_quests(conn)
        seed_meals(conn, uid)
        seed_workouts(conn, uid)
        seed_user_challenges(conn, uid, cid)
        seed_user_achievements(conn, uid, aid)
        seed_user_quests(conn, uid, qid)
        seed_exp_events(conn, uid)
    print("\n✅ Seed complete.\n")


if __name__ == "__main__":
    main()

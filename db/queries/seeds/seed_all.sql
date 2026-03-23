\set ON_ERROR_STOP on

-- Wrapper for psql so the split seed files remain the single source of truth.
\ir 001_users.sql
\ir 002_user_auth_profiles.sql
\ir 003_challenges.sql
\ir 004_achievements.sql
\ir 005_meals.sql
\ir 006_quests.sql
\ir 007_workouts.sql
\ir 008_user_challenges.sql
\ir 009_user_achievements.sql
\ir 010_user_quests.sql
\ir 011_exp_grants.sql
\ir 012_user_progress_refresh.sql

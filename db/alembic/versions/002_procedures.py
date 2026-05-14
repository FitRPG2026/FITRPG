"""Add workflow procedures

Revision ID: 002
down_revision = '001'
branch_labels = None
depends_on = None
"""
from alembic import op


def upgrade() -> None:
    op.execute("""
        SET check_function_bodies = false;

        -- ══════════════════════════════════════════════
        -- proc_register_user
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_register_user(
            IN p_email character varying,
            IN p_password_hash text,
            IN p_status text DEFAULT 'active'::text
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_user_id BIGINT;
        BEGIN
            IF p_email IS NULL OR char_length(trim(p_email)) = 0 THEN
                RAISE EXCEPTION 'Email cannot be blank';
            END IF;
            IF p_password_hash IS NULL OR char_length(trim(p_password_hash)) = 0 THEN
                RAISE EXCEPTION 'Password hash cannot be blank';
            END IF;

            INSERT INTO users (email, password_hash, status)
            VALUES (trim(p_email), trim(p_password_hash), p_status)
            RETURNING id INTO v_user_id;

            INSERT INTO user_auth (user_id)
            VALUES (v_user_id);
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_mark_login
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_mark_login(
            IN p_user_id bigint,
            IN p_logged_in_at timestamp with time zone DEFAULT now()
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_last_login_at TIMESTAMPTZ;
            v_current_streak INTEGER;
            v_new_streak INTEGER;
        BEGIN
            IF p_logged_in_at IS NULL THEN
                RAISE EXCEPTION 'p_logged_in_at cannot be null';
            END IF;

            SELECT last_login_at, current_login_streak_days
            INTO v_last_login_at, v_current_streak
            FROM user_auth
            WHERE user_id = p_user_id
            FOR UPDATE;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'User auth row for user % does not exist', p_user_id;
            END IF;

            IF v_last_login_at IS NULL THEN
                v_new_streak := 1;
            ELSIF v_last_login_at::date = p_logged_in_at::date THEN
                v_new_streak := GREATEST(v_current_streak, 1);
            ELSIF v_last_login_at::date = p_logged_in_at::date - 1 THEN
                v_new_streak := v_current_streak + 1;
            ELSE
                v_new_streak := 1;
            END IF;

            UPDATE user_auth SET
                last_login_at = GREATEST(COALESCE(last_login_at, p_logged_in_at), p_logged_in_at),
                login_count   = login_count + 1,
                current_login_streak_days = v_new_streak,
                updated_at    = NOW()
            WHERE user_id = p_user_id;

            UPDATE user_progress SET
                current_login_streak_days = v_new_streak,
                longest_login_streak_days = GREATEST(longest_login_streak_days, v_new_streak),
                updated_at = NOW()
            WHERE user_id = p_user_id;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_upsert_user_profile
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_upsert_user_profile(
            IN p_user_id bigint,
            IN p_username character varying DEFAULT NULL,
            IN p_display_name character varying DEFAULT NULL,
            IN p_birth_date date DEFAULT NULL,
            IN p_gender text DEFAULT NULL,
            IN p_height_cm numeric DEFAULT NULL,
            IN p_weight_kg numeric DEFAULT NULL,
            IN p_goal text DEFAULT NULL,
            IN p_activity_level text DEFAULT NULL
        )
        LANGUAGE plpgsql AS $$
        BEGIN
            PERFORM 1 FROM users WHERE id = p_user_id;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'User % does not exist', p_user_id;
            END IF;

            INSERT INTO user_profiles (
                user_id, username, display_name, birth_date,
                gender, height_cm, weight_kg, goal, activity_level
            )
            VALUES (
                p_user_id, p_username, p_display_name, p_birth_date,
                p_gender, p_height_cm, p_weight_kg, p_goal, p_activity_level
            )
            ON CONFLICT (user_id) DO UPDATE SET
                username       = EXCLUDED.username,
                display_name   = EXCLUDED.display_name,
                birth_date     = EXCLUDED.birth_date,
                gender         = EXCLUDED.gender,
                height_cm      = EXCLUDED.height_cm,
                weight_kg      = EXCLUDED.weight_kg,
                goal           = EXCLUDED.goal,
                activity_level = EXCLUDED.activity_level,
                updated_at     = NOW();
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_grant_exp
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_grant_exp(
            IN p_user_id bigint,
            IN p_source_type text,
            IN p_source_id bigint,
            IN p_exp_amount integer,
            IN p_reason text DEFAULT NULL,
            IN p_created_at timestamp with time zone DEFAULT now(),
            IN p_last_activity_at timestamp with time zone DEFAULT NULL
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_total_exp INTEGER;
            v_activity_date DATE := COALESCE(p_last_activity_at, p_created_at)::date;
        BEGIN
            IF p_exp_amount = 0 THEN
                RAISE EXCEPTION 'EXP amount cannot be zero';
            END IF;

            PERFORM 1 FROM users WHERE id = p_user_id;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'User % does not exist', p_user_id;
            END IF;

            SELECT total_exp INTO v_total_exp
            FROM user_progress WHERE user_id = p_user_id FOR UPDATE;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'User progress row for user % does not exist', p_user_id;
            END IF;

            IF v_total_exp + p_exp_amount < 0 THEN
                RAISE EXCEPTION 'Applying % EXP would make total_exp negative for user %', p_exp_amount, p_user_id;
            END IF;

            INSERT INTO exp_events (user_id, source_type, source_id, amount, reason, granted_at, created_at)
            VALUES (p_user_id, p_source_type, p_source_id, p_exp_amount, p_reason, p_created_at, p_created_at);

            UPDATE user_progress SET
                total_exp          = total_exp + p_exp_amount,
                last_activity_date = GREATEST(COALESCE(last_activity_date, v_activity_date), v_activity_date),
                updated_at         = NOW()
            WHERE user_id = p_user_id;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_log_meal
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_log_meal(
            IN p_user_id bigint,
            IN p_meal_type text DEFAULT NULL,
            IN p_eaten_at timestamp with time zone DEFAULT now(),
            IN p_title character varying DEFAULT NULL,
            IN p_photo_url text DEFAULT NULL,
            IN p_notes text DEFAULT NULL,
            IN p_health_score smallint DEFAULT NULL,
            IN p_ai_confidence numeric DEFAULT NULL,
            IN p_grant_exp boolean DEFAULT false,
            IN p_exp_amount integer DEFAULT NULL,
            IN p_exp_reason text DEFAULT NULL,
            IN p_exp_created_at timestamp with time zone DEFAULT NULL
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_meal_id BIGINT;
        BEGIN
            PERFORM 1 FROM users WHERE id = p_user_id;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'User % does not exist', p_user_id;
            END IF;

            IF p_grant_exp AND p_exp_amount IS NULL THEN
                RAISE EXCEPTION 'p_exp_amount is required when p_grant_exp is true';
            END IF;

            INSERT INTO meals (user_id, meal_type, eaten_at, title, photo_url, notes, health_score, ai_confidence)
            VALUES (p_user_id, p_meal_type, p_eaten_at, p_title, p_photo_url, p_notes, p_health_score, p_ai_confidence)
            RETURNING id INTO v_meal_id;

            UPDATE user_progress SET
                last_activity_date = GREATEST(COALESCE(last_activity_date, p_eaten_at::date), p_eaten_at::date),
                updated_at         = NOW()
            WHERE user_id = p_user_id;

            IF p_grant_exp THEN
                CALL proc_grant_exp(
                    p_user_id, 'meal', v_meal_id, p_exp_amount,
                    COALESCE(p_exp_reason, 'Meal logged'),
                    COALESCE(p_exp_created_at, p_eaten_at),
                    p_eaten_at
                );
            END IF;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_log_workout
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_log_workout(
            IN p_user_id bigint,
            IN p_workout_type text DEFAULT NULL,
            IN p_title character varying DEFAULT NULL,
            IN p_performed_at timestamp with time zone DEFAULT now(),
            IN p_duration_min integer DEFAULT NULL,
            IN p_health_score smallint DEFAULT NULL,
            IN p_notes text DEFAULT NULL,
            IN p_exercises jsonb DEFAULT '[]'::jsonb,
            IN p_grant_exp boolean DEFAULT false,
            IN p_exp_amount integer DEFAULT NULL,
            IN p_exp_reason text DEFAULT NULL,
            IN p_exp_created_at timestamp with time zone DEFAULT NULL,
            IN p_activity_category text DEFAULT NULL,
            IN p_activity_code character varying DEFAULT NULL,
            IN p_activity_name character varying DEFAULT NULL
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_exercises JSONB := COALESCE(p_exercises, '[]'::jsonb);
            v_workout_id BIGINT;
            v_activity_category TEXT;
        BEGIN
            PERFORM 1 FROM users WHERE id = p_user_id;
            IF NOT FOUND THEN
                RAISE EXCEPTION 'User % does not exist', p_user_id;
            END IF;

            IF jsonb_typeof(v_exercises) <> 'array' THEN
                RAISE EXCEPTION 'Workout exercises payload must be a JSON array';
            END IF;

            IF p_grant_exp AND p_exp_amount IS NULL THEN
                RAISE EXCEPTION 'p_exp_amount is required when p_grant_exp is true';
            END IF;

            v_activity_category := COALESCE(p_activity_category,
                CASE
                    WHEN p_workout_type = 'strength' THEN 'gym'
                    WHEN p_workout_type = 'sport'    THEN 'sport'
                    WHEN p_workout_type IN ('cardio', 'mobility') THEN 'general'
                    ELSE 'other'
                END
            );

            INSERT INTO workouts (
                user_id, workout_type, title, performed_at, duration_min,
                health_score, notes, activity_category, activity_code, activity_name
            )
            VALUES (
                p_user_id, p_workout_type, p_title, p_performed_at, p_duration_min,
                p_health_score, p_notes, v_activity_category, p_activity_code,
                COALESCE(p_activity_name, p_title)
            )
            RETURNING id INTO v_workout_id;

            IF jsonb_array_length(v_exercises) > 0 THEN
                INSERT INTO gym_workout_exercises (
                    workout_id, exercise_name, exercise_order, exercise_group,
                    sets, reps, weight_kg, duration_sec, distance_m, notes
                )
                SELECT
                    v_workout_id,
                    e.exercise_name, e.exercise_order, e.exercise_group,
                    e.sets, e.reps, e.weight_kg, e.duration_sec, e.distance_m, e.notes
                FROM jsonb_to_recordset(v_exercises) AS e(
                    exercise_name VARCHAR(255), exercise_order INTEGER,
                    exercise_group VARCHAR(60), sets INTEGER, reps INTEGER,
                    weight_kg NUMERIC(6,2), duration_sec INTEGER,
                    distance_m NUMERIC(8,2), notes TEXT
                );
            END IF;

            UPDATE user_progress SET
                last_activity_date = GREATEST(COALESCE(last_activity_date, p_performed_at::date), p_performed_at::date),
                updated_at         = NOW()
            WHERE user_id = p_user_id;

            IF p_grant_exp THEN
                CALL proc_grant_exp(
                    p_user_id, 'workout', v_workout_id, p_exp_amount,
                    COALESCE(p_exp_reason, 'Workout logged'),
                    COALESCE(p_exp_created_at, p_performed_at),
                    p_performed_at
                );
            END IF;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_create_challenge
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_create_challenge(
            IN p_title character varying,
            IN p_description text DEFAULT NULL,
            IN p_challenge_type text DEFAULT NULL,
            IN p_goal_value numeric DEFAULT NULL,
            IN p_reward_exp integer DEFAULT 0,
            IN p_start_date timestamp with time zone DEFAULT NULL,
            IN p_end_date timestamp with time zone DEFAULT NULL,
            IN p_created_at timestamp with time zone DEFAULT now(),
            IN p_mechanic_type text DEFAULT 'accumulation',
            IN p_event_trigger text DEFAULT 'manual',
            IN p_conditions jsonb DEFAULT '{}'::jsonb
        )
        LANGUAGE plpgsql AS $$
        BEGIN
            INSERT INTO challenges (
                title, description, challenge_type, goal_value, reward_exp,
                start_date, end_date, created_at, mechanic_type, event_trigger, conditions
            )
            VALUES (
                p_title, p_description, p_challenge_type, p_goal_value, p_reward_exp,
                p_start_date, p_end_date, p_created_at,
                COALESCE(p_mechanic_type, 'accumulation'),
                COALESCE(p_event_trigger, 'manual'),
                COALESCE(p_conditions, '{}'::jsonb)
            );
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_join_challenge
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_join_challenge(
            IN p_user_id bigint,
            IN p_challenge_id bigint,
            IN p_joined_at timestamp with time zone DEFAULT now()
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_start_date TIMESTAMPTZ;
            v_end_date   TIMESTAMPTZ;
        BEGIN
            PERFORM 1 FROM users WHERE id = p_user_id;
            IF NOT FOUND THEN RAISE EXCEPTION 'User % does not exist', p_user_id; END IF;

            SELECT start_date, end_date INTO v_start_date, v_end_date
            FROM challenges WHERE id = p_challenge_id;
            IF NOT FOUND THEN RAISE EXCEPTION 'Challenge % does not exist', p_challenge_id; END IF;

            IF v_start_date IS NOT NULL AND p_joined_at < v_start_date THEN
                RAISE EXCEPTION 'Cannot join challenge % before its start date', p_challenge_id;
            END IF;
            IF v_end_date IS NOT NULL AND p_joined_at > v_end_date THEN
                RAISE EXCEPTION 'Cannot join challenge % after its end date', p_challenge_id;
            END IF;

            INSERT INTO user_challenges (user_id, challenge_id, started_at)
            VALUES (p_user_id, p_challenge_id, p_joined_at)
            ON CONFLICT (user_id, challenge_id) DO NOTHING;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_update_challenge_progress
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_update_challenge_progress(
            IN p_user_id bigint,
            IN p_challenge_id bigint,
            IN p_progress_delta numeric DEFAULT NULL,
            IN p_progress_value numeric DEFAULT NULL,
            IN p_progress_at timestamp with time zone DEFAULT now(),
            IN p_progress_state jsonb DEFAULT NULL
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_uc_id          BIGINT;
            v_current        NUMERIC(12,2);
            v_goal_value     NUMERIC(12,2);
            v_status         TEXT;
            v_completed_at   TIMESTAMPTZ;
            v_new_progress   NUMERIC(12,2);
        BEGIN
            IF p_progress_delta IS NULL AND p_progress_value IS NULL THEN
                RAISE EXCEPTION 'Provide either p_progress_delta or p_progress_value';
            END IF;

            CALL proc_join_challenge(p_user_id, p_challenge_id, p_progress_at);

            SELECT uc.id, uc.progress_value, uc.status, uc.completed_at, c.goal_value
            INTO v_uc_id, v_current, v_status, v_completed_at, v_goal_value
            FROM user_challenges uc
            JOIN challenges c ON c.id = uc.challenge_id
            WHERE uc.user_id = p_user_id AND uc.challenge_id = p_challenge_id
            FOR UPDATE;

            IF v_status = 'claimed' THEN RETURN; END IF;
            IF v_status = 'failed' THEN
                RAISE EXCEPTION 'Challenge % for user % is failed', p_challenge_id, p_user_id;
            END IF;

            v_new_progress := COALESCE(p_progress_value, v_current + p_progress_delta);
            IF v_new_progress < 0 THEN RAISE EXCEPTION 'Challenge progress cannot be negative'; END IF;

            UPDATE user_challenges SET
                progress_value = v_new_progress,
                status = CASE
                    WHEN v_status = 'completed' THEN 'completed'
                    WHEN v_goal_value IS NOT NULL AND v_new_progress >= v_goal_value THEN 'completed'
                    ELSE 'active'
                END,
                completed_at = CASE
                    WHEN v_completed_at IS NOT NULL THEN v_completed_at
                    WHEN v_goal_value IS NOT NULL AND v_new_progress >= v_goal_value THEN p_progress_at
                    ELSE NULL
                END
            WHERE id = v_uc_id;

            UPDATE user_progress SET
                last_activity_date = GREATEST(COALESCE(last_activity_date, p_progress_at::date), p_progress_at::date),
                updated_at = NOW()
            WHERE user_id = p_user_id;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_claim_challenge_reward
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_claim_challenge_reward(
            IN p_user_id bigint,
            IN p_challenge_id bigint,
            IN p_claimed_at timestamp with time zone DEFAULT now()
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_uc_id        BIGINT;
            v_progress     NUMERIC(12,2);
            v_goal_value   NUMERIC(12,2);
            v_completed_at TIMESTAMPTZ;
            v_claimed_at   TIMESTAMPTZ;
            v_reward_exp   INTEGER;
            v_title        VARCHAR(100);
        BEGIN
            SELECT uc.id, uc.progress_value, uc.completed_at, uc.claimed_at,
                c.goal_value, c.reward_exp, c.title
            INTO v_uc_id, v_progress, v_completed_at, v_claimed_at, v_goal_value, v_reward_exp, v_title
            FROM user_challenges uc
            JOIN challenges c ON c.id = uc.challenge_id
            WHERE uc.user_id = p_user_id AND uc.challenge_id = p_challenge_id
            FOR UPDATE;

            IF NOT FOUND THEN RAISE EXCEPTION 'User % is not joined to challenge %', p_user_id, p_challenge_id; END IF;
            IF v_claimed_at IS NOT NULL THEN RETURN; END IF;
            IF v_completed_at IS NULL AND (v_goal_value IS NULL OR v_progress < v_goal_value) THEN
                RAISE EXCEPTION 'Challenge % is not completed for user %', p_challenge_id, p_user_id;
            END IF;

            UPDATE user_challenges SET
                status = 'claimed',
                completed_at = COALESCE(completed_at, p_claimed_at),
                claimed_at = p_claimed_at
            WHERE id = v_uc_id;

            IF v_reward_exp > 0 THEN
                CALL proc_grant_exp(p_user_id, 'challenge', p_challenge_id, v_reward_exp,
                    format('Claimed challenge reward: %s', v_title), p_claimed_at, p_claimed_at);
            END IF;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_fail_challenge
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_fail_challenge(
            IN p_user_id bigint,
            IN p_challenge_id bigint,
            IN p_failed_at timestamp with time zone DEFAULT now()
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_uc_id      BIGINT;
            v_claimed_at TIMESTAMPTZ;
        BEGIN
            SELECT uc.id, uc.claimed_at INTO v_uc_id, v_claimed_at
            FROM user_challenges uc
            WHERE uc.user_id = p_user_id AND uc.challenge_id = p_challenge_id
            FOR UPDATE;

            IF NOT FOUND THEN RAISE EXCEPTION 'User % is not joined to challenge %', p_user_id, p_challenge_id; END IF;
            IF v_claimed_at IS NOT NULL THEN
                RAISE EXCEPTION 'Claimed challenge % for user % cannot be failed', p_challenge_id, p_user_id;
            END IF;

            UPDATE user_challenges SET
                status = 'failed',
                failed_at = p_failed_at
            WHERE id = v_uc_id;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_create_achievement
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_create_achievement(
            IN p_code character varying,
            IN p_title character varying,
            IN p_description text DEFAULT NULL,
            IN p_achievement_type text DEFAULT NULL,
            IN p_target_value numeric DEFAULT NULL,
            IN p_reward_exp integer DEFAULT 0,
            IN p_icon_url text DEFAULT NULL,
            IN p_created_at timestamp with time zone DEFAULT now(),
            IN p_mechanic_type text DEFAULT 'accumulation',
            IN p_event_trigger text DEFAULT 'manual',
            IN p_conditions jsonb DEFAULT '{}'::jsonb
        )
        LANGUAGE plpgsql AS $$
        BEGIN
            IF p_target_value IS NULL OR p_target_value <= 0 THEN
                RAISE EXCEPTION 'Achievement target_value must be provided and greater than zero';
            END IF;

            INSERT INTO achievements (
                code, title, description, achievement_type, target_value,
                reward_exp, icon_url, created_at, mechanic_type, event_trigger, conditions
            )
            VALUES (
                p_code, p_title, p_description, p_achievement_type, p_target_value,
                p_reward_exp, p_icon_url, p_created_at,
                COALESCE(p_mechanic_type, 'accumulation'),
                COALESCE(p_event_trigger, 'manual'),
                COALESCE(p_conditions, '{}'::jsonb)
            )
            ON CONFLICT (code) DO UPDATE SET
                title            = EXCLUDED.title,
                description      = EXCLUDED.description,
                achievement_type = EXCLUDED.achievement_type,
                target_value     = EXCLUDED.target_value,
                reward_exp       = EXCLUDED.reward_exp,
                icon_url         = EXCLUDED.icon_url,
                mechanic_type    = EXCLUDED.mechanic_type,
                event_trigger    = EXCLUDED.event_trigger,
                conditions       = EXCLUDED.conditions;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_join_achievement
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_join_achievement(
            IN p_user_id bigint,
            IN p_achievement_id bigint,
            IN p_joined_at timestamp with time zone DEFAULT now()
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_target_value NUMERIC(12,2);
        BEGIN
            PERFORM 1 FROM users WHERE id = p_user_id;
            IF NOT FOUND THEN RAISE EXCEPTION 'User % does not exist', p_user_id; END IF;

            SELECT target_value INTO v_target_value FROM achievements WHERE id = p_achievement_id;
            IF NOT FOUND THEN RAISE EXCEPTION 'Achievement % does not exist', p_achievement_id; END IF;
            IF v_target_value IS NULL OR v_target_value <= 0 THEN
                RAISE EXCEPTION 'Achievement % has no valid target_value', p_achievement_id;
            END IF;

            INSERT INTO user_achievements (user_id, achievement_id, started_at)
            VALUES (p_user_id, p_achievement_id, p_joined_at)
            ON CONFLICT (user_id, achievement_id) DO NOTHING;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_update_achievement_progress
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_update_achievement_progress(
            IN p_user_id bigint,
            IN p_achievement_id bigint,
            IN p_progress_delta numeric DEFAULT NULL,
            IN p_progress_value numeric DEFAULT NULL,
            IN p_progress_at timestamp with time zone DEFAULT now(),
            IN p_progress_state jsonb DEFAULT NULL
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_ua_id        BIGINT;
            v_current      NUMERIC(12,2);
            v_target_value NUMERIC(12,2);
            v_completed_at TIMESTAMPTZ;
            v_claimed_at   TIMESTAMPTZ;
            v_new_progress NUMERIC(12,2);
        BEGIN
            IF p_progress_delta IS NULL AND p_progress_value IS NULL THEN
                RAISE EXCEPTION 'Provide either p_progress_delta or p_progress_value';
            END IF;

            SELECT ua.id, ua.progress_value, ua.completed_at, ua.claimed_at, a.target_value
            INTO v_ua_id, v_current, v_completed_at, v_claimed_at, v_target_value
            FROM user_achievements ua
            JOIN achievements a ON a.id = ua.achievement_id
            WHERE ua.user_id = p_user_id AND ua.achievement_id = p_achievement_id
            FOR UPDATE;

            IF NOT FOUND THEN
                RAISE EXCEPTION 'User % has not joined achievement %', p_user_id, p_achievement_id;
            END IF;
            IF v_claimed_at IS NOT NULL THEN RETURN; END IF;

            v_new_progress := COALESCE(p_progress_value, v_current + p_progress_delta);
            IF v_new_progress < 0 THEN RAISE EXCEPTION 'Achievement progress cannot be negative'; END IF;

            UPDATE user_achievements SET
                progress_value = GREATEST(progress_value, v_new_progress),
                completed_at = CASE
                    WHEN completed_at IS NOT NULL THEN completed_at
                    WHEN v_new_progress >= v_target_value THEN p_progress_at
                    ELSE NULL
                END
            WHERE id = v_ua_id;

            UPDATE user_progress SET
                last_activity_date = GREATEST(COALESCE(last_activity_date, p_progress_at::date), p_progress_at::date),
                updated_at = NOW()
            WHERE user_id = p_user_id;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_claim_achievement_reward
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_claim_achievement_reward(
            IN p_user_id bigint,
            IN p_achievement_id bigint,
            IN p_claimed_at timestamp with time zone DEFAULT now()
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_ua_id        BIGINT;
            v_progress     NUMERIC(12,2);
            v_target_value NUMERIC(12,2);
            v_completed_at TIMESTAMPTZ;
            v_claimed_at   TIMESTAMPTZ;
            v_reward_exp   INTEGER;
            v_title        VARCHAR(100);
        BEGIN
            SELECT ua.id, ua.progress_value, ua.completed_at, ua.claimed_at,
                a.target_value, a.reward_exp, a.title
            INTO v_ua_id, v_progress, v_completed_at, v_claimed_at, v_target_value, v_reward_exp, v_title
            FROM user_achievements ua
            JOIN achievements a ON a.id = ua.achievement_id
            WHERE ua.user_id = p_user_id AND ua.achievement_id = p_achievement_id
            FOR UPDATE;

            IF NOT FOUND THEN RAISE EXCEPTION 'User % does not have achievement row %', p_user_id, p_achievement_id; END IF;
            IF v_claimed_at IS NOT NULL THEN RETURN; END IF;
            IF v_completed_at IS NULL AND (v_target_value IS NULL OR v_progress < v_target_value) THEN
                RAISE EXCEPTION 'Achievement % is not unlocked for user %', p_achievement_id, p_user_id;
            END IF;

            UPDATE user_achievements SET
                completed_at = COALESCE(completed_at, p_claimed_at),
                claimed_at   = p_claimed_at
            WHERE id = v_ua_id;

            IF v_reward_exp > 0 THEN
                CALL proc_grant_exp(p_user_id, 'achievement', p_achievement_id, v_reward_exp,
                    format('Claimed achievement reward: %s', v_title), p_claimed_at, p_claimed_at);
            END IF;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_create_quest
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_create_quest(
            IN p_code character varying,
            IN p_title character varying,
            IN p_description text DEFAULT NULL,
            IN p_quest_type text DEFAULT NULL,
            IN p_progression_mode text DEFAULT 'standalone',
            IN p_quest_series_code character varying DEFAULT NULL,
            IN p_sequence_order integer DEFAULT NULL,
            IN p_target_value numeric DEFAULT NULL,
            IN p_reward_exp integer DEFAULT 0,
            IN p_created_at timestamp with time zone DEFAULT now(),
            IN p_mechanic_type text DEFAULT 'accumulation',
            IN p_event_trigger text DEFAULT 'manual',
            IN p_conditions jsonb DEFAULT '{}'::jsonb
        )
        LANGUAGE plpgsql AS $$
        BEGIN
            INSERT INTO quests (
                code, title, description, quest_type, progression_mode,
                quest_series_code, sequence_order, target_value, reward_exp,
                created_at, mechanic_type, event_trigger, conditions
            )
            VALUES (
                p_code, p_title, p_description, p_quest_type, p_progression_mode,
                p_quest_series_code, p_sequence_order, p_target_value, p_reward_exp,
                p_created_at,
                COALESCE(p_mechanic_type, 'accumulation'),
                COALESCE(p_event_trigger, 'manual'),
                COALESCE(p_conditions, '{}'::jsonb)
            )
            ON CONFLICT (code) DO UPDATE SET
                title             = EXCLUDED.title,
                description       = EXCLUDED.description,
                quest_type        = EXCLUDED.quest_type,
                progression_mode  = EXCLUDED.progression_mode,
                quest_series_code = EXCLUDED.quest_series_code,
                sequence_order    = EXCLUDED.sequence_order,
                target_value      = EXCLUDED.target_value,
                reward_exp        = EXCLUDED.reward_exp,
                mechanic_type     = EXCLUDED.mechanic_type,
                event_trigger     = EXCLUDED.event_trigger,
                conditions        = EXCLUDED.conditions;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_start_quest
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_start_quest(
            IN p_user_id bigint,
            IN p_quest_id bigint,
            IN p_started_at timestamp with time zone DEFAULT now()
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_progression_mode   TEXT;
            v_quest_series_code  VARCHAR(80);
            v_sequence_order     INTEGER;
            v_previous_quest_id  BIGINT;
            v_previous_completed TIMESTAMPTZ;
        BEGIN
            PERFORM 1 FROM users WHERE id = p_user_id;
            IF NOT FOUND THEN RAISE EXCEPTION 'User % does not exist', p_user_id; END IF;

            SELECT progression_mode, quest_series_code, sequence_order
            INTO v_progression_mode, v_quest_series_code, v_sequence_order
            FROM quests WHERE id = p_quest_id;
            IF NOT FOUND THEN RAISE EXCEPTION 'Quest % does not exist', p_quest_id; END IF;

            IF v_progression_mode = 'linear' THEN
                SELECT id INTO v_previous_quest_id
                FROM quests
                WHERE quest_series_code = v_quest_series_code
                AND sequence_order < v_sequence_order
                ORDER BY sequence_order DESC LIMIT 1;

                IF v_previous_quest_id IS NOT NULL THEN
                    SELECT completed_at INTO v_previous_completed
                    FROM user_quests
                    WHERE user_id = p_user_id AND quest_id = v_previous_quest_id;

                    IF v_previous_completed IS NULL THEN
                        RAISE EXCEPTION 'User % must complete previous quest % before starting %',
                            p_user_id, v_previous_quest_id, p_quest_id;
                    END IF;
                END IF;
            END IF;

            INSERT INTO user_quests (user_id, quest_id, started_at)
            VALUES (p_user_id, p_quest_id, p_started_at)
            ON CONFLICT (user_id, quest_id) DO NOTHING;

            UPDATE user_progress SET
                last_activity_date = GREATEST(COALESCE(last_activity_date, p_started_at::date), p_started_at::date),
                updated_at = NOW()
            WHERE user_id = p_user_id;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_update_quest_progress
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_update_quest_progress(
            IN p_user_id bigint,
            IN p_quest_id bigint,
            IN p_progress_delta numeric DEFAULT NULL,
            IN p_progress_value numeric DEFAULT NULL,
            IN p_progress_at timestamp with time zone DEFAULT now(),
            IN p_progress_state jsonb DEFAULT NULL
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_uq_id        BIGINT;
            v_current      NUMERIC(12,2);
            v_target_value NUMERIC(12,2);
            v_status       TEXT;
            v_completed_at TIMESTAMPTZ;
            v_new_progress NUMERIC(12,2);
        BEGIN
            IF p_progress_delta IS NULL AND p_progress_value IS NULL THEN
                RAISE EXCEPTION 'Provide either p_progress_delta or p_progress_value';
            END IF;

            CALL proc_start_quest(p_user_id, p_quest_id, p_progress_at);

            SELECT uq.id, uq.progress_value, uq.status, uq.completed_at, q.target_value
            INTO v_uq_id, v_current, v_status, v_completed_at, v_target_value
            FROM user_quests uq
            JOIN quests q ON q.id = uq.quest_id
            WHERE uq.user_id = p_user_id AND uq.quest_id = p_quest_id
            FOR UPDATE;

            IF v_status = 'claimed'   THEN RETURN; END IF;
            IF v_status = 'abandoned' THEN
                RAISE EXCEPTION 'Quest % for user % is abandoned', p_quest_id, p_user_id;
            END IF;

            v_new_progress := COALESCE(p_progress_value, v_current + p_progress_delta);
            IF v_new_progress < 0 THEN RAISE EXCEPTION 'Quest progress cannot be negative'; END IF;

            UPDATE user_quests SET
                progress_value = v_new_progress,
                status = CASE
                    WHEN v_status = 'completed' THEN 'completed'
                    WHEN v_target_value IS NOT NULL AND v_new_progress >= v_target_value THEN 'completed'
                    ELSE 'active'
                END,
                completed_at = CASE
                    WHEN v_completed_at IS NOT NULL THEN v_completed_at
                    WHEN v_target_value IS NOT NULL AND v_new_progress >= v_target_value THEN p_progress_at
                    ELSE NULL
                END
            WHERE id = v_uq_id;

            UPDATE user_progress SET
                last_activity_date = GREATEST(COALESCE(last_activity_date, p_progress_at::date), p_progress_at::date),
                updated_at = NOW()
            WHERE user_id = p_user_id;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_claim_quest_reward
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_claim_quest_reward(
            IN p_user_id bigint,
            IN p_quest_id bigint,
            IN p_claimed_at timestamp with time zone DEFAULT now()
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_uq_id        BIGINT;
            v_progress     NUMERIC(12,2);
            v_target_value NUMERIC(12,2);
            v_completed_at TIMESTAMPTZ;
            v_claimed_at   TIMESTAMPTZ;
            v_reward_exp   INTEGER;
            v_title        VARCHAR(255);
        BEGIN
            SELECT uq.id, uq.progress_value, uq.completed_at, uq.claimed_at,
                q.target_value, q.reward_exp, q.title
            INTO v_uq_id, v_progress, v_completed_at, v_claimed_at, v_target_value, v_reward_exp, v_title
            FROM user_quests uq
            JOIN quests q ON q.id = uq.quest_id
            WHERE uq.user_id = p_user_id AND uq.quest_id = p_quest_id
            FOR UPDATE;

            IF NOT FOUND THEN RAISE EXCEPTION 'User % does not have quest row %', p_user_id, p_quest_id; END IF;
            IF v_claimed_at IS NOT NULL THEN RETURN; END IF;
            IF v_completed_at IS NULL AND (v_target_value IS NULL OR v_progress < v_target_value) THEN
                RAISE EXCEPTION 'Quest % is not completed for user %', p_quest_id, p_user_id;
            END IF;

            UPDATE user_quests SET
                status       = 'claimed',
                completed_at = COALESCE(completed_at, p_claimed_at),
                claimed_at   = p_claimed_at
            WHERE id = v_uq_id;

            IF v_reward_exp > 0 THEN
                CALL proc_grant_exp(p_user_id, 'quest', p_quest_id, v_reward_exp,
                    format('Claimed quest reward: %s', v_title), p_claimed_at, p_claimed_at);
            END IF;
        END;
        $$;

        -- ══════════════════════════════════════════════
        -- proc_abandon_quest
        -- ══════════════════════════════════════════════
        CREATE OR REPLACE PROCEDURE public.proc_abandon_quest(
            IN p_user_id bigint,
            IN p_quest_id bigint,
            IN p_abandoned_at timestamp with time zone DEFAULT now()
        )
        LANGUAGE plpgsql AS $$
        DECLARE
            v_uq_id      BIGINT;
            v_claimed_at TIMESTAMPTZ;
        BEGIN
            SELECT uq.id, uq.claimed_at INTO v_uq_id, v_claimed_at
            FROM user_quests uq
            WHERE uq.user_id = p_user_id AND uq.quest_id = p_quest_id
            FOR UPDATE;

            IF NOT FOUND THEN RAISE EXCEPTION 'User % does not have quest row %', p_user_id, p_quest_id; END IF;
            IF v_claimed_at IS NOT NULL THEN
                RAISE EXCEPTION 'Claimed quest % for user % cannot be abandoned', p_quest_id, p_user_id;
            END IF;

            UPDATE user_quests SET
                status       = 'abandoned',
                completed_at = NULL,
                claimed_at   = NULL,
                abandoned_at = p_abandoned_at
            WHERE id = v_uq_id;
        END;
        $$;

        SET check_function_bodies = true;
    """)


def downgrade() -> None:
    op.execute("""
    DROP PROCEDURE IF EXISTS proc_register_user;
    DROP PROCEDURE IF EXISTS proc_mark_login;
    DROP PROCEDURE IF EXISTS proc_upsert_user_profile;
    DROP PROCEDURE IF EXISTS proc_grant_exp;
    DROP PROCEDURE IF EXISTS proc_log_meal;
    DROP PROCEDURE IF EXISTS proc_log_workout;
    DROP PROCEDURE IF EXISTS proc_create_challenge;
    DROP PROCEDURE IF EXISTS proc_join_challenge;
    DROP PROCEDURE IF EXISTS proc_update_challenge_progress;
    DROP PROCEDURE IF EXISTS proc_claim_challenge_reward;
    DROP PROCEDURE IF EXISTS proc_fail_challenge;
    DROP PROCEDURE IF EXISTS proc_create_achievement;
    DROP PROCEDURE IF EXISTS proc_join_achievement;
    DROP PROCEDURE IF EXISTS proc_update_achievement_progress;
    DROP PROCEDURE IF EXISTS proc_claim_achievement_reward;
    DROP PROCEDURE IF EXISTS proc_create_quest;
    DROP PROCEDURE IF EXISTS proc_start_quest;
    DROP PROCEDURE IF EXISTS proc_update_quest_progress;
    DROP PROCEDURE IF EXISTS proc_claim_quest_reward;
    DROP PROCEDURE IF EXISTS proc_abandon_quest;
    """)
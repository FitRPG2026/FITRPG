-- Event-driven progression rule metadata.
-- These columns let the backend fetch only definitions that match the event it is
-- currently handling, then evaluate flexible JSONB conditions in application code.

ALTER TABLE challenges
ADD COLUMN IF NOT EXISTS mechanic_type TEXT NOT NULL DEFAULT 'accumulation',
ADD COLUMN IF NOT EXISTS event_trigger TEXT NOT NULL DEFAULT 'manual',
ADD COLUMN IF NOT EXISTS conditions JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE achievements
ADD COLUMN IF NOT EXISTS mechanic_type TEXT NOT NULL DEFAULT 'accumulation',
ADD COLUMN IF NOT EXISTS event_trigger TEXT NOT NULL DEFAULT 'manual',
ADD COLUMN IF NOT EXISTS conditions JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE quests
ADD COLUMN IF NOT EXISTS mechanic_type TEXT NOT NULL DEFAULT 'accumulation',
ADD COLUMN IF NOT EXISTS event_trigger TEXT NOT NULL DEFAULT 'manual',
ADD COLUMN IF NOT EXISTS conditions JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE user_challenges
ADD COLUMN IF NOT EXISTS last_progress_at TIMESTAMPTZ;

ALTER TABLE user_achievements
ADD COLUMN IF NOT EXISTS last_progress_at TIMESTAMPTZ;

ALTER TABLE user_auth
ADD COLUMN IF NOT EXISTS last_login_date DATE,
ADD COLUMN IF NOT EXISTS current_login_streak_days INTEGER NOT NULL DEFAULT 0,
ADD COLUMN IF NOT EXISTS longest_login_streak_days INTEGER NOT NULL DEFAULT 0;

UPDATE user_auth
SET
    last_login_date = COALESCE(last_login_date, last_login_at::date),
    current_login_streak_days = CASE
        WHEN last_login_at IS NULL THEN current_login_streak_days
        ELSE GREATEST(current_login_streak_days, 1)
    END,
    longest_login_streak_days = CASE
        WHEN last_login_at IS NULL THEN longest_login_streak_days
        ELSE GREATEST(longest_login_streak_days, current_login_streak_days, 1)
    END;

ALTER TABLE challenges
DROP CONSTRAINT IF EXISTS challenges_mechanic_type_check;

ALTER TABLE challenges
ADD CONSTRAINT challenges_mechanic_type_check
    CHECK (mechanic_type IN ('threshold', 'accumulation', 'streak'));

ALTER TABLE achievements
DROP CONSTRAINT IF EXISTS achievements_mechanic_type_check;

ALTER TABLE achievements
ADD CONSTRAINT achievements_mechanic_type_check
    CHECK (mechanic_type IN ('threshold', 'accumulation', 'streak'));

ALTER TABLE quests
DROP CONSTRAINT IF EXISTS quests_mechanic_type_check;

ALTER TABLE quests
ADD CONSTRAINT quests_mechanic_type_check
    CHECK (mechanic_type IN ('threshold', 'accumulation', 'streak'));

ALTER TABLE challenges
DROP CONSTRAINT IF EXISTS challenges_event_trigger_check;

ALTER TABLE challenges
ADD CONSTRAINT challenges_event_trigger_check
    CHECK (event_trigger IN (
        'manual',
        'login',
        'profile_completed',
        'meal_logged',
        'workout_logged',
        'activity_logged',
        'hydration_logged',
        'quest_step_completed',
        'progress_recomputed'
    ));

ALTER TABLE achievements
DROP CONSTRAINT IF EXISTS achievements_event_trigger_check;

ALTER TABLE achievements
ADD CONSTRAINT achievements_event_trigger_check
    CHECK (event_trigger IN (
        'manual',
        'login',
        'profile_completed',
        'meal_logged',
        'workout_logged',
        'activity_logged',
        'hydration_logged',
        'quest_step_completed',
        'progress_recomputed'
    ));

ALTER TABLE quests
DROP CONSTRAINT IF EXISTS quests_event_trigger_check;

ALTER TABLE quests
ADD CONSTRAINT quests_event_trigger_check
    CHECK (event_trigger IN (
        'manual',
        'login',
        'profile_completed',
        'meal_logged',
        'workout_logged',
        'activity_logged',
        'hydration_logged',
        'quest_step_completed',
        'progress_recomputed'
    ));

ALTER TABLE challenges
DROP CONSTRAINT IF EXISTS challenges_conditions_object_check;

ALTER TABLE challenges
ADD CONSTRAINT challenges_conditions_object_check
    CHECK (jsonb_typeof(conditions) = 'object');

ALTER TABLE achievements
DROP CONSTRAINT IF EXISTS achievements_conditions_object_check;

ALTER TABLE achievements
ADD CONSTRAINT achievements_conditions_object_check
    CHECK (jsonb_typeof(conditions) = 'object');

ALTER TABLE quests
DROP CONSTRAINT IF EXISTS quests_conditions_object_check;

ALTER TABLE quests
ADD CONSTRAINT quests_conditions_object_check
    CHECK (jsonb_typeof(conditions) = 'object');

ALTER TABLE user_challenges
DROP CONSTRAINT IF EXISTS user_challenges_last_progress_after_joined_check;

ALTER TABLE user_challenges
ADD CONSTRAINT user_challenges_last_progress_after_joined_check
    CHECK (last_progress_at IS NULL OR last_progress_at >= joined_at);

ALTER TABLE user_achievements
DROP CONSTRAINT IF EXISTS user_achievements_last_progress_after_joined_check;

ALTER TABLE user_achievements
ADD CONSTRAINT user_achievements_last_progress_after_joined_check
    CHECK (last_progress_at IS NULL OR last_progress_at >= joined_at);

ALTER TABLE user_auth
DROP CONSTRAINT IF EXISTS user_auth_login_streak_check;

ALTER TABLE user_auth
ADD CONSTRAINT user_auth_login_streak_check
    CHECK (
        current_login_streak_days >= 0
        AND longest_login_streak_days >= current_login_streak_days
    );

CREATE INDEX IF NOT EXISTS challenges_event_trigger_idx
    ON challenges(event_trigger, mechanic_type);

CREATE INDEX IF NOT EXISTS achievements_event_trigger_idx
    ON achievements(event_trigger, mechanic_type);

CREATE INDEX IF NOT EXISTS quests_event_trigger_idx
    ON quests(event_trigger, mechanic_type);

CREATE INDEX IF NOT EXISTS challenges_conditions_gin_idx
    ON challenges USING GIN (conditions);

CREATE INDEX IF NOT EXISTS achievements_conditions_gin_idx
    ON achievements USING GIN (conditions);

CREATE INDEX IF NOT EXISTS quests_conditions_gin_idx
    ON quests USING GIN (conditions);

CREATE INDEX IF NOT EXISTS user_challenges_last_progress_idx
    ON user_challenges(user_id, last_progress_at DESC);

CREATE INDEX IF NOT EXISTS user_achievements_last_progress_idx
    ON user_achievements(user_id, last_progress_at DESC);

DROP PROCEDURE IF EXISTS proc_mark_login(BIGINT, TIMESTAMPTZ);

CREATE OR REPLACE PROCEDURE proc_mark_login(
    IN p_user_id BIGINT,
    IN p_logged_in_at TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_previous_login_date DATE;
    v_current_login_streak_days INTEGER;
    v_login_date DATE;
    v_new_login_streak_days INTEGER;
BEGIN
    IF p_logged_in_at IS NULL THEN
        RAISE EXCEPTION 'p_logged_in_at cannot be null';
    END IF;

    v_login_date := p_logged_in_at::date;

    SELECT
        last_login_date,
        current_login_streak_days
    INTO
        v_previous_login_date,
        v_current_login_streak_days
    FROM user_auth
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User auth row for user % does not exist', p_user_id;
    END IF;

    IF v_previous_login_date IS NULL THEN
        v_new_login_streak_days := 1;
    ELSIF v_login_date < v_previous_login_date THEN
        v_new_login_streak_days := v_current_login_streak_days;
    ELSIF v_login_date = v_previous_login_date THEN
        v_new_login_streak_days := GREATEST(v_current_login_streak_days, 1);
    ELSIF v_login_date = v_previous_login_date + 1 THEN
        v_new_login_streak_days := v_current_login_streak_days + 1;
    ELSE
        v_new_login_streak_days := 1;
    END IF;

    UPDATE user_auth
    SET
        last_login_at = CASE
            WHEN last_login_at IS NULL THEN p_logged_in_at
            ELSE GREATEST(last_login_at, p_logged_in_at)
        END,
        last_login_date = CASE
            WHEN last_login_date IS NULL THEN v_login_date
            ELSE GREATEST(last_login_date, v_login_date)
        END,
        current_login_streak_days = v_new_login_streak_days,
        longest_login_streak_days = GREATEST(longest_login_streak_days, v_new_login_streak_days)
    WHERE user_id = p_user_id;
END;
$$;

DROP PROCEDURE IF EXISTS proc_create_challenge(
    VARCHAR,
    TEXT,
    TEXT,
    NUMERIC,
    INTEGER,
    TIMESTAMPTZ,
    TIMESTAMPTZ,
    TIMESTAMPTZ
);

CREATE OR REPLACE PROCEDURE proc_create_challenge(
    IN p_title VARCHAR(100),
    IN p_description TEXT DEFAULT NULL,
    IN p_challenge_type TEXT DEFAULT NULL,
    IN p_goal_value NUMERIC(10,2) DEFAULT NULL,
    IN p_reward_exp INTEGER DEFAULT 0,
    IN p_start_date TIMESTAMPTZ DEFAULT NULL,
    IN p_end_date TIMESTAMPTZ DEFAULT NULL,
    IN p_created_at TIMESTAMPTZ DEFAULT NOW(),
    IN p_mechanic_type TEXT DEFAULT 'accumulation',
    IN p_event_trigger TEXT DEFAULT 'manual',
    IN p_conditions JSONB DEFAULT '{}'::jsonb
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO challenges (
        title,
        description,
        challenge_type,
        goal_value,
        reward_exp,
        start_date,
        end_date,
        created_at,
        mechanic_type,
        event_trigger,
        conditions
    )
    VALUES (
        p_title,
        p_description,
        p_challenge_type,
        p_goal_value,
        p_reward_exp,
        p_start_date,
        p_end_date,
        p_created_at,
        COALESCE(p_mechanic_type, 'accumulation'),
        COALESCE(p_event_trigger, 'manual'),
        COALESCE(p_conditions, '{}'::jsonb)
    );
END;
$$;

DROP PROCEDURE IF EXISTS proc_create_achievement(
    VARCHAR,
    VARCHAR,
    TEXT,
    TEXT,
    NUMERIC,
    INTEGER,
    TEXT,
    TIMESTAMPTZ
);

CREATE OR REPLACE PROCEDURE proc_create_achievement(
    IN p_code VARCHAR(50),
    IN p_title VARCHAR(100),
    IN p_description TEXT DEFAULT NULL,
    IN p_achievement_type TEXT DEFAULT NULL,
    IN p_target_value NUMERIC(10,2) DEFAULT NULL,
    IN p_reward_exp INTEGER DEFAULT 0,
    IN p_icon_url TEXT DEFAULT NULL,
    IN p_created_at TIMESTAMPTZ DEFAULT NOW(),
    IN p_mechanic_type TEXT DEFAULT 'accumulation',
    IN p_event_trigger TEXT DEFAULT 'manual',
    IN p_conditions JSONB DEFAULT '{}'::jsonb
)
LANGUAGE plpgsql
AS $$
BEGIN
    IF p_target_value IS NULL OR p_target_value <= 0 THEN
        RAISE EXCEPTION 'Achievement target_value must be provided and greater than zero';
    END IF;

    INSERT INTO achievements (
        code,
        title,
        description,
        achievement_type,
        target_value,
        reward_exp,
        icon_url,
        created_at,
        mechanic_type,
        event_trigger,
        conditions
    )
    VALUES (
        p_code,
        p_title,
        p_description,
        p_achievement_type,
        p_target_value,
        p_reward_exp,
        p_icon_url,
        p_created_at,
        COALESCE(p_mechanic_type, 'accumulation'),
        COALESCE(p_event_trigger, 'manual'),
        COALESCE(p_conditions, '{}'::jsonb)
    )
    ON CONFLICT (code) DO UPDATE
    SET
        title = EXCLUDED.title,
        description = EXCLUDED.description,
        achievement_type = EXCLUDED.achievement_type,
        target_value = EXCLUDED.target_value,
        reward_exp = EXCLUDED.reward_exp,
        icon_url = EXCLUDED.icon_url,
        mechanic_type = EXCLUDED.mechanic_type,
        event_trigger = EXCLUDED.event_trigger,
        conditions = EXCLUDED.conditions;
END;
$$;

DROP PROCEDURE IF EXISTS proc_create_quest(
    VARCHAR,
    VARCHAR,
    TEXT,
    TEXT,
    TEXT,
    VARCHAR,
    INTEGER,
    NUMERIC,
    INTEGER,
    TIMESTAMPTZ
);

CREATE OR REPLACE PROCEDURE proc_create_quest(
    IN p_code VARCHAR(50),
    IN p_title VARCHAR(100),
    IN p_description TEXT DEFAULT NULL,
    IN p_quest_type TEXT DEFAULT NULL,
    IN p_progression_mode TEXT DEFAULT 'standalone',
    IN p_quest_series_code VARCHAR(50) DEFAULT NULL,
    IN p_sequence_order INTEGER DEFAULT NULL,
    IN p_target_value NUMERIC(10,2) DEFAULT NULL,
    IN p_reward_exp INTEGER DEFAULT 0,
    IN p_created_at TIMESTAMPTZ DEFAULT NOW(),
    IN p_mechanic_type TEXT DEFAULT 'accumulation',
    IN p_event_trigger TEXT DEFAULT 'manual',
    IN p_conditions JSONB DEFAULT '{}'::jsonb
)
LANGUAGE plpgsql
AS $$
BEGIN
    INSERT INTO quests (
        code,
        title,
        description,
        quest_type,
        progression_mode,
        quest_series_code,
        sequence_order,
        target_value,
        reward_exp,
        created_at,
        mechanic_type,
        event_trigger,
        conditions
    )
    VALUES (
        p_code,
        p_title,
        p_description,
        p_quest_type,
        p_progression_mode,
        p_quest_series_code,
        p_sequence_order,
        p_target_value,
        p_reward_exp,
        p_created_at,
        COALESCE(p_mechanic_type, 'accumulation'),
        COALESCE(p_event_trigger, 'manual'),
        COALESCE(p_conditions, '{}'::jsonb)
    )
    ON CONFLICT (code) DO UPDATE
    SET
        title = EXCLUDED.title,
        description = EXCLUDED.description,
        quest_type = EXCLUDED.quest_type,
        progression_mode = EXCLUDED.progression_mode,
        quest_series_code = EXCLUDED.quest_series_code,
        sequence_order = EXCLUDED.sequence_order,
        target_value = EXCLUDED.target_value,
        reward_exp = EXCLUDED.reward_exp,
        mechanic_type = EXCLUDED.mechanic_type,
        event_trigger = EXCLUDED.event_trigger,
        conditions = EXCLUDED.conditions;
END;
$$;

CREATE OR REPLACE PROCEDURE proc_update_challenge_progress(
    IN p_user_id BIGINT,
    IN p_challenge_id BIGINT,
    IN p_progress_delta NUMERIC(10,2) DEFAULT NULL,
    IN p_progress_value NUMERIC(10,2) DEFAULT NULL,
    IN p_progress_at TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_challenge_id BIGINT;
    v_current_progress NUMERIC(10,2);
    v_goal_value NUMERIC(10,2);
    v_status TEXT;
    v_completed_at TIMESTAMPTZ;
    v_new_progress NUMERIC(10,2);
BEGIN
    IF p_progress_delta IS NULL AND p_progress_value IS NULL THEN
        RAISE EXCEPTION 'Provide either p_progress_delta or p_progress_value';
    END IF;

    IF p_progress_delta IS NOT NULL AND p_progress_value IS NOT NULL THEN
        RAISE EXCEPTION 'Provide only one of p_progress_delta or p_progress_value';
    END IF;

    CALL proc_join_challenge(
        p_user_id,
        p_challenge_id,
        p_progress_at
    );

    SELECT
        uc.id,
        uc.progress_value,
        uc.status,
        uc.completed_at,
        c.goal_value
    INTO
        v_user_challenge_id,
        v_current_progress,
        v_status,
        v_completed_at,
        v_goal_value
    FROM user_challenges uc
    JOIN challenges c ON c.id = uc.challenge_id
    WHERE uc.user_id = p_user_id
      AND uc.challenge_id = p_challenge_id
    FOR UPDATE;

    IF v_status = 'claimed' THEN
        RETURN;
    END IF;

    IF v_status = 'failed' THEN
        RAISE EXCEPTION 'Challenge % for user % is failed and cannot be progressed', p_challenge_id, p_user_id;
    END IF;

    v_new_progress := COALESCE(p_progress_value, v_current_progress + p_progress_delta);

    IF v_new_progress < 0 THEN
        RAISE EXCEPTION 'Challenge progress cannot be negative';
    END IF;

    UPDATE user_challenges
    SET
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
        END,
        last_progress_at = p_progress_at
    WHERE id = v_user_challenge_id;

    UPDATE user_progress
    SET
        last_activity_at = CASE
            WHEN last_activity_at IS NULL THEN p_progress_at
            ELSE GREATEST(last_activity_at, p_progress_at)
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$;

CREATE OR REPLACE PROCEDURE proc_update_achievement_progress(
    IN p_user_id BIGINT,
    IN p_achievement_id BIGINT,
    IN p_progress_delta NUMERIC(10,2) DEFAULT NULL,
    IN p_progress_value NUMERIC(10,2) DEFAULT NULL,
    IN p_progress_at TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_achievement_id BIGINT;
    v_current_progress NUMERIC(10,2);
    v_target_value NUMERIC(10,2);
    v_unlocked_at TIMESTAMPTZ;
    v_claimed_at TIMESTAMPTZ;
    v_new_progress NUMERIC(10,2);
BEGIN
    IF p_progress_delta IS NULL AND p_progress_value IS NULL THEN
        RAISE EXCEPTION 'Provide either p_progress_delta or p_progress_value';
    END IF;

    IF p_progress_delta IS NOT NULL AND p_progress_value IS NOT NULL THEN
        RAISE EXCEPTION 'Provide only one of p_progress_delta or p_progress_value';
    END IF;

    PERFORM 1
    FROM users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id;
    END IF;

    SELECT
        ua.id,
        ua.progress_value,
        ua.unlocked_at,
        ua.claimed_at,
        a.target_value
    INTO
        v_user_achievement_id,
        v_current_progress,
        v_unlocked_at,
        v_claimed_at,
        v_target_value
    FROM user_achievements ua
    JOIN achievements a ON a.id = ua.achievement_id
    WHERE ua.user_id = p_user_id
      AND ua.achievement_id = p_achievement_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % has not joined achievement %', p_user_id, p_achievement_id;
    END IF;

    IF v_target_value IS NULL OR v_target_value <= 0 THEN
        RAISE EXCEPTION 'Achievement % has no valid target_value', p_achievement_id;
    END IF;

    IF v_claimed_at IS NOT NULL THEN
        RETURN;
    END IF;

    v_new_progress := COALESCE(p_progress_value, v_current_progress + p_progress_delta);

    IF v_new_progress < 0 THEN
        RAISE EXCEPTION 'Achievement progress cannot be negative';
    END IF;

    UPDATE user_achievements
    SET
        progress_value = GREATEST(progress_value, v_new_progress),
        unlocked_at = CASE
            WHEN unlocked_at IS NOT NULL THEN unlocked_at
            WHEN v_new_progress >= v_target_value THEN p_progress_at
            ELSE NULL
        END,
        claimed_at = claimed_at,
        last_progress_at = p_progress_at
    WHERE id = v_user_achievement_id;

    UPDATE user_progress
    SET
        last_activity_at = CASE
            WHEN last_activity_at IS NULL THEN p_progress_at
            ELSE GREATEST(last_activity_at, p_progress_at)
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$;

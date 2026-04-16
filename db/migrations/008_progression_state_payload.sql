-- Optional per-user progression state for compound definitions.
-- `progress_value` remains the numeric value used for completion checks.
-- `progress_state` stores backend-owned details such as seen sport codes,
-- exercise-group coverage, streak anchors, or per-activity counters.

ALTER TABLE user_challenges
ADD COLUMN IF NOT EXISTS progress_state JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE user_achievements
ADD COLUMN IF NOT EXISTS progress_state JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE user_quests
ADD COLUMN IF NOT EXISTS progress_state JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE user_challenges
DROP CONSTRAINT IF EXISTS user_challenges_progress_state_object_check;

ALTER TABLE user_challenges
ADD CONSTRAINT user_challenges_progress_state_object_check
    CHECK (jsonb_typeof(progress_state) = 'object');

ALTER TABLE user_achievements
DROP CONSTRAINT IF EXISTS user_achievements_progress_state_object_check;

ALTER TABLE user_achievements
ADD CONSTRAINT user_achievements_progress_state_object_check
    CHECK (jsonb_typeof(progress_state) = 'object');

ALTER TABLE user_quests
DROP CONSTRAINT IF EXISTS user_quests_progress_state_object_check;

ALTER TABLE user_quests
ADD CONSTRAINT user_quests_progress_state_object_check
    CHECK (jsonb_typeof(progress_state) = 'object');

CREATE INDEX IF NOT EXISTS user_challenges_progress_state_gin_idx
    ON user_challenges USING GIN (progress_state);

CREATE INDEX IF NOT EXISTS user_achievements_progress_state_gin_idx
    ON user_achievements USING GIN (progress_state);

CREATE INDEX IF NOT EXISTS user_quests_progress_state_gin_idx
    ON user_quests USING GIN (progress_state);

DROP PROCEDURE IF EXISTS proc_update_challenge_progress(
    BIGINT,
    BIGINT,
    NUMERIC,
    NUMERIC,
    TIMESTAMPTZ
);

CREATE OR REPLACE PROCEDURE proc_update_challenge_progress(
    IN p_user_id BIGINT,
    IN p_challenge_id BIGINT,
    IN p_progress_delta NUMERIC(10,2) DEFAULT NULL,
    IN p_progress_value NUMERIC(10,2) DEFAULT NULL,
    IN p_progress_at TIMESTAMPTZ DEFAULT NOW(),
    IN p_progress_state JSONB DEFAULT NULL
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

    IF p_progress_state IS NOT NULL AND jsonb_typeof(p_progress_state) <> 'object' THEN
        RAISE EXCEPTION 'p_progress_state must be a JSON object';
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
        progress_state = COALESCE(p_progress_state, progress_state),
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

DROP PROCEDURE IF EXISTS proc_update_achievement_progress(
    BIGINT,
    BIGINT,
    NUMERIC,
    NUMERIC,
    TIMESTAMPTZ
);

CREATE OR REPLACE PROCEDURE proc_update_achievement_progress(
    IN p_user_id BIGINT,
    IN p_achievement_id BIGINT,
    IN p_progress_delta NUMERIC(10,2) DEFAULT NULL,
    IN p_progress_value NUMERIC(10,2) DEFAULT NULL,
    IN p_progress_at TIMESTAMPTZ DEFAULT NOW(),
    IN p_progress_state JSONB DEFAULT NULL
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

    IF p_progress_state IS NOT NULL AND jsonb_typeof(p_progress_state) <> 'object' THEN
        RAISE EXCEPTION 'p_progress_state must be a JSON object';
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
        progress_state = COALESCE(p_progress_state, progress_state),
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

DROP PROCEDURE IF EXISTS proc_update_quest_progress(
    BIGINT,
    BIGINT,
    NUMERIC,
    NUMERIC,
    TIMESTAMPTZ
);

CREATE OR REPLACE PROCEDURE proc_update_quest_progress(
    IN p_user_id BIGINT,
    IN p_quest_id BIGINT,
    IN p_progress_delta NUMERIC(10,2) DEFAULT NULL,
    IN p_progress_value NUMERIC(10,2) DEFAULT NULL,
    IN p_progress_at TIMESTAMPTZ DEFAULT NOW(),
    IN p_progress_state JSONB DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_quest_id BIGINT;
    v_current_progress NUMERIC(10,2);
    v_target_value NUMERIC(10,2);
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

    IF p_progress_state IS NOT NULL AND jsonb_typeof(p_progress_state) <> 'object' THEN
        RAISE EXCEPTION 'p_progress_state must be a JSON object';
    END IF;

    CALL proc_start_quest(
        p_user_id,
        p_quest_id,
        p_progress_at
    );

    SELECT
        uq.id,
        uq.progress_value,
        uq.status,
        uq.completed_at,
        q.target_value
    INTO
        v_user_quest_id,
        v_current_progress,
        v_status,
        v_completed_at,
        v_target_value
    FROM user_quests uq
    JOIN quests q ON q.id = uq.quest_id
    WHERE uq.user_id = p_user_id
      AND uq.quest_id = p_quest_id
    FOR UPDATE;

    IF v_status = 'claimed' THEN
        RETURN;
    END IF;

    IF v_status = 'abandoned' THEN
        RAISE EXCEPTION 'Quest % for user % is abandoned and cannot be progressed', p_quest_id, p_user_id;
    END IF;

    v_new_progress := COALESCE(p_progress_value, v_current_progress + p_progress_delta);

    IF v_new_progress < 0 THEN
        RAISE EXCEPTION 'Quest progress cannot be negative';
    END IF;

    UPDATE user_quests
    SET
        progress_value = v_new_progress,
        progress_state = COALESCE(p_progress_state, progress_state),
        status = CASE
            WHEN v_status = 'completed' THEN 'completed'
            WHEN v_target_value IS NOT NULL AND v_new_progress >= v_target_value THEN 'completed'
            ELSE 'active'
        END,
        completed_at = CASE
            WHEN v_completed_at IS NOT NULL THEN v_completed_at
            WHEN v_target_value IS NOT NULL AND v_new_progress >= v_target_value THEN p_progress_at
            ELSE NULL
        END,
        last_progress_at = p_progress_at
    WHERE id = v_user_quest_id;

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

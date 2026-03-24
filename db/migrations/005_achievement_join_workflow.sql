-- Achievement workflow adjustments:
-- - add explicit joined_at tracking for user achievements
-- - require achievements to define target_value before users can join/progress them
-- - require explicit join before progress updates

ALTER TABLE user_achievements
ADD COLUMN IF NOT EXISTS joined_at TIMESTAMPTZ;

UPDATE user_achievements
SET joined_at = COALESCE(joined_at, unlocked_at, claimed_at, NOW())
WHERE joined_at IS NULL;

ALTER TABLE user_achievements
ALTER COLUMN joined_at SET DEFAULT NOW();

ALTER TABLE user_achievements
ALTER COLUMN joined_at SET NOT NULL;

ALTER TABLE user_achievements
DROP CONSTRAINT IF EXISTS user_achievements_unlocked_after_joined_check;

ALTER TABLE user_achievements
ADD CONSTRAINT user_achievements_unlocked_after_joined_check
    CHECK (unlocked_at IS NULL OR unlocked_at >= joined_at);

CREATE INDEX IF NOT EXISTS user_achievements_user_joined_idx
ON user_achievements(user_id, joined_at DESC);

CREATE OR REPLACE PROCEDURE proc_create_achievement(
    IN p_code VARCHAR(50),
    IN p_title VARCHAR(100),
    IN p_description TEXT DEFAULT NULL,
    IN p_achievement_type TEXT DEFAULT NULL,
    IN p_target_value NUMERIC(10,2) DEFAULT NULL,
    IN p_reward_exp INTEGER DEFAULT 0,
    IN p_icon_url TEXT DEFAULT NULL,
    IN p_created_at TIMESTAMPTZ DEFAULT NOW()
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
        created_at
    )
    VALUES (
        p_code,
        p_title,
        p_description,
        p_achievement_type,
        p_target_value,
        p_reward_exp,
        p_icon_url,
        p_created_at
    )
    ON CONFLICT (code) DO UPDATE
    SET
        title = EXCLUDED.title,
        description = EXCLUDED.description,
        achievement_type = EXCLUDED.achievement_type,
        target_value = EXCLUDED.target_value,
        reward_exp = EXCLUDED.reward_exp,
        icon_url = EXCLUDED.icon_url;
END;
$$;

CREATE OR REPLACE PROCEDURE proc_join_achievement(
    IN p_user_id BIGINT,
    IN p_achievement_id BIGINT,
    IN p_joined_at TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_target_value NUMERIC(10,2);
BEGIN
    PERFORM 1
    FROM users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id;
    END IF;

    SELECT target_value
    INTO v_target_value
    FROM achievements
    WHERE id = p_achievement_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Achievement % does not exist', p_achievement_id;
    END IF;

    IF v_target_value IS NULL OR v_target_value <= 0 THEN
        RAISE EXCEPTION 'Achievement % has no valid target_value', p_achievement_id;
    END IF;

    INSERT INTO user_achievements (
        user_id,
        achievement_id,
        joined_at
    )
    VALUES (
        p_user_id,
        p_achievement_id,
        p_joined_at
    )
    ON CONFLICT (user_id, achievement_id) DO NOTHING;
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
        claimed_at = claimed_at
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

-- Workflow procedures for quest creation and per-user quest progression.

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
    IN p_created_at TIMESTAMPTZ DEFAULT NOW()
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
        created_at
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
        p_created_at
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
        reward_exp = EXCLUDED.reward_exp;
END;
$$;

CREATE OR REPLACE PROCEDURE proc_start_quest(
    IN p_user_id BIGINT,
    IN p_quest_id BIGINT,
    IN p_started_at TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_quest_id BIGINT;
    v_progression_mode TEXT;
    v_quest_series_code VARCHAR(50);
    v_sequence_order INTEGER;
    v_previous_quest_id BIGINT;
    v_previous_completed_at TIMESTAMPTZ;
BEGIN
    PERFORM 1
    FROM users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id;
    END IF;

    SELECT
        progression_mode,
        quest_series_code,
        sequence_order
    INTO
        v_progression_mode,
        v_quest_series_code,
        v_sequence_order
    FROM quests
    WHERE id = p_quest_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Quest % does not exist', p_quest_id;
    END IF;

    IF v_progression_mode = 'linear' THEN
        SELECT id
        INTO v_previous_quest_id
        FROM quests
        WHERE quest_series_code = v_quest_series_code
          AND sequence_order < v_sequence_order
        ORDER BY sequence_order DESC
        LIMIT 1;

        IF v_previous_quest_id IS NOT NULL THEN
            SELECT completed_at
            INTO v_previous_completed_at
            FROM user_quests
            WHERE user_id = p_user_id
              AND quest_id = v_previous_quest_id;

            IF v_previous_completed_at IS NULL THEN
                RAISE EXCEPTION 'User % must complete previous quest % before starting quest %', p_user_id, v_previous_quest_id, p_quest_id;
            END IF;
        END IF;
    END IF;

    INSERT INTO user_quests (
        user_id,
        quest_id,
        started_at,
        last_progress_at
    )
    VALUES (
        p_user_id,
        p_quest_id,
        p_started_at,
        p_started_at
    )
    ON CONFLICT (user_id, quest_id) DO NOTHING
    RETURNING id INTO v_user_quest_id;

    IF v_user_quest_id IS NULL THEN
        SELECT id
        INTO v_user_quest_id
        FROM user_quests
        WHERE user_id = p_user_id
          AND quest_id = p_quest_id;
    END IF;

    UPDATE user_progress
    SET
        last_activity_at = CASE
            WHEN last_activity_at IS NULL THEN p_started_at
            ELSE GREATEST(last_activity_at, p_started_at)
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$;

CREATE OR REPLACE PROCEDURE proc_update_quest_progress(
    IN p_user_id BIGINT,
    IN p_quest_id BIGINT,
    IN p_progress_delta NUMERIC(10,2) DEFAULT NULL,
    IN p_progress_value NUMERIC(10,2) DEFAULT NULL,
    IN p_progress_at TIMESTAMPTZ DEFAULT NOW()
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

CREATE OR REPLACE PROCEDURE proc_claim_quest_reward(
    IN p_user_id BIGINT,
    IN p_quest_id BIGINT,
    IN p_claimed_at TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_quest_id BIGINT;
    v_progress_value NUMERIC(10,2);
    v_target_value NUMERIC(10,2);
    v_completed_at TIMESTAMPTZ;
    v_claimed_at TIMESTAMPTZ;
    v_reward_exp INTEGER;
    v_title VARCHAR(100);
BEGIN
    SELECT
        uq.id,
        uq.progress_value,
        uq.completed_at,
        uq.claimed_at,
        q.target_value,
        q.reward_exp,
        q.title
    INTO
        v_user_quest_id,
        v_progress_value,
        v_completed_at,
        v_claimed_at,
        v_target_value,
        v_reward_exp,
        v_title
    FROM user_quests uq
    JOIN quests q ON q.id = uq.quest_id
    WHERE uq.user_id = p_user_id
      AND uq.quest_id = p_quest_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not have quest row %', p_user_id, p_quest_id;
    END IF;

    IF v_claimed_at IS NOT NULL THEN
        RETURN;
    END IF;

    IF v_completed_at IS NULL
       AND (v_target_value IS NULL OR v_progress_value < v_target_value) THEN
        RAISE EXCEPTION 'Quest % is not completed for user %', p_quest_id, p_user_id;
    END IF;

    UPDATE user_quests
    SET
        status = 'claimed',
        completed_at = COALESCE(completed_at, p_claimed_at),
        claimed_at = p_claimed_at
    WHERE id = v_user_quest_id;

    IF v_reward_exp > 0 THEN
        CALL proc_grant_exp(
            p_user_id,
            'quest',
            p_quest_id,
            v_reward_exp,
            format('Claimed quest reward: %s', v_title),
            p_claimed_at,
            p_claimed_at
        );
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE proc_abandon_quest(
    IN p_user_id BIGINT,
    IN p_quest_id BIGINT,
    IN p_abandoned_at TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_quest_id BIGINT;
    v_claimed_at TIMESTAMPTZ;
BEGIN
    SELECT
        uq.id,
        uq.claimed_at
    INTO
        v_user_quest_id,
        v_claimed_at
    FROM user_quests uq
    WHERE uq.user_id = p_user_id
      AND uq.quest_id = p_quest_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not have quest row %', p_user_id, p_quest_id;
    END IF;

    IF v_claimed_at IS NOT NULL THEN
        RAISE EXCEPTION 'Claimed quest % for user % cannot be abandoned', p_quest_id, p_user_id;
    END IF;

    UPDATE user_quests
    SET
        status = 'abandoned',
        completed_at = NULL,
        claimed_at = NULL,
        last_progress_at = p_abandoned_at
    WHERE id = v_user_quest_id;

    UPDATE user_progress
    SET
        last_activity_at = CASE
            WHEN last_activity_at IS NULL THEN p_abandoned_at
            ELSE GREATEST(last_activity_at, p_abandoned_at)
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$;

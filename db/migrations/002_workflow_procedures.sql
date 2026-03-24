-- Workflow procedures for multi-table writes.
-- User level is backend-derived from total_exp and is no longer stored in user_progress.

ALTER TABLE user_progress
DROP COLUMN IF EXISTS level;

CREATE OR REPLACE PROCEDURE proc_grant_exp(
    IN p_user_id BIGINT,
    IN p_source_type TEXT,
    IN p_source_id BIGINT,
    IN p_exp_amount INTEGER,
    IN p_reason TEXT DEFAULT NULL,
    IN p_created_at TIMESTAMPTZ DEFAULT NOW(),
    IN p_last_activity_at TIMESTAMPTZ DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_exp INTEGER;
    v_effective_activity_at TIMESTAMPTZ := COALESCE(p_last_activity_at, p_created_at);
BEGIN
    IF p_exp_amount = 0 THEN
        RAISE EXCEPTION 'EXP amount cannot be zero';
    END IF;

    PERFORM 1
    FROM users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id;
    END IF;

    SELECT total_exp
    INTO v_total_exp
    FROM user_progress
    WHERE user_id = p_user_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User progress row for user % does not exist', p_user_id;
    END IF;

    IF v_total_exp + p_exp_amount < 0 THEN
        RAISE EXCEPTION 'Applying % EXP would make total_exp negative for user %', p_exp_amount, p_user_id;
    END IF;

    INSERT INTO exp_events (
        user_id,
        source_type,
        source_id,
        exp_amount,
        reason,
        created_at
    )
    VALUES (
        p_user_id,
        p_source_type,
        p_source_id,
        p_exp_amount,
        p_reason,
        p_created_at
    );

    UPDATE user_progress
    SET
        total_exp = total_exp + p_exp_amount,
        last_activity_at = CASE
            WHEN v_effective_activity_at IS NULL THEN last_activity_at
            WHEN last_activity_at IS NULL THEN v_effective_activity_at
            ELSE GREATEST(last_activity_at, v_effective_activity_at)
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$;

CREATE OR REPLACE PROCEDURE proc_upsert_user_profile(
    IN p_user_id BIGINT,
    IN p_username VARCHAR(30) DEFAULT NULL,
    IN p_display_name VARCHAR(50) DEFAULT NULL,
    IN p_birth_date DATE DEFAULT NULL,
    IN p_sex TEXT DEFAULT NULL,
    IN p_height_cm NUMERIC(5,2) DEFAULT NULL,
    IN p_weight_kg NUMERIC(5,2) DEFAULT NULL,
    IN p_goal TEXT DEFAULT NULL,
    IN p_activity_level TEXT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
BEGIN
    PERFORM 1
    FROM users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id;
    END IF;

    INSERT INTO user_profiles (
        user_id,
        username,
        display_name,
        birth_date,
        sex,
        height_cm,
        weight_kg,
        goal,
        activity_level
    )
    VALUES (
        p_user_id,
        p_username,
        p_display_name,
        p_birth_date,
        p_sex,
        p_height_cm,
        p_weight_kg,
        p_goal,
        p_activity_level
    )
    ON CONFLICT (user_id) DO UPDATE
    SET
        username = EXCLUDED.username,
        display_name = EXCLUDED.display_name,
        birth_date = EXCLUDED.birth_date,
        sex = EXCLUDED.sex,
        height_cm = EXCLUDED.height_cm,
        weight_kg = EXCLUDED.weight_kg,
        goal = EXCLUDED.goal,
        activity_level = EXCLUDED.activity_level,
        updated_at = NOW();
END;
$$;

CREATE OR REPLACE PROCEDURE proc_mark_login(
    IN p_user_id BIGINT,
    IN p_logged_in_at TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
BEGIN
    UPDATE user_auth
    SET last_login_at = p_logged_in_at
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User auth row for user % does not exist', p_user_id;
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE proc_create_challenge(
    IN p_title VARCHAR(100),
    IN p_description TEXT DEFAULT NULL,
    IN p_challenge_type TEXT DEFAULT NULL,
    IN p_goal_value NUMERIC(10,2) DEFAULT NULL,
    IN p_reward_exp INTEGER DEFAULT 0,
    IN p_start_date TIMESTAMPTZ DEFAULT NULL,
    IN p_end_date TIMESTAMPTZ DEFAULT NULL,
    IN p_created_at TIMESTAMPTZ DEFAULT NOW()
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
        created_at
    )
    VALUES (
        p_title,
        p_description,
        p_challenge_type,
        p_goal_value,
        p_reward_exp,
        p_start_date,
        p_end_date,
        p_created_at
    );
END;
$$;

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

CREATE OR REPLACE PROCEDURE proc_log_meal(
    IN p_user_id BIGINT,
    IN p_meal_type TEXT DEFAULT NULL,
    IN p_eaten_at TIMESTAMPTZ DEFAULT NOW(),
    IN p_title VARCHAR(100) DEFAULT NULL,
    IN p_photo_url TEXT DEFAULT NULL,
    IN p_notes TEXT DEFAULT NULL,
    IN p_health_score SMALLINT DEFAULT NULL,
    IN p_ai_confidence NUMERIC(4,3) DEFAULT NULL,
    IN p_total_calories NUMERIC(8,2) DEFAULT NULL,
    IN p_total_protein_g NUMERIC(8,2) DEFAULT NULL,
    IN p_total_carbs_g NUMERIC(8,2) DEFAULT NULL,
    IN p_total_fat_g NUMERIC(8,2) DEFAULT NULL,
    IN p_items JSONB DEFAULT '[]'::jsonb,
    IN p_grant_exp BOOLEAN DEFAULT FALSE,
    IN p_exp_amount INTEGER DEFAULT NULL,
    IN p_exp_reason TEXT DEFAULT NULL,
    IN p_exp_created_at TIMESTAMPTZ DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_items JSONB := COALESCE(p_items, '[]'::jsonb);
    v_meal_id BIGINT;
BEGIN
    PERFORM 1
    FROM users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id;
    END IF;

    IF jsonb_typeof(v_items) <> 'array' THEN
        RAISE EXCEPTION 'Meal items payload must be a JSON array';
    END IF;

    IF p_grant_exp AND p_exp_amount IS NULL THEN
        RAISE EXCEPTION 'p_exp_amount is required when p_grant_exp is true';
    END IF;

    INSERT INTO meals (
        user_id,
        meal_type,
        eaten_at,
        title,
        photo_url,
        notes,
        health_score,
        ai_confidence,
        total_calories,
        total_protein_g,
        total_carbs_g,
        total_fat_g
    )
    VALUES (
        p_user_id,
        p_meal_type,
        p_eaten_at,
        p_title,
        p_photo_url,
        p_notes,
        p_health_score,
        p_ai_confidence,
        p_total_calories,
        p_total_protein_g,
        p_total_carbs_g,
        p_total_fat_g
    )
    RETURNING id INTO v_meal_id;

    IF jsonb_array_length(v_items) > 0 THEN
        INSERT INTO meal_items (
            meal_id,
            item_name,
            quantity,
            unit,
            grams,
            calories,
            protein_g,
            carbs_g,
            fat_g,
            health_score,
            created_at
        )
        SELECT
            v_meal_id,
            item.item_name,
            item.quantity,
            item.unit,
            item.grams,
            item.calories,
            item.protein_g,
            item.carbs_g,
            item.fat_g,
            item.health_score,
            COALESCE(item.created_at, NOW())
        FROM jsonb_to_recordset(v_items) AS item(
            item_name VARCHAR(100),
            quantity NUMERIC(8,2),
            unit VARCHAR(20),
            grams NUMERIC(8,2),
            calories NUMERIC(8,2),
            protein_g NUMERIC(8,2),
            carbs_g NUMERIC(8,2),
            fat_g NUMERIC(8,2),
            health_score SMALLINT,
            created_at TIMESTAMPTZ
        );

        UPDATE meals
        SET
            total_calories = agg.total_calories,
            total_protein_g = agg.total_protein_g,
            total_carbs_g = agg.total_carbs_g,
            total_fat_g = agg.total_fat_g,
            updated_at = NOW()
        FROM (
            SELECT
                meal_id,
                COALESCE(SUM(calories), 0)::NUMERIC(8,2) AS total_calories,
                COALESCE(SUM(protein_g), 0)::NUMERIC(8,2) AS total_protein_g,
                COALESCE(SUM(carbs_g), 0)::NUMERIC(8,2) AS total_carbs_g,
                COALESCE(SUM(fat_g), 0)::NUMERIC(8,2) AS total_fat_g
            FROM meal_items
            WHERE meal_id = v_meal_id
            GROUP BY meal_id
        ) AS agg
        WHERE meals.id = agg.meal_id;
    END IF;

    UPDATE user_progress
    SET
        last_activity_at = CASE
            WHEN last_activity_at IS NULL THEN p_eaten_at
            ELSE GREATEST(last_activity_at, p_eaten_at)
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    IF p_grant_exp THEN
        CALL proc_grant_exp(
            p_user_id,
            'meal',
            v_meal_id,
            p_exp_amount,
            COALESCE(p_exp_reason, 'Meal logged'),
            COALESCE(p_exp_created_at, p_eaten_at),
            p_eaten_at
        );
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE proc_log_workout(
    IN p_user_id BIGINT,
    IN p_workout_type TEXT DEFAULT NULL,
    IN p_title VARCHAR(100) DEFAULT NULL,
    IN p_performed_at TIMESTAMPTZ DEFAULT NOW(),
    IN p_duration_min INTEGER DEFAULT NULL,
    IN p_calories_burned NUMERIC(8,2) DEFAULT NULL,
    IN p_health_score SMALLINT DEFAULT NULL,
    IN p_notes TEXT DEFAULT NULL,
    IN p_exercises JSONB DEFAULT '[]'::jsonb,
    IN p_grant_exp BOOLEAN DEFAULT FALSE,
    IN p_exp_amount INTEGER DEFAULT NULL,
    IN p_exp_reason TEXT DEFAULT NULL,
    IN p_exp_created_at TIMESTAMPTZ DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_exercises JSONB := COALESCE(p_exercises, '[]'::jsonb);
    v_workout_id BIGINT;
BEGIN
    PERFORM 1
    FROM users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id;
    END IF;

    IF jsonb_typeof(v_exercises) <> 'array' THEN
        RAISE EXCEPTION 'Workout exercises payload must be a JSON array';
    END IF;

    IF p_grant_exp AND p_exp_amount IS NULL THEN
        RAISE EXCEPTION 'p_exp_amount is required when p_grant_exp is true';
    END IF;

    INSERT INTO workouts (
        user_id,
        workout_type,
        title,
        performed_at,
        duration_min,
        calories_burned,
        health_score,
        notes
    )
    VALUES (
        p_user_id,
        p_workout_type,
        p_title,
        p_performed_at,
        p_duration_min,
        p_calories_burned,
        p_health_score,
        p_notes
    )
    RETURNING id INTO v_workout_id;

    IF jsonb_array_length(v_exercises) > 0 THEN
        INSERT INTO workout_exercises (
            workout_id,
            exercise_name,
            exercise_order,
            sets,
            reps,
            weight_kg,
            duration_sec,
            distance_m,
            calories_burned,
            notes,
            created_at
        )
        SELECT
            v_workout_id,
            exercise.exercise_name,
            exercise.exercise_order,
            exercise.sets,
            exercise.reps,
            exercise.weight_kg,
            exercise.duration_sec,
            exercise.distance_m,
            exercise.calories_burned,
            exercise.notes,
            COALESCE(exercise.created_at, NOW())
        FROM jsonb_to_recordset(v_exercises) AS exercise(
            exercise_name VARCHAR(100),
            exercise_order INTEGER,
            sets INTEGER,
            reps INTEGER,
            weight_kg NUMERIC(8,2),
            duration_sec INTEGER,
            distance_m NUMERIC(10,2),
            calories_burned NUMERIC(8,2),
            notes TEXT,
            created_at TIMESTAMPTZ
        );

        IF p_calories_burned IS NULL THEN
            UPDATE workouts
            SET
                calories_burned = agg.total_calories_burned,
                updated_at = NOW()
            FROM (
                SELECT
                    workout_id,
                    COALESCE(SUM(calories_burned), 0)::NUMERIC(8,2) AS total_calories_burned
                FROM workout_exercises
                WHERE workout_id = v_workout_id
                GROUP BY workout_id
            ) AS agg
            WHERE workouts.id = agg.workout_id;
        END IF;
    END IF;

    UPDATE user_progress
    SET
        last_activity_at = CASE
            WHEN last_activity_at IS NULL THEN p_performed_at
            ELSE GREATEST(last_activity_at, p_performed_at)
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;

    IF p_grant_exp THEN
        CALL proc_grant_exp(
            p_user_id,
            'workout',
            v_workout_id,
            p_exp_amount,
            COALESCE(p_exp_reason, 'Workout logged'),
            COALESCE(p_exp_created_at, p_performed_at),
            p_performed_at
        );
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE proc_join_challenge(
    IN p_user_id BIGINT,
    IN p_challenge_id BIGINT,
    IN p_joined_at TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_start_date TIMESTAMPTZ;
    v_end_date TIMESTAMPTZ;
BEGIN
    PERFORM 1
    FROM users
    WHERE id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not exist', p_user_id;
    END IF;

    SELECT start_date, end_date
    INTO v_start_date, v_end_date
    FROM challenges
    WHERE id = p_challenge_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Challenge % does not exist', p_challenge_id;
    END IF;

    IF v_start_date IS NOT NULL AND p_joined_at < v_start_date THEN
        RAISE EXCEPTION 'Cannot join challenge % before its start date', p_challenge_id;
    END IF;

    IF v_end_date IS NOT NULL AND p_joined_at > v_end_date THEN
        RAISE EXCEPTION 'Cannot join challenge % after its end date', p_challenge_id;
    END IF;

    INSERT INTO user_challenges (
        user_id,
        challenge_id,
        joined_at
    )
    VALUES (
        p_user_id,
        p_challenge_id,
        p_joined_at
    )
    ON CONFLICT (user_id, challenge_id) DO NOTHING;
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
    WHERE uc.id = p_user_challenge_id
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
        END
    WHERE id = p_user_challenge_id;

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

CREATE OR REPLACE PROCEDURE proc_claim_challenge_reward(
    IN p_user_id BIGINT,
    IN p_challenge_id BIGINT,
    IN p_claimed_at TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_challenge_id BIGINT;
    v_progress_value NUMERIC(10,2);
    v_goal_value NUMERIC(10,2);
    v_completed_at TIMESTAMPTZ;
    v_claimed_at TIMESTAMPTZ;
    v_reward_exp INTEGER;
    v_title VARCHAR(100);
BEGIN
    SELECT
        uc.id,
        uc.progress_value,
        uc.completed_at,
        uc.claimed_at,
        c.goal_value,
        c.reward_exp,
        c.title
    INTO
        v_user_challenge_id,
        v_progress_value,
        v_completed_at,
        v_claimed_at,
        v_goal_value,
        v_reward_exp,
        v_title
    FROM user_challenges uc
    JOIN challenges c ON c.id = uc.challenge_id
    WHERE uc.user_id = p_user_id
      AND uc.challenge_id = p_challenge_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % is not joined to challenge %', p_user_id, p_challenge_id;
    END IF;

    IF v_claimed_at IS NOT NULL THEN
        RETURN;
    END IF;

    IF v_completed_at IS NULL
       AND (v_goal_value IS NULL OR v_progress_value < v_goal_value) THEN
        RAISE EXCEPTION 'Challenge % is not completed for user %', p_challenge_id, p_user_id;
    END IF;

    UPDATE user_challenges
    SET
        status = 'claimed',
        completed_at = COALESCE(completed_at, p_claimed_at),
        claimed_at = p_claimed_at
    WHERE id = v_user_challenge_id;

    IF v_reward_exp > 0 THEN
        CALL proc_grant_exp(
            p_user_id,
            'challenge',
            p_challenge_id,
            v_reward_exp,
            format('Claimed challenge reward: %s', v_title),
            p_claimed_at,
            p_claimed_at
        );
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE proc_fail_challenge(
    IN p_user_id BIGINT,
    IN p_challenge_id BIGINT,
    IN p_failed_at TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_challenge_id BIGINT;
    v_claimed_at TIMESTAMPTZ;
BEGIN
    SELECT
        uc.id,
        uc.claimed_at
    INTO
        v_user_challenge_id,
        v_claimed_at
    FROM user_challenges uc
    WHERE uc.user_id = p_user_id
      AND uc.challenge_id = p_challenge_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % is not joined to challenge %', p_user_id, p_challenge_id;
    END IF;

    IF v_claimed_at IS NOT NULL THEN
        RAISE EXCEPTION 'Claimed challenge % for user % cannot be failed', p_challenge_id, p_user_id;
    END IF;

    UPDATE user_challenges
    SET
        status = 'failed',
        claimed_at = NULL,
        completed_at = NULL
    WHERE id = v_user_challenge_id;

    UPDATE user_progress
    SET
        last_activity_at = CASE
            WHEN last_activity_at IS NULL THEN p_failed_at
            ELSE GREATEST(last_activity_at, p_failed_at)
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

    PERFORM 1
    FROM achievements
    WHERE id = p_achievement_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Achievement % does not exist', p_achievement_id;
    END IF;

    INSERT INTO user_achievements (
        user_id,
        achievement_id
    )
    VALUES (
        p_user_id,
        p_achievement_id
    )
    ON CONFLICT (user_id, achievement_id) DO NOTHING
    RETURNING id INTO v_user_achievement_id;

    IF v_user_achievement_id IS NULL THEN
        SELECT id
        INTO v_user_achievement_id
        FROM user_achievements
        WHERE user_id = p_user_id
          AND achievement_id = p_achievement_id;
    END IF;

    SELECT
        ua.progress_value,
        ua.unlocked_at,
        ua.claimed_at,
        a.target_value
    INTO
        v_current_progress,
        v_unlocked_at,
        v_claimed_at,
        v_target_value
    FROM user_achievements ua
    JOIN achievements a ON a.id = ua.achievement_id
    WHERE ua.id = v_user_achievement_id
    FOR UPDATE;

    v_new_progress := COALESCE(p_progress_value, v_current_progress + p_progress_delta);

    IF v_new_progress < 0 THEN
        RAISE EXCEPTION 'Achievement progress cannot be negative';
    END IF;

    UPDATE user_achievements
    SET
        progress_value = GREATEST(progress_value, v_new_progress),
        unlocked_at = CASE
            WHEN unlocked_at IS NOT NULL THEN unlocked_at
            WHEN v_target_value IS NOT NULL AND v_new_progress >= v_target_value THEN p_progress_at
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

CREATE OR REPLACE PROCEDURE proc_claim_achievement_reward(
    IN p_user_id BIGINT,
    IN p_achievement_id BIGINT,
    IN p_claimed_at TIMESTAMPTZ DEFAULT NOW()
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_achievement_id BIGINT;
    v_progress_value NUMERIC(10,2);
    v_target_value NUMERIC(10,2);
    v_unlocked_at TIMESTAMPTZ;
    v_claimed_at TIMESTAMPTZ;
    v_reward_exp INTEGER;
    v_title VARCHAR(100);
BEGIN
    SELECT
        ua.id,
        ua.progress_value,
        ua.unlocked_at,
        ua.claimed_at,
        a.target_value,
        a.reward_exp,
        a.title
    INTO
        v_user_achievement_id,
        v_progress_value,
        v_unlocked_at,
        v_claimed_at,
        v_target_value,
        v_reward_exp,
        v_title
    FROM user_achievements ua
    JOIN achievements a ON a.id = ua.achievement_id
    WHERE ua.user_id = p_user_id
      AND ua.achievement_id = p_achievement_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User % does not have achievement row %', p_user_id, p_achievement_id;
    END IF;

    IF v_claimed_at IS NOT NULL THEN
        RETURN;
    END IF;

    IF v_unlocked_at IS NULL
       AND (v_target_value IS NULL OR v_progress_value < v_target_value) THEN
        RAISE EXCEPTION 'Achievement % is not unlocked for user %', p_achievement_id, p_user_id;
    END IF;

    UPDATE user_achievements
    SET
        unlocked_at = COALESCE(unlocked_at, p_claimed_at),
        claimed_at = p_claimed_at
    WHERE id = v_user_achievement_id;

    IF v_reward_exp > 0 THEN
        CALL proc_grant_exp(
            p_user_id,
            'achievement',
            p_achievement_id,
            v_reward_exp,
            format('Claimed achievement reward: %s', v_title),
            p_claimed_at,
            p_claimed_at
        );
    END IF;
END;
$$;

CREATE OR REPLACE PROCEDURE proc_refresh_user_progress(
    IN p_user_id BIGINT,
    IN p_current_streak_days INTEGER DEFAULT NULL,
    IN p_longest_streak_days INTEGER DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_total_exp INTEGER;
    v_last_activity_at TIMESTAMPTZ;
BEGIN
    IF p_current_streak_days IS NOT NULL AND p_current_streak_days < 0 THEN
        RAISE EXCEPTION 'Current streak days cannot be negative';
    END IF;

    IF p_longest_streak_days IS NOT NULL AND p_longest_streak_days < 0 THEN
        RAISE EXCEPTION 'Longest streak days cannot be negative';
    END IF;

    PERFORM 1
    FROM user_progress
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User progress row for user % does not exist', p_user_id;
    END IF;

    SELECT COALESCE(SUM(exp_amount), 0)
    INTO v_total_exp
    FROM exp_events
    WHERE user_id = p_user_id;

    SELECT MAX(activity_at)
    INTO v_last_activity_at
    FROM (
        SELECT eaten_at AS activity_at
        FROM meals
        WHERE user_id = p_user_id

        UNION ALL

        SELECT performed_at AS activity_at
        FROM workouts
        WHERE user_id = p_user_id

        UNION ALL

        SELECT created_at AS activity_at
        FROM exp_events
        WHERE user_id = p_user_id
    ) AS activity_events;

    UPDATE user_progress
    SET
        total_exp = v_total_exp,
        current_streak_days = COALESCE(p_current_streak_days, current_streak_days),
        longest_streak_days = COALESCE(p_longest_streak_days, longest_streak_days),
        last_activity_at = v_last_activity_at,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$;

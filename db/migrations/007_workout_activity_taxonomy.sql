-- Workout taxonomy for the UI activity lists.
-- `workout_type` remains the coarse existing app metric. The new activity fields
-- represent the selectable UI taxonomy: gym, sport, general, or other.

ALTER TABLE workouts
ADD COLUMN IF NOT EXISTS activity_category TEXT,
ADD COLUMN IF NOT EXISTS activity_code VARCHAR(80),
ADD COLUMN IF NOT EXISTS activity_name VARCHAR(100);

ALTER TABLE gym_workout_exercises
ADD COLUMN IF NOT EXISTS exercise_group TEXT,
ADD COLUMN IF NOT EXISTS exercise_code VARCHAR(80);

UPDATE workouts
SET
    activity_category = COALESCE(
        activity_category,
        CASE
            WHEN workout_type = 'strength' THEN 'gym'
            WHEN workout_type = 'sport' THEN 'sport'
            WHEN workout_type IN ('cardio', 'mobility') THEN 'general'
            ELSE 'other'
        END
    ),
    activity_name = COALESCE(activity_name, title);

ALTER TABLE workouts
DROP CONSTRAINT IF EXISTS workouts_activity_category_check;

ALTER TABLE workouts
ADD CONSTRAINT workouts_activity_category_check
    CHECK (activity_category IS NULL OR activity_category IN ('gym', 'sport', 'general', 'other'));

ALTER TABLE workouts
DROP CONSTRAINT IF EXISTS workouts_activity_code_not_blank;

ALTER TABLE workouts
ADD CONSTRAINT workouts_activity_code_not_blank
    CHECK (activity_code IS NULL OR char_length(trim(activity_code)) > 0);

ALTER TABLE workouts
DROP CONSTRAINT IF EXISTS workouts_activity_name_not_blank;

ALTER TABLE workouts
ADD CONSTRAINT workouts_activity_name_not_blank
    CHECK (activity_name IS NULL OR char_length(trim(activity_name)) > 0);

ALTER TABLE gym_workout_exercises
DROP CONSTRAINT IF EXISTS gym_workout_exercises_group_check;

ALTER TABLE gym_workout_exercises
ADD CONSTRAINT gym_workout_exercises_group_check
    CHECK (
        exercise_group IS NULL OR exercise_group IN (
            'chest',
            'back',
            'legs',
            'glutes',
            'shoulders',
            'biceps',
            'triceps',
            'calves',
            'core',
            'cardio_conditioning',
            'calisthenics',
            'other'
        )
    );

ALTER TABLE gym_workout_exercises
DROP CONSTRAINT IF EXISTS gym_workout_exercises_code_not_blank;

ALTER TABLE gym_workout_exercises
ADD CONSTRAINT gym_workout_exercises_code_not_blank
    CHECK (exercise_code IS NULL OR char_length(trim(exercise_code)) > 0);

CREATE INDEX IF NOT EXISTS workouts_activity_category_idx
    ON workouts(activity_category);

CREATE INDEX IF NOT EXISTS workouts_activity_code_idx
    ON workouts(activity_code);

CREATE INDEX IF NOT EXISTS gym_workout_exercises_workout_id_idx
    ON gym_workout_exercises(workout_id);

CREATE INDEX IF NOT EXISTS gym_workout_exercises_group_idx
    ON gym_workout_exercises(exercise_group);

CREATE INDEX IF NOT EXISTS gym_workout_exercises_code_idx
    ON gym_workout_exercises(exercise_code);

DROP PROCEDURE IF EXISTS proc_log_workout(
    BIGINT,
    TEXT,
    VARCHAR,
    TIMESTAMPTZ,
    INTEGER,
    SMALLINT,
    TEXT,
    JSONB,
    BOOLEAN,
    INTEGER,
    TEXT,
    TIMESTAMPTZ
);

CREATE OR REPLACE PROCEDURE proc_log_workout(
    IN p_user_id BIGINT,
    IN p_workout_type TEXT DEFAULT NULL,
    IN p_title VARCHAR(100) DEFAULT NULL,
    IN p_performed_at TIMESTAMPTZ DEFAULT NOW(),
    IN p_duration_min INTEGER DEFAULT NULL,
    IN p_health_score SMALLINT DEFAULT NULL,
    IN p_notes TEXT DEFAULT NULL,
    IN p_exercises JSONB DEFAULT '[]'::jsonb,
    IN p_grant_exp BOOLEAN DEFAULT FALSE,
    IN p_exp_amount INTEGER DEFAULT NULL,
    IN p_exp_reason TEXT DEFAULT NULL,
    IN p_exp_created_at TIMESTAMPTZ DEFAULT NULL,
    IN p_activity_category TEXT DEFAULT NULL,
    IN p_activity_code VARCHAR(80) DEFAULT NULL,
    IN p_activity_name VARCHAR(100) DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_exercises JSONB := COALESCE(p_exercises, '[]'::jsonb);
    v_workout_id BIGINT;
    v_activity_category TEXT;
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

    v_activity_category := COALESCE(
        p_activity_category,
        CASE
            WHEN p_workout_type = 'strength' THEN 'gym'
            WHEN p_workout_type = 'sport' THEN 'sport'
            WHEN p_workout_type IN ('cardio', 'mobility') THEN 'general'
            ELSE 'other'
        END
    );

    IF v_activity_category <> 'gym' AND jsonb_array_length(v_exercises) > 0 THEN
        RAISE EXCEPTION 'Detailed exercises are only stored for gym workouts';
    END IF;

    INSERT INTO workouts (
        user_id,
        workout_type,
        title,
        performed_at,
        duration_min,
        health_score,
        notes,
        activity_category,
        activity_code,
        activity_name
    )
    VALUES (
        p_user_id,
        p_workout_type,
        p_title,
        p_performed_at,
        p_duration_min,
        p_health_score,
        p_notes,
        v_activity_category,
        p_activity_code,
        COALESCE(p_activity_name, p_title)
    )
    RETURNING id INTO v_workout_id;

    IF jsonb_array_length(v_exercises) > 0 THEN
        INSERT INTO gym_workout_exercises (
            workout_id,
            exercise_name,
            exercise_order,
            exercise_group,
            exercise_code,
            sets,
            reps,
            weight_kg,
            duration_sec,
            distance_m,
            notes,
            created_at
        )
        SELECT
            v_workout_id,
            exercise.exercise_name,
            exercise.exercise_order,
            exercise.exercise_group,
            exercise.exercise_code,
            exercise.sets,
            exercise.reps,
            exercise.weight_kg,
            exercise.duration_sec,
            exercise.distance_m,
            exercise.notes,
            COALESCE(exercise.created_at, NOW())
        FROM jsonb_to_recordset(v_exercises) AS exercise(
            exercise_name VARCHAR(100),
            exercise_order INTEGER,
            exercise_group TEXT,
            exercise_code VARCHAR(80),
            sets INTEGER,
            reps INTEGER,
            weight_kg NUMERIC(8,2),
            duration_sec INTEGER,
            distance_m NUMERIC(10,2),
            notes TEXT,
            created_at TIMESTAMPTZ
        );
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

-- Core account, activity, EXP, and workout logging schema.

CREATE TABLE users (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    email VARCHAR(254) NOT NULL,
    status TEXT NOT NULL DEFAULT 'active',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT users_status_check
        CHECK (status IN ('active', 'inactive', 'banned'))
);

CREATE UNIQUE INDEX users_email_unique_lower_idx
    ON users (LOWER(email));

CREATE TABLE user_auth (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    password_hash TEXT NOT NULL,
    password_updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    last_login_date DATE,
    current_login_streak_days INTEGER NOT NULL DEFAULT 0,
    longest_login_streak_days INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT user_auth_password_hash_not_blank
        CHECK (char_length(trim(password_hash)) > 0),

    CONSTRAINT user_auth_login_streak_check
        CHECK (
            current_login_streak_days >= 0
            AND longest_login_streak_days >= current_login_streak_days
        )
);

CREATE TABLE user_profiles (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    username VARCHAR(30),
    display_name VARCHAR(50),
    birth_date DATE,
    sex TEXT,
    height_cm NUMERIC(5,2),
    weight_kg NUMERIC(5,2),
    goal TEXT,
    activity_level TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT user_profiles_username_not_blank
        CHECK (username IS NULL OR char_length(trim(username)) > 0),

    CONSTRAINT user_profiles_username_format_check
        CHECK (username IS NULL OR username ~ '^[a-zA-Z0-9_]{3,30}$'),

    CONSTRAINT user_profiles_display_name_not_blank
        CHECK (display_name IS NULL OR char_length(trim(display_name)) > 0),

    CONSTRAINT user_profiles_height_check
        CHECK (height_cm IS NULL OR height_cm > 0),

    CONSTRAINT user_profiles_weight_check
        CHECK (weight_kg IS NULL OR weight_kg > 0)
);

CREATE UNIQUE INDEX user_profiles_username_unique_lower_idx
    ON user_profiles (LOWER(username))
    WHERE username IS NOT NULL;

CREATE TABLE meals (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    meal_type TEXT,
    eaten_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    title VARCHAR(100),
    photo_url TEXT,
    notes TEXT,
    health_score SMALLINT,
    ai_confidence NUMERIC(4,3),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT meals_health_score_check
        CHECK (health_score IS NULL OR health_score BETWEEN 1 AND 10),

    CONSTRAINT meals_ai_confidence_check
        CHECK (ai_confidence IS NULL OR ai_confidence BETWEEN 0 AND 1),

    CONSTRAINT meals_type_check
        CHECK (meal_type IS NULL OR meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'other'))
);

CREATE INDEX meals_user_eaten_at_idx
    ON meals(user_id, eaten_at DESC);

CREATE TABLE workouts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_type TEXT,
    title VARCHAR(100),
    performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    duration_min INTEGER,
    health_score SMALLINT,
    notes TEXT,
    activity_category TEXT,
    activity_code VARCHAR(80),
    activity_name VARCHAR(100),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT workouts_duration_check
        CHECK (duration_min IS NULL OR duration_min > 0),

    CONSTRAINT workouts_health_score_check
        CHECK (health_score IS NULL OR health_score BETWEEN 1 AND 10),

    CONSTRAINT workouts_type_check
        CHECK (workout_type IS NULL OR workout_type IN ('strength', 'cardio', 'mobility', 'sport', 'other')),

    CONSTRAINT workouts_activity_category_check
        CHECK (activity_category IS NULL OR activity_category IN ('gym', 'sport', 'general', 'other')),

    CONSTRAINT workouts_activity_code_not_blank
        CHECK (activity_code IS NULL OR char_length(trim(activity_code)) > 0),

    CONSTRAINT workouts_activity_name_not_blank
        CHECK (activity_name IS NULL OR char_length(trim(activity_name)) > 0)
);

CREATE INDEX workouts_user_performed_at_idx
    ON workouts(user_id, performed_at DESC);

CREATE INDEX workouts_activity_category_idx
    ON workouts(activity_category);

CREATE INDEX workouts_activity_code_idx
    ON workouts(activity_code);

CREATE TABLE gym_workout_exercises (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    workout_id BIGINT NOT NULL REFERENCES workouts(id) ON DELETE CASCADE,
    exercise_name VARCHAR(100) NOT NULL,
    exercise_order INTEGER,
    sets INTEGER,
    reps INTEGER,
    weight_kg NUMERIC(8,2),
    duration_sec INTEGER,
    distance_m NUMERIC(10,2),
    notes TEXT,
    exercise_group TEXT,
    exercise_code VARCHAR(80),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT gym_workout_exercises_name_not_blank
        CHECK (char_length(trim(exercise_name)) > 0),

    CONSTRAINT gym_workout_exercises_order_check
        CHECK (exercise_order IS NULL OR exercise_order > 0),

    CONSTRAINT gym_workout_exercises_sets_check
        CHECK (sets IS NULL OR sets > 0),

    CONSTRAINT gym_workout_exercises_reps_check
        CHECK (reps IS NULL OR reps > 0),

    CONSTRAINT gym_workout_exercises_weight_check
        CHECK (weight_kg IS NULL OR weight_kg >= 0),

    CONSTRAINT gym_workout_exercises_duration_check
        CHECK (duration_sec IS NULL OR duration_sec > 0),

    CONSTRAINT gym_workout_exercises_distance_check
        CHECK (distance_m IS NULL OR distance_m >= 0),

    CONSTRAINT gym_workout_exercises_group_check
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
        ),

    CONSTRAINT gym_workout_exercises_code_not_blank
        CHECK (exercise_code IS NULL OR char_length(trim(exercise_code)) > 0)
);

CREATE INDEX gym_workout_exercises_workout_id_idx
    ON gym_workout_exercises(workout_id);

CREATE INDEX gym_workout_exercises_group_idx
    ON gym_workout_exercises(exercise_group);

CREATE INDEX gym_workout_exercises_code_idx
    ON gym_workout_exercises(exercise_code);

CREATE TABLE exp_events (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    source_type TEXT NOT NULL,
    source_id BIGINT NOT NULL,
    exp_amount INTEGER NOT NULL,
    reason TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT exp_events_exp_amount_check
        CHECK (exp_amount <> 0),

    CONSTRAINT exp_events_source_type_check
        CHECK (source_type IN ('workout', 'meal', 'challenge', 'achievement', 'quest', 'manual', 'streak'))
);

CREATE INDEX exp_events_user_created_at_idx
    ON exp_events(user_id, created_at DESC);

CREATE TABLE user_progress (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    total_exp INTEGER NOT NULL DEFAULT 0,
    current_streak_days INTEGER NOT NULL DEFAULT 0,
    longest_streak_days INTEGER NOT NULL DEFAULT 0,
    last_activity_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT user_progress_total_exp_check
        CHECK (total_exp >= 0),

    CONSTRAINT user_progress_current_streak_check
        CHECK (current_streak_days >= 0),

    CONSTRAINT user_progress_longest_streak_check
        CHECK (longest_streak_days >= 0)
);

CREATE OR REPLACE FUNCTION create_user_progress_after_user_insert()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO user_progress (user_id)
    VALUES (NEW.id);

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_create_user_progress
AFTER INSERT ON users
FOR EACH ROW
EXECUTE FUNCTION create_user_progress_after_user_insert();

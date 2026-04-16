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

    CONSTRAINT user_auth_password_hash_not_blank
        CHECK (char_length(trim(password_hash)) > 0)
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

CREATE TABLE workouts (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    workout_type TEXT,
    title VARCHAR(100),
    performed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    duration_min INTEGER,
    health_score SMALLINT,
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT workouts_duration_check
        CHECK (duration_min IS NULL OR duration_min > 0),

    CONSTRAINT workouts_health_score_check
        CHECK (health_score IS NULL OR health_score BETWEEN 1 AND 10),

    CONSTRAINT workouts_type_check
        CHECK (workout_type IS NULL OR workout_type IN ('strength', 'cardio', 'mobility', 'sport', 'other'))
);

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
        CHECK (distance_m IS NULL OR distance_m >= 0)
);

CREATE INDEX gym_workout_exercises_workout_id_idx ON gym_workout_exercises(workout_id);
CREATE INDEX meals_user_eaten_at_idx ON meals(user_id, eaten_at DESC);
CREATE INDEX workouts_user_performed_at_idx ON workouts(user_id, performed_at DESC);


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
        CHECK (source_type IN ('workout', 'meal', 'challenge', 'achievement', 'manual', 'streak'))
);

CREATE INDEX exp_events_user_created_at_idx ON exp_events(user_id, created_at DESC);

CREATE TABLE user_progress (
    user_id BIGINT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    total_exp INTEGER NOT NULL DEFAULT 0,
    level INTEGER NOT NULL DEFAULT 1,
    current_streak_days INTEGER NOT NULL DEFAULT 0,
    longest_streak_days INTEGER NOT NULL DEFAULT 0,
    last_activity_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT user_progress_total_exp_check
        CHECK (total_exp >= 0),

    CONSTRAINT user_progress_level_check
        CHECK (level >= 1),

    CONSTRAINT user_progress_current_streak_check
        CHECK (current_streak_days >= 0),

    CONSTRAINT user_progress_longest_streak_check
        CHECK (longest_streak_days >= 0)
);

CREATE TABLE challenges (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    challenge_type TEXT,
    goal_value NUMERIC(10,2),
    reward_exp INTEGER NOT NULL DEFAULT 0,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT challenges_title_not_blank
        CHECK (char_length(trim(title)) > 0),

    CONSTRAINT challenges_goal_value_check
        CHECK (goal_value IS NULL OR goal_value > 0),

    CONSTRAINT challenges_reward_exp_check
        CHECK (reward_exp >= 0),

    CONSTRAINT challenges_date_range_check
        CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date)
);

CREATE TABLE user_challenges (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    challenge_id BIGINT NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    progress_value NUMERIC(10,2) NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    claimed_at TIMESTAMPTZ,

    CONSTRAINT user_challenges_progress_check
        CHECK (progress_value >= 0),

    CONSTRAINT user_challenges_status_check
        CHECK (status IN ('active', 'completed', 'claimed', 'failed')),

    CONSTRAINT user_challenges_completed_after_joined_check
        CHECK (completed_at IS NULL OR completed_at >= joined_at),

    CONSTRAINT user_challenges_claimed_after_completed_check
        CHECK (claimed_at IS NULL OR completed_at IS NULL OR claimed_at >= completed_at),

    CONSTRAINT user_challenges_unique
        UNIQUE (user_id, challenge_id)
);

CREATE INDEX user_challenges_user_id_idx ON user_challenges(user_id);
CREATE INDEX user_challenges_challenge_id_idx ON user_challenges(challenge_id);
CREATE INDEX user_challenges_user_status_idx ON user_challenges(user_id, status);

CREATE TABLE achievements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    achievement_type TEXT,
    target_value NUMERIC(10,2),
    reward_exp INTEGER NOT NULL DEFAULT 0,
    icon_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT achievements_code_not_blank
        CHECK (char_length(trim(code)) > 0),

    CONSTRAINT achievements_title_not_blank
        CHECK (char_length(trim(title)) > 0),

    CONSTRAINT achievements_target_value_check
        CHECK (target_value IS NULL OR target_value > 0),

    CONSTRAINT achievements_reward_exp_check
        CHECK (reward_exp >= 0)
);

CREATE TABLE user_achievements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id BIGINT NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    progress_value NUMERIC(10,2) NOT NULL DEFAULT 0,
    unlocked_at TIMESTAMPTZ,
    claimed_at TIMESTAMPTZ,

    CONSTRAINT user_achievements_progress_check
        CHECK (progress_value >= 0),

    CONSTRAINT user_achievements_claimed_after_unlocked_check
        CHECK (claimed_at IS NULL OR unlocked_at IS NULL OR claimed_at >= unlocked_at),

    CONSTRAINT user_achievements_unique
        UNIQUE (user_id, achievement_id)
);

CREATE INDEX user_achievements_user_id_idx ON user_achievements(user_id);
CREATE INDEX user_achievements_achievement_id_idx ON user_achievements(achievement_id);
CREATE INDEX user_achievements_user_unlocked_idx ON user_achievements(user_id, unlocked_at DESC);

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

CREATE OR REPLACE PROCEDURE proc_register_user(
    IN p_email VARCHAR(254),
    IN p_password_hash TEXT,
    IN p_status TEXT DEFAULT 'active'
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_user_id BIGINT;
BEGIN
    IF p_email IS NULL OR char_length(trim(p_email)) = 0 THEN
        RAISE EXCEPTION 'Email cannot be blank';
    END IF;

    IF p_password_hash IS NULL OR char_length(trim(p_password_hash)) = 0 THEN
        RAISE EXCEPTION 'Password hash cannot be blank';
    END IF;

    INSERT INTO users (email, status)
    VALUES (trim(p_email), p_status)
    RETURNING id INTO v_user_id;

    INSERT INTO user_auth (user_id, password_hash)
    VALUES (v_user_id, trim(p_password_hash));
END;
$$;

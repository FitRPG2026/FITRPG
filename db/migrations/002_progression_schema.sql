-- Progression definitions and per-user state for challenges, achievements, and quests.

CREATE TABLE challenges (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    challenge_type TEXT,
    goal_value NUMERIC(10,2),
    reward_exp INTEGER NOT NULL DEFAULT 0,
    start_date TIMESTAMPTZ,
    end_date TIMESTAMPTZ,
    mechanic_type TEXT NOT NULL DEFAULT 'accumulation',
    event_trigger TEXT NOT NULL DEFAULT 'manual',
    conditions JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT challenges_title_not_blank
        CHECK (char_length(trim(title)) > 0),

    CONSTRAINT challenges_goal_value_check
        CHECK (goal_value IS NULL OR goal_value > 0),

    CONSTRAINT challenges_reward_exp_check
        CHECK (reward_exp >= 0),

    CONSTRAINT challenges_date_range_check
        CHECK (end_date IS NULL OR start_date IS NULL OR end_date >= start_date),

    CONSTRAINT challenges_mechanic_type_check
        CHECK (mechanic_type IN ('threshold', 'accumulation', 'streak')),

    CONSTRAINT challenges_event_trigger_check
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
        )),

    CONSTRAINT challenges_conditions_object_check
        CHECK (jsonb_typeof(conditions) = 'object')
);

CREATE INDEX challenges_event_trigger_idx
    ON challenges(event_trigger, mechanic_type);

CREATE INDEX challenges_conditions_gin_idx
    ON challenges USING GIN (conditions);

CREATE TABLE achievements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    achievement_type TEXT,
    target_value NUMERIC(10,2),
    reward_exp INTEGER NOT NULL DEFAULT 0,
    icon_url TEXT,
    mechanic_type TEXT NOT NULL DEFAULT 'accumulation',
    event_trigger TEXT NOT NULL DEFAULT 'manual',
    conditions JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT achievements_code_not_blank
        CHECK (char_length(trim(code)) > 0),

    CONSTRAINT achievements_title_not_blank
        CHECK (char_length(trim(title)) > 0),

    CONSTRAINT achievements_target_value_check
        CHECK (target_value IS NULL OR target_value > 0),

    CONSTRAINT achievements_reward_exp_check
        CHECK (reward_exp >= 0),

    CONSTRAINT achievements_mechanic_type_check
        CHECK (mechanic_type IN ('threshold', 'accumulation', 'streak')),

    CONSTRAINT achievements_event_trigger_check
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
        )),

    CONSTRAINT achievements_conditions_object_check
        CHECK (jsonb_typeof(conditions) = 'object')
);

CREATE INDEX achievements_event_trigger_idx
    ON achievements(event_trigger, mechanic_type);

CREATE INDEX achievements_conditions_gin_idx
    ON achievements USING GIN (conditions);

CREATE TABLE quests (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    code VARCHAR(50) NOT NULL UNIQUE,
    title VARCHAR(100) NOT NULL,
    description TEXT,
    quest_type TEXT,
    progression_mode TEXT NOT NULL DEFAULT 'standalone',
    quest_series_code VARCHAR(50),
    sequence_order INTEGER,
    target_value NUMERIC(10,2),
    reward_exp INTEGER NOT NULL DEFAULT 0,
    mechanic_type TEXT NOT NULL DEFAULT 'accumulation',
    event_trigger TEXT NOT NULL DEFAULT 'manual',
    conditions JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),

    CONSTRAINT quests_code_not_blank
        CHECK (char_length(trim(code)) > 0),

    CONSTRAINT quests_title_not_blank
        CHECK (char_length(trim(title)) > 0),

    CONSTRAINT quests_type_check
        CHECK (
            quest_type IS NULL OR quest_type IN (
                'onboarding',
                'meal_count',
                'healthy_meals',
                'workout_count',
                'strength_sessions',
                'cardio_sessions',
                'mobility_sessions',
                'distance_m',
                'duration_min',
                'streak_days',
                'program_step'
            )
        ),

    CONSTRAINT quests_progression_mode_check
        CHECK (progression_mode IN ('standalone', 'linear')),

    CONSTRAINT quests_linear_shape_check
        CHECK (
            (
                progression_mode = 'standalone'
                AND quest_series_code IS NULL
                AND sequence_order IS NULL
            )
            OR (
                progression_mode = 'linear'
                AND quest_series_code IS NOT NULL
                AND sequence_order IS NOT NULL
            )
        ),

    CONSTRAINT quests_sequence_order_check
        CHECK (sequence_order IS NULL OR sequence_order > 0),

    CONSTRAINT quests_target_value_check
        CHECK (target_value IS NULL OR target_value > 0),

    CONSTRAINT quests_reward_exp_check
        CHECK (reward_exp >= 0),

    CONSTRAINT quests_mechanic_type_check
        CHECK (mechanic_type IN ('threshold', 'accumulation', 'streak')),

    CONSTRAINT quests_event_trigger_check
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
        )),

    CONSTRAINT quests_conditions_object_check
        CHECK (jsonb_typeof(conditions) = 'object')
);

CREATE UNIQUE INDEX quests_series_sequence_unique_idx
    ON quests(quest_series_code, sequence_order)
    WHERE quest_series_code IS NOT NULL;

CREATE INDEX quests_event_trigger_idx
    ON quests(event_trigger, mechanic_type);

CREATE INDEX quests_conditions_gin_idx
    ON quests USING GIN (conditions);

CREATE TABLE user_challenges (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    challenge_id BIGINT NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
    progress_value NUMERIC(10,2) NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    claimed_at TIMESTAMPTZ,
    last_progress_at TIMESTAMPTZ,
    progress_state JSONB NOT NULL DEFAULT '{}'::jsonb,

    CONSTRAINT user_challenges_progress_check
        CHECK (progress_value >= 0),

    CONSTRAINT user_challenges_status_check
        CHECK (status IN ('active', 'completed', 'claimed', 'failed')),

    CONSTRAINT user_challenges_completed_after_joined_check
        CHECK (completed_at IS NULL OR completed_at >= joined_at),

    CONSTRAINT user_challenges_claimed_after_completed_check
        CHECK (claimed_at IS NULL OR completed_at IS NULL OR claimed_at >= completed_at),

    CONSTRAINT user_challenges_last_progress_after_joined_check
        CHECK (last_progress_at IS NULL OR last_progress_at >= joined_at),

    CONSTRAINT user_challenges_progress_state_object_check
        CHECK (jsonb_typeof(progress_state) = 'object'),

    CONSTRAINT user_challenges_unique
        UNIQUE (user_id, challenge_id)
);

CREATE INDEX user_challenges_user_id_idx ON user_challenges(user_id);
CREATE INDEX user_challenges_challenge_id_idx ON user_challenges(challenge_id);
CREATE INDEX user_challenges_user_status_idx ON user_challenges(user_id, status);
CREATE INDEX user_challenges_last_progress_idx ON user_challenges(user_id, last_progress_at DESC);
CREATE INDEX user_challenges_progress_state_gin_idx ON user_challenges USING GIN (progress_state);

CREATE TABLE user_achievements (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    achievement_id BIGINT NOT NULL REFERENCES achievements(id) ON DELETE CASCADE,
    progress_value NUMERIC(10,2) NOT NULL DEFAULT 0,
    unlocked_at TIMESTAMPTZ,
    claimed_at TIMESTAMPTZ,
    joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_progress_at TIMESTAMPTZ,
    progress_state JSONB NOT NULL DEFAULT '{}'::jsonb,

    CONSTRAINT user_achievements_progress_check
        CHECK (progress_value >= 0),

    CONSTRAINT user_achievements_unlocked_after_joined_check
        CHECK (unlocked_at IS NULL OR unlocked_at >= joined_at),

    CONSTRAINT user_achievements_claimed_after_unlocked_check
        CHECK (claimed_at IS NULL OR unlocked_at IS NULL OR claimed_at >= unlocked_at),

    CONSTRAINT user_achievements_last_progress_after_joined_check
        CHECK (last_progress_at IS NULL OR last_progress_at >= joined_at),

    CONSTRAINT user_achievements_progress_state_object_check
        CHECK (jsonb_typeof(progress_state) = 'object'),

    CONSTRAINT user_achievements_unique
        UNIQUE (user_id, achievement_id)
);

CREATE INDEX user_achievements_user_id_idx ON user_achievements(user_id);
CREATE INDEX user_achievements_achievement_id_idx ON user_achievements(achievement_id);
CREATE INDEX user_achievements_user_unlocked_idx ON user_achievements(user_id, unlocked_at DESC);
CREATE INDEX user_achievements_user_joined_idx ON user_achievements(user_id, joined_at DESC);
CREATE INDEX user_achievements_last_progress_idx ON user_achievements(user_id, last_progress_at DESC);
CREATE INDEX user_achievements_progress_state_gin_idx ON user_achievements USING GIN (progress_state);

CREATE TABLE user_quests (
    id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id BIGINT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    quest_id BIGINT NOT NULL REFERENCES quests(id) ON DELETE CASCADE,
    progress_value NUMERIC(10,2) NOT NULL DEFAULT 0,
    status TEXT NOT NULL DEFAULT 'active',
    started_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    claimed_at TIMESTAMPTZ,
    last_progress_at TIMESTAMPTZ,
    progress_state JSONB NOT NULL DEFAULT '{}'::jsonb,

    CONSTRAINT user_quests_progress_check
        CHECK (progress_value >= 0),

    CONSTRAINT user_quests_status_check
        CHECK (status IN ('active', 'completed', 'claimed', 'abandoned')),

    CONSTRAINT user_quests_completed_after_started_check
        CHECK (completed_at IS NULL OR completed_at >= started_at),

    CONSTRAINT user_quests_claimed_after_completed_check
        CHECK (claimed_at IS NULL OR completed_at IS NULL OR claimed_at >= completed_at),

    CONSTRAINT user_quests_last_progress_after_started_check
        CHECK (last_progress_at IS NULL OR last_progress_at >= started_at),

    CONSTRAINT user_quests_progress_state_object_check
        CHECK (jsonb_typeof(progress_state) = 'object'),

    CONSTRAINT user_quests_unique
        UNIQUE (user_id, quest_id)
);

CREATE INDEX user_quests_user_id_idx ON user_quests(user_id);
CREATE INDEX user_quests_quest_id_idx ON user_quests(quest_id);
CREATE INDEX user_quests_user_status_idx ON user_quests(user_id, status);
CREATE INDEX user_quests_progress_state_gin_idx ON user_quests USING GIN (progress_state);

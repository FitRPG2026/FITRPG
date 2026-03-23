-- Quests are long-lived objectives for a user.
-- Unlike challenges, they are not tied to a global start/end window.

ALTER TABLE exp_events
DROP CONSTRAINT IF EXISTS exp_events_source_type_check;

ALTER TABLE exp_events
ADD CONSTRAINT exp_events_source_type_check
CHECK (source_type IN ('workout', 'meal', 'challenge', 'achievement', 'quest', 'manual', 'streak'));

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

    CONSTRAINT quests_sequence_order_check
        CHECK (sequence_order IS NULL OR sequence_order > 0),

    CONSTRAINT quests_target_value_check
        CHECK (target_value IS NULL OR target_value > 0),

    CONSTRAINT quests_reward_exp_check
        CHECK (reward_exp >= 0),

    CONSTRAINT quests_linear_shape_check
        CHECK (
            (progression_mode = 'standalone' AND quest_series_code IS NULL AND sequence_order IS NULL)
            OR
            (progression_mode = 'linear' AND quest_series_code IS NOT NULL AND sequence_order IS NOT NULL)
        )
);

CREATE UNIQUE INDEX quests_series_sequence_unique_idx
    ON quests (quest_series_code, sequence_order)
    WHERE quest_series_code IS NOT NULL;

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

    CONSTRAINT user_quests_unique
        UNIQUE (user_id, quest_id)
);

CREATE INDEX user_quests_user_id_idx ON user_quests(user_id);
CREATE INDEX user_quests_quest_id_idx ON user_quests(quest_id);
CREATE INDEX user_quests_user_status_idx ON user_quests(user_id, status);

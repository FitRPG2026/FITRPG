# Procedures

This file explains the stored procedures used by FITRPG progression and seed flows.

## Conventions

- `p_...` means procedure input parameter.
- `v_...` means local variable inside PL/pgSQL.
- User level is not stored in SQL. Backend derives it from `user_progress.total_exp`.

## Procedure Ownership

### Account And Profile

#### `proc_register_user`

Defined in `migrations/001_initial_schema.sql`.

What it does:
- inserts into `users`
- inserts into `user_auth`
- lets the trigger create `user_progress`

Example:

```sql
CALL proc_register_user(
    'anna.nowak@fitrpg.dev',
    '$2b$12$anna_demo_hash',
    'active'
);
```

#### `proc_mark_login`

Defined in `migrations/002_workflow_procedures.sql`.

What it does:
- updates `user_auth.last_login_at`

Example:

```sql
CALL proc_mark_login(
    (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'),
    '2026-03-22 07:15:00+00'
);
```

#### `proc_upsert_user_profile`

Defined in `migrations/002_workflow_procedures.sql`.

What it does:
- inserts a profile if none exists
- updates it if the user already has one

Example:

```sql
CALL proc_upsert_user_profile(
    (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'),
    'anna_nowak',
    'Anna',
    '1998-05-14',
    'female',
    168.00,
    62.50,
    'build_strength',
    'moderate'
);
```

### EXP And Progress

#### `proc_grant_exp`

Defined in `migrations/002_workflow_procedures.sql`.

What it does:
- inserts into `exp_events`
- updates `user_progress.total_exp`
- updates `user_progress.last_activity_at`

Use it for:
- manual bonuses
- streak rewards
- corrections
- rewards not already handled by a more specific workflow proc

Example:

```sql
CALL proc_grant_exp(
    (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'),
    'streak',
    (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'),
    30,
    'Seven-day activity streak reward.',
    '2026-03-21 06:45:00+00',
    '2026-03-21 06:45:00+00'
);
```

#### `proc_refresh_user_progress`

Defined in `migrations/002_workflow_procedures.sql`.

Use it as:
- a maintenance / repair helper for `user_progress`
- a seed helper for syncing sample users after manual data setup
- not as part of the main application workflow procedures

What it does:
- recomputes `total_exp` from `exp_events`
- recomputes `last_activity_at` from meals, workouts, and exp events
- preserves any newer `user_progress.last_activity_at` already written by other workflow procedures
- lets caller set `current_streak_days` and `longest_streak_days`

Example:

```sql
CALL proc_refresh_user_progress(
    (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'),
    7,
    9
);
```

### Challenges

#### `proc_create_challenge`

Defined in `migrations/002_workflow_procedures.sql`, overridden by `migrations/006_progression_rule_metadata.sql`.

What it does:
- inserts a challenge definition
- stores backend rule metadata:
  `p_mechanic_type`, `p_event_trigger`, and `p_conditions`

Example:

```sql
CALL proc_create_challenge(
    p_title => '100-Minute Cardio Week',
    p_description => 'Complete one hundred minutes of cardio workouts during the week.',
    p_challenge_type => 'duration_min',
    p_goal_value => 100.00,
    p_reward_exp => 70,
    p_start_date => '2026-03-16 00:00:00+00',
    p_end_date => '2026-03-22 23:59:59+00',
    p_created_at => '2026-03-16 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"workout_type":"cardio","progress_field":"duration_min"}'::jsonb
);
```

#### `proc_join_challenge`

What it does:
- creates `user_challenges` row if missing
- validates challenge date window

#### `proc_update_challenge_progress`

What it does:
- creates membership if needed through `proc_join_challenge`
- updates `progress_value`
- marks challenge `completed` when `goal_value` is reached
- stores `last_progress_at`

Example:

```sql
CALL proc_update_challenge_progress(
    (SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'),
    (SELECT id FROM challenges WHERE title = '10K Run Distance'),
    NULL,
    10000.00,
    '2026-03-21 17:32:00+00'
);
```

#### `proc_claim_challenge_reward`

What it does:
- marks `claimed_at`
- changes status to `claimed`
- grants reward EXP through `proc_grant_exp`

#### `proc_fail_challenge`

What it does:
- marks challenge as `failed`
- blocks further progress unless state is changed elsewhere

### Achievements

#### `proc_create_achievement`

Defined in `migrations/002_workflow_procedures.sql`, overridden by `migrations/005_achievement_join_workflow.sql` and `migrations/006_progression_rule_metadata.sql`.

What it does:
- creates or updates an achievement definition by `code`
- requires `target_value` to be provided and greater than zero
- stores backend rule metadata:
  `p_mechanic_type`, `p_event_trigger`, and `p_conditions`

#### `proc_join_achievement`

Defined in `migrations/005_achievement_join_workflow.sql`.

What it does:
- creates the user's `user_achievements` row explicitly
- stores `joined_at`
- rejects joins for achievements without a valid `target_value`

#### `proc_update_achievement_progress`

What it does:
- requires an existing `user_achievements` row
- updates progress
- sets `unlocked_at` when target is reached
- stores `last_progress_at`
- ignores further progress updates after the reward was already claimed
- rejects progress for achievements without a valid `target_value`

#### `proc_claim_achievement_reward`

What it does:
- sets `claimed_at`
- grants reward EXP through `proc_grant_exp`

Example:

```sql
CALL proc_join_achievement(
    (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'),
    (SELECT id FROM achievements WHERE code = 'FIRST_WORKOUT'),
    '2026-03-20 19:01:00+00'
);
```

```sql
CALL proc_update_achievement_progress(
    (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'),
    (SELECT id FROM achievements WHERE code = 'FIRST_WORKOUT'),
    NULL,
    1.00,
    '2026-03-20 19:02:00+00'
);
```

```sql
CALL proc_claim_achievement_reward(
    (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'),
    (SELECT id FROM achievements WHERE code = 'FIRST_WORKOUT'),
    '2026-03-20 19:03:00+00'
);
```

### Meals

#### `proc_log_meal`

Defined in `migrations/002_workflow_procedures.sql`.

What it does:
- inserts into `meals`
- inserts `meal_items` from `jsonb`
- recalculates meal totals from the items
- optionally grants meal EXP

Notes:
- `p_items` must be a JSON array of item objects.
- If `p_grant_exp = TRUE`, `p_exp_amount` is required.

Example:

```sql
CALL proc_log_meal(
    p_user_id => (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'),
    p_meal_type => 'breakfast',
    p_eaten_at => '2026-03-20 07:35:00+00',
    p_title => 'High Protein Oats',
    p_items => $$[
        {"item_name":"Oats","quantity":80.00,"unit":"g","grams":80.00,"calories":311.00,"protein_g":10.00,"carbs_g":53.00,"fat_g":5.50,"health_score":9}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 10
);
```

### Workouts

#### `proc_log_workout`

Defined in `migrations/002_workflow_procedures.sql`, overridden by `migrations/007_workout_activity_taxonomy.sql`.

What it does:
- inserts into `workouts`
- inserts `workout_exercises` from `jsonb`
- stores UI activity taxonomy in `activity_category`, `activity_code`, and `activity_name`
- stores exercise taxonomy from JSONB fields `exercise_group` and `exercise_code`
- optionally derives `calories_burned` from exercises
- optionally grants workout EXP

Notes:
- `p_exercises` must be a JSON array.
- If `p_grant_exp = TRUE`, `p_exp_amount` is required.
- `p_activity_category` should be `gym`, `sport`, `general`, or `other`.
- Use normalized ASCII `activity_code` / `exercise_code` values for challenge conditions, for example `basketball`, `football`, `lat_pulldown`.
- Gym `exercise_group` values are constrained to:
  `chest`, `back`, `legs`, `glutes`, `shoulders`, `biceps`, `triceps`, `calves`,
  `core`, `cardio_conditioning`, `calisthenics`, or `other`.

Example:

```sql
CALL proc_log_workout(
    p_user_id => (SELECT id FROM users WHERE email = 'filip.mazur@fitrpg.dev'),
    p_workout_type => 'sport',
    p_title => 'Basketball Scrimmage',
    p_performed_at => '2026-03-22 18:30:00+00',
    p_duration_min => 53,
    p_exercises => $$[
        {"exercise_name":"Full-court scrimmage","exercise_order":1,"duration_sec":3180,"distance_m":4600.00}
    ]$$::jsonb,
    p_activity_category => 'sport',
    p_activity_code => 'basketball',
    p_activity_name => 'Basketball'
);
```

### Quests

All quest procedures are defined in `migrations/004_quest_workflow_procedures.sql`.
`proc_create_quest` is overridden by `migrations/006_progression_rule_metadata.sql`.

#### `proc_create_quest`

What it does:
- creates or updates a quest definition by `code`
- stores backend rule metadata:
  `p_mechanic_type`, `p_event_trigger`, and `p_conditions`

Important fields:
- `p_progression_mode`: `standalone` or `linear`
- `p_quest_series_code` and `p_sequence_order` are required for `linear`

### Progression Rule Metadata

Challenge-like definitions use the same event-driven rule shape:

- `mechanic_type = 'threshold'`
  A one-off condition, for example one meal with `health_score >= 9`.
- `mechanic_type = 'accumulation'`
  A counter or sum, for example `100` cardio minutes or `3` basketball sessions.
- `mechanic_type = 'streak'`
  Consecutive-day logic, for example login or activity streaks.

The backend should call its challenge engine only after relevant app events:

```text
check_challenges(user_id, event_type='meal_logged', event_data={...})
```

The engine should query definitions by `event_trigger`, evaluate JSONB `conditions`, then call the relevant progress procedure. Example condition payloads:

```json
{"min_health_score": 8}
{"activity_category": "sport", "activity_code": "basketball", "progress_delta": 1}
{"required_activity_codes": ["football", "handball"], "distinct_activity_codes": true}
{"activity_category": "gym", "min_exercise_count": 2}
{"streak_field": "current_login_streak_days"}
```

#### `proc_start_quest`

What it does:
- creates `user_quests` row if missing
- enforces linear order for quest lines

#### `proc_update_quest_progress`

What it does:
- auto-starts the quest if needed
- updates progress
- marks the quest completed when target is reached

#### `proc_claim_quest_reward`

What it does:
- sets `claimed_at`
- grants quest reward EXP through `proc_grant_exp`

#### `proc_abandon_quest`

What it does:
- marks a user quest as `abandoned`

Example:

```sql
CALL proc_update_quest_progress(
    (SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'),
    (SELECT id FROM quests WHERE code = 'RUN_FOUNDATIONS_01'),
    NULL,
    1.00,
    '2026-03-20 09:00:00+00'
);
```

## Seed Usage

The canonical example of procedure-driven usage is in `queries/seeds/seed_all.sql` and the ordered files beside it.

Seed flow order:

1. register users
2. mark logins and upsert profiles
3. create definitions: challenges, achievements, quests
4. log meals and workouts
5. join achievements where tracking should exist
6. update challenge, achievement, and quest progress
7. grant manual or streak EXP
8. refresh user progress

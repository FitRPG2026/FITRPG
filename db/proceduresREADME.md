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

Defined in `migrations/002_workflow_procedures.sql`.

What it does:
- inserts a challenge definition

Example:

```sql
CALL proc_create_challenge(
    '7-Day Logging Streak',
    'Log at least one meal or workout for seven consecutive days.',
    'streak_days',
    7.00,
    40,
    '2026-03-10 00:00:00+00',
    '2026-03-31 23:59:59+00',
    '2026-03-10 00:00:00+00'
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

Defined in `migrations/002_workflow_procedures.sql`.

What it does:
- creates or updates an achievement definition by `code`

#### `proc_update_achievement_progress`

What it does:
- creates `user_achievements` row if missing
- updates progress
- sets `unlocked_at` when target is reached

#### `proc_claim_achievement_reward`

What it does:
- sets `claimed_at`
- grants reward EXP through `proc_grant_exp`

Example:

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

Defined in `migrations/002_workflow_procedures.sql`.

What it does:
- inserts into `workouts`
- inserts `workout_exercises` from `jsonb`
- optionally derives `calories_burned` from exercises
- optionally grants workout EXP

Notes:
- `p_exercises` must be a JSON array.
- If `p_grant_exp = TRUE`, `p_exp_amount` is required.

### Quests

All quest procedures are defined in `migrations/004_quest_workflow_procedures.sql`.

#### `proc_create_quest`

What it does:
- creates or updates a quest definition by `code`

Important fields:
- `p_progression_mode`: `standalone` or `linear`
- `p_quest_series_code` and `p_sequence_order` are required for `linear`

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
5. update challenge, achievement, and quest progress
6. grant manual or streak EXP
7. refresh user progress

# Database

This folder contains the shared database SQL for the project.

## Structure

- `migrations/` stores ordered SQL files used to create or change database structure.
- `queries/` stores optional manual SQL, helper scripts, analysis queries, and convenience wrappers like `queries/seed_all.sql`.
- `queries/seed_inspect.sql` is a manual verification helper for reviewing the currently seeded dataset.
- `queries/seeds/` stores ordered sample data for local development, demos, and manual testing.
- `proceduresREADME.md` documents progression procedures and example `CALL` usage for developers.

## Convention

- Name migration files in execution order, for example `000_init.sql`, `001_...sql`, `002_...sql`.
- Treat migrations as history. After a migration is shared, add a new file instead of rewriting the old one.
- Keep each migration focused on one clear change set.
- Use `queries/` only for SQL that is not part of the canonical schema history.
- Keep seed data out of `migrations/` unless the rows are required canonical application data.
- Prefer split seed files in dependency order, with an optional `seed_all.sql` wrapper for convenience.
- Treat `queries/seeds/` as the source of truth. `queries/seed_all.sql` is a flattened convenience script for local manual execution.
- Prefer procedure-driven writes for sample data and multi-table app flows.

## Current Schema

The current application schema is the ordered migration set in `migrations/`.
At the moment, a fresh database needs `001_initial_schema.sql`, `002_workflow_procedures.sql`,
`003_quests_schema.sql`, `004_quest_workflow_procedures.sql`, and
`005_achievement_join_workflow.sql` applied in filename order.

### Main Table Groups

- `users`, `user_auth`, `user_profiles`
  Core account data, login data, and optional profile / health data.
- `meals`, `meal_items`
  A meal log plus its detailed ingredients or detected items.
- `workouts`, `workout_exercises`
  A workout log plus optional exercise-level breakdown.
- `exp_events`, `user_progress`
  Experience history and the user's current progression state.
- `challenges`, `user_challenges`
  Time-bounded global challenge definitions and each user's progress in them.
- `quests`, `user_quests`
  Long-lived quest definitions and each user's persistent progress in them.
  Quests can be standalone or part of a linear quest line.
- `achievements`, `user_achievements`
  Achievement definitions and each user's unlock progress.

### Relationship Summary

- One `users` row can have one `user_auth` row.
- One `users` row can have zero or one `user_profiles` row.
- One user can have many meals and many workouts.
- One meal can have many `meal_items`.
- One workout can have many `workout_exercises`.
- One user can have many `exp_events`.
- One user has one `user_progress` row.
- Challenge, quest, and achievement tables are split into:
  definition table + per-user join/progress table.

### Less Obvious Columns

- `NUMERIC(5,2)` or `NUMERIC(8,2)`
  Fixed precision decimal values. Example: `NUMERIC(5,2)` fits values like `180.50`.
- `TIMESTAMPTZ`
  Timestamp with timezone. Use this for actions that happen at a real moment in time.
- `ai_confidence`
  Number from `0` to `1` describing how confident the AI is in a meal classification or estimate.
- `health_score`
  Manual or AI-generated score on a `1-10` scale for meals or workouts.
- `meal_type`
  Controlled meal category: `breakfast`, `lunch`, `dinner`, `snack`, or `other`.
- `quantity`, `unit`, `grams`
  `quantity` + `unit` represent user-friendly input like `2 pcs` or `250 ml`, while `grams` gives a normalized amount for calculations.
- `workout_type`
  Controlled workout category: `strength`, `cardio`, `mobility`, `sport`, or `other`.
- `exercise_order`
  Keeps exercise display order inside one workout.
- `source_type` and `source_id` in `exp_events`
  Polymorphic reference to where EXP came from, for example a workout, challenge, achievement, or meal-related action.
- Recommended `exp_events.source_type` values
  `workout`, `meal`, `challenge`, `quest`, `achievement`, `manual`, and optionally `streak` if streak rewards are handled as separate EXP events.
- `progress_value`
  Current progress toward a challenge or achievement target.
- `progression_mode`, `quest_series_code`, `sequence_order`
  Quest progression metadata. Use `standalone` for independent quests, or `linear` plus a shared `quest_series_code` and increasing `sequence_order` for ordered quest lines.
- `quest_type`
  Controlled quest progress category. Recommended values:
  `onboarding`, `meal_count`, `healthy_meals`, `workout_count`, `strength_sessions`,
  `cardio_sessions`, `mobility_sessions`, `distance_m`, `duration_min`,
  `streak_days`, `program_step`.
- `claimed_at`
  Timestamp for reward claim if unlocking and claiming are treated as separate actions.
- `joined_at`
  Timestamp for when a user starts tracking an achievement before it is unlocked or claimed.

### Why Some Data Is Repeated

- `meals` stores total macros for the full meal.
- `meal_items` stores item-level data for the meal breakdown.
- `workouts` stores workout-level data.
- `workout_exercises` stores exercise-level details.

This is intentional. Parent tables are optimized for quick reads of the full object, while child tables keep the detailed breakdown shown in the UI.

### Action Flows

#### User Registration

1. Insert into `users`.
2. Insert login credentials into `user_auth`.
3. Optionally create `user_profiles`.
4. `user_progress` is created automatically by a database trigger.

#### User Completes Profile

1. Insert or update `user_profiles`.
2. Keep `users` and `user_auth` unchanged unless account data changes.

#### User Logs a Meal

1. Insert one row into `meals`.
2. Insert one or more rows into `meal_items`.
3. Recalculate and persist `meals.total_calories`, `total_protein_g`, `total_carbs_g`, `total_fat_g`.
4. If the meal grants EXP, insert into `exp_events`.
5. Update `user_progress`.

#### User Logs a Workout

1. Insert one row into `workouts`.
2. Optionally insert many rows into `workout_exercises`.
3. If the workout grants EXP, insert into `exp_events`.
4. Update `user_progress`.

#### User Progresses a Challenge

1. Insert definition into `challenges` once.
2. Insert or update the user's row in `user_challenges`.
3. When completed, set `completed_at` and optionally `claimed_at`.
4. If the reward includes EXP, insert into `exp_events` and update `user_progress`.

#### User Progresses a Quest

1. Insert definition into `quests` once.
2. Insert or update the user's row in `user_quests`.
3. When completed, set `completed_at` and optionally `claimed_at`.
4. If the reward includes EXP, insert into `exp_events` with source type `quest` and update `user_progress`.

#### User Unlocks an Achievement

1. Insert definition into `achievements` once.
2. Ensure the achievement definition has a non-null positive `target_value`.
3. Insert the user's row in `user_achievements` through explicit join or tracking.
4. Update progress after the user has joined the achievement.
5. Set `unlocked_at` when the condition is met.
6. If claim is separate, set `claimed_at` later.
7. If the reward includes EXP, insert into `exp_events` and update `user_progress`.

### Current Modeling Decisions

- `user_profiles` is optional, so a user account can exist before profile completion.
- The schema does not currently use `foods`, `products`, or `exercises` reference tables.
- Meal and workout detail tables store direct logged values instead of referencing external dictionaries.
- Challenges are intended for global daily/weekly or otherwise time-bounded events.
- Quests are intended for durable objectives that do not expire on a schedule.
- Linear quests should share one `quest_series_code` and use `sequence_order` to define progression order.
- Standalone quests should leave `quest_series_code` and `sequence_order` as `NULL`.
- Email uniqueness is case-insensitive through a unique index on `LOWER(email)`.
- Username uniqueness is also case-insensitive through a unique index on `LOWER(username)`.
- `exp_events.source_type` is now constrained in SQL to the allowed event source list.

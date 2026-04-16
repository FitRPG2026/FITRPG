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
- Treat migrations as history after the schema is shared outside this dev branch. While the app is still pre-release, this branch may squash migrations back into the baseline.
- Keep each migration focused on one clear change set.
- Use `queries/` only for SQL that is not part of the canonical schema history.
- Keep seed data out of `migrations/` unless the rows are required canonical application data.
- Prefer split seed files in dependency order, with an optional `seed_all.sql` wrapper for convenience.
- Treat `queries/seeds/` as the source of truth. `queries/seed_all.sql` is a flattened convenience script for local manual execution.
- Prefer procedure-driven writes for sample data and multi-table app flows.

## Current Schema

The current application schema is squashed into the ordered migration set in `migrations/`.
At the moment, a fresh database needs `000_init.sql` run against the default `postgres` database,
then the remaining files run against the created `fitrpg` database:

- `001_core_schema.sql`
- `002_progression_schema.sql`
- `003_workflow_procedures.sql`
- `004_seed_support_or_views.sql`

### Main Table Groups

- `users`, `user_auth`, `user_profiles`
  Core account data, login data, and optional profile / health data.
- `meals`
  A meal log with user, timestamp, type, optional photo/notes, and score.
- `workouts`, `gym_workout_exercises`
  A workout log for gym and non-gym activities plus optional exercise-level breakdown for gym workouts only.
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
- Meal nutrition/calorie item breakdown is not stored in the database.
- One gym workout can have many `gym_workout_exercises`.
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
- `workout_type`
  Controlled workout category: `strength`, `cardio`, `mobility`, `sport`, or `other`.
- `activity_category`, `activity_code`, `activity_name`
  UI-level workout taxonomy. `activity_category` is `gym`, `sport`, `general`, or `other`;
  `activity_code` is the backend-friendly normalized activity key such as `basketball`;
  `activity_name` is the display label from the user-facing activity list.
- `exercise_group`, `exercise_code`
  Optional exercise-level taxonomy for gym details. `exercise_group` supports the gym groups used by challenge logic:
  `chest`, `back`, `legs`, `glutes`, `shoulders`, `biceps`, `triceps`, `calves`,
  `core`, `cardio_conditioning`, `calisthenics`, or `other`.
- `exercise_order`
  Keeps exercise display order inside one workout.
- `source_type` and `source_id` in `exp_events`
  Polymorphic reference to where EXP came from, for example a workout, challenge, achievement, or meal-related action.
- Recommended `exp_events.source_type` values
  `workout`, `meal`, `challenge`, `quest`, `achievement`, `manual`, and optionally `streak` if streak rewards are handled as separate EXP events.
- `progress_value`
  Current progress toward a challenge or achievement target.
- `progress_state`
  Optional JSONB progress details owned by the backend for compound definitions.
  Use it for state that cannot fit in one number, for example seen sport codes,
  per-activity counters, covered gym exercise groups, or streak anchors.
- `mechanic_type`
  Progress mechanic for challenges, achievements, and quests:
  `threshold` for one-off checks, `accumulation` for counters or sums, and `streak` for consecutive-day logic.
- `event_trigger`
  Event that should wake the backend progression engine, for example `meal_logged`, `workout_logged`,
  `activity_logged`, `login`, `profile_completed`, or `quest_step_completed`.
- `conditions`
  JSONB rule payload for backend evaluation. Use it for filters and rule details such as
  `{"activity_category":"sport","activity_code":"basketball"}`,
  `{"min_health_score":8}`, or `{"required_activity_codes":["football","handball"]}`.
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
- `last_progress_at`
  Timestamp for the latest challenge, achievement, or quest progress update.
- `last_login_date`, `current_login_streak_days`, `longest_login_streak_days`
  Login streak state stored on `user_auth` so the backend can emit a `login` challenge event without scanning all login history.

### Controlled Values And Constraints

These are the values currently enforced by SQL `CHECK` constraints. Use them in backend validation and UI option lists.

#### Quests

- `quest_type`
  `onboarding`, `meal_count`, `healthy_meals`, `workout_count`, `strength_sessions`,
  `cardio_sessions`, `mobility_sessions`, `distance_m`, `duration_min`,
  `streak_days`, `program_step`.
- `progression_mode`
  `standalone`, `linear`.
- `mechanic_type`
  `threshold`, `accumulation`, `streak`.
- `event_trigger`
  `manual`, `login`, `profile_completed`, `meal_logged`, `workout_logged`,
  `activity_logged`, `hydration_logged`, `quest_step_completed`, `progress_recomputed`.
- `conditions`
  Must be a JSON object.
- `target_value`
  Must be `NULL` or greater than `0`.
- `reward_exp`
  Must be greater than or equal to `0`.
- `sequence_order`
  Must be `NULL` or greater than `0`.
- Linear quest shape
  If `progression_mode = 'standalone'`, `quest_series_code` and `sequence_order` must be `NULL`.
  If `progression_mode = 'linear'`, `quest_series_code` and `sequence_order` must not be `NULL`.

#### Challenges

- `mechanic_type`
  `threshold`, `accumulation`, `streak`.
- `event_trigger`
  `manual`, `login`, `profile_completed`, `meal_logged`, `workout_logged`,
  `activity_logged`, `hydration_logged`, `quest_step_completed`, `progress_recomputed`.
- `challenge_type`
  No enum constraint. Use it only as a loose label/grouping field; backend processing should rely on `mechanic_type`, `event_trigger`, and `conditions`.
- `conditions`
  Must be a JSON object.
- `goal_value`
  Must be `NULL` or greater than `0`.
- `reward_exp`
  Must be greater than or equal to `0`.
- Date range
  `end_date` must be greater than or equal to `start_date`, unless one of them is `NULL`.

#### Achievements

- `mechanic_type`
  `threshold`, `accumulation`, `streak`.
- `event_trigger`
  `manual`, `login`, `profile_completed`, `meal_logged`, `workout_logged`,
  `activity_logged`, `hydration_logged`, `quest_step_completed`, `progress_recomputed`.
- `achievement_type`
  No enum constraint. Use it only as a loose label/grouping field; backend processing should rely on `mechanic_type`, `event_trigger`, and `conditions`.
- `conditions`
  Must be a JSON object.
- `target_value`
  Must be `NULL` or greater than `0`.
- `reward_exp`
  Must be greater than or equal to `0`.
- `code`
  Must not be blank and is unique.
- `title`
  Must not be blank.

#### Meals

- `meal_type`
  `breakfast`, `lunch`, `dinner`, `snack`, `other`.
- `health_score`
  Must be `NULL` or between `1` and `10`.
- `ai_confidence`
  Must be `NULL` or between `0` and `1`.

#### Workouts

- `workout_type`
  `strength`, `cardio`, `mobility`, `sport`, `other`.
- `activity_category`
  `gym`, `sport`, `general`, `other`.
- `duration_min`
  Must be `NULL` or greater than `0`.
- `health_score`
  Must be `NULL` or between `1` and `10`.
- `activity_code`
  Must not be blank if provided.
- `activity_name`
  Must not be blank if provided.

#### Gym Workout Exercises

- `exercise_group`
  `chest`, `back`, `legs`, `glutes`, `shoulders`, `biceps`, `triceps`, `calves`,
  `core`, `cardio_conditioning`, `calisthenics`, `other`.
- `exercise_name`
  Must not be blank.
- `exercise_order`
  Must be `NULL` or greater than `0`.
- `sets`
  Must be `NULL` or greater than `0`.
- `reps`
  Must be `NULL` or greater than `0`.
- `weight_kg`
  Must be `NULL` or greater than or equal to `0`.
- `duration_sec`
  Must be `NULL` or greater than `0`.
- `distance_m`
  Must be `NULL` or greater than or equal to `0`.
- `exercise_code`
  Must not be blank if provided.

### Why Some Data Is Repeated

- `workouts` stores workout-level data.
- `gym_workout_exercises` stores exercise-level details only for workouts where `activity_category = 'gym'`.

This is intentional. Meals keep only the AI/user score and metadata needed by progression.
Workout details are split because non-gym activities only need the workout row, while gym sessions can have concrete exercises.

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
2. Store `health_score` and optional AI confidence/photo metadata.
3. If the meal grants EXP, insert into `exp_events`.
4. Update `user_progress`.

#### User Logs a Workout

1. Insert one row into `workouts`.
2. Store the UI taxonomy in `activity_category`, `activity_code`, and `activity_name`.
3. If `activity_category = 'gym'`, optionally insert many rows into `gym_workout_exercises`, including `exercise_group` and `exercise_code`.
4. If the workout grants EXP, insert into `exp_events`.
5. Update `user_progress`.

#### User Progresses a Challenge

1. Insert definition into `challenges` once.
2. Backend receives an event and fetches only active definitions matching `event_trigger`.
3. Backend evaluates `conditions` from JSONB against the event payload.
4. Insert or update the user's row in `user_challenges`.
5. When completed, set `completed_at` and optionally `claimed_at`.
6. If the reward includes EXP, insert into `exp_events` and update `user_progress`.

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
- Meal item nutrition/calorie values are intentionally not stored; meal progression should use `meals.health_score`.
- Gym exercise detail rows store direct logged values instead of referencing an exercise dictionary.
- Workout activity lists from the UI should map to `activity_category`, `activity_code`, and `activity_name`.
  The current top-level categories are `gym`, `sport`, `general`, and fallback `other`.
- Challenge-like definitions are event-driven. Do not scan every challenge on every request; filter by `event_trigger`, then evaluate JSONB `conditions` in backend code.
- `conditions` is intentionally flexible, but the top-level progression shape is not flexible: use `mechanic_type` for `threshold`, `accumulation`, or `streak`.
- Challenges are intended for global daily/weekly or otherwise time-bounded events.
- Quests are intended for durable objectives that do not expire on a schedule.
- Linear quests should share one `quest_series_code` and use `sequence_order` to define progression order.
- Standalone quests should leave `quest_series_code` and `sequence_order` as `NULL`.
- Email uniqueness is case-insensitive through a unique index on `LOWER(email)`.
- Username uniqueness is also case-insensitive through a unique index on `LOWER(username)`.
- `exp_events.source_type` is now constrained in SQL to the allowed event source list.

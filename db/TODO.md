# DB TODO

- Fix challenge and quest progress when `progress_value` is corrected below the target after completion.
- Decide how downward progress corrections should work: block, clamp, or rollback state.
- Add DB functions/getters for backend reads.
- Add DB views for backend read models.
- Keep progress-state rules consistent between procedures, functions, and views.
- Implement FastAPI progression engine around `event_trigger`, `mechanic_type`, and JSONB `conditions`.
- Define backend condition interpreters for:
  threshold checks, accumulation counters, streak resets, same-day combinations, distinct sport/activity collections, and gym exercise group coverage.
- Normalize UI activity lists into stable `activity_code` and `exercise_code` values before saving workouts.
- Decide whether meal item matching needs normalized food/product codes before adding item-specific achievements like banana counters.

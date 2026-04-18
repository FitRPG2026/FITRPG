CALL proc_create_achievement(
    p_code => 'FIRST_MEAL',
    p_title => 'First Meal Logged',
    p_description => 'Log your first meal in the app.',
    p_achievement_type => 'meal_count',
    p_target_value => 1.00,
    p_reward_exp => 20,
    p_icon_url => 'https://cdn.fitrpg.dev/icons/first_meal.svg',
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'threshold',
    p_event_trigger => 'meal_logged',
    p_conditions => '{}'::jsonb
);

CALL proc_create_achievement(
    p_code => 'FIRST_WORKOUT',
    p_title => 'First Workout Logged',
    p_description => 'Log your first workout in the app.',
    p_achievement_type => 'workout_count',
    p_target_value => 1.00,
    p_reward_exp => 25,
    p_icon_url => 'https://cdn.fitrpg.dev/icons/first_workout.svg',
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'threshold',
    p_event_trigger => 'workout_logged',
    p_conditions => '{}'::jsonb
);

CALL proc_create_achievement(
    p_code => 'STREAK_7',
    p_title => 'Seven Day Streak',
    p_description => 'Stay active for seven consecutive days.',
    p_achievement_type => 'streak_days',
    p_target_value => 7.00,
    p_reward_exp => 35,
    p_icon_url => 'https://cdn.fitrpg.dev/icons/streak_7.svg',
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'streak',
    p_event_trigger => 'activity_logged',
    p_conditions => '{"streak_field": "current_streak_days"}'::jsonb
);

CALL proc_create_achievement(
    p_code => 'MEAL_LOGGER_10',
    p_title => 'Meal Logger',
    p_description => 'Log ten meals.',
    p_achievement_type => 'meal_count',
    p_target_value => 10.00,
    p_reward_exp => 45,
    p_icon_url => 'https://cdn.fitrpg.dev/icons/meal_logger_10.svg',
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'meal_logged',
    p_conditions => '{"progress_delta": 1}'::jsonb
);

CALL proc_create_achievement(
    p_code => 'RUNNER_10K',
    p_title => '10K Runner',
    p_description => 'Reach ten kilometers of running distance.',
    p_achievement_type => 'distance_m',
    p_target_value => 10000.00,
    p_reward_exp => 25,
    p_icon_url => 'https://cdn.fitrpg.dev/icons/runner_10k.svg',
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"activity_category": "general", "activity_code": "running", "workout_type": "cardio", "progress_field": "distance_m"}'::jsonb
);

CALL proc_create_achievement(
    p_code => 'STRENGTH_5',
    p_title => 'Strength Builder',
    p_description => 'Complete five strength workouts.',
    p_achievement_type => 'strength_sessions',
    p_target_value => 5.00,
    p_reward_exp => 30,
    p_icon_url => 'https://cdn.fitrpg.dev/icons/strength_5.svg',
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"activity_category": "gym", "workout_type": "strength", "progress_delta": 1}'::jsonb
);

CALL proc_create_achievement(
    p_code => 'SPORT_SAMPLER',
    p_title => 'Sport Sampler',
    p_description => 'Log three different sport activities.',
    p_achievement_type => 'sport_collection',
    p_target_value => 3.00,
    p_reward_exp => 40,
    p_icon_url => 'https://cdn.fitrpg.dev/icons/sport_sampler.svg',
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"activity_category": "sport", "distinct_activity_codes": true}'::jsonb
);

CALL proc_create_achievement(
    p_code => 'EXERCISE_DETAIL_2',
    p_title => 'Detailed Session',
    p_description => 'Log a gym workout with at least two exercises.',
    p_achievement_type => 'exercise_count',
    p_target_value => 1.00,
    p_reward_exp => 25,
    p_icon_url => 'https://cdn.fitrpg.dev/icons/exercise_detail_2.svg',
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'threshold',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"activity_category": "gym", "min_exercise_count": 2}'::jsonb
);

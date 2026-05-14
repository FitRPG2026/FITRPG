CALL proc_create_challenge(
    p_title => '7-Day Logging Streak',
    p_description => 'Log at least one meal or workout for seven consecutive days.',
    p_challenge_type => 'streak_days',
    p_goal_value => 7.00,
    p_reward_exp => 40,
    p_start_date => '2026-03-10 00:00:00+00',
    p_end_date => '2026-03-31 23:59:59+00',
    p_created_at => '2026-03-10 00:00:00+00',
    p_mechanic_type => 'streak',
    p_event_trigger => 'activity_logged',
    p_conditions => '{"requires_daily_activity": true}'::jsonb
);

CALL proc_create_challenge(
    p_title => 'Three Strength Sessions',
    p_description => 'Complete three strength workouts during the challenge window.',
    p_challenge_type => 'strength_sessions',
    p_goal_value => 3.00,
    p_reward_exp => 80,
    p_start_date => '2026-03-10 00:00:00+00',
    p_end_date => '2026-03-31 23:59:59+00',
    p_created_at => '2026-03-10 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"activity_category": "gym", "workout_type": "strength", "progress_delta": 1}'::jsonb
);

CALL proc_create_challenge(
    p_title => '10K Run Distance',
    p_description => 'Accumulate ten kilometers of running workouts.',
    p_challenge_type => 'distance_m',
    p_goal_value => 10000.00,
    p_reward_exp => 60,
    p_start_date => '2026-03-12 00:00:00+00',
    p_end_date => '2026-03-31 23:59:59+00',
    p_created_at => '2026-03-12 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"activity_category": "general", "activity_code": "running", "workout_type": "cardio", "progress_field": "distance_m"}'::jsonb
);

CALL proc_create_challenge(
    p_title => 'Colorful Plate Week',
    p_description => 'Eat five meals with vegetables or fruit across one week.',
    p_challenge_type => 'healthy_meals',
    p_goal_value => 5.00,
    p_reward_exp => 50,
    p_start_date => '2026-03-14 00:00:00+00',
    p_end_date => '2026-03-28 23:59:59+00',
    p_created_at => '2026-03-14 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'meal_logged',
    p_conditions => '{"min_health_score": 8, "requires_fruit_or_vegetables": true, "progress_delta": 1}'::jsonb
);

CALL proc_create_challenge(
    p_title => 'Weekend Warrior',
    p_description => 'Log two workouts over the weekend.',
    p_challenge_type => 'weekend_workouts',
    p_goal_value => 2.00,
    p_reward_exp => 50,
    p_start_date => '2026-03-20 00:00:00+00',
    p_end_date => '2026-03-22 23:59:59+00',
    p_created_at => '2026-03-20 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"day_of_week": ["saturday", "sunday"], "progress_delta": 1}'::jsonb
);

CALL proc_create_challenge(
    p_title => 'Hydration Habit',
    p_description => 'Hit your hydration target on five separate days.',
    p_challenge_type => 'hydration_days',
    p_goal_value => 5.00,
    p_reward_exp => 30,
    p_start_date => '2026-03-01 00:00:00+00',
    p_end_date => NULL,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'hydration_logged',
    p_conditions => '{"daily_target_required": true, "progress_delta": 1}'::jsonb
);

CALL proc_create_challenge(
    p_title => 'Green Master',
    p_description => 'Log one meal with a high health score and vegetables.',
    p_challenge_type => 'healthy_meals',
    p_goal_value => 1.00,
    p_reward_exp => 35,
    p_start_date => '2026-03-20 00:00:00+00',
    p_end_date => '2026-03-27 23:59:59+00',
    p_created_at => '2026-03-20 00:00:00+00',
    p_mechanic_type => 'threshold',
    p_event_trigger => 'meal_logged',
    p_conditions => '{"min_health_score": 9, "requires_vegetables": true}'::jsonb
);

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
    p_conditions => '{"workout_type": "cardio", "progress_field": "duration_min"}'::jsonb
);

CALL proc_create_challenge(
    p_title => 'Three Login Streak',
    p_description => 'Log in three days in a row.',
    p_challenge_type => 'login_streak_days',
    p_goal_value => 3.00,
    p_reward_exp => 20,
    p_start_date => '2026-03-01 00:00:00+00',
    p_end_date => NULL,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'streak',
    p_event_trigger => 'login',
    p_conditions => '{"streak_field": "current_login_streak_days"}'::jsonb
);

CALL proc_create_challenge(
    p_title => 'Gym Group Tour',
    p_description => 'Log exercises from each main gym exercise group.',
    p_challenge_type => 'exercise_group_coverage',
    p_goal_value => 11.00,
    p_reward_exp => 120,
    p_start_date => '2026-03-01 00:00:00+00',
    p_end_date => NULL,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"activity_category": "gym", "distinct_exercise_groups": ["chest", "back", "legs", "glutes", "shoulders", "biceps", "triceps", "calves", "core", "cardio_conditioning", "calisthenics"]}'::jsonb
);

CALL proc_create_challenge(
    p_title => 'Team Sport Pair',
    p_description => 'Log both football and handball during the challenge window.',
    p_challenge_type => 'sport_combo',
    p_goal_value => 2.00,
    p_reward_exp => 60,
    p_start_date => '2026-03-01 00:00:00+00',
    p_end_date => NULL,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"activity_category": "sport", "required_activity_codes": ["football", "handball"], "distinct_activity_codes": true}'::jsonb
);

CALL proc_create_challenge(
    p_title => 'Basketball Regular',
    p_description => 'Log basketball three times.',
    p_challenge_type => 'sport_sessions',
    p_goal_value => 3.00,
    p_reward_exp => 45,
    p_start_date => '2026-03-01 00:00:00+00',
    p_end_date => NULL,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"activity_category": "sport", "activity_code": "basketball", "progress_delta": 1}'::jsonb
);

CALL proc_create_challenge(
    p_title => 'Sport Explorer',
    p_description => 'Log three sessions for each tracked sport activity.',
    p_challenge_type => 'sport_collection',
    p_goal_value => 3.00,
    p_reward_exp => 100,
    p_start_date => '2026-03-01 00:00:00+00',
    p_end_date => NULL,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"activity_category": "sport", "per_activity_code_target": 3}'::jsonb
);

CALL proc_create_challenge(
    p_title => 'Training Plus Gym Day',
    p_description => 'Log a general workout and a gym workout on the same day.',
    p_challenge_type => 'same_day_combo',
    p_goal_value => 1.00,
    p_reward_exp => 50,
    p_start_date => '2026-03-01 00:00:00+00',
    p_end_date => NULL,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'threshold',
    p_event_trigger => 'activity_logged',
    p_conditions => '{"same_day_activity_categories": ["general", "gym"]}'::jsonb
);

CALL proc_create_challenge(
    p_title => 'Back-to-Back Training',
    p_description => 'Log training on two consecutive days.',
    p_challenge_type => 'training_streak_days',
    p_goal_value => 2.00,
    p_reward_exp => 35,
    p_start_date => '2026-03-01 00:00:00+00',
    p_end_date => NULL,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'streak',
    p_event_trigger => 'activity_logged',
    p_conditions => '{"requires_daily_workout": true}'::jsonb
);

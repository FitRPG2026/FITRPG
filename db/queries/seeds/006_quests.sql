CALL proc_create_quest(
    p_code => 'ONBOARD_PROFILE',
    p_title => 'Profile Apprentice',
    p_description => 'Complete your first profile setup.',
    p_quest_type => 'onboarding',
    p_progression_mode => 'standalone',
    p_quest_series_code => NULL,
    p_sequence_order => NULL,
    p_target_value => 1.00,
    p_reward_exp => 15,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'threshold',
    p_event_trigger => 'profile_completed',
    p_conditions => '{}'::jsonb
);

CALL proc_create_quest(
    p_code => 'FIRST_3_MEALS',
    p_title => 'Meal Habit Starter',
    p_description => 'Log your first three meals.',
    p_quest_type => 'meal_count',
    p_progression_mode => 'standalone',
    p_quest_series_code => NULL,
    p_sequence_order => NULL,
    p_target_value => 3.00,
    p_reward_exp => 20,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'meal_logged',
    p_conditions => '{"progress_delta": 1}'::jsonb
);

CALL proc_create_quest(
    p_code => 'CORE_RESET',
    p_title => 'Core Reset',
    p_description => 'Finish four mobility-focused sessions.',
    p_quest_type => 'mobility_sessions',
    p_progression_mode => 'standalone',
    p_quest_series_code => NULL,
    p_sequence_order => NULL,
    p_target_value => 4.00,
    p_reward_exp => 20,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'accumulation',
    p_event_trigger => 'workout_logged',
    p_conditions => '{"activity_category": "general", "workout_type": "mobility", "progress_delta": 1}'::jsonb
);

CALL proc_create_quest(
    p_code => 'RUN_FOUNDATIONS_01',
    p_title => 'Run Foundations I',
    p_description => 'Finish the first run foundation step.',
    p_quest_type => 'program_step',
    p_progression_mode => 'linear',
    p_quest_series_code => 'RUN_FOUNDATIONS',
    p_sequence_order => 1,
    p_target_value => 1.00,
    p_reward_exp => 15,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'threshold',
    p_event_trigger => 'quest_step_completed',
    p_conditions => '{"program_code": "run_foundations", "step": 1}'::jsonb
);

CALL proc_create_quest(
    p_code => 'RUN_FOUNDATIONS_02',
    p_title => 'Run Foundations II',
    p_description => 'Finish the second run foundation step.',
    p_quest_type => 'program_step',
    p_progression_mode => 'linear',
    p_quest_series_code => 'RUN_FOUNDATIONS',
    p_sequence_order => 2,
    p_target_value => 1.00,
    p_reward_exp => 20,
    p_created_at => '2026-03-01 00:00:00+00',
    p_mechanic_type => 'threshold',
    p_event_trigger => 'quest_step_completed',
    p_conditions => '{"program_code": "run_foundations", "step": 2}'::jsonb
);

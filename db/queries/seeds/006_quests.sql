CALL proc_create_quest('ONBOARD_PROFILE', 'Profile Apprentice', 'Complete your first profile setup.', 'onboarding', 'standalone', NULL, NULL, 1.00, 15, '2026-03-01 00:00:00+00');
CALL proc_create_quest('FIRST_3_MEALS', 'Meal Habit Starter', 'Log your first three meals.', 'meal_count', 'standalone', NULL, NULL, 3.00, 20, '2026-03-01 00:00:00+00');
CALL proc_create_quest('CORE_RESET', 'Core Reset', 'Finish four mobility-focused sessions.', 'mobility_sessions', 'standalone', NULL, NULL, 4.00, 20, '2026-03-01 00:00:00+00');
CALL proc_create_quest('RUN_FOUNDATIONS_01', 'Run Foundations I', 'Finish the first run foundation step.', 'program_step', 'linear', 'RUN_FOUNDATIONS', 1, 1.00, 15, '2026-03-01 00:00:00+00');
CALL proc_create_quest('RUN_FOUNDATIONS_02', 'Run Foundations II', 'Finish the second run foundation step.', 'program_step', 'linear', 'RUN_FOUNDATIONS', 2, 1.00, 20, '2026-03-01 00:00:00+00');

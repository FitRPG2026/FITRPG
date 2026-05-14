DO $$
DECLARE
    v_anna_user_id BIGINT;
    v_bartek_user_id BIGINT;
    v_clara_user_id BIGINT;
    v_diego_user_id BIGINT;
    v_emilia_user_id BIGINT;
    v_filip_user_id BIGINT;
    v_three_strength_sessions_id BIGINT;
    v_colorful_plate_week_id BIGINT;
    v_seven_day_logging_streak_id BIGINT;
    v_run_distance_10k_id BIGINT;
    v_weekend_warrior_id BIGINT;
    v_hydration_habit_id BIGINT;
BEGIN
    SELECT id INTO v_anna_user_id FROM users WHERE email = 'anna.nowak@fitrpg.dev';
    SELECT id INTO v_bartek_user_id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev';
    SELECT id INTO v_clara_user_id FROM users WHERE email = 'clara.zielinska@fitrpg.dev';
    SELECT id INTO v_diego_user_id FROM users WHERE email = 'diego.santos@fitrpg.dev';
    SELECT id INTO v_emilia_user_id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev';
    SELECT id INTO v_filip_user_id FROM users WHERE email = 'filip.mazur@fitrpg.dev';
    SELECT id INTO v_three_strength_sessions_id FROM challenges WHERE title = 'Three Strength Sessions';
    SELECT id INTO v_colorful_plate_week_id FROM challenges WHERE title = 'Colorful Plate Week';
    SELECT id INTO v_seven_day_logging_streak_id FROM challenges WHERE title = '7-Day Logging Streak';
    SELECT id INTO v_run_distance_10k_id FROM challenges WHERE title = '10K Run Distance';
    SELECT id INTO v_weekend_warrior_id FROM challenges WHERE title = 'Weekend Warrior';
    SELECT id INTO v_hydration_habit_id FROM challenges WHERE title = 'Hydration Habit';

    CALL proc_update_challenge_progress(v_anna_user_id, v_three_strength_sessions_id, NULL, 3.00, '2026-03-20 19:05:00+00');
    CALL proc_claim_challenge_reward(v_anna_user_id, v_three_strength_sessions_id, '2026-03-20 19:10:00+00');
    CALL proc_update_challenge_progress(v_anna_user_id, v_colorful_plate_week_id, NULL, 4.00, '2026-03-21 12:00:00+00');

    CALL proc_update_challenge_progress(v_bartek_user_id, v_seven_day_logging_streak_id, NULL, 2.00, '2026-03-20 07:00:00+00');

    CALL proc_update_challenge_progress(v_clara_user_id, v_run_distance_10k_id, NULL, 10000.00, '2026-03-21 17:32:00+00');
    CALL proc_claim_challenge_reward(v_clara_user_id, v_run_distance_10k_id, '2026-03-21 17:40:00+00');
    CALL proc_update_challenge_progress(v_clara_user_id, v_seven_day_logging_streak_id, NULL, 6.00, '2026-03-22 08:35:00+00');

    CALL proc_update_challenge_progress(v_diego_user_id, v_weekend_warrior_id, NULL, 1.00, '2026-03-20 10:00:00+00');
    CALL proc_fail_challenge(v_diego_user_id, v_weekend_warrior_id, '2026-03-22 21:00:00+00');

    CALL proc_update_challenge_progress(v_emilia_user_id, v_colorful_plate_week_id, NULL, 5.00, '2026-03-22 13:10:00+00');
    CALL proc_update_challenge_progress(v_emilia_user_id, v_weekend_warrior_id, NULL, 2.00, '2026-03-22 18:15:00+00');
    CALL proc_claim_challenge_reward(v_emilia_user_id, v_weekend_warrior_id, '2026-03-22 18:20:00+00');

    CALL proc_update_challenge_progress(v_filip_user_id, v_three_strength_sessions_id, NULL, 2.00, '2026-03-22 14:15:00+00');
    CALL proc_update_challenge_progress(v_filip_user_id, v_hydration_habit_id, NULL, 4.00, '2026-03-22 20:00:00+00');
END;
$$;

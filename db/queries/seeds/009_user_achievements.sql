DO $$
DECLARE
    v_anna_user_id BIGINT;
    v_bartek_user_id BIGINT;
    v_clara_user_id BIGINT;
    v_diego_user_id BIGINT;
    v_emilia_user_id BIGINT;
    v_filip_user_id BIGINT;
    v_first_meal_id BIGINT;
    v_first_workout_id BIGINT;
    v_meal_logger_10_id BIGINT;
    v_streak_7_id BIGINT;
    v_runner_10k_id BIGINT;
    v_strength_5_id BIGINT;
BEGIN
    SELECT id INTO v_anna_user_id FROM users WHERE email = 'anna.nowak@fitrpg.dev';
    SELECT id INTO v_bartek_user_id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev';
    SELECT id INTO v_clara_user_id FROM users WHERE email = 'clara.zielinska@fitrpg.dev';
    SELECT id INTO v_diego_user_id FROM users WHERE email = 'diego.santos@fitrpg.dev';
    SELECT id INTO v_emilia_user_id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev';
    SELECT id INTO v_filip_user_id FROM users WHERE email = 'filip.mazur@fitrpg.dev';
    SELECT id INTO v_first_meal_id FROM achievements WHERE code = 'FIRST_MEAL';
    SELECT id INTO v_first_workout_id FROM achievements WHERE code = 'FIRST_WORKOUT';
    SELECT id INTO v_meal_logger_10_id FROM achievements WHERE code = 'MEAL_LOGGER_10';
    SELECT id INTO v_streak_7_id FROM achievements WHERE code = 'STREAK_7';
    SELECT id INTO v_runner_10k_id FROM achievements WHERE code = 'RUNNER_10K';
    SELECT id INTO v_strength_5_id FROM achievements WHERE code = 'STRENGTH_5';

    CALL proc_join_achievement(v_anna_user_id, v_first_meal_id, '2026-03-20 07:36:00+00');
    CALL proc_update_achievement_progress(v_anna_user_id, v_first_meal_id, NULL, 1.00, '2026-03-20 07:37:00+00');
    CALL proc_claim_achievement_reward(v_anna_user_id, v_first_meal_id, '2026-03-20 07:38:00+00');
    CALL proc_join_achievement(v_anna_user_id, v_first_workout_id, '2026-03-20 19:01:00+00');
    CALL proc_update_achievement_progress(v_anna_user_id, v_first_workout_id, NULL, 1.00, '2026-03-20 19:02:00+00');
    CALL proc_claim_achievement_reward(v_anna_user_id, v_first_workout_id, '2026-03-20 19:03:00+00');
    CALL proc_join_achievement(v_anna_user_id, v_meal_logger_10_id, '2026-03-21 16:20:00+00');
    CALL proc_update_achievement_progress(v_anna_user_id, v_meal_logger_10_id, NULL, 3.00, '2026-03-21 16:22:00+00');

    CALL proc_join_achievement(v_bartek_user_id, v_first_meal_id, '2026-03-19 06:56:00+00');
    CALL proc_update_achievement_progress(v_bartek_user_id, v_first_meal_id, NULL, 1.00, '2026-03-19 06:57:00+00');
    CALL proc_join_achievement(v_bartek_user_id, v_streak_7_id, '2026-03-20 12:55:00+00');
    CALL proc_update_achievement_progress(v_bartek_user_id, v_streak_7_id, NULL, 2.00, '2026-03-20 12:56:00+00');

    CALL proc_join_achievement(v_clara_user_id, v_first_workout_id, '2026-03-21 17:30:00+00');
    CALL proc_update_achievement_progress(v_clara_user_id, v_first_workout_id, NULL, 1.00, '2026-03-21 17:31:00+00');
    CALL proc_claim_achievement_reward(v_clara_user_id, v_first_workout_id, '2026-03-21 17:31:30+00');
    CALL proc_join_achievement(v_clara_user_id, v_runner_10k_id, '2026-03-21 17:32:00+00');
    CALL proc_update_achievement_progress(v_clara_user_id, v_runner_10k_id, NULL, 10000.00, '2026-03-21 17:33:00+00');
    CALL proc_claim_achievement_reward(v_clara_user_id, v_runner_10k_id, '2026-03-21 17:45:00+00');

    CALL proc_join_achievement(v_diego_user_id, v_first_workout_id, '2026-03-16 19:00:00+00');
    CALL proc_update_achievement_progress(v_diego_user_id, v_first_workout_id, NULL, 1.00, '2026-03-16 19:01:00+00');

    CALL proc_join_achievement(v_emilia_user_id, v_first_meal_id, '2026-03-22 09:16:00+00');
    CALL proc_update_achievement_progress(v_emilia_user_id, v_first_meal_id, NULL, 1.00, '2026-03-22 09:17:00+00');
    CALL proc_claim_achievement_reward(v_emilia_user_id, v_first_meal_id, '2026-03-22 09:18:00+00');
    CALL proc_join_achievement(v_emilia_user_id, v_meal_logger_10_id, '2026-03-22 16:05:00+00');
    CALL proc_update_achievement_progress(v_emilia_user_id, v_meal_logger_10_id, NULL, 4.00, '2026-03-22 16:06:00+00');

    CALL proc_join_achievement(v_filip_user_id, v_first_workout_id, '2026-03-22 14:10:00+00');
    CALL proc_update_achievement_progress(v_filip_user_id, v_first_workout_id, NULL, 1.00, '2026-03-22 14:11:00+00');
    CALL proc_join_achievement(v_filip_user_id, v_strength_5_id, '2026-03-22 14:11:30+00');
    CALL proc_update_achievement_progress(v_filip_user_id, v_strength_5_id, NULL, 5.00, '2026-03-22 14:12:00+00');
    CALL proc_claim_achievement_reward(v_filip_user_id, v_strength_5_id, '2026-03-22 14:20:00+00');
END;
$$;

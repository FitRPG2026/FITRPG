DO $$
DECLARE
    v_anna_user_id BIGINT;
    v_clara_user_id BIGINT;
    v_diego_user_id BIGINT;
    v_emilia_user_id BIGINT;
    v_filip_user_id BIGINT;
    v_onboard_profile_id BIGINT;
    v_first_3_meals_id BIGINT;
    v_run_foundations_01_id BIGINT;
    v_run_foundations_02_id BIGINT;
    v_core_reset_id BIGINT;
BEGIN
    SELECT id INTO v_anna_user_id FROM users WHERE email = 'anna.nowak@fitrpg.dev';
    SELECT id INTO v_clara_user_id FROM users WHERE email = 'clara.zielinska@fitrpg.dev';
    SELECT id INTO v_diego_user_id FROM users WHERE email = 'diego.santos@fitrpg.dev';
    SELECT id INTO v_emilia_user_id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev';
    SELECT id INTO v_filip_user_id FROM users WHERE email = 'filip.mazur@fitrpg.dev';
    SELECT id INTO v_onboard_profile_id FROM quests WHERE code = 'ONBOARD_PROFILE';
    SELECT id INTO v_first_3_meals_id FROM quests WHERE code = 'FIRST_3_MEALS';
    SELECT id INTO v_run_foundations_01_id FROM quests WHERE code = 'RUN_FOUNDATIONS_01';
    SELECT id INTO v_run_foundations_02_id FROM quests WHERE code = 'RUN_FOUNDATIONS_02';
    SELECT id INTO v_core_reset_id FROM quests WHERE code = 'CORE_RESET';

    CALL proc_update_quest_progress(v_anna_user_id, v_onboard_profile_id, NULL, 1.00, '2026-03-20 08:00:00+00');
    CALL proc_claim_quest_reward(v_anna_user_id, v_onboard_profile_id, '2026-03-20 08:05:00+00');
    CALL proc_update_quest_progress(v_anna_user_id, v_first_3_meals_id, NULL, 3.00, '2026-03-21 16:22:00+00');

    CALL proc_update_quest_progress(v_clara_user_id, v_run_foundations_01_id, NULL, 1.00, '2026-03-20 09:00:00+00');
    CALL proc_claim_quest_reward(v_clara_user_id, v_run_foundations_01_id, '2026-03-20 09:05:00+00');
    CALL proc_update_quest_progress(v_clara_user_id, v_run_foundations_02_id, NULL, 1.00, '2026-03-21 17:34:00+00');

    CALL proc_update_quest_progress(v_diego_user_id, v_first_3_meals_id, NULL, 1.00, '2026-03-15 12:36:00+00');
    CALL proc_start_quest(v_diego_user_id, v_core_reset_id, '2026-03-16 18:00:00+00');
    CALL proc_abandon_quest(v_diego_user_id, v_core_reset_id, '2026-03-17 18:00:00+00');

    CALL proc_update_quest_progress(v_emilia_user_id, v_core_reset_id, NULL, 4.00, '2026-03-22 18:10:00+00');

    CALL proc_update_quest_progress(v_filip_user_id, v_first_3_meals_id, NULL, 2.00, '2026-03-22 20:51:00+00');
END;
$$;

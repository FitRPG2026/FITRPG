-- Login and profile completion are separate user-facing flows.

DO $$
DECLARE
    v_anna_user_id BIGINT;
    v_bartek_user_id BIGINT;
    v_clara_user_id BIGINT;
    v_diego_user_id BIGINT;
    v_emilia_user_id BIGINT;
    v_filip_user_id BIGINT;
    v_grace_user_id BIGINT;
BEGIN
    SELECT id INTO v_anna_user_id FROM users WHERE email = 'anna.nowak@fitrpg.dev';
    SELECT id INTO v_bartek_user_id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev';
    SELECT id INTO v_clara_user_id FROM users WHERE email = 'clara.zielinska@fitrpg.dev';
    SELECT id INTO v_diego_user_id FROM users WHERE email = 'diego.santos@fitrpg.dev';
    SELECT id INTO v_emilia_user_id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev';
    SELECT id INTO v_filip_user_id FROM users WHERE email = 'filip.mazur@fitrpg.dev';
    SELECT id INTO v_grace_user_id FROM users WHERE email = 'grace.demo@fitrpg.dev';

    CALL proc_mark_login(v_anna_user_id, '2026-03-22 07:15:00+00');
    CALL proc_mark_login(v_bartek_user_id, '2026-03-20 06:50:00+00');
    CALL proc_mark_login(v_clara_user_id, '2026-03-22 19:05:00+00');
    CALL proc_mark_login(v_diego_user_id, '2026-03-14 17:40:00+00');
    CALL proc_mark_login(v_emilia_user_id, '2026-03-22 15:30:00+00');
    CALL proc_mark_login(v_filip_user_id, '2026-03-22 20:10:00+00');
    CALL proc_mark_login(v_grace_user_id, '2026-03-10 09:20:00+00');

    CALL proc_upsert_user_profile(v_anna_user_id, 'anna_nowak', 'Anna', '1998-05-14', 'female', 168.00, 62.50, 'build_strength', 'moderate');
    CALL proc_upsert_user_profile(v_bartek_user_id, 'bartek_fit', 'Bartek', '1995-09-02', 'male', 182.00, 86.20, 'lose_weight', 'light');
    CALL proc_upsert_user_profile(v_clara_user_id, 'clara_runs', 'Clara Z.', '2000-01-19', 'female', 171.00, 59.40, 'improve_endurance', 'very_active');
    CALL proc_upsert_user_profile(v_diego_user_id, 'diego_s', 'Diego', '1992-12-11', 'male', 176.00, 91.00, 'restart_habits', 'sedentary');
    CALL proc_upsert_user_profile(v_emilia_user_id, 'emi_balance', 'Emilia', '1997-07-23', 'female', 165.00, 57.80, 'maintain_balance', 'moderate');
    CALL proc_upsert_user_profile(v_filip_user_id, 'filip_lifts', 'Filip', NULL, NULL, 188.00, 95.50, 'gain_muscle', 'active');
END;
$$;

-- Recompute totals from exp history and set streak counters for sample users.

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

    CALL proc_refresh_user_progress(v_anna_user_id, 7, 9);
    CALL proc_refresh_user_progress(v_bartek_user_id, 2, 4);
    CALL proc_refresh_user_progress(v_clara_user_id, 5, 8);
    CALL proc_refresh_user_progress(v_diego_user_id, 1, 3);
    CALL proc_refresh_user_progress(v_emilia_user_id, 4, 6);
    CALL proc_refresh_user_progress(v_filip_user_id, 3, 5);
    CALL proc_refresh_user_progress(v_grace_user_id, 0, 0);
END;
$$;

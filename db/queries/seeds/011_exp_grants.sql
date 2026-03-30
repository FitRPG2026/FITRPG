DO $$
DECLARE
    v_anna_user_id BIGINT;
    v_bartek_user_id BIGINT;
    v_clara_user_id BIGINT;
    v_diego_user_id BIGINT;
BEGIN
    SELECT id INTO v_anna_user_id FROM users WHERE email = 'anna.nowak@fitrpg.dev';
    SELECT id INTO v_bartek_user_id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev';
    SELECT id INTO v_clara_user_id FROM users WHERE email = 'clara.zielinska@fitrpg.dev';
    SELECT id INTO v_diego_user_id FROM users WHERE email = 'diego.santos@fitrpg.dev';

    CALL proc_grant_exp(v_anna_user_id, 'streak', v_anna_user_id, 30, 'Seven-day activity streak reward.', '2026-03-21 06:45:00+00', '2026-03-21 06:45:00+00');
    CALL proc_grant_exp(v_bartek_user_id, 'manual', v_bartek_user_id, 15, 'Welcome bonus from onboarding campaign.', '2026-03-18 08:00:00+00', '2026-03-18 08:00:00+00');
    CALL proc_grant_exp(v_clara_user_id, 'streak', v_clara_user_id, 20, 'Short consistency streak reward.', '2026-03-22 08:40:00+00', '2026-03-22 08:40:00+00');
    CALL proc_grant_exp(v_diego_user_id, 'manual', v_diego_user_id, -5, 'Manual correction after duplicate sync.', '2026-03-16 19:10:00+00', '2026-03-16 19:10:00+00');
END;
$$;

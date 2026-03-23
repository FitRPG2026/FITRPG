CALL proc_grant_exp((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), 'streak', (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), 30, 'Seven-day activity streak reward.', '2026-03-21 06:45:00+00', '2026-03-21 06:45:00+00');

CALL proc_grant_exp((SELECT id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev'), 'manual', (SELECT id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev'), 15, 'Welcome bonus from onboarding campaign.', '2026-03-18 08:00:00+00', '2026-03-18 08:00:00+00');

CALL proc_grant_exp((SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), 'streak', (SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), 20, 'Short consistency streak reward.', '2026-03-22 08:40:00+00', '2026-03-22 08:40:00+00');

CALL proc_grant_exp((SELECT id FROM users WHERE email = 'diego.santos@fitrpg.dev'), 'manual', (SELECT id FROM users WHERE email = 'diego.santos@fitrpg.dev'), -5, 'Manual correction after duplicate sync.', '2026-03-16 19:10:00+00', '2026-03-16 19:10:00+00');

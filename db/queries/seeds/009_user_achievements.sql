CALL proc_update_achievement_progress((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'FIRST_MEAL'), NULL, 1.00, '2026-03-20 07:37:00+00');
CALL proc_claim_achievement_reward((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'FIRST_MEAL'), '2026-03-20 07:38:00+00');
CALL proc_update_achievement_progress((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'FIRST_WORKOUT'), NULL, 1.00, '2026-03-20 19:02:00+00');
CALL proc_claim_achievement_reward((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'FIRST_WORKOUT'), '2026-03-20 19:03:00+00');
CALL proc_update_achievement_progress((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'MEAL_LOGGER_10'), NULL, 3.00, '2026-03-21 16:22:00+00');

CALL proc_update_achievement_progress((SELECT id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'FIRST_MEAL'), NULL, 1.00, '2026-03-19 06:57:00+00');
CALL proc_update_achievement_progress((SELECT id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'STREAK_7'), NULL, 2.00, '2026-03-20 12:56:00+00');

CALL proc_update_achievement_progress((SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'FIRST_WORKOUT'), NULL, 1.00, '2026-03-21 17:31:00+00');
CALL proc_claim_achievement_reward((SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'FIRST_WORKOUT'), '2026-03-21 17:31:30+00');
CALL proc_update_achievement_progress((SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'RUNNER_10K'), NULL, 10000.00, '2026-03-21 17:33:00+00');
CALL proc_claim_achievement_reward((SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'RUNNER_10K'), '2026-03-21 17:45:00+00');

CALL proc_update_achievement_progress((SELECT id FROM users WHERE email = 'diego.santos@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'FIRST_WORKOUT'), NULL, 1.00, '2026-03-16 19:01:00+00');

CALL proc_update_achievement_progress((SELECT id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'FIRST_MEAL'), NULL, 1.00, '2026-03-22 09:17:00+00');
CALL proc_claim_achievement_reward((SELECT id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'FIRST_MEAL'), '2026-03-22 09:18:00+00');
CALL proc_update_achievement_progress((SELECT id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'MEAL_LOGGER_10'), NULL, 4.00, '2026-03-22 16:06:00+00');

CALL proc_update_achievement_progress((SELECT id FROM users WHERE email = 'filip.mazur@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'FIRST_WORKOUT'), NULL, 1.00, '2026-03-22 14:11:00+00');
CALL proc_update_achievement_progress((SELECT id FROM users WHERE email = 'filip.mazur@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'STRENGTH_5'), NULL, 5.00, '2026-03-22 14:12:00+00');
CALL proc_claim_achievement_reward((SELECT id FROM users WHERE email = 'filip.mazur@fitrpg.dev'), (SELECT id FROM achievements WHERE code = 'STRENGTH_5'), '2026-03-22 14:20:00+00');

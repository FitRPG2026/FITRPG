CALL proc_update_challenge_progress((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), (SELECT id FROM challenges WHERE title = 'Three Strength Sessions'), NULL, 3.00, '2026-03-20 19:05:00+00');
CALL proc_claim_challenge_reward((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), (SELECT id FROM challenges WHERE title = 'Three Strength Sessions'), '2026-03-20 19:10:00+00');
CALL proc_update_challenge_progress((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), (SELECT id FROM challenges WHERE title = 'Colorful Plate Week'), NULL, 4.00, '2026-03-21 12:00:00+00');

CALL proc_update_challenge_progress((SELECT id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev'), (SELECT id FROM challenges WHERE title = '7-Day Logging Streak'), NULL, 2.00, '2026-03-20 07:00:00+00');

CALL proc_update_challenge_progress((SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), (SELECT id FROM challenges WHERE title = '10K Run Distance'), NULL, 10000.00, '2026-03-21 17:32:00+00');
CALL proc_claim_challenge_reward((SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), (SELECT id FROM challenges WHERE title = '10K Run Distance'), '2026-03-21 17:40:00+00');
CALL proc_update_challenge_progress((SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), (SELECT id FROM challenges WHERE title = '7-Day Logging Streak'), NULL, 6.00, '2026-03-22 08:35:00+00');

CALL proc_update_challenge_progress((SELECT id FROM users WHERE email = 'diego.santos@fitrpg.dev'), (SELECT id FROM challenges WHERE title = 'Weekend Warrior'), NULL, 1.00, '2026-03-20 10:00:00+00');
CALL proc_fail_challenge((SELECT id FROM users WHERE email = 'diego.santos@fitrpg.dev'), (SELECT id FROM challenges WHERE title = 'Weekend Warrior'), '2026-03-22 21:00:00+00');

CALL proc_update_challenge_progress((SELECT id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev'), (SELECT id FROM challenges WHERE title = 'Colorful Plate Week'), NULL, 5.00, '2026-03-22 13:10:00+00');
CALL proc_update_challenge_progress((SELECT id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev'), (SELECT id FROM challenges WHERE title = 'Weekend Warrior'), NULL, 2.00, '2026-03-22 18:15:00+00');
CALL proc_claim_challenge_reward((SELECT id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev'), (SELECT id FROM challenges WHERE title = 'Weekend Warrior'), '2026-03-22 18:20:00+00');

CALL proc_update_challenge_progress((SELECT id FROM users WHERE email = 'filip.mazur@fitrpg.dev'), (SELECT id FROM challenges WHERE title = 'Three Strength Sessions'), NULL, 2.00, '2026-03-22 14:15:00+00');
CALL proc_update_challenge_progress((SELECT id FROM users WHERE email = 'filip.mazur@fitrpg.dev'), (SELECT id FROM challenges WHERE title = 'Hydration Habit'), NULL, 4.00, '2026-03-22 20:00:00+00');

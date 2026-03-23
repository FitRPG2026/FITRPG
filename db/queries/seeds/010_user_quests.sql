CALL proc_update_quest_progress((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), (SELECT id FROM quests WHERE code = 'ONBOARD_PROFILE'), NULL, 1.00, '2026-03-20 08:00:00+00');
CALL proc_claim_quest_reward((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), (SELECT id FROM quests WHERE code = 'ONBOARD_PROFILE'), '2026-03-20 08:05:00+00');
CALL proc_update_quest_progress((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), (SELECT id FROM quests WHERE code = 'FIRST_3_MEALS'), NULL, 3.00, '2026-03-21 16:22:00+00');

CALL proc_update_quest_progress((SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), (SELECT id FROM quests WHERE code = 'RUN_FOUNDATIONS_01'), NULL, 1.00, '2026-03-20 09:00:00+00');
CALL proc_claim_quest_reward((SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), (SELECT id FROM quests WHERE code = 'RUN_FOUNDATIONS_01'), '2026-03-20 09:05:00+00');
CALL proc_update_quest_progress((SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), (SELECT id FROM quests WHERE code = 'RUN_FOUNDATIONS_02'), NULL, 1.00, '2026-03-21 17:34:00+00');

CALL proc_update_quest_progress((SELECT id FROM users WHERE email = 'diego.santos@fitrpg.dev'), (SELECT id FROM quests WHERE code = 'FIRST_3_MEALS'), NULL, 1.00, '2026-03-15 12:36:00+00');
CALL proc_start_quest((SELECT id FROM users WHERE email = 'diego.santos@fitrpg.dev'), (SELECT id FROM quests WHERE code = 'CORE_RESET'), '2026-03-16 18:00:00+00');
CALL proc_abandon_quest((SELECT id FROM users WHERE email = 'diego.santos@fitrpg.dev'), (SELECT id FROM quests WHERE code = 'CORE_RESET'), '2026-03-17 18:00:00+00');

CALL proc_update_quest_progress((SELECT id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev'), (SELECT id FROM quests WHERE code = 'CORE_RESET'), NULL, 4.00, '2026-03-22 18:10:00+00');

CALL proc_update_quest_progress((SELECT id FROM users WHERE email = 'filip.mazur@fitrpg.dev'), (SELECT id FROM quests WHERE code = 'FIRST_3_MEALS'), NULL, 2.00, '2026-03-22 20:51:00+00');

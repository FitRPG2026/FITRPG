-- Recompute totals from exp history and set streak counters for sample users.

CALL proc_refresh_user_progress((SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'), 7, 9);
CALL proc_refresh_user_progress((SELECT id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev'), 2, 4);
CALL proc_refresh_user_progress((SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'), 5, 8);
CALL proc_refresh_user_progress((SELECT id FROM users WHERE email = 'diego.santos@fitrpg.dev'), 1, 3);
CALL proc_refresh_user_progress((SELECT id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev'), 4, 6);
CALL proc_refresh_user_progress((SELECT id FROM users WHERE email = 'filip.mazur@fitrpg.dev'), 3, 5);
CALL proc_refresh_user_progress((SELECT id FROM users WHERE email = 'grace.demo@fitrpg.dev'), 0, 0);

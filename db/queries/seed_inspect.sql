-- Single-query helper for checking seeded data in one result grid.
-- Shows up to 20 rows per table.

WITH snapshot AS (
    SELECT
        'users' AS table_name,
        u.id AS row_id,
        to_jsonb(u) AS row_data
    FROM (
        SELECT *
        FROM users
        ORDER BY id
        LIMIT 20
    ) u

    UNION ALL

    SELECT
        'user_auth' AS table_name,
        ua.user_id AS row_id,
        to_jsonb(ua) || jsonb_build_object('email', u.email) AS row_data
    FROM (
        SELECT *
        FROM user_auth
        ORDER BY user_id
        LIMIT 20
    ) ua
    JOIN users u ON u.id = ua.user_id

    UNION ALL

    SELECT
        'user_profiles' AS table_name,
        upf.user_id AS row_id,
        to_jsonb(upf) || jsonb_build_object('email', u.email) AS row_data
    FROM (
        SELECT *
        FROM user_profiles
        ORDER BY user_id
        LIMIT 20
    ) upf
    JOIN users u ON u.id = upf.user_id

    UNION ALL

    SELECT
        'user_progress' AS table_name,
        prog.user_id AS row_id,
        to_jsonb(prog) || jsonb_build_object('email', u.email) AS row_data
    FROM (
        SELECT *
        FROM user_progress
        ORDER BY user_id
        LIMIT 20
    ) prog
    JOIN users u ON u.id = prog.user_id

    UNION ALL

    SELECT
        'challenges' AS table_name,
        c.id AS row_id,
        to_jsonb(c) AS row_data
    FROM (
        SELECT *
        FROM challenges
        ORDER BY id
        LIMIT 20
    ) c

    UNION ALL

    SELECT
        'user_challenges' AS table_name,
        uc.id AS row_id,
        to_jsonb(uc)
            || jsonb_build_object('email', u.email, 'challenge_title', c.title) AS row_data
    FROM (
        SELECT *
        FROM user_challenges
        ORDER BY id
        LIMIT 20
    ) uc
    JOIN users u ON u.id = uc.user_id
    JOIN challenges c ON c.id = uc.challenge_id

    UNION ALL

    SELECT
        'achievements' AS table_name,
        a.id AS row_id,
        to_jsonb(a) AS row_data
    FROM (
        SELECT *
        FROM achievements
        ORDER BY id
        LIMIT 20
    ) a

    UNION ALL

    SELECT
        'user_achievements' AS table_name,
        ua.id AS row_id,
        to_jsonb(ua)
            || jsonb_build_object('email', u.email, 'achievement_code', a.code, 'achievement_title', a.title) AS row_data
    FROM (
        SELECT *
        FROM user_achievements
        ORDER BY id
        LIMIT 20
    ) ua
    JOIN users u ON u.id = ua.user_id
    JOIN achievements a ON a.id = ua.achievement_id

    UNION ALL

    SELECT
        'quests' AS table_name,
        q.id AS row_id,
        to_jsonb(q) AS row_data
    FROM (
        SELECT *
        FROM quests
        ORDER BY id
        LIMIT 20
    ) q

    UNION ALL

    SELECT
        'user_quests' AS table_name,
        uq.id AS row_id,
        to_jsonb(uq)
            || jsonb_build_object('email', u.email, 'quest_code', q.code, 'quest_title', q.title) AS row_data
    FROM (
        SELECT *
        FROM user_quests
        ORDER BY id
        LIMIT 20
    ) uq
    JOIN users u ON u.id = uq.user_id
    JOIN quests q ON q.id = uq.quest_id

    UNION ALL

    SELECT
        'meals' AS table_name,
        m.id AS row_id,
        to_jsonb(m) || jsonb_build_object('email', u.email) AS row_data
    FROM (
        SELECT *
        FROM meals
        ORDER BY id
        LIMIT 20
    ) m
    JOIN users u ON u.id = m.user_id

    UNION ALL

    SELECT
        'meal_items' AS table_name,
        mi.id AS row_id,
        to_jsonb(mi)
            || jsonb_build_object('email', u.email, 'meal_title', m.title, 'meal_type', m.meal_type) AS row_data
    FROM (
        SELECT *
        FROM meal_items
        ORDER BY id
        LIMIT 20
    ) mi
    JOIN meals m ON m.id = mi.meal_id
    JOIN users u ON u.id = m.user_id

    UNION ALL

    SELECT
        'workouts' AS table_name,
        w.id AS row_id,
        to_jsonb(w) || jsonb_build_object('email', u.email) AS row_data
    FROM (
        SELECT *
        FROM workouts
        ORDER BY id
        LIMIT 20
    ) w
    JOIN users u ON u.id = w.user_id

    UNION ALL

    SELECT
        'workout_exercises' AS table_name,
        we.id AS row_id,
        to_jsonb(we)
            || jsonb_build_object('email', u.email, 'workout_title', w.title, 'workout_type', w.workout_type) AS row_data
    FROM (
        SELECT *
        FROM workout_exercises
        ORDER BY id
        LIMIT 20
    ) we
    JOIN workouts w ON w.id = we.workout_id
    JOIN users u ON u.id = w.user_id

    UNION ALL

    SELECT
        'exp_events' AS table_name,
        ee.id AS row_id,
        to_jsonb(ee) || jsonb_build_object('email', u.email) AS row_data
    FROM (
        SELECT *
        FROM exp_events
        ORDER BY id
        LIMIT 20
    ) ee
    JOIN users u ON u.id = ee.user_id
)
SELECT
    table_name,
    row_id,
    row_data
FROM snapshot
ORDER BY table_name, row_id;

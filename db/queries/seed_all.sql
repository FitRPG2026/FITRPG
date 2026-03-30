-- Convenience all-in-one seed script for local manual execution.
-- Canonical seed files live in db/queries/seeds/.

-- >>> BEGIN seeds/001_users.sql

-- Seed users through the registration procedure so auth and user_progress are created by flow.

CALL proc_register_user('anna.nowak@fitrpg.dev', '$2b$12$anna_demo_hash', 'active');
CALL proc_register_user('bartek.kowalski@fitrpg.dev', '$2b$12$bartek_demo_hash', 'active');
CALL proc_register_user('clara.zielinska@fitrpg.dev', '$2b$12$clara_demo_hash', 'active');
CALL proc_register_user('diego.santos@fitrpg.dev', '$2b$12$diego_demo_hash', 'inactive');
CALL proc_register_user('emilia.wisniewska@fitrpg.dev', '$2b$12$emilia_demo_hash', 'active');
CALL proc_register_user('filip.mazur@fitrpg.dev', '$2b$12$filip_demo_hash', 'active');
CALL proc_register_user('grace.demo@fitrpg.dev', '$2b$12$grace_demo_hash', 'banned');

-- <<< END seeds/001_users.sql

-- >>> BEGIN seeds/002_user_auth_profiles.sql

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

-- <<< END seeds/002_user_auth_profiles.sql

-- >>> BEGIN seeds/003_challenges.sql

CALL proc_create_challenge('7-Day Logging Streak', 'Log at least one meal or workout for seven consecutive days.', 'streak_days', 7.00, 40, '2026-03-10 00:00:00+00', '2026-03-31 23:59:59+00', '2026-03-10 00:00:00+00');
CALL proc_create_challenge('Three Strength Sessions', 'Complete three strength workouts during the challenge window.', 'strength_sessions', 3.00, 80, '2026-03-10 00:00:00+00', '2026-03-31 23:59:59+00', '2026-03-10 00:00:00+00');
CALL proc_create_challenge('10K Run Distance', 'Accumulate ten kilometers of running workouts.', 'distance_m', 10000.00, 60, '2026-03-12 00:00:00+00', '2026-03-31 23:59:59+00', '2026-03-12 00:00:00+00');
CALL proc_create_challenge('Colorful Plate Week', 'Eat five meals with vegetables or fruit across one week.', 'healthy_meals', 5.00, 50, '2026-03-14 00:00:00+00', '2026-03-28 23:59:59+00', '2026-03-14 00:00:00+00');
CALL proc_create_challenge('Weekend Warrior', 'Log two workouts over the weekend.', 'weekend_workouts', 2.00, 50, '2026-03-20 00:00:00+00', '2026-03-22 23:59:59+00', '2026-03-20 00:00:00+00');
CALL proc_create_challenge('Hydration Habit', 'Hit your hydration target on five separate days.', 'hydration_days', 5.00, 30, '2026-03-01 00:00:00+00', NULL, '2026-03-01 00:00:00+00');

-- <<< END seeds/003_challenges.sql

-- >>> BEGIN seeds/004_achievements.sql

CALL proc_create_achievement('FIRST_MEAL', 'First Meal Logged', 'Log your first meal in the app.', 'meal_count', 1.00, 20, 'https://cdn.fitrpg.dev/icons/first_meal.svg', '2026-03-01 00:00:00+00');
CALL proc_create_achievement('FIRST_WORKOUT', 'First Workout Logged', 'Log your first workout in the app.', 'workout_count', 1.00, 25, 'https://cdn.fitrpg.dev/icons/first_workout.svg', '2026-03-01 00:00:00+00');
CALL proc_create_achievement('STREAK_7', 'Seven Day Streak', 'Stay active for seven consecutive days.', 'streak_days', 7.00, 35, 'https://cdn.fitrpg.dev/icons/streak_7.svg', '2026-03-01 00:00:00+00');
CALL proc_create_achievement('MEAL_LOGGER_10', 'Meal Logger', 'Log ten meals.', 'meal_count', 10.00, 45, 'https://cdn.fitrpg.dev/icons/meal_logger_10.svg', '2026-03-01 00:00:00+00');
CALL proc_create_achievement('RUNNER_10K', '10K Runner', 'Reach ten kilometers of running distance.', 'distance_m', 10000.00, 25, 'https://cdn.fitrpg.dev/icons/runner_10k.svg', '2026-03-01 00:00:00+00');
CALL proc_create_achievement('STRENGTH_5', 'Strength Builder', 'Complete five strength workouts.', 'strength_sessions', 5.00, 30, 'https://cdn.fitrpg.dev/icons/strength_5.svg', '2026-03-01 00:00:00+00');

-- <<< END seeds/004_achievements.sql

-- >>> BEGIN seeds/005_meals.sql

DO $seed$
DECLARE
    v_anna_user_id BIGINT;
    v_bartek_user_id BIGINT;
    v_clara_user_id BIGINT;
    v_diego_user_id BIGINT;
    v_emilia_user_id BIGINT;
    v_filip_user_id BIGINT;
BEGIN
    SELECT id INTO v_anna_user_id FROM users WHERE email = 'anna.nowak@fitrpg.dev';
    SELECT id INTO v_bartek_user_id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev';
    SELECT id INTO v_clara_user_id FROM users WHERE email = 'clara.zielinska@fitrpg.dev';
    SELECT id INTO v_diego_user_id FROM users WHERE email = 'diego.santos@fitrpg.dev';
    SELECT id INTO v_emilia_user_id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev';
    SELECT id INTO v_filip_user_id FROM users WHERE email = 'filip.mazur@fitrpg.dev';

CALL proc_log_meal(
    p_user_id => v_anna_user_id,
    p_meal_type => 'breakfast',
    p_eaten_at => '2026-03-20 07:35:00+00',
    p_title => 'High Protein Oats',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/high_protein_oats.jpg',
    p_notes => 'Added berries after training.',
    p_health_score => 9::SMALLINT,
    p_ai_confidence => 0.962,
    p_items => $$[
        {"item_name":"Oats","quantity":80.00,"unit":"g","grams":80.00,"calories":311.00,"protein_g":10.00,"carbs_g":53.00,"fat_g":5.50,"health_score":9},
        {"item_name":"Skyr","quantity":150.00,"unit":"g","grams":150.00,"calories":96.00,"protein_g":17.00,"carbs_g":6.00,"fat_g":0.20,"health_score":9},
        {"item_name":"Blueberries","quantity":60.00,"unit":"g","grams":60.00,"calories":34.00,"protein_g":0.40,"carbs_g":8.00,"fat_g":0.20,"health_score":10}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 10,
    p_exp_reason => 'Logged a high-quality breakfast.',
    p_exp_created_at => '2026-03-20 07:37:00+00'
);

CALL proc_log_meal(
    p_user_id => v_anna_user_id,
    p_meal_type => 'lunch',
    p_eaten_at => '2026-03-20 13:10:00+00',
    p_title => 'Chicken Power Bowl',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/chicken_power_bowl.jpg',
    p_notes => 'Meal-prepped bowl with rice and avocado.',
    p_health_score => 8::SMALLINT,
    p_ai_confidence => 0.911,
    p_items => $$[
        {"item_name":"Chicken breast","quantity":160.00,"unit":"g","grams":160.00,"calories":264.00,"protein_g":49.00,"carbs_g":0.00,"fat_g":5.80,"health_score":9},
        {"item_name":"Cooked rice","quantity":180.00,"unit":"g","grams":180.00,"calories":234.00,"protein_g":4.50,"carbs_g":50.00,"fat_g":0.40,"health_score":7},
        {"item_name":"Avocado","quantity":70.00,"unit":"g","grams":70.00,"calories":112.00,"protein_g":1.40,"carbs_g":6.00,"fat_g":10.50,"health_score":9},
        {"item_name":"Roasted vegetables","quantity":150.00,"unit":"g","grams":150.00,"calories":100.00,"protein_g":3.00,"carbs_g":12.00,"fat_g":7.30,"health_score":8}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 15,
    p_exp_reason => 'Logged a balanced lunch.',
    p_exp_created_at => '2026-03-20 13:13:00+00'
);

CALL proc_log_meal(
    p_user_id => v_anna_user_id,
    p_meal_type => 'snack',
    p_eaten_at => '2026-03-21 16:20:00+00',
    p_title => 'Greek Yogurt Snack',
    p_notes => 'Fast snack between meetings.',
    p_health_score => 8::SMALLINT,
    p_items => $$[
        {"item_name":"Greek yogurt","quantity":170.00,"unit":"g","grams":170.00,"calories":146.00,"protein_g":17.00,"carbs_g":6.00,"fat_g":5.00,"health_score":8},
        {"item_name":"Honey","quantity":15.00,"unit":"g","grams":15.00,"calories":46.00,"protein_g":0.00,"carbs_g":12.00,"fat_g":0.00,"health_score":6},
        {"item_name":"Walnuts","quantity":12.00,"unit":"g","grams":12.00,"calories":79.00,"protein_g":1.80,"carbs_g":1.00,"fat_g":7.80,"health_score":8}
    ]$$::jsonb
);

CALL proc_log_meal(
    p_user_id => v_bartek_user_id,
    p_meal_type => 'breakfast',
    p_eaten_at => '2026-03-19 06:55:00+00',
    p_title => 'Office Breakfast Wrap',
    p_notes => 'Grabbed on the way to work.',
    p_health_score => 6::SMALLINT,
    p_ai_confidence => 0.702,
    p_items => $$[
        {"item_name":"Tortilla wrap","quantity":1.00,"unit":"pcs","grams":70.00,"calories":220.00,"protein_g":6.00,"carbs_g":36.00,"fat_g":5.00,"health_score":6},
        {"item_name":"Scrambled eggs","quantity":2.00,"unit":"pcs","grams":100.00,"calories":155.00,"protein_g":13.00,"carbs_g":1.00,"fat_g":11.00,"health_score":7},
        {"item_name":"Cheddar cheese","quantity":25.00,"unit":"g","grams":25.00,"calories":101.00,"protein_g":6.00,"carbs_g":1.00,"fat_g":8.00,"health_score":5},
        {"item_name":"Tomato salsa","quantity":40.00,"unit":"g","grams":40.00,"calories":34.00,"protein_g":0.50,"carbs_g":8.00,"fat_g":0.20,"health_score":8}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 10,
    p_exp_reason => 'Logged breakfast during workday.',
    p_exp_created_at => '2026-03-19 06:57:00+00'
);

CALL proc_log_meal(
    p_user_id => v_bartek_user_id,
    p_meal_type => 'dinner',
    p_eaten_at => '2026-03-20 19:15:00+00',
    p_title => 'Salmon Rice Plate',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/salmon_rice_plate.jpg',
    p_notes => 'Restaurant dinner, estimate adjusted manually.',
    p_health_score => 8::SMALLINT,
    p_ai_confidence => 0.834,
    p_items => $$[
        {"item_name":"Salmon fillet","quantity":170.00,"unit":"g","grams":170.00,"calories":354.00,"protein_g":34.00,"carbs_g":0.00,"fat_g":22.00,"health_score":9},
        {"item_name":"Jasmine rice","quantity":170.00,"unit":"g","grams":170.00,"calories":221.00,"protein_g":4.00,"carbs_g":48.00,"fat_g":0.40,"health_score":7},
        {"item_name":"Cucumber salad","quantity":120.00,"unit":"g","grams":120.00,"calories":58.00,"protein_g":1.00,"carbs_g":7.00,"fat_g":3.00,"health_score":8}
    ]$$::jsonb
);

CALL proc_log_meal(
    p_user_id => v_clara_user_id,
    p_meal_type => 'snack',
    p_eaten_at => '2026-03-21 17:45:00+00',
    p_title => 'Post Run Smoothie',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/post_run_smoothie.jpg',
    p_notes => 'Recovery smoothie after tempo run.',
    p_health_score => 9::SMALLINT,
    p_ai_confidence => 0.955,
    p_items => $$[
        {"item_name":"Banana","quantity":1.00,"unit":"pcs","grams":120.00,"calories":105.00,"protein_g":1.30,"carbs_g":27.00,"fat_g":0.40,"health_score":8},
        {"item_name":"Protein powder","quantity":30.00,"unit":"g","grams":30.00,"calories":120.00,"protein_g":24.00,"carbs_g":3.00,"fat_g":1.50,"health_score":8},
        {"item_name":"Oat milk","quantity":250.00,"unit":"ml","grams":250.00,"calories":105.00,"protein_g":1.00,"carbs_g":8.00,"fat_g":5.00,"health_score":7}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 12,
    p_exp_reason => 'Recovery meal logged after training.',
    p_exp_created_at => '2026-03-21 17:48:00+00'
);

CALL proc_log_meal(
    p_user_id => v_clara_user_id,
    p_meal_type => 'dinner',
    p_eaten_at => '2026-03-21 20:15:00+00',
    p_title => 'Veggie Pasta Dinner',
    p_notes => 'Homemade whole-grain pasta.',
    p_health_score => 8::SMALLINT,
    p_items => $$[
        {"item_name":"Whole-grain pasta","quantity":110.00,"unit":"g","grams":110.00,"calories":380.00,"protein_g":15.00,"carbs_g":72.00,"fat_g":2.00,"health_score":8},
        {"item_name":"Tomato sauce","quantity":140.00,"unit":"g","grams":140.00,"calories":72.00,"protein_g":2.00,"carbs_g":12.00,"fat_g":1.50,"health_score":8},
        {"item_name":"Parmesan","quantity":18.00,"unit":"g","grams":18.00,"calories":77.00,"protein_g":7.00,"carbs_g":1.00,"fat_g":5.00,"health_score":7},
        {"item_name":"Zucchini and peppers","quantity":160.00,"unit":"g","grams":160.00,"calories":61.00,"protein_g":1.50,"carbs_g":10.00,"fat_g":1.80,"health_score":9}
    ]$$::jsonb
);

CALL proc_log_meal(
    p_user_id => v_diego_user_id,
    p_meal_type => 'lunch',
    p_eaten_at => '2026-03-15 12:30:00+00',
    p_title => 'Quick Convenience Lunch',
    p_notes => 'Logged to restart tracking habit.',
    p_health_score => 4::SMALLINT,
    p_items => $$[
        {"item_name":"Ham sandwich","quantity":1.00,"unit":"pcs","grams":210.00,"calories":430.00,"protein_g":17.00,"carbs_g":42.00,"fat_g":17.00,"health_score":4},
        {"item_name":"Potato chips","quantity":45.00,"unit":"g","grams":45.00,"calories":239.00,"protein_g":3.00,"carbs_g":27.00,"fat_g":14.00,"health_score":2},
        {"item_name":"Cola","quantity":330.00,"unit":"ml","grams":330.00,"calories":139.00,"protein_g":0.00,"carbs_g":35.00,"fat_g":0.00,"health_score":1}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 5,
    p_exp_reason => 'Logged a meal after a long gap.',
    p_exp_created_at => '2026-03-15 12:36:00+00'
);

CALL proc_log_meal(
    p_user_id => v_emilia_user_id,
    p_meal_type => 'breakfast',
    p_eaten_at => '2026-03-22 09:10:00+00',
    p_title => 'Weekend Pancakes',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/weekend_pancakes.jpg',
    p_notes => 'Shared breakfast, estimated half portion.',
    p_health_score => 6::SMALLINT,
    p_ai_confidence => 0.821,
    p_items => $$[
        {"item_name":"Pancakes","quantity":3.00,"unit":"pcs","grams":210.00,"calories":366.00,"protein_g":9.00,"carbs_g":52.00,"fat_g":11.00,"health_score":6},
        {"item_name":"Maple syrup","quantity":25.00,"unit":"g","grams":25.00,"calories":65.00,"protein_g":0.00,"carbs_g":17.00,"fat_g":0.00,"health_score":4},
        {"item_name":"Strawberries","quantity":90.00,"unit":"g","grams":90.00,"calories":29.00,"protein_g":0.70,"carbs_g":7.00,"fat_g":0.30,"health_score":10},
        {"item_name":"Greek yogurt topping","quantity":80.00,"unit":"g","grams":80.00,"calories":80.00,"protein_g":7.30,"carbs_g":3.00,"fat_g":2.80,"health_score":8}
    ]$$::jsonb
);

CALL proc_log_meal(
    p_user_id => v_emilia_user_id,
    p_meal_type => 'lunch',
    p_eaten_at => '2026-03-22 13:05:00+00',
    p_title => 'Mediterranean Salad',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/mediterranean_salad.jpg',
    p_notes => 'Mostly manual corrections after scan.',
    p_health_score => 9::SMALLINT,
    p_ai_confidence => 0.943,
    p_items => $$[
        {"item_name":"Mixed greens","quantity":70.00,"unit":"g","grams":70.00,"calories":18.00,"protein_g":1.50,"carbs_g":2.00,"fat_g":0.20,"health_score":10},
        {"item_name":"Chickpeas","quantity":100.00,"unit":"g","grams":100.00,"calories":164.00,"protein_g":9.00,"carbs_g":27.00,"fat_g":2.60,"health_score":8},
        {"item_name":"Feta cheese","quantity":45.00,"unit":"g","grams":45.00,"calories":119.00,"protein_g":6.50,"carbs_g":2.00,"fat_g":9.60,"health_score":7},
        {"item_name":"Olive oil dressing","quantity":12.00,"unit":"g","grams":12.00,"calories":108.00,"protein_g":0.00,"carbs_g":0.00,"fat_g":12.00,"health_score":7}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 14,
    p_exp_reason => 'Logged nutrient-dense lunch.',
    p_exp_created_at => '2026-03-22 13:10:00+00'
);

CALL proc_log_meal(
    p_user_id => v_emilia_user_id,
    p_meal_type => 'snack',
    p_eaten_at => '2026-03-22 16:05:00+00',
    p_title => 'Apple Peanut Snack',
    p_health_score => 7::SMALLINT,
    p_items => $$[
        {"item_name":"Apple","quantity":1.00,"unit":"pcs","grams":180.00,"calories":95.00,"protein_g":0.50,"carbs_g":25.00,"fat_g":0.30,"health_score":9},
        {"item_name":"Peanut butter","quantity":25.00,"unit":"g","grams":25.00,"calories":148.00,"protein_g":6.00,"carbs_g":4.00,"fat_g":12.60,"health_score":6}
    ]$$::jsonb
);

CALL proc_log_meal(
    p_user_id => v_filip_user_id,
    p_meal_type => 'snack',
    p_eaten_at => '2026-03-22 14:40:00+00',
    p_title => 'Protein Shake',
    p_notes => 'Post leg day shake.',
    p_health_score => 8::SMALLINT,
    p_items => $$[
        {"item_name":"Whey protein","quantity":35.00,"unit":"g","grams":35.00,"calories":140.00,"protein_g":28.00,"carbs_g":4.00,"fat_g":2.50,"health_score":8},
        {"item_name":"Banana","quantity":1.00,"unit":"pcs","grams":120.00,"calories":105.00,"protein_g":1.30,"carbs_g":27.00,"fat_g":0.40,"health_score":8},
        {"item_name":"Milk","quantity":200.00,"unit":"ml","grams":200.00,"calories":103.00,"protein_g":6.80,"carbs_g":10.00,"fat_g":5.10,"health_score":7}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 8,
    p_exp_reason => 'Logged post-workout snack.',
    p_exp_created_at => '2026-03-22 14:42:00+00'
);

CALL proc_log_meal(
    p_user_id => v_filip_user_id,
    p_meal_type => 'dinner',
    p_eaten_at => '2026-03-22 20:45:00+00',
    p_title => 'Sushi Dinner',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/sushi_dinner.jpg',
    p_notes => 'Dinner after basketball with friends.',
    p_health_score => 7::SMALLINT,
    p_ai_confidence => 0.776,
    p_items => $$[
        {"item_name":"Salmon nigiri","quantity":6.00,"unit":"pcs","grams":210.00,"calories":290.00,"protein_g":18.00,"carbs_g":33.00,"fat_g":8.00,"health_score":8},
        {"item_name":"California rolls","quantity":8.00,"unit":"pcs","grams":220.00,"calories":255.00,"protein_g":8.00,"carbs_g":38.00,"fat_g":7.00,"health_score":7},
        {"item_name":"Miso soup","quantity":1.00,"unit":"bowl","grams":240.00,"calories":70.00,"protein_g":5.00,"carbs_g":8.00,"fat_g":2.50,"health_score":8}
    ]$$::jsonb
);
END;
$seed$;

-- <<< END seeds/005_meals.sql

-- >>> BEGIN seeds/006_quests.sql

CALL proc_create_quest('ONBOARD_PROFILE', 'Profile Apprentice', 'Complete your first profile setup.', 'onboarding', 'standalone', NULL, NULL, 1.00, 15, '2026-03-01 00:00:00+00');
CALL proc_create_quest('FIRST_3_MEALS', 'Meal Habit Starter', 'Log your first three meals.', 'meal_count', 'standalone', NULL, NULL, 3.00, 20, '2026-03-01 00:00:00+00');
CALL proc_create_quest('CORE_RESET', 'Core Reset', 'Finish four mobility-focused sessions.', 'mobility_sessions', 'standalone', NULL, NULL, 4.00, 20, '2026-03-01 00:00:00+00');
CALL proc_create_quest('RUN_FOUNDATIONS_01', 'Run Foundations I', 'Finish the first run foundation step.', 'program_step', 'linear', 'RUN_FOUNDATIONS', 1, 1.00, 15, '2026-03-01 00:00:00+00');
CALL proc_create_quest('RUN_FOUNDATIONS_02', 'Run Foundations II', 'Finish the second run foundation step.', 'program_step', 'linear', 'RUN_FOUNDATIONS', 2, 1.00, 20, '2026-03-01 00:00:00+00');

-- <<< END seeds/006_quests.sql

-- >>> BEGIN seeds/007_workouts.sql

DO $seed$
DECLARE
    v_anna_user_id BIGINT;
    v_bartek_user_id BIGINT;
    v_clara_user_id BIGINT;
    v_diego_user_id BIGINT;
    v_emilia_user_id BIGINT;
    v_filip_user_id BIGINT;
BEGIN
    SELECT id INTO v_anna_user_id FROM users WHERE email = 'anna.nowak@fitrpg.dev';
    SELECT id INTO v_bartek_user_id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev';
    SELECT id INTO v_clara_user_id FROM users WHERE email = 'clara.zielinska@fitrpg.dev';
    SELECT id INTO v_diego_user_id FROM users WHERE email = 'diego.santos@fitrpg.dev';
    SELECT id INTO v_emilia_user_id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev';
    SELECT id INTO v_filip_user_id FROM users WHERE email = 'filip.mazur@fitrpg.dev';

CALL proc_log_workout(
    p_user_id => v_anna_user_id,
    p_workout_type => 'strength',
    p_title => 'Upper Body Strength',
    p_performed_at => '2026-03-20 18:00:00+00',
    p_duration_min => 58,
    p_health_score => 9::SMALLINT,
    p_notes => 'Focused on progressive overload.',
    p_exercises => $$[
        {"exercise_name":"Bench Press","exercise_order":1,"sets":4,"reps":8,"weight_kg":42.50,"calories_burned":120.00,"notes":"Last set close to failure."},
        {"exercise_name":"One-Arm Dumbbell Row","exercise_order":2,"sets":4,"reps":10,"weight_kg":20.00,"calories_burned":95.00},
        {"exercise_name":"Seated Shoulder Press","exercise_order":3,"sets":3,"reps":10,"weight_kg":14.00,"calories_burned":82.00},
        {"exercise_name":"Plank","exercise_order":4,"sets":3,"duration_sec":180,"calories_burned":28.00,"notes":"Three sixty-second holds."}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 40,
    p_exp_reason => 'Completed a strength workout.',
    p_exp_created_at => '2026-03-20 19:01:00+00'
);

CALL proc_log_workout(
    p_user_id => v_anna_user_id,
    p_workout_type => 'mobility',
    p_title => 'Morning Mobility Flow',
    p_performed_at => '2026-03-21 06:40:00+00',
    p_duration_min => 22,
    p_health_score => 8::SMALLINT,
    p_notes => 'Short recovery-focused session.',
    p_exercises => $$[
        {"exercise_name":"Hip Openers","exercise_order":1,"sets":2,"reps":12,"duration_sec":420,"calories_burned":18.00},
        {"exercise_name":"Thoracic Rotations","exercise_order":2,"sets":2,"reps":10,"duration_sec":360,"calories_burned":14.00},
        {"exercise_name":"Hamstring Stretch","exercise_order":3,"sets":2,"duration_sec":300,"calories_burned":12.00,"notes":"Held both sides equally."}
    ]$$::jsonb
);

CALL proc_log_workout(
    p_user_id => v_bartek_user_id,
    p_workout_type => 'cardio',
    p_title => 'Lunch Break Walk',
    p_performed_at => '2026-03-20 12:15:00+00',
    p_duration_min => 35,
    p_health_score => 7::SMALLINT,
    p_notes => 'Walked around the office district.',
    p_exercises => $$[
        {"exercise_name":"Outdoor brisk walk","exercise_order":1,"duration_sec":2100,"distance_m":3200.00,"calories_burned":180.00,"notes":"Mostly flat route."}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 20,
    p_exp_reason => 'Completed lunchtime walk.',
    p_exp_created_at => '2026-03-20 12:56:00+00'
);

CALL proc_log_workout(
    p_user_id => v_clara_user_id,
    p_workout_type => 'cardio',
    p_title => '5K Tempo Run',
    p_performed_at => '2026-03-21 16:50:00+00',
    p_duration_min => 31,
    p_health_score => 9::SMALLINT,
    p_notes => 'Sustained race-pace effort.',
    p_exercises => $$[
        {"exercise_name":"Warm-up jog","exercise_order":1,"duration_sec":480,"distance_m":1200.00,"calories_burned":70.00},
        {"exercise_name":"Tempo block","exercise_order":2,"duration_sec":1320,"distance_m":4000.00,"calories_burned":250.00,"notes":"Held a strong but controlled pace."},
        {"exercise_name":"Cool-down jog","exercise_order":3,"duration_sec":300,"distance_m":800.00,"calories_burned":35.00}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 45,
    p_exp_reason => 'Completed tempo run.',
    p_exp_created_at => '2026-03-21 17:31:00+00'
);

CALL proc_log_workout(
    p_user_id => v_clara_user_id,
    p_workout_type => 'mobility',
    p_title => 'Recovery Stretch',
    p_performed_at => '2026-03-22 08:10:00+00',
    p_duration_min => 18,
    p_health_score => 8::SMALLINT,
    p_notes => 'Mobility and foam rolling.',
    p_exercises => $$[
        {"exercise_name":"Foam rolling","exercise_order":1,"duration_sec":420,"calories_burned":18.00},
        {"exercise_name":"Calf stretch","exercise_order":2,"sets":2,"duration_sec":240,"calories_burned":8.00},
        {"exercise_name":"Glute mobility","exercise_order":3,"sets":2,"reps":10,"duration_sec":300,"calories_burned":12.00}
    ]$$::jsonb
);

CALL proc_log_workout(
    p_user_id => v_diego_user_id,
    p_workout_type => 'strength',
    p_title => 'Beginner Gym Session',
    p_performed_at => '2026-03-16 18:10:00+00',
    p_duration_min => 42,
    p_health_score => 6::SMALLINT,
    p_notes => 'First gym visit in a while.',
    p_exercises => $$[
        {"exercise_name":"Leg Press","exercise_order":1,"sets":3,"reps":12,"weight_kg":80.00,"calories_burned":92.00,"notes":"Conservative weight selection."},
        {"exercise_name":"Lat Pulldown","exercise_order":2,"sets":3,"reps":10,"weight_kg":35.00,"calories_burned":70.00},
        {"exercise_name":"Bike warm-up","exercise_order":3,"duration_sec":600,"distance_m":3800.00,"calories_burned":45.00}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 25,
    p_exp_reason => 'Completed return-to-gym session.',
    p_exp_created_at => '2026-03-16 19:01:00+00'
);

CALL proc_log_workout(
    p_user_id => v_emilia_user_id,
    p_workout_type => 'cardio',
    p_title => 'Saturday Bike Ride',
    p_performed_at => '2026-03-22 10:30:00+00',
    p_duration_min => 74,
    p_health_score => 9::SMALLINT,
    p_notes => 'Long outdoor ride with friends.',
    p_exercises => $$[
        {"exercise_name":"Outdoor cycling","exercise_order":1,"duration_sec":4440,"distance_m":24000.00,"calories_burned":520.00,"notes":"Rolling terrain and moderate wind."}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 35,
    p_exp_reason => 'Completed long bike ride.',
    p_exp_created_at => '2026-03-22 11:56:00+00'
);

CALL proc_log_workout(
    p_user_id => v_emilia_user_id,
    p_workout_type => 'mobility',
    p_title => 'Pilates Core Session',
    p_performed_at => '2026-03-22 17:20:00+00',
    p_duration_min => 41,
    p_health_score => 8::SMALLINT,
    p_notes => 'Studio pilates class.',
    p_exercises => $$[
        {"exercise_name":"Hundred","exercise_order":1,"sets":1,"reps":100,"duration_sec":180,"calories_burned":28.00},
        {"exercise_name":"Roll-Up","exercise_order":2,"sets":3,"reps":8,"duration_sec":240,"calories_burned":26.00},
        {"exercise_name":"Single-Leg Stretch","exercise_order":3,"sets":3,"reps":12,"duration_sec":360,"calories_burned":32.00}
    ]$$::jsonb
);

CALL proc_log_workout(
    p_user_id => v_filip_user_id,
    p_workout_type => 'strength',
    p_title => 'Leg Day',
    p_performed_at => '2026-03-22 12:50:00+00',
    p_duration_min => 67,
    p_health_score => 9::SMALLINT,
    p_notes => 'Heavy lower-body workout.',
    p_exercises => $$[
        {"exercise_name":"Back Squat","exercise_order":1,"sets":5,"reps":5,"weight_kg":120.00,"calories_burned":170.00,"notes":"Top set felt strong."},
        {"exercise_name":"Romanian Deadlift","exercise_order":2,"sets":4,"reps":8,"weight_kg":90.00,"calories_burned":130.00},
        {"exercise_name":"Walking Lunges","exercise_order":3,"sets":3,"reps":12,"weight_kg":22.00,"calories_burned":95.00,"notes":"Per leg."},
        {"exercise_name":"Sled Push","exercise_order":4,"sets":4,"weight_kg":140.00,"duration_sec":300,"distance_m":120.00,"calories_burned":75.00,"notes":"Heavy finishers."}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 50,
    p_exp_reason => 'Completed heavy strength session.',
    p_exp_created_at => '2026-03-22 14:11:00+00'
);

CALL proc_log_workout(
    p_user_id => v_filip_user_id,
    p_workout_type => 'sport',
    p_title => 'Basketball Scrimmage',
    p_performed_at => '2026-03-22 18:30:00+00',
    p_duration_min => 53,
    p_health_score => 8::SMALLINT,
    p_notes => 'Competitive full-court game.',
    p_exercises => $$[
        {"exercise_name":"Full-court scrimmage","exercise_order":1,"duration_sec":3180,"distance_m":4600.00,"calories_burned":430.00,"notes":"Tracked by smartwatch estimate."}
    ]$$::jsonb
);
END;
$seed$;

-- <<< END seeds/007_workouts.sql

-- >>> BEGIN seeds/008_user_challenges.sql

DO $$
DECLARE
    v_anna_user_id BIGINT;
    v_bartek_user_id BIGINT;
    v_clara_user_id BIGINT;
    v_diego_user_id BIGINT;
    v_emilia_user_id BIGINT;
    v_filip_user_id BIGINT;
    v_three_strength_sessions_id BIGINT;
    v_colorful_plate_week_id BIGINT;
    v_seven_day_logging_streak_id BIGINT;
    v_run_distance_10k_id BIGINT;
    v_weekend_warrior_id BIGINT;
    v_hydration_habit_id BIGINT;
BEGIN
    SELECT id INTO v_anna_user_id FROM users WHERE email = 'anna.nowak@fitrpg.dev';
    SELECT id INTO v_bartek_user_id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev';
    SELECT id INTO v_clara_user_id FROM users WHERE email = 'clara.zielinska@fitrpg.dev';
    SELECT id INTO v_diego_user_id FROM users WHERE email = 'diego.santos@fitrpg.dev';
    SELECT id INTO v_emilia_user_id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev';
    SELECT id INTO v_filip_user_id FROM users WHERE email = 'filip.mazur@fitrpg.dev';
    SELECT id INTO v_three_strength_sessions_id FROM challenges WHERE title = 'Three Strength Sessions';
    SELECT id INTO v_colorful_plate_week_id FROM challenges WHERE title = 'Colorful Plate Week';
    SELECT id INTO v_seven_day_logging_streak_id FROM challenges WHERE title = '7-Day Logging Streak';
    SELECT id INTO v_run_distance_10k_id FROM challenges WHERE title = '10K Run Distance';
    SELECT id INTO v_weekend_warrior_id FROM challenges WHERE title = 'Weekend Warrior';
    SELECT id INTO v_hydration_habit_id FROM challenges WHERE title = 'Hydration Habit';

    CALL proc_update_challenge_progress(v_anna_user_id, v_three_strength_sessions_id, NULL, 3.00, '2026-03-20 19:05:00+00');
    CALL proc_claim_challenge_reward(v_anna_user_id, v_three_strength_sessions_id, '2026-03-20 19:10:00+00');
    CALL proc_update_challenge_progress(v_anna_user_id, v_colorful_plate_week_id, NULL, 4.00, '2026-03-21 12:00:00+00');

    CALL proc_update_challenge_progress(v_bartek_user_id, v_seven_day_logging_streak_id, NULL, 2.00, '2026-03-20 07:00:00+00');

    CALL proc_update_challenge_progress(v_clara_user_id, v_run_distance_10k_id, NULL, 10000.00, '2026-03-21 17:32:00+00');
    CALL proc_claim_challenge_reward(v_clara_user_id, v_run_distance_10k_id, '2026-03-21 17:40:00+00');
    CALL proc_update_challenge_progress(v_clara_user_id, v_seven_day_logging_streak_id, NULL, 6.00, '2026-03-22 08:35:00+00');

    CALL proc_update_challenge_progress(v_diego_user_id, v_weekend_warrior_id, NULL, 1.00, '2026-03-20 10:00:00+00');
    CALL proc_fail_challenge(v_diego_user_id, v_weekend_warrior_id, '2026-03-22 21:00:00+00');

    CALL proc_update_challenge_progress(v_emilia_user_id, v_colorful_plate_week_id, NULL, 5.00, '2026-03-22 13:10:00+00');
    CALL proc_update_challenge_progress(v_emilia_user_id, v_weekend_warrior_id, NULL, 2.00, '2026-03-22 18:15:00+00');
    CALL proc_claim_challenge_reward(v_emilia_user_id, v_weekend_warrior_id, '2026-03-22 18:20:00+00');

    CALL proc_update_challenge_progress(v_filip_user_id, v_three_strength_sessions_id, NULL, 2.00, '2026-03-22 14:15:00+00');
    CALL proc_update_challenge_progress(v_filip_user_id, v_hydration_habit_id, NULL, 4.00, '2026-03-22 20:00:00+00');
END;
$$;

-- <<< END seeds/008_user_challenges.sql

-- >>> BEGIN seeds/009_user_achievements.sql

DO $$
DECLARE
    v_anna_user_id BIGINT;
    v_bartek_user_id BIGINT;
    v_clara_user_id BIGINT;
    v_diego_user_id BIGINT;
    v_emilia_user_id BIGINT;
    v_filip_user_id BIGINT;
    v_first_meal_id BIGINT;
    v_first_workout_id BIGINT;
    v_meal_logger_10_id BIGINT;
    v_streak_7_id BIGINT;
    v_runner_10k_id BIGINT;
    v_strength_5_id BIGINT;
BEGIN
    SELECT id INTO v_anna_user_id FROM users WHERE email = 'anna.nowak@fitrpg.dev';
    SELECT id INTO v_bartek_user_id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev';
    SELECT id INTO v_clara_user_id FROM users WHERE email = 'clara.zielinska@fitrpg.dev';
    SELECT id INTO v_diego_user_id FROM users WHERE email = 'diego.santos@fitrpg.dev';
    SELECT id INTO v_emilia_user_id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev';
    SELECT id INTO v_filip_user_id FROM users WHERE email = 'filip.mazur@fitrpg.dev';
    SELECT id INTO v_first_meal_id FROM achievements WHERE code = 'FIRST_MEAL';
    SELECT id INTO v_first_workout_id FROM achievements WHERE code = 'FIRST_WORKOUT';
    SELECT id INTO v_meal_logger_10_id FROM achievements WHERE code = 'MEAL_LOGGER_10';
    SELECT id INTO v_streak_7_id FROM achievements WHERE code = 'STREAK_7';
    SELECT id INTO v_runner_10k_id FROM achievements WHERE code = 'RUNNER_10K';
    SELECT id INTO v_strength_5_id FROM achievements WHERE code = 'STRENGTH_5';

    CALL proc_join_achievement(v_anna_user_id, v_first_meal_id, '2026-03-20 07:36:00+00');
    CALL proc_update_achievement_progress(v_anna_user_id, v_first_meal_id, NULL, 1.00, '2026-03-20 07:37:00+00');
    CALL proc_claim_achievement_reward(v_anna_user_id, v_first_meal_id, '2026-03-20 07:38:00+00');
    CALL proc_join_achievement(v_anna_user_id, v_first_workout_id, '2026-03-20 19:01:00+00');
    CALL proc_update_achievement_progress(v_anna_user_id, v_first_workout_id, NULL, 1.00, '2026-03-20 19:02:00+00');
    CALL proc_claim_achievement_reward(v_anna_user_id, v_first_workout_id, '2026-03-20 19:03:00+00');
    CALL proc_join_achievement(v_anna_user_id, v_meal_logger_10_id, '2026-03-21 16:20:00+00');
    CALL proc_update_achievement_progress(v_anna_user_id, v_meal_logger_10_id, NULL, 3.00, '2026-03-21 16:22:00+00');

    CALL proc_join_achievement(v_bartek_user_id, v_first_meal_id, '2026-03-19 06:56:00+00');
    CALL proc_update_achievement_progress(v_bartek_user_id, v_first_meal_id, NULL, 1.00, '2026-03-19 06:57:00+00');
    CALL proc_join_achievement(v_bartek_user_id, v_streak_7_id, '2026-03-20 12:55:00+00');
    CALL proc_update_achievement_progress(v_bartek_user_id, v_streak_7_id, NULL, 2.00, '2026-03-20 12:56:00+00');

    CALL proc_join_achievement(v_clara_user_id, v_first_workout_id, '2026-03-21 17:30:00+00');
    CALL proc_update_achievement_progress(v_clara_user_id, v_first_workout_id, NULL, 1.00, '2026-03-21 17:31:00+00');
    CALL proc_claim_achievement_reward(v_clara_user_id, v_first_workout_id, '2026-03-21 17:31:30+00');
    CALL proc_join_achievement(v_clara_user_id, v_runner_10k_id, '2026-03-21 17:32:00+00');
    CALL proc_update_achievement_progress(v_clara_user_id, v_runner_10k_id, NULL, 10000.00, '2026-03-21 17:33:00+00');
    CALL proc_claim_achievement_reward(v_clara_user_id, v_runner_10k_id, '2026-03-21 17:45:00+00');

    CALL proc_join_achievement(v_diego_user_id, v_first_workout_id, '2026-03-16 19:00:00+00');
    CALL proc_update_achievement_progress(v_diego_user_id, v_first_workout_id, NULL, 1.00, '2026-03-16 19:01:00+00');

    CALL proc_join_achievement(v_emilia_user_id, v_first_meal_id, '2026-03-22 09:16:00+00');
    CALL proc_update_achievement_progress(v_emilia_user_id, v_first_meal_id, NULL, 1.00, '2026-03-22 09:17:00+00');
    CALL proc_claim_achievement_reward(v_emilia_user_id, v_first_meal_id, '2026-03-22 09:18:00+00');
    CALL proc_join_achievement(v_emilia_user_id, v_meal_logger_10_id, '2026-03-22 16:05:00+00');
    CALL proc_update_achievement_progress(v_emilia_user_id, v_meal_logger_10_id, NULL, 4.00, '2026-03-22 16:06:00+00');

    CALL proc_join_achievement(v_filip_user_id, v_first_workout_id, '2026-03-22 14:10:00+00');
    CALL proc_update_achievement_progress(v_filip_user_id, v_first_workout_id, NULL, 1.00, '2026-03-22 14:11:00+00');
    CALL proc_join_achievement(v_filip_user_id, v_strength_5_id, '2026-03-22 14:11:30+00');
    CALL proc_update_achievement_progress(v_filip_user_id, v_strength_5_id, NULL, 5.00, '2026-03-22 14:12:00+00');
    CALL proc_claim_achievement_reward(v_filip_user_id, v_strength_5_id, '2026-03-22 14:20:00+00');
END;
$$;

-- <<< END seeds/009_user_achievements.sql

-- >>> BEGIN seeds/010_user_quests.sql

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

-- <<< END seeds/010_user_quests.sql

-- >>> BEGIN seeds/011_exp_grants.sql

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

-- <<< END seeds/011_exp_grants.sql

-- >>> BEGIN seeds/012_user_progress_refresh.sql

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

-- <<< END seeds/012_user_progress_refresh.sql


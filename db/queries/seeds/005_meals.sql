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
    p_health_score => 8::SMALLINT
);

CALL proc_log_meal(
    p_user_id => v_bartek_user_id,
    p_meal_type => 'breakfast',
    p_eaten_at => '2026-03-19 06:55:00+00',
    p_title => 'Office Breakfast Wrap',
    p_notes => 'Grabbed on the way to work.',
    p_health_score => 6::SMALLINT,
    p_ai_confidence => 0.702,
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
    p_ai_confidence => 0.834
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
    p_health_score => 8::SMALLINT
);

CALL proc_log_meal(
    p_user_id => v_diego_user_id,
    p_meal_type => 'lunch',
    p_eaten_at => '2026-03-15 12:30:00+00',
    p_title => 'Quick Convenience Lunch',
    p_notes => 'Logged to restart tracking habit.',
    p_health_score => 4::SMALLINT,
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
    p_ai_confidence => 0.821
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
    p_health_score => 7::SMALLINT
);

CALL proc_log_meal(
    p_user_id => v_filip_user_id,
    p_meal_type => 'snack',
    p_eaten_at => '2026-03-22 14:40:00+00',
    p_title => 'Protein Shake',
    p_notes => 'Post leg day shake.',
    p_health_score => 8::SMALLINT,
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
    p_ai_confidence => 0.776
);
END;
$seed$;

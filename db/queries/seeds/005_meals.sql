CALL proc_log_meal(
    p_user_id => (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'),
    p_meal_type => 'breakfast',
    p_eaten_at => '2026-03-20 07:35:00+00',
    p_title => 'High Protein Oats',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/high_protein_oats.jpg',
    p_notes => 'Added berries after training.',
    p_health_score => 9,
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
    p_user_id => (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'),
    p_meal_type => 'lunch',
    p_eaten_at => '2026-03-20 13:10:00+00',
    p_title => 'Chicken Power Bowl',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/chicken_power_bowl.jpg',
    p_notes => 'Meal-prepped bowl with rice and avocado.',
    p_health_score => 8,
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
    p_user_id => (SELECT id FROM users WHERE email = 'anna.nowak@fitrpg.dev'),
    p_meal_type => 'snack',
    p_eaten_at => '2026-03-21 16:20:00+00',
    p_title => 'Greek Yogurt Snack',
    p_notes => 'Fast snack between meetings.',
    p_health_score => 8,
    p_items => $$[
        {"item_name":"Greek yogurt","quantity":170.00,"unit":"g","grams":170.00,"calories":146.00,"protein_g":17.00,"carbs_g":6.00,"fat_g":5.00,"health_score":8},
        {"item_name":"Honey","quantity":15.00,"unit":"g","grams":15.00,"calories":46.00,"protein_g":0.00,"carbs_g":12.00,"fat_g":0.00,"health_score":6},
        {"item_name":"Walnuts","quantity":12.00,"unit":"g","grams":12.00,"calories":79.00,"protein_g":1.80,"carbs_g":1.00,"fat_g":7.80,"health_score":8}
    ]$$::jsonb
);

CALL proc_log_meal(
    p_user_id => (SELECT id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev'),
    p_meal_type => 'breakfast',
    p_eaten_at => '2026-03-19 06:55:00+00',
    p_title => 'Office Breakfast Wrap',
    p_notes => 'Grabbed on the way to work.',
    p_health_score => 6,
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
    p_user_id => (SELECT id FROM users WHERE email = 'bartek.kowalski@fitrpg.dev'),
    p_meal_type => 'dinner',
    p_eaten_at => '2026-03-20 19:15:00+00',
    p_title => 'Salmon Rice Plate',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/salmon_rice_plate.jpg',
    p_notes => 'Restaurant dinner, estimate adjusted manually.',
    p_health_score => 8,
    p_ai_confidence => 0.834,
    p_items => $$[
        {"item_name":"Salmon fillet","quantity":170.00,"unit":"g","grams":170.00,"calories":354.00,"protein_g":34.00,"carbs_g":0.00,"fat_g":22.00,"health_score":9},
        {"item_name":"Jasmine rice","quantity":170.00,"unit":"g","grams":170.00,"calories":221.00,"protein_g":4.00,"carbs_g":48.00,"fat_g":0.40,"health_score":7},
        {"item_name":"Cucumber salad","quantity":120.00,"unit":"g","grams":120.00,"calories":58.00,"protein_g":1.00,"carbs_g":7.00,"fat_g":3.00,"health_score":8}
    ]$$::jsonb
);

CALL proc_log_meal(
    p_user_id => (SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'),
    p_meal_type => 'snack',
    p_eaten_at => '2026-03-21 17:45:00+00',
    p_title => 'Post Run Smoothie',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/post_run_smoothie.jpg',
    p_notes => 'Recovery smoothie after tempo run.',
    p_health_score => 9,
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
    p_user_id => (SELECT id FROM users WHERE email = 'clara.zielinska@fitrpg.dev'),
    p_meal_type => 'dinner',
    p_eaten_at => '2026-03-21 20:15:00+00',
    p_title => 'Veggie Pasta Dinner',
    p_notes => 'Homemade whole-grain pasta.',
    p_health_score => 8,
    p_items => $$[
        {"item_name":"Whole-grain pasta","quantity":110.00,"unit":"g","grams":110.00,"calories":380.00,"protein_g":15.00,"carbs_g":72.00,"fat_g":2.00,"health_score":8},
        {"item_name":"Tomato sauce","quantity":140.00,"unit":"g","grams":140.00,"calories":72.00,"protein_g":2.00,"carbs_g":12.00,"fat_g":1.50,"health_score":8},
        {"item_name":"Parmesan","quantity":18.00,"unit":"g","grams":18.00,"calories":77.00,"protein_g":7.00,"carbs_g":1.00,"fat_g":5.00,"health_score":7},
        {"item_name":"Zucchini and peppers","quantity":160.00,"unit":"g","grams":160.00,"calories":61.00,"protein_g":1.50,"carbs_g":10.00,"fat_g":1.80,"health_score":9}
    ]$$::jsonb
);

CALL proc_log_meal(
    p_user_id => (SELECT id FROM users WHERE email = 'diego.santos@fitrpg.dev'),
    p_meal_type => 'lunch',
    p_eaten_at => '2026-03-15 12:30:00+00',
    p_title => 'Quick Convenience Lunch',
    p_notes => 'Logged to restart tracking habit.',
    p_health_score => 4,
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
    p_user_id => (SELECT id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev'),
    p_meal_type => 'breakfast',
    p_eaten_at => '2026-03-22 09:10:00+00',
    p_title => 'Weekend Pancakes',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/weekend_pancakes.jpg',
    p_notes => 'Shared breakfast, estimated half portion.',
    p_health_score => 6,
    p_ai_confidence => 0.821,
    p_items => $$[
        {"item_name":"Pancakes","quantity":3.00,"unit":"pcs","grams":210.00,"calories":366.00,"protein_g":9.00,"carbs_g":52.00,"fat_g":11.00,"health_score":6},
        {"item_name":"Maple syrup","quantity":25.00,"unit":"g","grams":25.00,"calories":65.00,"protein_g":0.00,"carbs_g":17.00,"fat_g":0.00,"health_score":4},
        {"item_name":"Strawberries","quantity":90.00,"unit":"g","grams":90.00,"calories":29.00,"protein_g":0.70,"carbs_g":7.00,"fat_g":0.30,"health_score":10},
        {"item_name":"Greek yogurt topping","quantity":80.00,"unit":"g","grams":80.00,"calories":80.00,"protein_g":7.30,"carbs_g":3.00,"fat_g":2.80,"health_score":8}
    ]$$::jsonb
);

CALL proc_log_meal(
    p_user_id => (SELECT id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev'),
    p_meal_type => 'lunch',
    p_eaten_at => '2026-03-22 13:05:00+00',
    p_title => 'Mediterranean Salad',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/mediterranean_salad.jpg',
    p_notes => 'Mostly manual corrections after scan.',
    p_health_score => 9,
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
    p_user_id => (SELECT id FROM users WHERE email = 'emilia.wisniewska@fitrpg.dev'),
    p_meal_type => 'snack',
    p_eaten_at => '2026-03-22 16:05:00+00',
    p_title => 'Apple Peanut Snack',
    p_health_score => 7,
    p_items => $$[
        {"item_name":"Apple","quantity":1.00,"unit":"pcs","grams":180.00,"calories":95.00,"protein_g":0.50,"carbs_g":25.00,"fat_g":0.30,"health_score":9},
        {"item_name":"Peanut butter","quantity":25.00,"unit":"g","grams":25.00,"calories":148.00,"protein_g":6.00,"carbs_g":4.00,"fat_g":12.60,"health_score":6}
    ]$$::jsonb
);

CALL proc_log_meal(
    p_user_id => (SELECT id FROM users WHERE email = 'filip.mazur@fitrpg.dev'),
    p_meal_type => 'snack',
    p_eaten_at => '2026-03-22 14:40:00+00',
    p_title => 'Protein Shake',
    p_notes => 'Post leg day shake.',
    p_health_score => 8,
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
    p_user_id => (SELECT id FROM users WHERE email = 'filip.mazur@fitrpg.dev'),
    p_meal_type => 'dinner',
    p_eaten_at => '2026-03-22 20:45:00+00',
    p_title => 'Sushi Dinner',
    p_photo_url => 'https://cdn.fitrpg.dev/meals/sushi_dinner.jpg',
    p_notes => 'Dinner after basketball with friends.',
    p_health_score => 7,
    p_ai_confidence => 0.776,
    p_items => $$[
        {"item_name":"Salmon nigiri","quantity":6.00,"unit":"pcs","grams":210.00,"calories":290.00,"protein_g":18.00,"carbs_g":33.00,"fat_g":8.00,"health_score":8},
        {"item_name":"California rolls","quantity":8.00,"unit":"pcs","grams":220.00,"calories":255.00,"protein_g":8.00,"carbs_g":38.00,"fat_g":7.00,"health_score":7},
        {"item_name":"Miso soup","quantity":1.00,"unit":"bowl","grams":240.00,"calories":70.00,"protein_g":5.00,"carbs_g":8.00,"fat_g":2.50,"health_score":8}
    ]$$::jsonb
);

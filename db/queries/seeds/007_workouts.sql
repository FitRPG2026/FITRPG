DO $$
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
    p_health_score => 9,
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
    p_health_score => 8,
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
    p_health_score => 7,
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
    p_health_score => 9,
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
    p_health_score => 8,
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
    p_health_score => 6,
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
    p_health_score => 9,
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
    p_health_score => 8,
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
    p_health_score => 9,
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
    p_health_score => 8,
    p_notes => 'Competitive full-court game.',
    p_exercises => $$[
        {"exercise_name":"Full-court scrimmage","exercise_order":1,"duration_sec":3180,"distance_m":4600.00,"calories_burned":430.00,"notes":"Tracked by smartwatch estimate."}
    ]$$::jsonb
);
END;
$$;

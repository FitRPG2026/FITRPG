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
        {"exercise_name":"Bench Press","exercise_order":1,"exercise_group":"chest","sets":4,"reps":8,"weight_kg":42.50,"notes":"Last set close to failure."},
        {"exercise_name":"One-Arm Dumbbell Row","exercise_order":2,"exercise_group":"back","sets":4,"reps":10,"weight_kg":20.00},
        {"exercise_name":"Seated Shoulder Press","exercise_order":3,"exercise_group":"shoulders","sets":3,"reps":10,"weight_kg":14.00},
        {"exercise_name":"Plank","exercise_order":4,"exercise_group":"core","sets":3,"duration_sec":180,"notes":"Three sixty-second holds."}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 40,
    p_exp_reason => 'Completed a strength workout.',
    p_exp_created_at => '2026-03-20 19:01:00+00',
    p_activity_category => 'gym',
    p_activity_code => 'upper_body_strength',
    p_activity_name => 'Upper Body Strength'
);

CALL proc_log_workout(
    p_user_id => v_anna_user_id,
    p_workout_type => 'mobility',
    p_title => 'Morning Mobility Flow',
    p_performed_at => '2026-03-21 06:40:00+00',
    p_duration_min => 22,
    p_health_score => 8::SMALLINT,
    p_notes => 'Short recovery-focused session.',
    p_activity_category => 'general',
    p_activity_code => 'mobility',
    p_activity_name => 'Morning Mobility Flow'
);

CALL proc_log_workout(
    p_user_id => v_bartek_user_id,
    p_workout_type => 'cardio',
    p_title => 'Lunch Break Walk',
    p_performed_at => '2026-03-20 12:15:00+00',
    p_duration_min => 35,
    p_health_score => 7::SMALLINT,
    p_notes => 'Walked around the office district.',
    p_grant_exp => TRUE,
    p_exp_amount => 20,
    p_exp_reason => 'Completed lunchtime walk.',
    p_exp_created_at => '2026-03-20 12:56:00+00',
    p_activity_category => 'general',
    p_activity_code => 'walking',
    p_activity_name => 'Outdoor brisk walk'
);

CALL proc_log_workout(
    p_user_id => v_clara_user_id,
    p_workout_type => 'cardio',
    p_title => '5K Tempo Run',
    p_performed_at => '2026-03-21 16:50:00+00',
    p_duration_min => 31,
    p_health_score => 9::SMALLINT,
    p_notes => 'Sustained race-pace effort.',
    p_grant_exp => TRUE,
    p_exp_amount => 45,
    p_exp_reason => 'Completed tempo run.',
    p_exp_created_at => '2026-03-21 17:31:00+00',
    p_activity_category => 'general',
    p_activity_code => 'running',
    p_activity_name => '5K Tempo Run'
);

CALL proc_log_workout(
    p_user_id => v_clara_user_id,
    p_workout_type => 'mobility',
    p_title => 'Recovery Stretch',
    p_performed_at => '2026-03-22 08:10:00+00',
    p_duration_min => 18,
    p_health_score => 8::SMALLINT,
    p_notes => 'Mobility and foam rolling.',
    p_activity_category => 'general',
    p_activity_code => 'stretching',
    p_activity_name => 'Recovery Stretch'
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
        {"exercise_name":"Leg Press","exercise_order":1,"exercise_group":"legs","sets":3,"reps":12,"weight_kg":80.00,"notes":"Conservative weight selection."},
        {"exercise_name":"Lat Pulldown","exercise_order":2,"exercise_group":"back","sets":3,"reps":10,"weight_kg":35.00},
        {"exercise_name":"Bike warm-up","exercise_order":3,"exercise_group":"cardio_conditioning","duration_sec":600,"distance_m":3800.00}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 25,
    p_exp_reason => 'Completed return-to-gym session.',
    p_exp_created_at => '2026-03-16 19:01:00+00',
    p_activity_category => 'gym',
    p_activity_code => 'beginner_gym',
    p_activity_name => 'Beginner Gym Session'
);

CALL proc_log_workout(
    p_user_id => v_emilia_user_id,
    p_workout_type => 'cardio',
    p_title => 'Saturday Bike Ride',
    p_performed_at => '2026-03-22 10:30:00+00',
    p_duration_min => 74,
    p_health_score => 9::SMALLINT,
    p_notes => 'Long outdoor ride with friends.',
    p_grant_exp => TRUE,
    p_exp_amount => 35,
    p_exp_reason => 'Completed long bike ride.',
    p_exp_created_at => '2026-03-22 11:56:00+00',
    p_activity_category => 'sport',
    p_activity_code => 'cycling',
    p_activity_name => 'Outdoor cycling'
);

CALL proc_log_workout(
    p_user_id => v_emilia_user_id,
    p_workout_type => 'mobility',
    p_title => 'Pilates Core Session',
    p_performed_at => '2026-03-22 17:20:00+00',
    p_duration_min => 41,
    p_health_score => 8::SMALLINT,
    p_notes => 'Studio pilates class.',
    p_activity_category => 'general',
    p_activity_code => 'pilates',
    p_activity_name => 'Pilates'
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
        {"exercise_name":"Back Squat","exercise_order":1,"exercise_group":"legs","sets":5,"reps":5,"weight_kg":120.00,"notes":"Top set felt strong."},
        {"exercise_name":"Romanian Deadlift","exercise_order":2,"exercise_group":"glutes","sets":4,"reps":8,"weight_kg":90.00},
        {"exercise_name":"Walking Lunges","exercise_order":3,"exercise_group":"legs","sets":3,"reps":12,"weight_kg":22.00,"notes":"Per leg."},
        {"exercise_name":"Sled Push","exercise_order":4,"exercise_group":"cardio_conditioning","sets":4,"weight_kg":140.00,"duration_sec":300,"distance_m":120.00,"notes":"Heavy finishers."}
    ]$$::jsonb,
    p_grant_exp => TRUE,
    p_exp_amount => 50,
    p_exp_reason => 'Completed heavy strength session.',
    p_exp_created_at => '2026-03-22 14:11:00+00',
    p_activity_category => 'gym',
    p_activity_code => 'leg_day',
    p_activity_name => 'Leg Day'
);

CALL proc_log_workout(
    p_user_id => v_filip_user_id,
    p_workout_type => 'sport',
    p_title => 'Basketball Scrimmage',
    p_performed_at => '2026-03-22 18:30:00+00',
    p_duration_min => 53,
    p_health_score => 8::SMALLINT,
    p_notes => 'Competitive full-court game.',
    p_activity_category => 'sport',
    p_activity_code => 'basketball',
    p_activity_name => 'Basketball'
);
END;
$seed$;

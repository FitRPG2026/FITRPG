-- Seed users through the registration procedure so auth and user_progress are created by flow.

CALL proc_register_user('anna.nowak@fitrpg.dev', '$2b$12$anna_demo_hash', 'active');
CALL proc_register_user('bartek.kowalski@fitrpg.dev', '$2b$12$bartek_demo_hash', 'active');
CALL proc_register_user('clara.zielinska@fitrpg.dev', '$2b$12$clara_demo_hash', 'active');
CALL proc_register_user('diego.santos@fitrpg.dev', '$2b$12$diego_demo_hash', 'inactive');
CALL proc_register_user('emilia.wisniewska@fitrpg.dev', '$2b$12$emilia_demo_hash', 'active');
CALL proc_register_user('filip.mazur@fitrpg.dev', '$2b$12$filip_demo_hash', 'active');
CALL proc_register_user('grace.demo@fitrpg.dev', '$2b$12$grace_demo_hash', 'banned');

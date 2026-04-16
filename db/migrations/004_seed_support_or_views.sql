-- Seed and maintenance helpers.

SET check_function_bodies = false;


--
-- Name: proc_refresh_user_progress(bigint, integer, integer); Type: PROCEDURE; Schema: public; Owner: -
--

CREATE PROCEDURE public.proc_refresh_user_progress(IN p_user_id bigint, IN p_current_streak_days integer DEFAULT NULL::integer, IN p_longest_streak_days integer DEFAULT NULL::integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
    v_total_exp INTEGER;
    v_last_activity_at TIMESTAMPTZ;
BEGIN
    IF p_current_streak_days IS NOT NULL AND p_current_streak_days < 0 THEN
        RAISE EXCEPTION 'Current streak days cannot be negative';
    END IF;

    IF p_longest_streak_days IS NOT NULL AND p_longest_streak_days < 0 THEN
        RAISE EXCEPTION 'Longest streak days cannot be negative';
    END IF;

    PERFORM 1
    FROM user_progress
    WHERE user_id = p_user_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'User progress row for user % does not exist', p_user_id;
    END IF;

    SELECT COALESCE(SUM(exp_amount), 0)
    INTO v_total_exp
    FROM exp_events
    WHERE user_id = p_user_id;

    SELECT MAX(activity_at)
    INTO v_last_activity_at
    FROM (
        SELECT eaten_at AS activity_at
        FROM meals
        WHERE user_id = p_user_id

        UNION ALL

        SELECT performed_at AS activity_at
        FROM workouts
        WHERE user_id = p_user_id

        UNION ALL

        SELECT created_at AS activity_at
        FROM exp_events
        WHERE user_id = p_user_id
    ) AS activity_events;

    UPDATE user_progress
    SET
        total_exp = v_total_exp,
        current_streak_days = COALESCE(p_current_streak_days, current_streak_days),
        longest_streak_days = COALESCE(p_longest_streak_days, longest_streak_days),
        last_activity_at = CASE
            WHEN v_last_activity_at IS NULL THEN last_activity_at
            WHEN last_activity_at IS NULL THEN v_last_activity_at
            ELSE GREATEST(last_activity_at, v_last_activity_at)
        END,
        updated_at = NOW()
    WHERE user_id = p_user_id;
END;
$$;


SET check_function_bodies = true;

import json
from datetime import date, datetime, timezone, timedelta

from fastapi import APIRouter, BackgroundTasks, Depends, HTTPException, status
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.ext.asyncio import AsyncSession

from ..core.db import get_db
from ..core import queries
from ..core.exp import calculate_workout_exp, calculate_meal_exp
from ..core.exp_utils import compute_level
from ..core.ml_service import process_meal_with_ai
from ..core.security import hash_password, verify_password, create_access_token, get_current_user
from ..schemas import (
    RegisterRequest, 
    LoginRequest, 
    TokenResponse, 
    MeResponse, 
    UpdateProfileRequest, 
    UserProfileResponse, 
    UpdateSettingsRequest, 
    UserSettingsResponse, 
    WorkoutRequest, 
    WorkoutResponse, 
    MealRequest, 
    MealResponse, 
    ChallengeRewardItem,
    QuestResponse, ChallengeResponse,
    UserQuestResponse, UserChallengeResponse,
    GameContentResponse,
    UpsertProfileRequest, ProfileResponse,
    LogWorkoutRequest, WorkoutLoggedResponse,
    LogMealRequest, MealLoggedResponse, MealStatusResponse,
    ErrorResponse,
)

router = APIRouter()

# ─── Helpers ───────────────────────────────────────────────────────────────────
def _compute_challenge_delta(mechanic_type: str, last_activity_date, event_date) -> dict:
    """
    Zwraca słownik z kluczami delta lub progress_value do przekazania do proc_update_challenge_progress.
    - count/accumulation: zawsze +1
    - streak: +1 jeśli ostatnia aktywność była wczoraj, reset do 1 jeśli dawniej, 0 jeśli już dziś
    """
    today = event_date.date() if hasattr(event_date, 'date') else event_date

    if mechanic_type == "streak":
        if last_activity_date is None:
            return {"progress_value": 1}
        elif last_activity_date == today:
            return None  # już policzone dziś, pomijamy
        elif last_activity_date == today - timedelta(days=1):
            return {"delta": 1}
        else:
            return {"progress_value": 1}  # reset
    else:
        # count, accumulation i inne
        return {"delta": 1}

# ─── System ────────────────────────────────────────────────────────────────────

@router.get("/test", tags=["System"], summary="Sprawdzenie działania API")
def connection_check():
    return {"status": "ok", "message": "Backend dziala poprawnie"}


@router.get("/health", tags=["System"], summary="Sprawdzenie połączenia z bazą")
async def health(db: AsyncSession = Depends(get_db)):

    import asyncio
    await asyncio.sleep(20)

    try:
        await db.execute(text("SELECT 1"))
        return {"status": "ok", "database": "connected"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Database unavailable: {str(e)}",
        )


# ─── Auth ──────────────────────────────────────────────────────────────────────

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED, tags=["Auth"], summary="Rejestracja użytkownika")
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    if await queries.get_user_by_email(db, body.email):
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Użytkownik z tym adresem e-mail już istnieje",
        )

    password_hash = hash_password(body.password)
    await db.execute(
        text("CALL proc_register_user(:email, :hash, :status)"),
        {"email": body.email, "hash": password_hash, "status": "active"},
    )

    user_row = await db.execute(
        text("SELECT id FROM users WHERE LOWER(email) = LOWER(:email)"),
        {"email": body.email},
    )
    new_user_id = user_row.scalar_one_or_none()
    if new_user_id:
        await db.execute(
            text("INSERT INTO user_progress (user_id) VALUES (:uid) ON CONFLICT DO NOTHING"),
            {"uid": new_user_id},
        )
    await db.commit()

    user = await queries.get_user_by_email(db, body.email)
    if not user:
        raise HTTPException(status_code=500, detail="Wystąpił błąd. Nie udało się utworzyć konta")

    token = create_access_token(user["id"], user["email"])
    return TokenResponse(access_token=token, user_id=user["id"], email=user["email"])


@router.post("/login", response_model=TokenResponse, tags=["Auth"], summary="Logowanie")
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    user = await queries.get_user_by_email(db, body.email)
    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Nieprawidłowy email lub hasło")
    if user["status"] != "active":
        raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail=f"Konto ma status: {user['status']}. Dostęp zablokowany.")
    if not verify_password(body.password, user["password_hash"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Nieprawidłowy email lub hasło")

    await queries.call_mark_login(db, user["id"], datetime.now(timezone.utc))
    await db.commit()

    token = create_access_token(user["id"], user["email"])
    return TokenResponse(
        access_token=token,
        user_id=user["id"],
        email=user["email"],
        username=user.get("username"),
        display_name=user.get("display_name"),
    )


@router.get("/me", response_model=MeResponse, tags=["Auth"], summary="Dane aktualnego użytkownika")
async def get_me(current_user: dict = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    user = await queries.get_user_by_email(db, current_user["email"])
    if not user:
        raise HTTPException(status_code=404, detail="Użytkownik nie istnieje")
    return MeResponse(
        user_id=current_user["user_id"],
        email=current_user["email"],
        username=user.get("username"),
        display_name=user.get("display_name"),
        status=user.get("status"),
    )


# ─── Profile ───────────────────────────────────────────────────────────────────

@router.get("/profile", response_model=ProfileResponse, tags=["Profile"], summary="Pobierz profil użytkownika")
async def get_profile(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await queries.get_profile(db, current_user["user_id"])
    if not profile:
        raise HTTPException(status_code=404, detail="Użytkownik nie istnieje")
    level_data = compute_level(profile["total_exp"])
    return ProfileResponse(
        user_id=profile["user_id"],
        email=profile["email"],
        username=profile.get("username"),
        display_name=profile.get("display_name"),
        birth_date=profile.get("birth_date"),
        gender=profile.get("gender"),
        height_cm=float(profile["height_cm"]) if profile.get("height_cm") is not None else None,
        weight_kg=float(profile["weight_kg"]) if profile.get("weight_kg") is not None else None,
        goal=profile.get("goal"),
        activity_level=profile.get("activity_level"),
        total_exp=profile["total_exp"],
        level=level_data["level"],
        xp_in_level=level_data["xp_in_level"],
        xp_to_next_level=level_data["xp_to_next_level"],
        current_streak_days=profile["current_streak_days"],
        longest_streak_days=profile["longest_streak_days"],
    )


@router.put("/profile", response_model=ProfileResponse, tags=["Profile"], summary="Zaktualizuj profil użytkownika")
async def update_profile(
    body: UpsertProfileRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    
    birth_date = date.fromisoformat(body.birth_date) if body.birth_date else None
    try:
        await queries.upsert_profile(
            db,
            user_id=current_user["user_id"],
            username=body.username,
            display_name=body.display_name,
            birth_date=birth_date,
            gender=body.gender,
            height_cm=body.height_cm,
            weight_kg=body.weight_kg,
            goal=body.goal,
            activity_level=body.activity_level,
        )
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Podana nazwa użytkownika jest już zajęta")

    profile = await queries.get_profile(db, current_user["user_id"])
    level_data = compute_level(profile["total_exp"])
    return ProfileResponse(
        user_id=profile["user_id"],
        email=profile["email"],
        username=profile.get("username"),
        display_name=profile.get("display_name"),
        birth_date=profile.get("birth_date"),
        gender=profile.get("gender"),
        height_cm=float(profile["height_cm"]) if profile.get("height_cm") is not None else None,
        weight_kg=float(profile["weight_kg"]) if profile.get("weight_kg") is not None else None,
        goal=profile.get("goal"),
        activity_level=profile.get("activity_level"),
        total_exp=profile["total_exp"],
        level=level_data["level"],
        xp_in_level=level_data["xp_in_level"],
        xp_to_next_level=level_data["xp_to_next_level"],
        current_streak_days=profile["current_streak_days"],
        longest_streak_days=profile["longest_streak_days"],
    )


# ─── Settings ──────────────────────────────────────────────────────────────────

@router.get("/settings", response_model=UserSettingsResponse, tags=["Profile"], summary="Pobierz ustawienia prywatności")
async def get_settings(current_user: dict = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    settings = await queries.get_user_settings(db, current_user["user_id"])
    return UserSettingsResponse(**settings)


@router.put("/settings", response_model=UserSettingsResponse, tags=["Profile"], summary="Zaktualizuj ustawienia prywatności")
async def update_settings(
    body: UpdateSettingsRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    await queries.upsert_user_settings(db, current_user["user_id"], body.data_processing_consent, body.profile_public)
    await db.commit()
    return UserSettingsResponse(data_processing_consent=body.data_processing_consent, profile_public=body.profile_public)


# ─── Workouts ──────────────────────────────────────────────────────────────────

@router.post("/workouts", response_model=WorkoutLoggedResponse, status_code=status.HTTP_201_CREATED, tags=["Activity"], summary="Zapisz trening")
async def log_workout(
    body: LogWorkoutRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    user_id = current_user["user_id"]
    performed_at = body.performed_at or datetime.now(timezone.utc)
    exp_amount = calculate_workout_exp(body.workout_type, body.duration_min, body.health_score)
    exercises_json = json.dumps([e.model_dump() for e in (body.exercises or [])])

    last_activity_date = await queries.get_last_activity_date(db, user_id)
    active_challenges = await queries.get_active_challenges_for_trigger(db, user_id, "workout_logged")
    active_challenges += await queries.get_active_challenges_for_trigger(db, user_id, "activity_logged")
    challenge_ids = [r["challenge_id"] for r in active_challenges]

    try:
        await queries.call_log_workout(
            db,
            user_id=user_id,
            workout_type=body.workout_type,
            title=body.title,
            performed_at=performed_at,
            duration_min=body.duration_min,
            health_score=body.health_score,
            notes=body.notes,
            exercises_json=exercises_json,
            exp_amount=exp_amount,
            activity_category=body.activity_category,
            activity_code=body.activity_code,
            activity_name=body.activity_name,
        )
    except Exception as e:
        await db.rollback()
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e).split("\n")[0])

    # Challenge tracking
    for challenge in active_challenges:
        delta_data = _compute_challenge_delta(
            challenge["mechanic_type"], last_activity_date, performed_at
        )
        if delta_data is None:
            continue
        params = {"uid": user_id, "cid": challenge["challenge_id"], "ts": performed_at}
        if "delta" in delta_data:
            await db.execute(
                text("CALL proc_update_challenge_progress(:uid, :cid, :delta, NULL, :ts, NULL)"),
                {**params, "delta": delta_data["delta"]},
            )
        else:
            await db.execute(
                text("CALL proc_update_challenge_progress(:uid, :cid, NULL, :pval, :ts, NULL)"),
                {**params, "pval": delta_data["progress_value"]},
            )

    row = await db.execute(
        text("SELECT id FROM workouts WHERE user_id = :uid ORDER BY created_at DESC LIMIT 1"),
        {"uid": user_id},
    )
    workout_id = row.scalar_one()

    newly_completed = await queries.get_newly_completed_challenges(db, user_id, challenge_ids)

    for r in newly_completed:
        await db.execute(
            text("CALL proc_claim_challenge_reward(:uid, :cid, :ts)"),
            {"uid": user_id, "cid": r["challenge_id"], "ts": performed_at},
        )

    await db.commit()

    progress = await queries.get_user_progress(db, user_id)
    rewards = [
        ChallengeRewardItem(
            challenge_id=r["challenge_id"],
            title=r["title"],
            points_earned=r["reward_exp"],
        )
        for r in newly_completed
    ]
    return WorkoutLoggedResponse(
        message="Trening zapisany",
        workout_id=workout_id,
        exp_granted=exp_amount,
        total_exp=progress["total_exp"] if progress else 0,
        rewards=rewards,
    )



@router.get("/workouts", response_model=list, tags=["Activity"])
async def get_workouts(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """
    Bezpieczna wersja testowa endpointu zwracająca listę treningów.
    """
    user_id = current_user["user_id"]
    
    try:
        # Pobieramy podstawowe kolumny. Jeśli któraś powoduje błąd bazy, 
        # informacja o tym zostanie dokładnie przekazana w treści błędu.
        result = await db.execute(
            text("""
                SELECT id, user_id, workout_type, title, performed_at, 
                    duration_min, health_score, notes,
                    activity_category, activity_name
                FROM workouts 
                WHERE user_id = :uid 
                ORDER BY performed_at DESC
            """),
            {"uid": user_id}
        )
        
        # Mapujemy surowe wiersze z bazy danych bezpośrednio na słowniki Pythona
        raw_workouts = result.mappings().all()
        workouts_list = [dict(row) for row in raw_workouts]
        
        return workouts_list

    except Exception as e:
        # Zamiast ogólnego błędu 500, zwracamy dokładny komunikat o błędzie z bazy danych
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Blad wykonania zapytania bazy danych: {str(e)}"
        )
# ─── Meals ─────────────────────────────────────────────────────────────────────

@router.post("/meals", response_model=MealLoggedResponse, status_code=status.HTTP_202_ACCEPTED, tags=["Activity"], summary="Zapisz posiłek")
async def log_meal(
    body: LogMealRequest,
    background_tasks: BackgroundTasks,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    user_id = current_user["user_id"]
    eaten_at = body.eaten_at or datetime.now(timezone.utc)

    last_activity_date = await queries.get_last_activity_date(db, user_id)
    active_challenges = await queries.get_active_challenges_for_trigger(db, user_id, "meal_logged")
    active_challenges += await queries.get_active_challenges_for_trigger(db, user_id, "activity_logged")
    challenge_ids = [r["challenge_id"] for r in active_challenges]

    await db.execute(
        text("""
            CALL proc_log_meal(
                p_user_id        => :user_id,
                p_meal_type      => :meal_type,
                p_eaten_at       => :eaten_at,
                p_title          => :title,
                p_photo_url      => :photo_url,
                p_notes          => :notes,
                p_health_score   => NULL,
                p_ai_confidence  => NULL,
                p_grant_exp      => false,
                p_exp_amount     => 0,
                p_exp_reason     => 'Meal pending',
                p_exp_created_at => :eaten_at
            )
        """),
        {
            "user_id": user_id,
            "meal_type": body.meal_type,
            "eaten_at": eaten_at,
            "title": body.title,
            "photo_url": body.photo_url,
            "notes": body.notes,
        },
    )

    row = await db.execute(
        text("SELECT id FROM meals WHERE user_id = :uid ORDER BY created_at DESC LIMIT 1"),
        {"uid": user_id},
    )
    meal_id = row.scalar_one()

    # Challenge tracking
    for challenge in active_challenges:
        delta_data = _compute_challenge_delta(
            challenge["mechanic_type"], last_activity_date, eaten_at
        )
        if delta_data is None:
            continue
        params = {"uid": user_id, "cid": challenge["challenge_id"], "ts": eaten_at}
        if "delta" in delta_data:
            await db.execute(
                text("CALL proc_update_challenge_progress(:uid, :cid, :delta, NULL, :ts, NULL)"),
                {**params, "delta": delta_data["delta"]},
            )
        else:
            await db.execute(
                text("CALL proc_update_challenge_progress(:uid, :cid, NULL, :pval, :ts, NULL)"),
                {**params, "pval": delta_data["progress_value"]},
            )

    newly_completed = await queries.get_newly_completed_challenges(db, user_id, challenge_ids)

    for r in newly_completed:
        await db.execute(
            text("CALL proc_claim_challenge_reward(:uid, :cid, :ts)"),
            {"uid": user_id, "cid": r["challenge_id"], "ts": eaten_at},
        )

    await db.commit()

    background_tasks.add_task(process_meal_with_ai, meal_id, body.photo_url, user_id)

    rewards = [
        ChallengeRewardItem(
            challenge_id=r["challenge_id"],
            title=r["title"],
            points_earned=r["reward_exp"],
        )
        for r in newly_completed
    ]
    return MealLoggedResponse(
        meal_id=meal_id,
        status="pending",
        exp_granted=0,
        rewards=rewards,
        message="Zdjęcie odebrane. AI analizuje posiłek...",
    )

@router.get("/meals/{meal_id}", response_model=MealStatusResponse, tags=["Activity"], summary="Pobierz status posiłku")
async def get_meal_status(
    meal_id: int,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    user_id = current_user["user_id"]

    row = await db.execute(
        text("SELECT id, status, health_score, photo_url FROM meals WHERE id = :meal_id AND user_id = :uid"),
        {"meal_id": meal_id, "uid": user_id},
    )
    meal = row.mappings().one_or_none()

    if not meal:
        raise HTTPException(status_code=404, detail="Posiłek nie znaleziony")

    exp_granted = calculate_meal_exp(meal["health_score"]) if meal["health_score"] is not None else 0
    
    return MealStatusResponse(
        meal_id=meal["id"],
        status=meal["status"],
        health_score=meal["health_score"],
        photo_url=meal["photo_url"],
        exp_granted=exp_granted,
    )






# -----Profile----------------------------------------------------------------------------------------------------------------------------------------------------------------

# @router.get("/profile", response_model=UserProfileResponse, tags=["Profile"], summary="Pobierz profil użytkownika")
# async def get_profile(current_user: dict = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
#     user_id = current_user["user_id"]
#     profile = await queries.get_user_profile(db, user_id)
#     if not profile:
#         raise HTTPException(status_code=404, detail="Profil nie istnieje")
#     level_data = compute_level(profile["total_exp"])
#     birth = profile.get("birth_date")
#     return UserProfileResponse(
#         user_id=profile["user_id"],
#         username=profile.get("username"),
#         display_name=profile.get("display_name"),
#         birth_date=str(birth) if birth else None,
#         sex=profile.get("sex"),
#         height_cm=float(profile["height_cm"]) if profile.get("height_cm") is not None else None,
#         weight_kg=float(profile["weight_kg"]) if profile.get("weight_kg") is not None else None,
#         goal=profile.get("goal"),
#         activity_level=profile.get("activity_level"),
#         total_exp=profile["total_exp"],
#         level=level_data["level"],
#         xp_in_level=level_data["xp_in_level"],
#         xp_to_next_level=level_data["xp_to_next_level"],
#         current_streak_days=profile["current_streak_days"],
#         longest_streak_days=profile["longest_streak_days"],
#     )


# @router.put("/profile", response_model=UserProfileResponse, tags=["Profile"], summary="Zaktualizuj profil użytkownika")
# async def update_profile(body: UpdateProfileRequest, current_user: dict = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
#     user_id = current_user["user_id"]
#     from datetime import date
#     birth_date = None
#     if body.birth_date:
#         try:
#             birth_date = date.fromisoformat(body.birth_date)
#         except ValueError:
#             raise HTTPException(status_code=422, detail="Nieprawidłowy format daty urodzenia (oczekiwano YYYY-MM-DD)")

#     await db.execute(
#         text("CALL proc_upsert_user_profile(:uid, :username, :display_name, :birth_date, :sex, :height_cm, :weight_kg, :goal, :activity_level)"),
#         {
#             "uid": user_id,
#             "username": body.username,
#             "display_name": body.display_name,
#             "birth_date": birth_date,
#             "sex": body.sex,
#             "height_cm": body.height_cm,
#             "weight_kg": body.weight_kg,
#             "goal": body.goal,
#             "activity_level": body.activity_level,
#         },
#     )
#     await db.commit()

#     profile = await queries.get_user_profile(db, user_id)
#     level_data = compute_level(profile["total_exp"])
#     birth = profile.get("birth_date")
#     return UserProfileResponse(
#         user_id=profile["user_id"],
#         username=profile.get("username"),
#         display_name=profile.get("display_name"),
#         birth_date=str(birth) if birth else None,
#         sex=profile.get("sex"),
#         height_cm=float(profile["height_cm"]) if profile.get("height_cm") is not None else None,
#         weight_kg=float(profile["weight_kg"]) if profile.get("weight_kg") is not None else None,
#         goal=profile.get("goal"),
#         activity_level=profile.get("activity_level"),
#         total_exp=profile["total_exp"],
#         level=level_data["level"],
#         xp_in_level=level_data["xp_in_level"],
#         xp_to_next_level=level_data["xp_to_next_level"],
#         current_streak_days=profile["current_streak_days"],
#         longest_streak_days=profile["longest_streak_days"],
#     )




# ─── Settings ─────────────────────────────────────────────────────────────────

@router.get("/settings", response_model=UserSettingsResponse, tags=["Profile"], summary="Pobierz ustawienia prywatności")
async def get_settings(current_user: dict = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    settings = await queries.get_user_settings(db, current_user["user_id"])
    return UserSettingsResponse(**settings)


@router.put("/settings", response_model=UserSettingsResponse, tags=["Profile"], summary="Zaktualizuj ustawienia prywatności")
async def update_settings(body: UpdateSettingsRequest, current_user: dict = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    await queries.upsert_user_settings(db, current_user["user_id"], body.data_processing_consent, body.profile_public)
    await db.commit()
    return UserSettingsResponse(data_processing_consent=body.data_processing_consent, profile_public=body.profile_public)




# ─── Quests & Challenges ───────────────────────────────────────────────────────

@router.get(
    "/quests",
    response_model=list[UserQuestResponse],
    tags=["Progress"],
    summary="Pobierz questy użytkownika",
)
async def get_quests(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    rows = await queries.get_user_quests(db, current_user["user_id"])
    return [
        UserQuestResponse(
            quest=QuestResponse(
                id=r["id"], code=r["code"], title=r["title"],
                description=r.get("description"),
                quest_type=r["quest_type"],
                progression_mode=r["progression_mode"],
                quest_series_code=r.get("quest_series_code"),
                sequence_order=r.get("sequence_order"),
                target_value=float(r["target_value"]),
                reward_exp=r["reward_exp"],
                mechanic_type=r["mechanic_type"],
                event_trigger=r["event_trigger"],
                conditions=r["conditions"],
            ),
            status=r["status"],
            progress_value=float(r["progress_value"]),
            started_at=r.get("started_at"),
            completed_at=r.get("completed_at"),
        )
        for r in rows
    ]


@router.get(
    "/challenges",
    response_model=list[UserChallengeResponse],
    tags=["Progress"],
    summary="Pobierz wyzwania użytkownika",
)
async def get_challenges(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    rows = await queries.get_user_challenges(db, current_user["user_id"])
    return [
        UserChallengeResponse(
            challenge=ChallengeResponse(
                id=r["id"], code=r["code"], title=r["title"],
                description=r.get("description"),
                quest_type=r["quest_type"],
                goal_value=float(r["goal_value"]),
                reward_exp=r["reward_exp"],
                mechanic_type=r["mechanic_type"],
                event_trigger=r["event_trigger"],
                end_date=r.get("end_date"),
            ),
            status=r["status"],
            progress_value=float(r["progress_value"]),
            started_at=r.get("started_at"),
            completed_at=r.get("completed_at"),
        )
        for r in rows
    ]


@router.get(
    "/game-content",
    response_model=GameContentResponse,
    tags=["Progress"],
    summary="Pobierz questy i wyzwania naraz",
)
async def get_game_content(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """Single endpoint returning both quests and challenges — useful for mobile app startup."""
    quest_rows = await queries.get_user_quests(db, current_user["user_id"])
    challenge_rows = await queries.get_user_challenges(db, current_user["user_id"])

    quests = [
        UserQuestResponse(
            quest=QuestResponse(
                id=r["id"], code=r["code"], title=r["title"],
                description=r.get("description"),
                quest_type=r["quest_type"],
                progression_mode=r["progression_mode"],
                quest_series_code=r.get("quest_series_code"),
                sequence_order=r.get("sequence_order"),
                target_value=float(r["target_value"]),
                reward_exp=r["reward_exp"],
                mechanic_type=r["mechanic_type"],
                event_trigger=r["event_trigger"],
                conditions=r["conditions"],
            ),
            status=r["status"],
            progress_value=float(r["progress_value"]),
            started_at=r.get("started_at"),
            completed_at=r.get("completed_at"),
        )
        for r in quest_rows
    ]

    challenges = [
        UserChallengeResponse(
            challenge=ChallengeResponse(
                id=r["id"], code=r["code"], title=r["title"],
                description=r.get("description"),
                quest_type=r["quest_type"],
                goal_value=float(r["goal_value"]),
                reward_exp=r["reward_exp"],
                mechanic_type=r["mechanic_type"],
                event_trigger=r["event_trigger"],
                end_date=r.get("end_date"),
            ),
            status=r["status"],
            progress_value=float(r["progress_value"]),
            started_at=r.get("started_at"),
            completed_at=r.get("completed_at"),
        )
        for r in challenge_rows
    ]

    return GameContentResponse(quests=quests, challenges=challenges)




# # ─── Workouts ─────────────────────────────────────────────────────────────────

# @router.post("/workouts", response_model=WorkoutResponse, status_code=status.HTTP_201_CREATED, tags=["Activity"], summary="Zapisz trening")
# async def log_workout(body: WorkoutRequest, current_user: dict = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
#     user_id = current_user["user_id"]
#     performed_at = body.performed_at or datetime.now(timezone.utc)
#     exp_amount = compute_workout_exp(body.duration_min, body.workout_type)

#     active_challenges = await queries.get_active_challenges_for_trigger(db, user_id, "workout_logged")
#     challenge_ids = [r["challenge_id"] for r in active_challenges]

#     import json
#     exercises_json = json.dumps([
#         {
#             "exercise_name": e.exercise_name,
#             "exercise_order": e.exercise_order,
#             "exercise_group": e.exercise_group,
#             "sets": e.sets,
#             "reps": e.reps,
#             "weight_kg": float(e.weight_kg) if e.weight_kg is not None else None,
#             "notes": e.notes,
#         }
#         for e in body.exercises
#     ])

#     await db.execute(
#         text("""
#             CALL proc_log_workout(
#                 :user_id, :workout_type, :title, :performed_at,
#                 :duration_min, NULL, :notes, CAST(:exercises AS jsonb),
#                 TRUE, :exp_amount, 'Workout logged', NULL,
#                 :activity_category, NULL, NULL
#             )
#         """),
#         {
#             "user_id": user_id,
#             "workout_type": body.workout_type,
#             "title": body.title,
#             "performed_at": performed_at,
#             "duration_min": body.duration_min,
#             "notes": body.notes or "",
#             "exercises": exercises_json,
#             "exp_amount": exp_amount,
#             "activity_category": body.activity_category,
#         },
#     )

#     for cid in challenge_ids:
#         await db.execute(
#             text("CALL proc_update_challenge_progress(:uid, :cid, :delta, NULL, :ts, NULL)"),
#             {"uid": user_id, "cid": cid, "delta": 1, "ts": performed_at},
#         )

#     row = await db.execute(
#         text("SELECT id FROM workouts WHERE user_id = :uid ORDER BY created_at DESC LIMIT 1"),
#         {"uid": user_id},
#     )
#     workout_id = row.scalar_one()

#     newly_completed = await queries.get_newly_completed_challenges(db, user_id, challenge_ids)
#     await db.commit()

#     rewards = [
#         ChallengeRewardItem(challenge_id=r["challenge_id"], title=r["title"], points_earned=r["reward_exp"])
#         for r in newly_completed
#     ]
#     return WorkoutResponse(workout_id=workout_id, exp_granted=exp_amount, rewards=rewards)


# # ─── Meals ────────────────────────────────────────────────────────────────────

# @router.post("/meals", response_model=MealResponse, status_code=status.HTTP_201_CREATED, tags=["Activity"], summary="Zapisz posiłek")
# async def log_meal(body: MealRequest, current_user: dict = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
#     user_id = current_user["user_id"]
#     eaten_at = body.eaten_at or datetime.now(timezone.utc)
#     exp_amount = compute_meal_exp(body.health_score)

#     active_challenges = await queries.get_active_challenges_for_trigger(db, user_id, "meal_logged")
#     challenge_ids = [r["challenge_id"] for r in active_challenges]

#     await db.execute(
#         text("""
#             CALL proc_log_meal(
#                 :user_id, :meal_type, :eaten_at, :title,
#                 NULL, :notes, :health_score, NULL,
#                 TRUE, :exp_amount, 'Meal logged', NULL
#             )
#         """),
#         {
#             "user_id": user_id,
#             "meal_type": body.meal_type,
#             "eaten_at": eaten_at,
#             "title": body.title,
#             "notes": body.notes or "",
#             "health_score": body.health_score,
#             "exp_amount": exp_amount,
#         },
#     )

#     for cid in challenge_ids:
#         await db.execute(
#             text("CALL proc_update_challenge_progress(:uid, :cid, :delta, NULL, :ts, NULL)"),
#             {"uid": user_id, "cid": cid, "delta": 1, "ts": eaten_at},
#         )

#     row = await db.execute(
#         text("SELECT id FROM meals WHERE user_id = :uid ORDER BY created_at DESC LIMIT 1"),
#         {"uid": user_id},
#     )
#     meal_id = row.scalar_one()

#     newly_completed = await queries.get_newly_completed_challenges(db, user_id, challenge_ids)
#     await db.commit()

#     rewards = [
#         ChallengeRewardItem(challenge_id=r["challenge_id"], title=r["title"], points_earned=r["reward_exp"])
#         for r in newly_completed
#     ]
#     return MealResponse(meal_id=meal_id, exp_granted=exp_amount, rewards=rewards)


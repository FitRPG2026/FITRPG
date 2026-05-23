import json
from fastapi import APIRouter, HTTPException, Depends, status
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from ..core.db import get_db
from ..core import queries
from ..core.security import hash_password, verify_password, create_access_token, get_current_user_id, get_current_user
from ..core.exp import calculate_workout_exp, calculate_meal_exp
from ..schemas import RegisterRequest, LoginRequest, TokenResponse, MeResponse, UpsertProfileRequest, LogWorkoutRequest, WorkoutLoggedResponse, LogMealRequest, MealLoggedResponse, ProfileResponse
from ..core.exp_utils import compute_level, compute_workout_exp, compute_meal_exp
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
    ChallengeRewardItem
)
from fastapi import BackgroundTasks
from ..core.ml_service import process_meal_with_ai



#   Tutaj przechowywane beda endpointy
router = APIRouter()

@router.get("/test", tags=["System"], summary="Sprawdzenie działania API") # z prefixem /api
def connection_check():
    """
    Zwraca prostą odpowiedź w celu potwierdzenia, że aplikacja backendowa działa i jest osiągalna.
    """
    return {'status':'ok', 'message':'Backend dziala poprawnie'}


@router.get("/health", tags=["System"], summary="Sprawdzenie połączenia z bazą")
async def health(db: AsyncSession = Depends(get_db)):
    """
    Wykonuje proste zapytanie do bazy danych (SELECT 1), aby zweryfikować czy połączenie
    pomiędzy API a bazą PostgreSQL działa poprawnie.
    """
    try:
        await db.execute(text("SELECT 1"))
        return {"status": "ok", "database": "connected"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Database unavailable: {str(e)}",
        )

# ─── Authentication  ───────────────────────────────────────────────────────────────────

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED, tags=["Auth"], summary="Rejestracja użytkownika")
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):
    """
    Tworzy nowe konto użytkownika w systemie FITRPG.
    
    - Sprawdza, czy podany e-mail nie jest już zarejestrowany.
    - Haszuje hasło za pomocą bcrypt.
    - Wywołuje procedurę bazodanową `proc_register_user`.
    - Po pomyślnej rejestracji od razu generuje i zwraca token JWT.
    """
    user = await queries.get_user_by_email(db, body.email)
    if user is not None:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Użytkownik z tym adresem e-mail już istnieje",
        )

    password_hash = hash_password(body.password)

    await db.execute(
        text("CALL proc_register_user(:email, :hash, :status)"),
        {"email": body.email, "hash": password_hash, "status": "active"},
    )
    # proc_register_user nie tworzy user_progress (brak triggera w tym schemacie)
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
        raise HTTPException(
            status_code=500,
            detail="Wystąpił błąd. Nie udało się utworzyć konta"
        )
    token = create_access_token(user["id"], user["email"])
    return TokenResponse(access_token=token, user_id=user["id"], email=user["email"])


@router.post("/login", response_model=TokenResponse, tags=["Auth"], summary="Logowanie")
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
    """
    Uwierzytelnia użytkownika i wydaje token dostępu.
    
    - Weryfikuje istnienie e-maila w bazie.
    - Sprawdza, czy konto ma status "active".
    - Waliduje hasło z hashem.
    - Zapisuje czas ostatniego logowania wywołując `proc_mark_login`.
    """
    user = await queries.get_user_by_email(db, body.email)

    if not user:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nieprawidłowy email lub hasło",
        )
    if user["status"] != "active":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=f"Konto ma status: {user['status']}. Dostęp zablokowany.",
        )
    if not verify_password(body.password, user["password_hash"]):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Nieprawidłowy email lub hasło",
        )

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
    """
    Zwraca szczegółowe informacje o aktualnie zalogowanym użytkowniku.
    Wymaga przekazania poprawnego tokenu JWT w nagłówku Authorization.
    """
    user = await queries.get_user_by_email(db, current_user["email"])
    if not user:
        raise HTTPException(status_code=404, detail="Użytkownik nie istnieje")
    return {
        "user_id": current_user["user_id"],
        "email": current_user["email"],
        "username": user.get("username"),
        "display_name": user.get("display_name"),
        "status": user.get("status"),
    }


# ─── Profile ───────────────────────────────────────────────────────────────────

@router.get("/profile", response_model=ProfileResponse)
async def get_profile(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    profile = await queries.get_profile(db, current_user["user_id"])
    if not profile:
        raise HTTPException(status_code=404, detail="Użytkownik nie istnieje")
    return profile


@router.put("/profile", status_code=status.HTTP_200_OK)
async def update_profile(
    body: UpsertProfileRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        await queries.upsert_profile(
            db,
            user_id=current_user["user_id"],
            username=body.username,
            display_name=body.display_name,
            birth_date=body.birth_date,
            gender=body.gender,
            height_cm=body.height_cm,
            weight_kg=body.weight_kg,
            goal=body.goal,
            activity_level=body.activity_level,
        )
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Podana nazwa użytkownika jest już zajęta",
        )

    profile = await queries.get_profile(db, current_user["user_id"])
    return profile


# ─── Workouts ──────────────────────────────────────────────────────────────────

@router.post("/workouts", response_model=WorkoutLoggedResponse, status_code=status.HTTP_201_CREATED)
async def log_workout(
    body: LogWorkoutRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    user_id = current_user["user_id"]
    performed_at = body.performed_at or datetime.now(timezone.utc)

    exp_amount = calculate_workout_exp(body.workout_type, body.duration_min, body.health_score)

    exercises_list = [e.model_dump() for e in (body.exercises or [])]

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
            exercises_json=json.dumps(exercises_list),
            exp_amount=exp_amount,
            activity_category=body.activity_category,
            activity_code=body.activity_code,
            activity_name=body.activity_name,
        )
        await db.commit()
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e).split("\n")[0],
        )

    progress = await queries.get_user_progress(db, user_id)
    return WorkoutLoggedResponse(
        message="Trening zapisany",
        exp_granted=exp_amount,
        total_exp=progress["total_exp"] if progress else 0,
    )


# ─── Meals ─────────────────────────────────────────────────────────────────────

# @router.post("/meals", response_model=MealLoggedResponse, status_code=status.HTTP_201_CREATED)
# async def log_meal(
#     body: LogMealRequest,
#     current_user: dict = Depends(get_current_user),
#     db: AsyncSession = Depends(get_db),
# ):
#     user_id = current_user["user_id"]
#     eaten_at = body.eaten_at or datetime.now(timezone.utc)

#     exp_amount = calculate_meal_exp(body.health_score)

#     try:
#         await queries.call_log_meal(
#             db,
#             user_id=user_id,
#             meal_type=body.meal_type,
#             eaten_at=eaten_at,
#             title=body.title,
#             photo_url=body.photo_url,
#             notes=body.notes,
#             health_score=body.health_score,
#             ai_confidence=body.ai_confidence,
#             exp_amount=exp_amount,
#         )
#         await db.commit()
#     except Exception as e:
#         await db.rollback()
#         raise HTTPException(
#             status_code=status.HTTP_400_BAD_REQUEST,
#             detail=str(e).split("\n")[0],
#         )

#     progress = await queries.get_user_progress(db, user_id)
#     return MealLoggedResponse(
#         message="Posiłek zapisany",
#         exp_granted=exp_amount,
#         total_exp=progress["total_exp"] if progress else 0,
#     )

@router.get("/meals/{meal_id}", tags=["Activity"], summary="Pobierz status posiłku")
async def get_meal_status(
    meal_id: int, 
    current_user: dict = Depends(get_current_user), 
    db: AsyncSession = Depends(get_db)
):
    """
    Endpoint wykorzystywany przez frontend do Polling'u.
    Sprawdza, czy AI skończyło analizować posiłek.
    """
    user_id = current_user["user_id"]
    
    # Wyciągamy posiłek z bazy upewniając się, że należy do tego użytkownika
    row = await db.execute(
        text("SELECT id, status, health_score, photo_url FROM meals WHERE id = :meal_id AND user_id = :uid"),
        {"meal_id": meal_id, "uid": user_id}
    )
    meal = row.mappings().one_or_none()
    
    if not meal:
        raise HTTPException(status_code=404, detail="Posiłek nie znaleziony")
        
    # Obliczamy exp, jeśli analiza się zakończyła i jest wynik
    exp_granted = 0
    if meal["health_score"] is not None:
        exp_granted = calculate_meal_exp(meal["health_score"])

    return {
        "meal_id": meal["id"],
        "status": meal["status"],          # Zwraca 'pending', 'completed' lub 'failed'
        "health_score": meal["health_score"],
        "photo_url": meal["photo_url"],
        "exp_granted": exp_granted
    }


@router.post("/meals", response_model=MealLoggedResponse, status_code=status.HTTP_202_ACCEPTED)
async def log_meal(
    body: LogMealRequest, 
    background_tasks: BackgroundTasks, 
    current_user: dict = Depends(get_current_user), 
    db: AsyncSession = Depends(get_db)
):
    user_id = current_user["user_id"]
    eaten_at = body.eaten_at or datetime.now(timezone.utc)

    # 1. Zapisujemy posiłek bez punktów i health_score
    await db.execute(
        text("""
            CALL proc_log_meal(
                p_user_id => :user_id, p_meal_type => :meal_type, p_eaten_at => :eaten_at,
                p_title => :title, p_photo_url => :photo_url, p_notes => :notes,
                p_health_score => NULL, p_ai_confidence => NULL, 
                p_grant_exp => false, p_exp_amount => 0, p_exp_reason => 'Meal pending', p_exp_created_at => :eaten_at
            )
        """),
        {
            "user_id": user_id, "meal_type": body.meal_type, "eaten_at": eaten_at,
            "title": body.title, "photo_url": body.photo_url, "notes": body.notes,
        },
    )
    
    # 2. Pobieramy ID zapisanego posiłku
    row = await db.execute(text("SELECT id FROM meals WHERE user_id = :uid ORDER BY created_at DESC LIMIT 1"), {"uid": user_id})
    meal_id = row.scalar_one()
    await db.commit()

    # 3. Zlecamy zadanie w tle!
    background_tasks.add_task(process_meal_with_ai, meal_id, body.photo_url, user_id)

    # 4. Natychmiast odpowiadamy frontendowi
    return MealLoggedResponse(
        meal_id=meal_id,
        status="pending",
        message="Zdjęcie odebrane. AI analizuje posiłek..."
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

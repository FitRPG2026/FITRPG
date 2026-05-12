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
from ..schemas import RegisterRequest, LoginRequest, TokenResponse, MeResponse, UpsertProfileRequest, LogWorkoutRequest, WorkoutLoggedResponse, LogMealRequest, MealLoggedResponse

#   Tutaj przechowywane beda endpointy
router = APIRouter()


# ─── Utility ──────────────────────────────────────────────────────────────────

@router.get("/test")
def connection_check():
    return {'status':'ok', 'message':'Backend dziala poprawnie'}


@router.get("/health")
async def health(db: AsyncSession = Depends(get_db)):
    try:
        await db.execute(text("SELECT 1"))
        return {"status": "ok", "database": "connected"}
    except Exception as e:
        raise HTTPException(
            status_code=status.HTTP_503_SERVICE_UNAVAILABLE,
            detail=f"Database unavailable: {str(e)}",
        )

# ─── Authentication  ───────────────────────────────────────────────────────────────────

@router.post("/register", response_model=TokenResponse, status_code=status.HTTP_201_CREATED)
async def register(body: RegisterRequest, db: AsyncSession = Depends(get_db)):

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


@router.post("/login", response_model=TokenResponse)
async def login(body: LoginRequest, db: AsyncSession = Depends(get_db)):
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


@router.get("/me")
async def get_me(current_user: dict = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
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

@router.put("/profile", status_code=status.HTTP_200_OK)
async def upsert_profile(
    body: UpsertProfileRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    try:
        await queries.call_upsert_profile(
            db,
            user_id=current_user["user_id"],
            username=body.username,
            display_name=body.display_name,
            birth_date=body.birth_date,
            sex=body.sex,
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

    return {"message": "Profil zaktualizowany"}


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

@router.post("/meals", response_model=MealLoggedResponse, status_code=status.HTTP_201_CREATED)
async def log_meal(
    body: LogMealRequest,
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    user_id = current_user["user_id"]
    eaten_at = body.eaten_at or datetime.now(timezone.utc)

    exp_amount = calculate_meal_exp(body.health_score)

    try:
        await queries.call_log_meal(
            db,
            user_id=user_id,
            meal_type=body.meal_type,
            eaten_at=eaten_at,
            title=body.title,
            photo_url=body.photo_url,
            notes=body.notes,
            health_score=body.health_score,
            ai_confidence=body.ai_confidence,
            exp_amount=exp_amount,
        )
        await db.commit()
    except Exception as e:
        await db.rollback()
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail=str(e).split("\n")[0],
        )

    progress = await queries.get_user_progress(db, user_id)
    return MealLoggedResponse(
        message="Posiłek zapisany",
        exp_granted=exp_amount,
        total_exp=progress["total_exp"] if progress else 0,
    )
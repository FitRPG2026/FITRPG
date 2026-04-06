from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from ..core.db import get_db
from ..core import queries
from ..core.security import hash_password, verify_password, create_access_token, get_current_user_id, get_current_user
from ..schemas import RegisterRequest, LoginRequest, TokenResponse, UserProgressResponse, LogMealRequest, LogMealResponse, LogWorkoutRequest, LogWorkoutResponse
#   Tutaj przechowywane beda endpointy
router = APIRouter()

@router.get("/test")    # z prefixem /api
def connection_check():
    return {'status':'ok', 'message':'Backend dziala poprawnie'}

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

    token = create_access_token(user["id"], user["email"])

    return TokenResponse(
        access_token=token,
        user_id=user["id"],
        email=user["email"],
        username=user.get("username"),
        display_name=user.get("display_name"),
    )


# ─── Progress ───────────────────────────────────────────────────────────────────

@router.get("/progress/me", response_model=UserProgressResponse)
async def get_my_progress(
    current_user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    progress = await queries.get_user_progress(db, current_user["user_id"])

    if not progress:
        raise HTTPException(status_code=404, detail="Brak danych")

    return UserProgressResponse(**progress)



# ─── Meals ───────────────────────────────────────────────────────────────────

@router.post("/meals", response_model=LogMealResponse, status_code=status.HTTP_201_CREATED)
async def log_meal(
    body: LogMealRequest,
    user_id: int = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    if body.grant_exp and not body.exp_amount:
        raise HTTPException(422, detail="exp_amount jest wymagany gdy grant_exp=True")

    body_dict = body.model_dump()
    body_dict["items"] = [
        {k: v for k, v in item.items() if v is not None}
        for item in body_dict["items"]
    ]

    try:
        await queries.call_log_meal(db, user_id, body_dict)
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Błąd zapisu danych — sprawdź wartości")

    meal = await queries.get_last_meal(db, user_id)
    if not meal:
        raise HTTPException(500, detail="Błąd odczytu po zapisie")

    return LogMealResponse(message="Posiłek zapisany pomyślnie", meal_id=meal["id"])


@router.get("/meals")
async def get_my_meals(
    limit: int = 20,
    user_id: int = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    
    return {"meals": await queries.get_meals(db, user_id, limit)}


@router.get("/meals/{meal_id}")
async def get_meal(
    meal_id: int,
    user_id: int = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    meal = await queries.get_meal_with_items(db, meal_id, user_id)

    if meal is None:
        raise HTTPException(status_code=404, detail="Posiłek nie znaleziony")

    return meal

# ─── Workouts ──────────────────────────────────────────────────────────────────

@router.post("/workouts", response_model=LogWorkoutResponse, status_code=status.HTTP_201_CREATED)
async def log_workout(
    body: LogWorkoutRequest,
    user_id: int = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    if body.grant_exp and not body.exp_amount:
        raise HTTPException(422, detail="exp_amount jest wymagany gdy grant_exp=True")

    body_dict = body.model_dump()
    body_dict["exercises"] = [
        {k: v for k, v in ex.items() if v is not None}
        for ex in body_dict["exercises"]
    ]

    try:
        await queries.call_log_workout(db, user_id, body_dict)
        await db.commit()
    except IntegrityError:
        await db.rollback()
        raise HTTPException(status_code=400, detail="Błąd zapisu danych — sprawdź wartości")

    workout = await queries.get_last_workout(db, user_id)
    if not workout:
        raise HTTPException(500, detail="Błąd odczytu po zapisie")

    return LogWorkoutResponse(message="Trening zapisany pomyślnie", workout_id=workout["id"])

@router.get("/workouts")
async def get_my_workouts(
    limit: int = 20,
    user_id: int = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
   
    return {"workouts": await queries.get_workouts(db, user_id, limit)}


@router.get("/workout/{workout_id}")
async def get_workout(
    workout_id: int,
    user_id: int = Depends(get_current_user_id),
    db: AsyncSession = Depends(get_db),
):
    workout = await queries.get_workout_with_exercises(db, workout_id, user_id)
    if workout is None:
        raise HTTPException(status_code=404, detail="Trening nie znaleziony")
    return workout
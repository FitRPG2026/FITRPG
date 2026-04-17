from fastapi import APIRouter, HTTPException, Depends, status
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import distinct, select, text
from sqlalchemy.exc import IntegrityError
from sqlalchemy.orm import Session
from ..core.db import get_db
from ..core import queries
from ..core.security import hash_password, verify_password, create_access_token, get_current_user_id, get_current_user
from ..schemas import RegisterRequest, LoginRequest, TokenResponse, MeResponse

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
    
# ─── EXERCISE ───────────────────────────────────────────────────────────────────

@router.get("/training-data")
async def get_training_data_from_history(db: AsyncSession = Depends(get_db)):
    types_stmt = select(distinct(queries.Workout.workout_type)).where(queries.Workout.workout_type != None)
    types_result = await db.execute(types_stmt)
    existing_types = types_result.scalars().all()

    ex_stmt = (
        select(queries.Workout.workout_type, queries.WorkoutExercise.exercise_name)
        .join(queries.WorkoutExercise, queries.Workout.id == queries.WorkoutExercise.workout_id)
        .distinct()
    )
    ex_result = await db.execute(ex_stmt)
    rows = ex_result.all()

    categories = [{"value": t, "label": t.capitalize()} for t in existing_types]
    
    exercise_types = {t: [] for t in existing_types}
    for w_type, ex_name in rows:
        if w_type in exercise_types:
            exercise_types[w_type].append(ex_name)

    return {
        "categories": categories,
        "exercise_types": exercise_types
    }
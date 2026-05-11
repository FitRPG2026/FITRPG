from fastapi import APIRouter, HTTPException, Depends, status
from datetime import datetime, timezone
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import text
from sqlalchemy.exc import IntegrityError
from ..core.db import get_db
from ..core import queries
from ..core.security import hash_password, verify_password, create_access_token, get_current_user_id, get_current_user
from ..schemas import RegisterRequest, LoginRequest, TokenResponse, MeResponse

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
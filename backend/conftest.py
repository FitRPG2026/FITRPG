import asyncio
import pytest
from httpx import AsyncClient, ASGITransport
from datetime import datetime
import importlib
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from sqlalchemy import text

from app.core.db import engine, get_db
from app.main import app as fastapi_app

try:
    importlib.import_module("app.api.routes")
except ImportError:
    pass

@pytest.fixture(scope="session", autouse=True)
def event_loop():
    """Tworzy jeden wspólny loop dla całej sesji testowej."""
    policy = asyncio.get_event_loop_policy()
    loop = policy.new_event_loop()
    yield loop
    loop.close()

_created_test_user_ids = []

@pytest.fixture(scope="session", autouse=True)
def override_database_dependency():
    """Podmienia get_db w FastAPI, aby aplikacja używała kontrolowanego sessionmakera."""
    TestingAsyncSessionLocal = async_sessionmaker(
        bind=engine,
        class_=AsyncSession,
        expire_on_commit=False,
    )
    
    async def _override_get_db() -> AsyncSession:
        async with TestingAsyncSessionLocal() as session:
            yield session
            
    fastapi_app.dependency_overrides[get_db] = _override_get_db
    yield
    fastapi_app.dependency_overrides.clear()

@pytest.fixture(scope="function", autouse=True)
async def clean_database_between_tests():
    """
    Bezpieczne czyszczenie dla bazy produkcyjnej/chmurowej.
    Usuwa TYLKO użytkowników stworzonych w ramach bieżącego testu.
    """
    start_idx = len(_created_test_user_ids)
    yield
    new_ids = _created_test_user_ids[start_idx:]
    
    if new_ids:
        async with engine.begin() as conn:
            await conn.execute(
                text("DELETE FROM users WHERE id = ANY(:ids);"),
                {"ids": new_ids}
            )

@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"

@pytest.fixture(scope="session")
async def client():
    """Tworzy jeden wspólny asynchroniczny klient HTTP dla całej sesji."""
    async with AsyncClient(
        transport=ASGITransport(app=fastapi_app),
        base_url="http://testserver"
    ) as ac:
        yield ac

@pytest.fixture(scope="function")
async def registered_user(client):
    """Tworzy unikalnego użytkownika i rejestruje jego ID do usunięcia."""
    unique_suffix = int(datetime.now().timestamp() * 1000)
    email = f"test_{unique_suffix}@example.com"
    password = "test123456"
    
    response = await client.post("/api/register", json={
        "email": email,
        "password": password
    })
    
    assert response.status_code == 201
    data = response.json()
    
    user_id = data["user_id"]
    _created_test_user_ids.append(user_id)
    
    return {
        "email": email,
        "password": password,
        "token": data["access_token"],
        "user_id": user_id
    }

@pytest.fixture(scope="function")
def logged_in_headers(registered_user):
    return {"Authorization": f"Bearer {registered_user['token']}"}
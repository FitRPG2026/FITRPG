import pytest
from httpx import AsyncClient, ASGITransport
from datetime import datetime
import importlib
from app.core.db import engine
from sqlalchemy import text
from app.main import app as fastapi_app

try:
    importlib.import_module("app.api.routes")
except ImportError:
    pass

@pytest.fixture(scope="function", autouse=True)
async def clean_database_between_tests():
    """
    Ta funkcja uruchamia się automatycznie dla każdego testu.
    Pozwala bazie w chmurze zachować strukturę, ale czyści dane testowe po zakończeniu.
    """
    yield
    
    async with engine.begin() as conn:
        await conn.execute(text("TRUNCATE TABLE users CASCADE;"))

@pytest.fixture(scope="session")
def anyio_backend():
    return "asyncio"

@pytest.fixture(scope="session")
async def client():
    """Tworzy jeden wspólny asynchroniczny klient HTTP dla całej sesji testowej."""
    async with AsyncClient(
        transport=ASGITransport(app=fastapi_app),
        base_url="http://testserver"
    ) as ac:
        yield ac

@pytest.fixture(scope="function")
async def registered_user(client):
    """Tworzy unikalnego użytkownika testowego dla testu."""
    unique_suffix = int(datetime.now().timestamp() * 1000)
    email = f"test_{unique_suffix}@example.com"
    password = "test123456"
    
    response = await client.post("/api/register", json={
        "email": email,
        "password": password
    })
    
    assert response.status_code == 201
    data = response.json()
    
    return {
        "email": email,
        "password": password,
        "token": data["access_token"],
        "user_id": data["user_id"]
    }

@pytest.fixture(scope="function")
async def logged_in_headers(registered_user):
    """Tworzy nagłówki z tokenem dla zalogowanych testów."""
    return {"Authorization": f"Bearer {registered_user['token']}"}
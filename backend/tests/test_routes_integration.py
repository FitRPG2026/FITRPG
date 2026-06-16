import pytest
from unittest.mock import patch
from datetime import datetime, timezone
from conftest import _created_test_user_ids

@pytest.mark.asyncio
async def test_register_creates_token(client):
    """Testuje czystą rejestrację nowego użytkownika."""
    unique_email = f"new_user_{datetime.now().timestamp()}@example.com"
    response = await client.post("/api/register", json={
        "email": unique_email,
        "password": "password123"
    })
    
    assert response.status_code == 201
    data = response.json()
    assert "access_token" in data
    assert len(data["access_token"]) > 0
    assert data["email"] == unique_email
    assert "user_id" in data
    
    _created_test_user_ids.append(data["user_id"])

@pytest.mark.asyncio
async def test_register_duplicate_email(client, registered_user):
    """Testuje rejestrację z duplikatem emaila (wstrzykujemy registered_user)."""
    response = await client.post("/api/register", json={
        "email": registered_user["email"],
        "password": "anotherpassword"
    })
    
    assert response.status_code == 409
    data = response.json()
    
    assert "error" in data
    assert "istnieje" in data["error"].lower()


@pytest.mark.asyncio
async def test_login_creates_token(client, registered_user):
    response = await client.post("/api/login", json={
        "email": registered_user["email"],
        "password": registered_user["password"]
    })
    
    assert response.status_code == 200
    data = response.json()
    assert "access_token" in data
    assert data["email"] == registered_user["email"]


@pytest.mark.asyncio
async def test_login_wrong_password(client, registered_user):
    response = await client.post("/api/login", json={
        "email": registered_user["email"],
        "password": "wrongpassword"
    })
    
    assert response.status_code == 401
    data = response.json()
    
    assert "error" in data


@pytest.mark.asyncio
async def test_login_nonexistent_user(client):
    response = await client.post("/api/login", json={
        "email": "nonexistent@example.com",
        "password": "password"
    })
    assert response.status_code == 401


@pytest.mark.asyncio
async def test_log_workout_success(client, logged_in_headers):
    response = await client.post(
        "/api/workouts",
        headers=logged_in_headers,
        json={
            "workout_type": "cardio",
            "title": "Trening biegowy",
            "performed_at": datetime.now(timezone.utc).isoformat(),
            "duration_min": 30,
            "health_score": 7,
            "notes": "Bieganie na bieżni"
        }
    )
    assert response.status_code in [200, 201]


@pytest.mark.asyncio
async def test_log_workout_invalid_type(client, logged_in_headers):
    response = await client.post(
        "/api/workouts",
        headers=logged_in_headers,
        json={"workout_type": "invalid_type", "duration_min": 30}
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_log_workout_zero_duration(client, logged_in_headers):
    response = await client.post(
        "/api/workouts",
        headers=logged_in_headers,
        json={"workout_type": "cardio", "duration_min": 0}
    )
    assert response.status_code == 422


@pytest.mark.asyncio
async def test_log_meal_with_mock_ai(client, logged_in_headers):
    with patch("app.api.routes.process_meal_with_ai") as mock_ai:
        mock_ai.return_value = None
        
        response = await client.post(
            "/api/meals",
            headers=logged_in_headers,
            json={
                "meal_type": "breakfast",
                "title": "Śniadanie",
                "photo_url": "https://example.com/meal.jpg",
                "notes": "Jajecznica"
            }
        )
    assert response.status_code == 202
    assert "meal_id" in response.json()

@pytest.mark.asyncio
async def test_log_meal_without_photo_does_not_start_ai(client, logged_in_headers):
    with patch("app.api.routes.process_meal_with_ai") as mock_ai:
        response = await client.post(
            "/api/meals",
            headers=logged_in_headers,
            json={
                "meal_type": "breakfast",
                "title": "Breakfast",
                "health_score": 4,
                "notes": "Oats"
            }
        )

    assert response.status_code == 202
    data = response.json()
    assert data["status"] == "completed"
    assert data["exp_granted"] > 0
    mock_ai.assert_not_called()

@pytest.mark.asyncio
async def test_profile_updates_after_workout(client, logged_in_headers):
    profile_res_before = await client.get("/api/profile", headers=logged_in_headers)
    exp_before = profile_res_before.json()["total_exp"]
    
    await client.post(
        "/api/workouts",
        headers=logged_in_headers,
        json={"workout_type": "cardio", "title": "Bieganie", "duration_min": 30, "health_score": 7}
    )
    
    profile_res_after = await client.get("/api/profile", headers=logged_in_headers)
    assert profile_res_after.json()["total_exp"] >= exp_before


@pytest.mark.asyncio
async def test_profile_returns_all_stats(client, logged_in_headers):
    response = await client.get("/api/profile", headers=logged_in_headers)
    assert response.status_code == 200
    data = response.json()
    
    for field in ["user_id", "email", "total_exp", "level"]:
        assert field in data


@pytest.mark.asyncio
async def test_get_me_current_user(client, registered_user, logged_in_headers):
    """Dodano registered_user jako argument, aby sprawdzić asercję poprawności danych."""
    response = await client.get("/api/me", headers=logged_in_headers)
    assert response.status_code == 200
    data = response.json()
    assert data["email"] == registered_user["email"]
    assert data["user_id"] == registered_user["user_id"]

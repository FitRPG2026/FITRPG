# Dokumentacja Backend - FITRPG API

Dokumentacja techniczna struktury plików i odpowiedzialności poszczególnych modułów aplikacji opartej na FastAPI.

## Struktura i Opis Plików

### Główne pliki aplikacji

*   **[`app/main.py`](app/main.py)** – Główny punkt wejścia aplikacji FastAPI. Definiuje konfigurację globalną, w tym:
    *   Obsługę **CORS** z listą dozwolonych domen (frontend `localhost:4200`, Vercel deployment)
    *   Globalne handlery wyjątków dla `HTTPException` oraz błędów walidacji `RequestValidationError`
    *   Podpięcie routerów pod prefiks `/api` oraz inicjalizację dokumentacji **Swagger/OpenAPI**
    *   Definicję endpointu `/test` do sprawdzenia dostępności API

*   **[`app/api/routes.py`](app/api/routes.py)** – Kontrolery API (Endpointy). Zawiera definicje ścieżek URL dla operacji:
    *   **Autoryzacja**: `/register` (rejestracja), `/login` (logowanie), `/me` (dane użytkownika)
    *   **Profil**: `/profile` (GET/PUT) – zarządzanie danymi użytkownika
    *   **Ustawienia**: `/settings` (GET/PUT) – ustawienia prywatności i zgody na przetwarzanie danych
    *   **Aktywność**:
        *   `/workouts` (POST) – logowanie treningów z obliczaniem EXP
        *   `/meals` (POST) – logowanie posiłków z analizą AI w tle
        *   `/meals/{meal_id}` (GET) – sprawdzanie statusu analizy AI (polling)
    *   System **Dependency Injection** (`Depends`) do wstrzykiwania sesji bazy danych i logiki bezpieczeństwa
    *   Obsługa zadań w tle (`BackgroundTasks`) dla analizy AI posiłków

### Rdzeń aplikacji (Core)

*   **[`app/core/config.py`](app/core/config.py)** – Zarządzanie konfiguracją przy użyciu `pydantic_settings`. Automatycznie ładuje zmienne środowiskowe z pliku `.env` (np. `DATABASE_URL`, `SECRET_KEY`, `ACCESS_TOKEN_EXPIRE_MINUTES`, `HF_TOKEN`) i rzuca błąd, jeśli brakuje wymaganych danych.

*   **[`app/core/db.py`](app/core/db.py)** – Konfiguracja asynchronicznego połączenia z bazą **PostgreSQL** przy użyciu `asyncpg` i **SQLAlchemy**. Zarządza pulą połączeń (pool_size=10, max_overflow=20) i udostępnia generator sesji `get_db` dla żądań API. Obsługuje SSL dla hostów Neon.tech.

*   **[`app/core/queries.py`](app/core/queries.py)** – Warstwa dostępu do danych (DAL). Hermetyzuje surowe zapytania SQL oraz wywołania procedur składowanych:
    *   `get_user_by_email` – pobieranie danych użytkownika z JOIN-ami
    *   `call_mark_login` – aktualizacja ostatniego logowania i serii logowań
    *   `get_profile`, `upsert_profile` – operacje na profilu użytkownika
    *   `get_user_progress`, `call_log_workout`, `call_log_meal` – operacje na postępach i aktywności
    *   `get_user_settings`, `upsert_user_settings` – zarządzanie ustawieniami prywatności

*   **[`app/core/security.py`](app/core/security.py)** – Moduł bezpieczeństwa. Odpowiada za:
    *   Hashowanie i weryfikację haseł (algorytm bcrypt)
    *   Generowanie i dekodowanie tokenów **JWT** (HS256)
    *   Definiowanie zależności `get_current_user` do ochrony zasobów przed nieautoryzowanym dostępem
    *   Walidację statusu użytkownika (tylko "active")

*   **[`app/core/ml_service.py`](app/core/ml_service.py)** – Usługa AI do analizy zdrowotności posiłków.
    *   Korzysta z klienta Gradio do interakcji z modelem Hugging Face (`stachtotalny/fitrpg`)
    *   Funkcja `process_meal_with_ai` wykonuje analizę obrazu posiłku i zwraca wynikową ocenę zdrowotną (health_score)
    *   Wykorzystuje `asyncio.to_thread` do wykonywania synchronicznych wywołań w tle, nie blokując wątku FastAPI
    *   Aktualizuje stan posiłku w bazie (`pending` → `completed`/`failed`) i przyznaje EXP na podstawie wyniku

*   **[`app/core/stats.py`](app/core/stats.py)** – Moduł statystyk użytkownika.
    *   Funkcja `get_user_stats` pobiera szczegółowe statystyki za ostatnie N dni:
        *   Liczba treningów i posiłków
        *   Całkowity EXP, poziom, serie logowań
        *   Średni czas treningu, średnia ocena zdrowotna posiłków
        *   Rozkład treningów i posiłków według typu
        *   Rozkład aktywności per dzień

*   **[`app/core/exp.py`](app/core/exp.py)** – System obliczania EXP.
    *   `calculate_workout_exp` – oblicza EXP za trening na podstawie typu, czasu trwania i oceny zdrowotnej
    *   `calculate_meal_exp` – oblicza EXP za posiłek na podstawie oceny zdrowotnej (health_score)

*   **[`app/core/exp_utils.py`](app/core/exp_utils.py)** – Narzędzia pomocnicze do obliczeń.
    *   `compute_level` – oblicza poziom gracza i XP na podstawie całkowitego EXP (wzór: level n wymaga 100*n XP)
    *   `compute_workout_exp`, `compute_meal_exp` – starsze funkcje obliczeniowe (zachowane dla kompatybilności)

### Schematy danych (Schemas)

*   **[`app/schemas.py`](app/schemas.py)** – Modele DTO (Data Transfer Objects) oparte na bibliotece **Pydantic**.
    *   **AUTH**: `RegisterRequest`, `LoginRequest`, `TokenResponse`, `MeResponse`
    *   **PROFILE**: `UpsertProfileRequest`, `ProfileResponse`, `UpdateProfileRequest`, `UserProfileResponse`
    *   **SETTINGS**: `UpdateSettingsRequest`, `UserSettingsResponse`
    *   **WORKOUTS**: `LogWorkoutRequest`, `WorkoutLoggedResponse`, `ExerciseInput`
    *   **MEALS**: `LogMealRequest`, `MealLoggedResponse`, `MealRequest`
    *   **STATS**: `UserStatsResponse`
    *   Walidacja danych wejściowych z niestandardowymi regułami (np. minimalna długość hasła, zakresy wartości)

### Konteneryzacja i Zależności

*   **[`Dockerfile`](Dockerfile)** – Plik konfiguracyjny do budowy obrazu kontenera opartego na Python 3.11-slim. Definiuje środowisko pracy, instaluje zależności i uruchamia serwer `uvicorn` na porcie 8000.
*   **[`requirements.txt`](requirements.txt)** – Lista wszystkich bibliotek niezbędnych do działania projektu (m.in. FastAPI, SQLAlchemy, asyncpg, python-jose, bcrypt, gradio-client).
*   **[`pytest.ini`](pytest.ini)** – Konfiguracja testów z trybem asynchronicznym (`asyncio_mode = auto`).
*   **[`conftest.py`](conftest.py)** – Punkt wejścia do konfiguracji testów (obecnie pusty).

## Technologie

*   **Framework:** FastAPI 0.135.1
*   **Baza danych:** PostgreSQL (Async) z Neon.tech
*   **ORM:** SQLAlchemy 2.0
*   **Bezpieczeństwo:** JWT (HS256), Bcrypt
*   **AI/ML:** Gradio Client (Hugging Face)
*   **Konteneryzacja:** Docker
*   **Testy:** pytest 9.0.2 (asyncio_mode)
*   **Typowanie:** pydantic-core 2.41.5, typing-extensions 4.15.0

## Endpointy API

### System
| Metoda | Endpoint | Opis |
|--------|----------|------|
| GET | `/api/test` | Sprawdzenie dostępności API |
| GET | `/api/health` | Sprawdzenie połączenia z bazą danych |

### Autoryzacja
| Metoda | Endpoint | Opis |
|--------|----------|------|
| POST | `/api/register` | Rejestracja nowego użytkownika |
| POST | `/api/login` | Logowanie i uzyskanie tokenu JWT |
| GET | `/api/me` | Pobierz dane aktualnie zalogowanego użytkownika |

### Profil
| Metoda | Endpoint | Opis |
|--------|----------|------|
| GET | `/api/profile` | Pobierz profil użytkownika |
| PUT | `/api/profile` | Zaktualizuj profil użytkownika |
| GET | `/api/settings` | Pobierz ustawienia prywatności |
| PUT | `/api/settings` | Zaktualizuj ustawienia prywatności |

### Aktywność
| Metoda | Endpoint | Opis |
|--------|----------|------|
| POST | `/api/workouts` | Zapisz trening (z obliczaniem EXP) |
| POST | `/api/meals` | Zapisz posiłek (analiza AI w tle) |
| GET | `/api/meals/{meal_id}` | Sprawdź status analizy AI posiłku |

### Statystyki
| Metoda | Endpoint | Opis |
|--------|----------|------|
| GET | `/api/stats` | Pobierz statystyki użytkownika |

## Zmienne środowiskowe

| Zmienna | Opis |
|---------|------|
| `DATABASE_URL` | URL połączenia z bazą PostgreSQL (Neon.tech) |
| `SECRET_KEY` | Tajny klucz do generowania tokenu JWT |
| `ACCESS_TOKEN_EXPIRE_MINUTES` | Czas ważności tokenu JWT (domyślnie 60 minut) |
| `ALGORITHM` | Algorytm szyfrowania JWT (domyślnie "HS256") |
| `HF_TOKEN` | Token Hugging Face do autoryzacji w API AI |

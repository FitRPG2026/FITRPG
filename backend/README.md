# Dokumentacja Backend - FITRPG API

Dokumentacja techniczna struktury plików i odpowiedzialności poszczególnych modułów aplikacji opartej na FastAPI.

## Struktura i Opis Plików

### Główne pliki aplikacji
*   **`app/main.py`** – Główny punkt wejścia aplikacji FastAPI[cite: 1]. Definiuje konfigurację globalną, w tym:
    *   Obsługę **CORS** (umożliwiającą komunikację z frontendem pod adresem `localhost:4200`)[cite: 1].
    *   Globalne handlery wyjątków dla `HTTPException` oraz błędów walidacji `RequestValidationError`[cite: 1].
    *   Podpięcie routerów pod prefiks `/api` oraz inicjalizację dokumentacji **Swagger/OpenAPI**[cite: 1].
*   **`app/api/routes.py`** – Kontrolery API (Endpointy)[cite: 2]. Zawiera definicje ścieżek URL dla takich operacji jak:
    *   Rejestracja (`/register`) i Logowanie (`/login`)[cite: 2].
    *   Sprawdzanie stanu zdrowia aplikacji (`/health`) i profilu użytkownika (`/me`)[cite: 2].
    *   Wykorzystuje mechanizm **Dependency Injection** (`Depends`) do wstrzykiwania sesji bazy danych i logiki bezpieczeństwa[cite: 2].
*   **`app/schemas.py`** – Modele DTO (Data Transfer Objects) oparte na bibliotece **Pydantic**[cite: 3].
    *   Odpowiadają za ścisłą walidację danych wejściowych (request body)[cite: 3].
    *   Definiują format danych wyjściowych (response)[cite: 3].
    *   Zawierają niestandardową logikę walidacji, np. weryfikację minimalnej długości hasła[cite: 3].

### Rdzeń aplikacji (Core)
*   **`app/core/config.py`** – Zarządzanie konfiguracją przy użyciu `pydantic_settings`[cite: 4]. Automatycznie ładuje zmienne środowiskowe z pliku `.env` (np. `DATABASE_URL`, `SECRET_KEY`) i rzuca błąd, jeśli brakuje wymaganych danych[cite: 4].
*   **`app/core/db.py`** – Konfiguracja asynchronicznego połączenia z bazą **PostgreSQL** przy użyciu `asyncpg` i **SQLAlchemy**[cite: 5]. Zarządza pulą połączeń i udostępnia generator sesji `get_db` dla żądań API[cite: 5].
*   **`app/core/queries.py`** – Warstwa dostępu do danych (DAL)[cite: 6]. Hermetyzuje surowe zapytania SQL oraz wywołania procedur składowanych (np. `proc_register_user`, `proc_mark_login`), oddzielając logikę bazodanową od kontrolerów[cite: 6].
*   **`app/core/security.py`** – Moduł bezpieczeństwa[cite: 7]. Odpowiada za:
    *   Hashowanie i weryfikację haseł (algorytm bcrypt)[cite: 7].
    *   Generowanie i dekodowanie tokenów **JWT**[cite: 7].
    *   Definiowanie zależności (np. `get_current_user`), które chronią zasoby przed nieautoryzowanym dostępem[cite: 7].

### Konteneryzacja i Zależności
*   **`Dockerfile`** – Plik konfiguracyjny do budowy obrazu kontenera opartego na Python 3.11-slim[cite: 8]. Definiuje środowisko pracy, instaluje zależności i uruchamia serwer `uvicorn`[cite: 8].
*   **`requirements.txt`** – Lista wszystkich bibliotek niezbędnych do działania projektu (m.in. FastAPI, SQLAlchemy, asyncpg, python-jose)[cite: 9].

## Technologie
*   **Framework:** FastAPI
*   **Baza danych:** PostgreSQL (Async)
*   **ORM:** SQLAlchemy 2.0
*   **Bezpieczeństwo:** JWT, Bcrypt
*   **Konteneryzacja:** Docker
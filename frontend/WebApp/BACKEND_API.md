# Backend API — FitRPG

Plik opisuje czego Angular oczekuje od backendu (FastAPI).

---

## Konfiguracja CORS

Backend musi zezwolić na requesty z `http://localhost:4200`.

```python
from fastapi.middleware.cors import CORSMiddleware

app.add_middleware(
    CORSMiddleware,
    allow_origins=["http://localhost:4200"],
    allow_methods=["*"],
    allow_headers=["*"],
)
```

---

## Endpointy

### 1. Logowanie

**URL:** `POST /api/login`

**Request body:**
```json
{
  "email": "user@example.com",
  "password": "haslo123"
}
```

**Response — sukces (200):**
```json
{
  "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6..."
}
```

**Response — błąd (401):**
```json
{
  "detail": "Invalid credentials"
}
```

**Co robi Angular po odpowiedzi:**
- `200` → zapisuje `access_token` w `localStorage` i przekierowuje na `/dashboard`
- `401` → wyświetla komunikat "Nieprawidłowy email lub hasło."
- inne → wyświetla "Błąd serwera. Spróbuj ponownie."

---

### 2. Rejestracja

**URL:** `POST /api/register`

**Request body:**
```json
{
  "email": "user@example.com",
  "password": "haslo123"
}
```

**Response — sukces (200 lub 201):**
```json
{
  "message": "User created successfully"
}
```

**Response — email już istnieje (409):**
```json
{
  "detail": "Email already registered"
}
```

**Co robi Angular po odpowiedzi:**
- `200` / `201` → przekierowuje na `/login`
- `409` → wyświetla komunikat "Konto z tym emailem już istnieje."
- inne → wyświetla "Błąd serwera. Spróbuj ponownie."

---

## Walidacja po stronie Angulara

Angular sprawdza te rzeczy **zanim** wyśle request do backendu:

- Hasła muszą być identyczne
- Hasło musi mieć minimum 8 znaków

Backend powinien jednak też walidować te rzeczy niezależnie.

---

## Domyślny adres backendu

Angular wysyła requesty na:
```
http://localhost:8000
```

Jeśli backend działa na innym porcie, zmień URL w:
- `src/app/login/login.ts` — linia z `http.post(...)`
- `src/app/register/register.ts` — linia z `http.post(...)`

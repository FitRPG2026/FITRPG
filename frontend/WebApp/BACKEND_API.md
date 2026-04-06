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

> ⚠️ **Stan tymczasowy:** logowanie aktualnie używa Mock Service (`of({ access_token: 'mock-token-123' }).pipe(delay(1000))`).
> Gdy backend będzie gotowy, w `src/app/login/login.ts` zastąp mock rzeczywistym `HttpClient`:
>
> ```typescript
> this.http.post('http://localhost:8000/api/login', { email, password }).subscribe({
>   next: (response: any) => {
>     localStorage.setItem('token', response.access_token);
>     this.router.navigate(['/dashboard']);
>   },
>   error: (err) => {
>     this.isLoading = false;
>     if (err.status === 401) this.errorMessage = 'Nieprawidłowy email lub hasło.';
>     else this.errorMessage = 'Błąd serwera. Spróbuj ponownie.';
>   }
> });
> ```
> Pamiętaj też przywrócić `HttpClient` do importów i konstruktora komponentu.

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

### 3. Dashboard — dane użytkownika

Poniższe endpointy są aktualnie symulowane przez `src/app/mock-service/mock-data.service.ts`.
Każda metoda serwisu ma komentarz z odpowiadającym endpointem do zaimplementowania.

Wszystkie requesty powinny zawierać nagłówek autoryzacyjny:
```
Authorization: Bearer <access_token>
```

---

**GET /api/user/profile**

```json
{
  "name": "Jan Kowalski",
  "level": 12,
  "xp": 3420,
  "xpToNext": 5000,
  "class": "Wojownik Kondycji",
  "avatar": "🧙",
  "streak": 7,
  "joinDate": "2024-01-15"
}
```

---

**GET /api/user/stats**

```json
[
  { "name": "Siła", "value": 74, "max": 100, "icon": "💪", "color": "#e74c3c" },
  { "name": "Wytrzymałość", "value": 58, "max": 100, "icon": "🏃", "color": "#2a8f5e" },
  { "name": "Zwinność", "value": 43, "max": 100, "icon": "⚡", "color": "#f39c12" },
  { "name": "Wola", "value": 81, "max": 100, "icon": "🧠", "color": "#9b59b6" }
]
```

---

**GET /api/quests**

```json
[
  {
    "id": 1,
    "title": "10 000 kroków",
    "description": "Przejdź 10 000 kroków w ciągu dnia",
    "xp": 150,
    "completed": false,
    "category": "Cardio",
    "dueDate": "Dziś"
  }
]
```

---

**POST /api/quests/{id}/complete**

Response:
```json
{
  "success": true,
  "message": "Quest ukończony! XP dodane.",
  "updatedXp": 3570
}
```

---

**GET /api/achievements**

```json
[
  {
    "id": 1,
    "title": "Pierwszy krok",
    "description": "Ukończ swój pierwszy quest",
    "icon": "🥇",
    "unlockedAt": "2024-01-16",
    "locked": false
  }
]
```

---

**GET /api/activity/weekly**

```json
[
  { "day": "Pon", "workouts": 2, "xp": 380 },
  { "day": "Wt",  "workouts": 1, "xp": 150 }
]
```

---

**PATCH /api/user/profile**

Request body (tylko zmienione pola):
```json
{
  "name": "Jan Kowalski"
}
```

Response:
```json
{
  "success": true,
  "message": "Profil zaktualizowany pomyślnie!"
}
```

---

## Walidacja po stronie Angulara

Angular sprawdza te rzeczy **zanim** wyśle request do backendu:

- Hasła muszą być identyczne
- Hasło musi mieć minimum 8 znaków

Backend powinien jednak też walidować te rzeczy niezależnie.

---

## Jak podpiąć backend pod Mock Service

Gdy backend będzie gotowy, otwórz `src/app/mock-service/mock-data.service.ts` i zastąp każdą metodę rzeczywistym `HttpClient`. Przykład dla `getUserProfile()`:

```typescript
// PRZED (mock)
getUserProfile() {
  return of<UserProfile>({ ... }).pipe(delay(600));
}

// PO (backend)
getUserProfile() {
  return this.http.get<UserProfile>('http://localhost:8000/api/user/profile');
}
```

Pamiętaj o wstrzyknięciu `HttpClient` w konstruktorze serwisu:
```typescript
constructor(private http: HttpClient) {}
```

---

## Domyślny adres backendu

```
http://localhost:8000
```

Jeśli backend działa na innym porcie, zmień URL w:
- `src/app/login/login.ts`
- `src/app/register/register.ts`
- `src/app/mock-service/mock-data.service.ts` (po podpięciu backendu)

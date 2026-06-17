# 🏋️‍♂️ FITRPG

> **Web app for health created by students.** > FITRPG to aplikacja webowa łącząca dbanie o zdrowy styl życia z elementami grywalizacji. Trenuj, jedz zdrowo, zdobywaj punkty i podejmuj wyzwania!


*Produkcja:* [https://fitrpg-mocha.vercel.app](https://fitrpg-mocha.vercel.app)

*Stagging:* [https://fitrpg2026.vercel.app](https://fitrpg2026.vercel.app)

Przygotowana przez:
- Maciej Dąbrowski ( PM, Tech Lead) [ Zarządzanie projektem i zespołem, Architektura i DevOps, Full-Stack Development]
- Jakub Rosa ( Backend developer) [endpointy, logika, bezpieczeństwo, łączenie chmur, rozbudowanie logowania]
- Maja Szerszeń ( Backend dev., DB enginner) [logowanie z jwt, logika, łączenie z bazą, wdrożenie bazy, wyzwania, podstawy architektury lokalnej]
- Wojciech Seńko ( DB engineer, Fulstack dev.) [ zaprojektowanie bazy, segment cloudinary, wstępne testowe dane, przygotownanie gotowego komponentu]
- Semion Lisichik ( Backend dev., Test dev.) [logika statystyk, testy jednostkowe i E2E, dokumentacja, rywalizacja]
- Antoni Szymański ( Frontend dev.) [ większość frontu od strony UI i UX, przygotowanie mniejszego komponentu, mock upy]
- Jakub Dąbrowski (Frontend dev.) [ większość frontu od strony logiki i funckjonowania, rozbudowanie logowania, ekrany]
- Joanna Dagil ( ML eng.) [ przygotowanie modeli, testy modeli, pomoc przy architekturze ML 
- Stanisław Mierzejewski ( ML eng.) [rozwinięcie datasetu, przygotowanie wyzwań, dokumentacja pdf]



## ✨ Główne funkcjonalności


* **📸 Ocena Posiłków AI:** Zrób zdjęcie swojego jedzenia, a nasz moduł Machine Learning (Computer Vision) oceni jego zdrowotność i przyzna punkty
* **🏆 Grywalizacja:** Zdobywaj punkty doświadczenia, bierz udział w wyzwaniach i pnij się w rankingu (Leaderboards)     [ niedługo]
* **👤 Profile Użytkowników:** Śledzenie własnego progresu i statystyk zdrowotnych
* **📅 Wyzwania:** Walcz i zdobywaj punkty

---

## 🛠️ Stack Technologiczny

Projekt oparty jest na architekturze mikroserwisów w środowisku Monorepo.

* **Frontend:** Angular (PWA), CSS, TS, html
* **Backend API:** Python 
* **Machine Learning:** Python (FastAPI + CNN) - Hugging Face
* **Baza Danych:** PostgreSQL- Neon Tech
* **Infrastruktura & DevOps:** Docker, GitHub Actions, Render, Vercel
* **Zdjęcia:** Cloudinary

---

## 📂 Struktura Repozytorium (Monorepo)

```text
FITRPG/
├── frontend/      # Aplikacja kliencka (Angular)
├── backend/       # Główne API REST i logika biznesowa
├── db/            # alembic i dokumentacja
├── ML/            # Mikroserwis sztucznej inteligencji do oceny zdjęć posiłków
├── docker-compose.yml # Konfiguracja środowiska lokalnego
└── README.md
```



## 🛠️ Wymagania ( wersji lokalnej): 
Zainstalowany Docker oraz Docker Compose.



## 🚀 Uruchomienie ( wersji lokalnej):
* git clone [https://github.com/MD04-CFC/FITRPG.git](https://github.com/MD04-CFC/FITRPG.git)
* cd FITRPG
* docker-compose up --build
* http://localhost:4200

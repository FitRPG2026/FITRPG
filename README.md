# 🏋️‍♂️ FITRPG

> **Web app for health created by students.** > FITRPG to aplikacja webowa łącząca dbanie o zdrowy styl życia z elementami grywalizacji. Trenuj, jedz zdrowo, zdobywaj punkty i podejmuj wyzwania!


*Produkcja:* [https://fitrpg-mocha.vercel.app](https://fitrpg-mocha.vercel.app)

*Stagging:* [https://fitrpg2026.vercel.app](https://fitrpg2026.vercel.app)

Przygotowana przez:
- Maciej Dąbrowski
- Jakub Dąbrowski
- Jakub Rosa
- Maja Szerszeń
- Joanna Dagil
- Stanisław Mierzejewski
- Semion Lisichik
- Antoni Szymański
- Wojciech Seńko

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

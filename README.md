# 🏋️‍♂️ FITRPG

> **Web app for health created by students.** > FITRPG to aplikacja webowa łącząca dbanie o zdrowy styl życia z elementami grywalizacji. Trenuj, jedz zdrowo, zdobywaj punkty i podejmuj wyzwania!

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

* **📅 Harmonogramy Treningów:** Rozpisywanie planów treningowych i przypomnienia o aktywności (Push/SMS Notifications)
* **📸 Ocena Posiłków AI:** Zrób zdjęcie swojego jedzenia, a nasz moduł Machine Learning (Computer Vision) oceni jego zdrowotność i przyzna punkty
* **🏆 Grywalizacja:** Zdobywaj punkty doświadczenia, bierz udział w wyzwaniach i pnij się w rankingu (Leaderboards)
* **👤 Profile Użytkowników:** Śledzenie własnego progresu i statystyk zdrowotnych

---

## 🛠️ Wymagania: 
Zainstalowany Docker oraz Docker Compose.



## 🚀 Uruchomienie:
* git clone [https://github.com/MD04-CFC/FITRPG.git](https://github.com/MD04-CFC/FITRPG.git)
* cd FITRPG
* docker-compose up --build
* http://localhost:4200



## 🛠️ Stack Technologiczny

Projekt oparty jest na architekturze mikroserwisów w środowisku Monorepo.

* **Frontend:** Angular (PWA), CSS, TS, html
* **Backend API:** Python 
* **Machine Learning:** Python (FastAPI + CNN)
* **Baza Danych:** PostgreSQL
* **Infrastruktura & DevOps:** Docker, GitHub Actions, Railway/GCP (Deployment, ?)

---

## 📂 Struktura Repozytorium (Monorepo)

```text
FITRPG/
├── frontend/      # Aplikacja kliencka (Angular)
├── backend/       # Główne API REST i logika biznesowa
├── db/            # Schemat bazy danych i migracje
├── ML/            # Mikroserwis sztucznej inteligencji do oceny zdjęć posiłków
├── docker-compose.yml # Konfiguracja środowiska lokalnego
└── README.md
```

import json
import asyncio
from gradio_client import Client
from sqlalchemy.orm import Session
from sqlalchemy import text
from .exp import calculate_meal_exp
from ..core.db import get_db
from ..core.exp import calculate_meal_exp

# Inicjujemy klienta raz, przy starcie aplikacji (szybciej działa)
hf_client = Client("stachtotalny/fitrpg", hf_token="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")

async def process_meal_with_ai(meal_id: int, photo_url: str, user_id: int):
    print(f"Rozpoczęto analizę AI dla posiłku {meal_id}")
    
    # 1. Pobieramy nową sesję bazy danych dla zadania w tle
    async for db in get_db():
        try:
            # 2. Odpytujemy Hugging Face w osobnym wątku, żeby nie zablokować FastAPI!
            result = await asyncio.to_thread(
                hf_client.predict,
                image_url=photo_url,
                api_name="/predict_health"
            )
            
            health_score = int(result) 
            exp_amount = calculate_meal_exp(health_score)
            
            # 3. Zapisujemy SUKCES w bazie danych
            await db.execute(
                text("UPDATE meals SET health_score = :score, status = 'completed' WHERE id = :meal_id"),
                {"score": health_score, "meal_id": meal_id}
            )
            
            # Aktualizacja EXP (zakładam, że exp trzymasz w user_progress jak w queries.py)
            await db.execute(
                text("UPDATE user_progress SET total_exp = total_exp + :exp WHERE user_id = :uid"),
                {"exp": exp_amount, "uid": user_id}
            )
            
            await db.commit()
            print(f"Sukces! Posiłek {meal_id} oceniony na {health_score}.")
            
        except Exception as e:
            print(f"Błąd analizy AI dla {meal_id}: {e}")
            await db.rollback()
            
            # 4. Zapisujemy BŁĄD w bazie danych (żeby frontend mógł przerwać Polling)
            await db.execute(
                text("UPDATE meals SET status = 'failed' WHERE id = :meal_id"),
                {"meal_id": meal_id}
            )
            await db.commit()
            
        finally:
            break

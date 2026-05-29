import json
import asyncio
import os
from gradio_client import Client
from sqlalchemy.orm import Session
from sqlalchemy import text
from .exp import calculate_meal_exp
from ..core.db import get_db

hf_token = os.getenv("HF_TOKEN")

if hf_token:
    hf_client = Client("stachtotalny/fitrpg", hf_token=hf_token)
else:
    hf_client = Client("stachtotalny/fitrpg")

async def process_meal_with_ai(meal_id: int, photo_url: str, user_id: int):
    print(f"Rozpoczęto analizę AI dla posiłku {meal_id}")
    
    # 1. Pobieramy nową sesję bazy danych dla zadania w tle
    async for db in get_db():
        try:
            print(f"[DEBUG HF CALL] Wysyłam sam URL do HF: {photo_url}")

            result = await asyncio.to_thread(
                hf_client.predict,
                photo_url,
                fn_index=0
            )

            # result to lista: [top_class_name, weighted_avg, top, health_scores_probs]
            health_score = int(result[2]) 
            exp_amount = calculate_meal_exp(health_score)

            # result to lista: [top_class_name, weighted_avg, top, health_scores_probs]
            # Interesuje nas indeks 2 (czyli wartość 'top', np. 3, 4, 5)
            health_score = int(result[2]) 
            exp_amount = calculate_meal_exp(health_score)
            # POPRAWKA 3: result to lista/krotka zwracana z HF: 
            # [top_class_name, weighted_avg, top, health_scores_probs]
            # Wyciągamy 'top', czyli element o indeksie 2
            health_score = int(result[2]) 
            exp_amount = calculate_meal_exp(health_score)
            
            # 3. Zapisujemy SUKCES w bazie danych
            await db.execute(
                text("UPDATE meals SET health_score = :score, status = 'completed' WHERE id = :meal_id"),
                {"score": health_score, "meal_id": meal_id}
            )
            
            # Aktualizacja EXP
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

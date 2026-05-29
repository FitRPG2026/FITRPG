import json
import asyncio
import os
import traceback
from gradio_client import Client
from sqlalchemy.orm import Session
from sqlalchemy import text
from .exp import calculate_meal_exp
from ..core.db import get_db

# Wymuszamy pobranie tokenu z systemu
# Wymuszamy pobranie tokenu z systemu
hf_token = os.getenv("HF_TOKEN")

# W nowej wersji gradio_client używamy argumentu 'token' zamiast 'hf_token'
if hf_token:
    print("[DEBUG] Wykryto HF_TOKEN, inicjalizuję bezpieczne połączenie.")
    hf_client = Client("stachtotalny/fitrpg", token=hf_token)  # <-- TUTAJ ZMIANA
else:
    print("[WARNING] BRAK HF_TOKEN! Połączenie z prywatnym Space może się nie udać.")
    hf_client = Client("stachtotalny/fitrpg")

async def process_meal_with_ai(meal_id: int, photo_url: str, user_id: int):
    print(f"Rozpoczęto analizę AI dla posiłku {meal_id}")
    
    async for db in get_db():
        try:
            print(f"[DEBUG HF CALL] Wysyłam sam URL do HF: {photo_url}")

            # Wywołanie z poprawną nazwą endpointu
            result = await asyncio.to_thread(
                hf_client.predict,
                photo_url,
                api_name="/predict_health"
            )

            # Wyciągamy ocenę (indeks 2 z listy)
            health_score = int(result[2]) 
            exp_amount = calculate_meal_exp(health_score)
            
            await db.execute(
                text("UPDATE meals SET health_score = :score, status = 'completed' WHERE id = :meal_id"),
                {"score": health_score, "meal_id": meal_id}
            )
            
            await db.execute(
                text("UPDATE user_progress SET total_exp = total_exp + :exp WHERE user_id = :uid"),
                {"exp": exp_amount, "uid": user_id}
            )
            
            await db.commit()
            print(f"Sukces! Posiłek {meal_id} oceniony na {health_score}.")
            
        except Exception as e:
            print(f"Błąd analizy AI dla {meal_id}: {e}")
            traceback.print_exc()
            await db.rollback()
            
            await db.execute(
                text("UPDATE meals SET status = 'failed' WHERE id = :meal_id"),
                {"meal_id": meal_id}
            )
            await db.commit()
            
        finally:
            break

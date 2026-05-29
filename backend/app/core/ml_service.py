import json
import asyncio
import os
import traceback  # <-- Dodajemy ten moduł do dokładnego debugowania
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
    
    async for db in get_db():
        try:
            print(f"[DEBUG HF CALL] Wysyłam sam URL do HF: {photo_url}")

            result = await asyncio.to_thread(
                hf_client.predict,
                photo_url,
                fn_index=0
            )

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
            # ---> TO WYDRUKUJE CAŁY BŁĄD W LOGACH RENDERA <---
            traceback.print_exc() 
            
            await db.rollback()
            
            await db.execute(
                text("UPDATE meals SET status = 'failed' WHERE id = :meal_id"),
                {"meal_id": meal_id}
            )
            await db.commit()
            
        finally:
            break

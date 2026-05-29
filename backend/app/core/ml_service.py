import json
import asyncio
import os
from gradio_client import Client
from sqlalchemy import text
from .exp import calculate_meal_exp
from ..core.db import get_db

hf_token = os.getenv("HF_TOKEN")

if hf_token:
    hf_client = Client("stachtotalny/fitrpg", token=hf_token)
else:
    hf_client = Client("stachtotalny/fitrpg")

async def process_meal_with_ai(meal_id: int, photo_url: str, user_id: int):
    async for db in get_db():
        try:
            # Wysyłamy zapytanie do Hugging Face
            result = await asyncio.to_thread(
                hf_client.predict,
                photo_url,
                api_name="/predict_health"
            )

            # Wyciągamy ocenę i przeliczamy EXP
            health_score = int(result[2]) 
            exp_amount = calculate_meal_exp(health_score)
            
            # Aktualizacja bazy danych po sukcesie
            await db.execute(
                text("UPDATE meals SET health_score = :score, status = 'completed' WHERE id = :meal_id"),
                {"score": health_score, "meal_id": meal_id}
            )
            
            await db.execute(
                text("UPDATE user_progress SET total_exp = total_exp + :exp WHERE user_id = :uid"),
                {"exp": exp_amount, "uid": user_id}
            )
            
            await db.commit()
            
        except Exception:
            # W razie błędu wycofujemy zmiany i ustawiamy status 'failed'
            await db.rollback()
            await db.execute(
                text("UPDATE meals SET status = 'failed' WHERE id = :meal_id"),
                {"meal_id": meal_id}
            )
            await db.commit()
            
        finally:
            break

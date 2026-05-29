import json
import asyncio
import os
import traceback
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
    
    # WYDRUK MAPY API: To pokaże nam w logach Rendera dokładną nazwę endpointu
    try:
        print("=== DOSTĘPNE ENDPOINTY GRADIO ===")
        hf_client.view_api()
        print("=================================")
    except Exception as api_err:
        print(f"Nie udało się pobrać mapy API: {api_err}")

    async for db in get_db():
        try:
            print(f"[DEBUG HF CALL] Wysyłam sam URL do HF: {photo_url}")

            # Przekazujemy adres URL pozycyjnie, a api_name bez ukośnika
            result = await asyncio.to_thread(
                hf_client.predict,
                photo_url,
                api_name="predict_health"
            )

            # Wyciągamy ocenę (indeks 2 z listy zwracanej przez Hugging Face)
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

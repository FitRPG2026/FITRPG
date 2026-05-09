from fastapi import FastAPI, BackgroundTasks
from pydantic import BaseModel

app = FastAPI()


class PredictRequest(BaseModel):
    image_url: str
    meal_id: int


def run_prediction(image_url: str, meal_id: int):
    pass  # DEV-53 


@app.post("/predict", status_code=202)
async def predict(body: PredictRequest, background_tasks: BackgroundTasks):
    background_tasks.add_task(run_prediction, body.image_url, body.meal_id)
    return {"status": "processing", "meal_id": body.meal_id}
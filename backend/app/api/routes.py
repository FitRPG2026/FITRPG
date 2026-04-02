from fastapi import APIRouter, HTTPException

#   Tutaj przechowywane beda endpointy
router = APIRouter()

@router.get("/test")    # z prefixem /api
def connection_check():
    return {'status':'ok', 'message':'Backend dziala poprawnie'}

@router.get("/workout/{workout_id}")
def get_workout(workout_id: int):
    #workout = find_workout(workout_id)
    workout = None
    if workout is None:
        raise HTTPException(status_code=404, detail="Trening nie znaleziony")
    return workout
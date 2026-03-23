from fastapi import APIRouter

#   Tutaj przechowywane beda endpointy
router = APIRouter()

@router.get("/test")    # z prefixem /api
def connection_check():
    return {'status':'ok', 'message':'Backend dziala poprawnie'}
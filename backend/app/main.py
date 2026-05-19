from fastapi import FastAPI, Request
from fastapi.responses import JSONResponse
from fastapi.middleware.cors import CORSMiddleware
from fastapi.exceptions import HTTPException, RequestValidationError
from app.api.routes import router

app = FastAPI(
    title='FITRPG Backend Api',
    description='API aplikacji FITRPG'
)

origins = [
    "http://localhost:4200",
    "https://fitrpg-mocha.vercel.app",  #prod
    "https://fitrpg2026.vercel.app",    
]

# app.add_middleware(
#     CORSMiddleware,
#     allow_origins=origins,
#     allow_credentials=True,
#     allow_methods=["GET", "POST", "PUT", "DELETE"],
#     allow_headers=["*"],
# )

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_origin_regex=r"https://fitrpg-.*\.vercel\.app", 
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

@app.exception_handler(HTTPException)
async def not_found_handler(request: Request, exc: HTTPException):
    return JSONResponse(status_code=exc.status_code, content={"error": exc.detail})

@app.exception_handler(RequestValidationError)
async def validation_error_handler(reques: Request, exc: RequestValidationError):
    return JSONResponse(status_code=422, content={"error": "Nieprawidlowe dane wejsciowe"})


app.include_router(router, prefix='/api')

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from ..app.api.routes import router

app = FastAPI(
    title='FITRPG Backend Api',
    description='API aplikacji FITRPG'
)

origins = [
    "http://localhost:4200",
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

app.include_router(router, prefix='api')
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from ..app.api.routes import router

app = FastAPI(
    title='FITRPG Backend Api',
    description='API aplikacji FITRPG'
)

app.add_middleware(
    CORSMiddleware
)

app.include_router(router, prefix='api')
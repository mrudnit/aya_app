from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.firebase import init_firebase
from app.api.v1 import debug, overview

# Initialise Firebase once
init_firebase()

app = FastAPI(
    title="Aya Analytics API",
    version="1.0.0",
)

# Allow Flutter app to call this API
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

#  Routers
app.include_router(
    debug.router,
    prefix="/api/v1/analytics",
    tags=["Debug"],
)

app.include_router(
    overview.router,
    prefix="/api/v1/analytics",
    tags=["Analytics"],
)

@app.get("/")
def root():
    return {"status": "ok", "service": "Aya Analytics API v1.0"}

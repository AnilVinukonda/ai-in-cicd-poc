from fastapi import FastAPI
import os

app = FastAPI()

@app.get("/")
def root():
    return {"message": "Hello from AI-in-CI/CD demo!"}

@app.get("/healthz")
def healthz():
    return {"ok": True}

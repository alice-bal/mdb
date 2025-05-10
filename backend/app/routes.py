from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db

router = APIRouter()

@router.get("/ping")
def ping():
    return {"message": "pong"}

@router.get("/db-test")
def db_test(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))  # простая проверка соединения
    return {"message": "База данных работает"}
from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import get_db

from app.models.model import Model
from app.schemas.model import ModelOut
from sqlalchemy.orm import Session
from fastapi import Depends

router = APIRouter()
# проверка ping pong
@router.get("/ping")
def ping():
    return {"message": "pong"}

# проверка соединения с бд
@router.get("/db-test")
def db_test(db: Session = Depends(get_db)):
    db.execute(text("SELECT 1"))  # простая проверка соединения
    return {"message": "База данных работает"}

# возврат список моделей цифровой зрелости
@router.get("/models", response_model=list[ModelOut])
def get_models(db: Session = Depends(get_db)):
    return db.query(Model).all()


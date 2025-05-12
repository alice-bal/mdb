from sqlalchemy import Column, Integer, String
from app.database import Base

class Model(Base):
    __tablename__ = "models"

    model_id = Column(Integer, primary_key=True, index=True)  # <- вот так
    model_name = Column(String, nullable=False)
    description = Column(String)
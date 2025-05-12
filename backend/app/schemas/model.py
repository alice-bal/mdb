from pydantic import BaseModel

class ModelOut(BaseModel):
    model_id: int
    model_name: str
    description: str | None = None

    class Config:
        from_attributes = True  # если FastAPI 0.100+ / Pydantic V2
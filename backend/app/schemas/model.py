from pydantic import BaseModel

class ModelOut(BaseModel):
    id: int
    name: str
    description: str | None = None

    class Config:
        orm_mode = True
from typing import List, Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr


class CalculationBase(BaseModel):
    operation: str
    operand_a: float
    operand_b: float
    result: float
    user_id: int


class CalculationCreate(CalculationBase):
    pass


class CalculationUpdate(BaseModel):
    result: float


class Calculation(CalculationBase):
    id: int
    timestamp: Optional[datetime]

    class Config:
        orm_mode = True


class UserBase(BaseModel):
    username: str
    email: EmailStr


class UserCreate(UserBase):
    pass


class UserUpdate(BaseModel):
    username: Optional[str] = None
    email: Optional[EmailStr] = None


class User(UserBase):
    id: int
    created_at: Optional[datetime]
    calculations: List[Calculation] = []

    class Config:
        orm_mode = True

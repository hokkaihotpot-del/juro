from __future__ import annotations

from pydantic import BaseModel


class AllergyItemCreate(BaseModel):
    ingredient_name: str
    is_preset: bool = True


class AllergyItemRead(BaseModel):
    id: str
    ingredient_name: str
    is_preset: bool

    model_config = {"from_attributes": True}


class AllergyListResponse(BaseModel):
    items: list[AllergyItemRead]
    total: int


class DoctorInfoCreate(BaseModel):
    doctor_name: str
    email: str | None = None
    system_id: str | None = None


class DoctorInfoRead(BaseModel):
    id: str
    doctor_name: str
    email: str | None
    system_id: str | None

    model_config = {"from_attributes": True}

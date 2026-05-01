from __future__ import annotations

from pydantic import BaseModel, EmailStr, Field


class UserCreate(BaseModel):
    email: EmailStr
    password: str = Field(min_length=8)
    region: str = Field(default="jp", pattern="^(jp|us|uk)$")


class UserRead(BaseModel):
    id: str
    email: str
    region: str
    preprocessing_correction_enabled: bool

    model_config = {"from_attributes": True}


class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"


class LoginRequest(BaseModel):
    email: EmailStr
    password: str


class NutritionLimitUpdate(BaseModel):
    phosphorus_limit_mg: int = Field(gt=0, default=800)
    potassium_limit_mg: int = Field(gt=0, default=2000)
    sodium_limit_g: float = Field(gt=0, default=6.0)


class NutritionLimitRead(BaseModel):
    phosphorus_limit_mg: int
    potassium_limit_mg: int
    sodium_limit_g: float

    model_config = {"from_attributes": True}


class SettingsUpdate(BaseModel):
    preprocessing_correction_enabled: bool | None = None
    region: str | None = Field(default=None, pattern="^(jp|us|uk)$")


class SettingsRead(BaseModel):
    region: str
    preprocessing_correction_enabled: bool
    nutrition_limits: NutritionLimitRead | None = None

    model_config = {"from_attributes": True}

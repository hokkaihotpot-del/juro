from __future__ import annotations

from datetime import date

from pydantic import BaseModel


class WeeklyReportRow(BaseModel):
    log_date: date
    weekday: str
    phosphorus_mg: float
    potassium_mg: float
    sodium_g: float
    menu_summary: str


class WeeklyReport(BaseModel):
    start_date: date
    end_date: date
    rows: list[WeeklyReportRow]
    weekly_avg_phosphorus: float
    weekly_avg_potassium: float
    weekly_avg_sodium: float
    weekly_total_phosphorus: float
    weekly_total_potassium: float
    weekly_total_sodium: float
    daily_phosphorus_limit: int
    daily_potassium_limit: int
    daily_sodium_limit: float
    phosphorus_achievement_rate: float
    potassium_achievement_rate: float
    sodium_achievement_rate: float


class ReportSendRequest(BaseModel):
    doctor_id: str
    week_start: date
    user_consented: bool


class ReportSendResponse(BaseModel):
    success: bool
    consent_log_id: str
    message: str

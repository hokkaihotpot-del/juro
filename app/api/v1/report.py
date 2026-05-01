from __future__ import annotations

from datetime import date, timedelta

from fastapi import APIRouter, Depends, HTTPException, Response
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.database import get_db
from app.deps import get_current_user
from app.models.consent_log import ConsentLog
from app.models.doctor import DoctorInfo
from app.models.nutrition_log import NutritionLog
from app.models.user import User
from app.repositories.user import UserRepository
from app.schemas.report import ReportSendRequest, ReportSendResponse, WeeklyReport
from app.services.report_gen import build_weekly_report_data, generate_pdf
from app.models.base import new_uuid

router = APIRouter(prefix="/report", tags=["report"])


@router.get("/weekly", response_model=WeeklyReport)
async def get_weekly_report(
    week_start: date | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if week_start is None:
        today = date.today()
        week_start = today - timedelta(days=today.weekday() + 7)

    repo = UserRepository(db)
    limits = await repo.get_nutrition_limit(current_user.id)

    week_end = week_start + timedelta(days=6)
    result = await db.execute(
        select(NutritionLog).where(
            NutritionLog.user_id == current_user.id,
            NutritionLog.log_date >= week_start,
            NutritionLog.log_date <= week_end,
        )
    )
    logs_raw = result.scalars().all()

    logs = [
        {
            "log_date": log.log_date,
            "phosphorus_mg": log.phosphorus_mg,
            "potassium_corrected_mg": log.potassium_corrected_mg,
            "sodium_g": log.sodium_g,
            "menu_summary": None,
        }
        for log in logs_raw
    ]

    return build_weekly_report_data(
        logs=logs,
        nutrition_limits={
            "phosphorus_limit_mg": limits.phosphorus_limit_mg,
            "potassium_limit_mg": limits.potassium_limit_mg,
            "sodium_limit_g": limits.sodium_limit_g,
        },
        start_date=week_start,
    )


@router.get("/weekly/pdf")
async def download_weekly_report_pdf(
    week_start: date | None = None,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    report = await get_weekly_report(week_start=week_start, db=db, current_user=current_user)
    pdf_bytes = generate_pdf(report, current_user.email)
    return StreamingResponse(
        iter([pdf_bytes]),
        media_type="application/pdf",
        headers={"Content-Disposition": "attachment; filename=juro_weekly_report.pdf"},
    )


@router.post("/send", response_model=ReportSendResponse)
async def send_report_to_doctor(
    body: ReportSendRequest,
    db: AsyncSession = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    if not body.user_consented:
        raise HTTPException(status_code=400, detail="User consent is required")

    doc_result = await db.execute(
        select(DoctorInfo).where(
            DoctorInfo.id == body.doctor_id,
            DoctorInfo.user_id == current_user.id,
        )
    )
    doctor = doc_result.scalar_one_or_none()
    if doctor is None:
        raise HTTPException(status_code=404, detail="Doctor not found")

    # 同意ログ記録
    consent_id = new_uuid()
    consent = ConsentLog(
        id=consent_id,
        user_id=current_user.id,
        consent_type="doctor_report_send",
        target_period=f"{body.week_start}",
        doctor_id=body.doctor_id,
        send_status="sending",
    )
    db.add(consent)
    await db.flush()

    # 送信処理（メールまたは医療システムAPI）
    try:
        report = await get_weekly_report(week_start=body.week_start, db=db, current_user=current_user)
        pdf_bytes = generate_pdf(report, current_user.email)
        await _send_email(doctor.email, pdf_bytes, current_user.email, body.week_start)
        consent.send_status = "sent"
    except Exception as e:
        consent.send_status = "failed"
        raise HTTPException(status_code=502, detail=f"Email delivery failed: {str(e)}")

    return ReportSendResponse(
        success=True,
        consent_log_id=consent_id,
        message="担当医へのレポート送信が完了しました",
    )


async def _send_email(doctor_email: str | None, pdf_bytes: bytes, patient_email: str, week_start: date):
    if not doctor_email:
        return
    try:
        import aiosmtplib
        from email.mime.multipart import MIMEMultipart
        from email.mime.base import MIMEBase
        from email.mime.text import MIMEText
        from email import encoders
        from app.config import settings

        msg = MIMEMultipart()
        msg["From"] = settings.smtp_user
        msg["To"] = doctor_email
        msg["Subject"] = f"JURO 週次栄養レポート（{week_start}〜）- {patient_email}"

        body = MIMEText(f"患者 {patient_email} の週次栄養摂取レポートを添付しています。", "plain", "utf-8")
        msg.attach(body)

        attachment = MIMEBase("application", "pdf")
        attachment.set_payload(pdf_bytes)
        encoders.encode_base64(attachment)
        attachment.add_header("Content-Disposition", "attachment", filename="juro_report.pdf")
        msg.attach(attachment)

        await aiosmtplib.send(
            msg,
            hostname=settings.smtp_host,
            port=settings.smtp_port,
            start_tls=settings.smtp_tls,
            username=settings.smtp_user,
            password=settings.smtp_password,
        )
    except ImportError:
        pass

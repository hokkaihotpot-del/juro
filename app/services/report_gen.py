from __future__ import annotations

import io
from datetime import date, timedelta

from reportlab.lib import colors
from reportlab.lib.pagesizes import A4
from reportlab.lib.styles import getSampleStyleSheet, ParagraphStyle
from reportlab.lib.units import mm
from reportlab.platypus import (
    SimpleDocTemplate,
    Table,
    TableStyle,
    Paragraph,
    Spacer,
)

from app.schemas.report import WeeklyReport, WeeklyReportRow

WEEKDAY_JP = ["月", "火", "水", "木", "金", "土", "日"]


def _weekday_jp(d: date) -> str:
    return WEEKDAY_JP[d.weekday()] + "曜日"


def build_weekly_report_data(
    logs: list[dict],
    nutrition_limits: dict,
    start_date: date,
) -> WeeklyReport:
    """DB から取得した日別ログから週次レポートデータを構築する。"""
    end_date = start_date + timedelta(days=6)
    log_by_date: dict[date, dict] = {}
    for row in logs:
        d = row["log_date"]
        if d not in log_by_date:
            log_by_date[d] = {"p": 0.0, "k": 0.0, "na": 0.0, "menus": []}
        log_by_date[d]["p"] += row.get("phosphorus_mg", 0.0)
        log_by_date[d]["k"] += row.get("potassium_corrected_mg", 0.0)
        log_by_date[d]["na"] += row.get("sodium_g", 0.0)
        if row.get("menu_summary"):
            log_by_date[d]["menus"].append(row["menu_summary"])

    rows = []
    for i in range(7):
        d = start_date + timedelta(days=i)
        daily = log_by_date.get(d, {"p": 0.0, "k": 0.0, "na": 0.0, "menus": []})
        rows.append(
            WeeklyReportRow(
                log_date=d,
                weekday=_weekday_jp(d),
                phosphorus_mg=round(daily["p"], 1),
                potassium_mg=round(daily["k"], 1),
                sodium_g=round(daily["na"], 2),
                menu_summary="、".join(daily["menus"]) or "記録なし",
            )
        )

    total_p = sum(r.phosphorus_mg for r in rows)
    total_k = sum(r.potassium_mg for r in rows)
    total_na = sum(r.sodium_g for r in rows)
    avg_p = total_p / 7
    avg_k = total_k / 7
    avg_na = total_na / 7

    p_limit = nutrition_limits["phosphorus_limit_mg"]
    k_limit = nutrition_limits["potassium_limit_mg"]
    na_limit = nutrition_limits["sodium_limit_g"]

    return WeeklyReport(
        start_date=start_date,
        end_date=end_date,
        rows=rows,
        weekly_avg_phosphorus=round(avg_p, 1),
        weekly_avg_potassium=round(avg_k, 1),
        weekly_avg_sodium=round(avg_na, 2),
        weekly_total_phosphorus=round(total_p, 1),
        weekly_total_potassium=round(total_k, 1),
        weekly_total_sodium=round(total_na, 2),
        daily_phosphorus_limit=p_limit,
        daily_potassium_limit=k_limit,
        daily_sodium_limit=na_limit,
        phosphorus_achievement_rate=round(avg_p / p_limit * 100, 1),
        potassium_achievement_rate=round(avg_k / k_limit * 100, 1),
        sodium_achievement_rate=round(avg_na / na_limit * 100, 1),
    )


def generate_pdf(report: WeeklyReport, user_email: str) -> bytes:
    """週次レポートPDFをバイト列で返す"""
    buf = io.BytesIO()
    doc = SimpleDocTemplate(buf, pagesize=A4, rightMargin=15 * mm, leftMargin=15 * mm,
                            topMargin=20 * mm, bottomMargin=20 * mm)
    styles = getSampleStyleSheet()
    title_style = ParagraphStyle("title", parent=styles["Title"], fontSize=16, leading=20)
    normal_style = styles["Normal"]

    story = []
    story.append(Paragraph("JURO 週次栄養摂取レポート", title_style))
    story.append(Spacer(1, 6 * mm))
    story.append(Paragraph(
        f"対象期間: {report.start_date} 〜 {report.end_date}　　患者: {user_email}",
        normal_style,
    ))
    story.append(Spacer(1, 4 * mm))

    header = ["日付", "曜日", "リン(mg)", "カリウム(mg)", "塩分(g)", "献立概要"]
    data = [header]
    for r in report.rows:
        data.append([
            str(r.log_date),
            r.weekday,
            str(r.phosphorus_mg),
            str(r.potassium_mg),
            str(r.sodium_g),
            r.menu_summary[:30],
        ])
    data.append(["週平均", "", str(report.weekly_avg_phosphorus),
                 str(report.weekly_avg_potassium), str(report.weekly_avg_sodium), "—"])
    data.append(["週合計", "", str(report.weekly_total_phosphorus),
                 str(report.weekly_total_potassium), str(report.weekly_total_sodium), "—"])
    data.append(["1日上限値", "", str(report.daily_phosphorus_limit),
                 str(report.daily_potassium_limit), str(report.daily_sodium_limit), "—"])
    data.append(["上限達成率", "", f"{report.phosphorus_achievement_rate}%",
                 f"{report.potassium_achievement_rate}%",
                 f"{report.sodium_achievement_rate}%", "—"])

    col_widths = [28 * mm, 18 * mm, 28 * mm, 32 * mm, 22 * mm, None]
    table = Table(data, colWidths=col_widths, repeatRows=1)
    table.setStyle(TableStyle([
        ("BACKGROUND", (0, 0), (-1, 0), colors.HexColor("#2D6A4F")),
        ("TEXTCOLOR", (0, 0), (-1, 0), colors.white),
        ("FONTNAME", (0, 0), (-1, -1), "Helvetica"),
        ("FONTSIZE", (0, 0), (-1, -1), 9),
        ("GRID", (0, 0), (-1, -1), 0.5, colors.grey),
        ("ROWBACKGROUNDS", (0, 1), (-1, -5), [colors.white, colors.HexColor("#F0F7F4")]),
        ("BACKGROUND", (0, -4), (-1, -1), colors.HexColor("#E8F4F0")),
        ("ALIGN", (2, 0), (-2, -1), "RIGHT"),
    ]))
    story.append(table)

    doc.build(story)
    return buf.getvalue()

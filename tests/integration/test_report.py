from __future__ import annotations

from datetime import date, timedelta

import pytest
from httpx import AsyncClient
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.base import new_uuid
from app.models.nutrition_log import NutritionLog


async def _insert_nutrition_log(
    db: AsyncSession,
    user_id: str,
    log_date: date,
    phosphorus_mg: float = 200.0,
    potassium_corrected_mg: float = 500.0,
    sodium_g: float = 1.5,
) -> NutritionLog:
    log = NutritionLog(
        id=new_uuid(),
        user_id=user_id,
        log_date=log_date,
        meal_type="breakfast",
        phosphorus_mg=phosphorus_mg,
        potassium_raw_mg=potassium_corrected_mg,
        potassium_corrected_mg=potassium_corrected_mg,
        sodium_g=sodium_g,
        correction_applied=True,
    )
    db.add(log)
    await db.flush()
    return log


async def _get_user_id(client: AsyncClient, auth_headers: dict[str, str]) -> str:
    resp = await client.get("/v1/settings", headers=auth_headers)
    # settings は user_id を返さないので signup 後の users テーブルを使う。
    # 代わりに settings レスポンスは user 情報を持たないため、
    # signup レスポンスのフィールドを取得するか、別途 token をデコードする必要がある。
    # ここでは別途 signup を発行して id を取得するヘルパーを使う。
    return resp.json()  # 使わず下の方法を採用


class TestWeeklyReport:
    async def test_weekly_report_empty(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.get("/v1/report/weekly", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert "rows" in data
        assert len(data["rows"]) == 7  # 7日分のスロット
        assert data["weekly_total_phosphorus"] == 0.0
        assert data["weekly_total_potassium"] == 0.0
        assert data["weekly_total_sodium"] == 0.0

    async def test_weekly_report_with_logs(
        self,
        client: AsyncClient,
        db_session: AsyncSession,
        auth_headers: dict[str, str],
    ):
        # テストユーザーIDを取得（signup 経由）
        signup_resp = await client.post(
            "/v1/auth/signup",
            json={
                "email": "report_user@example.com",
                "password": "TestPass1!",
                "region": "jp",
            },
        )
        user_id = signup_resp.json()["id"]
        login_resp = await client.post(
            "/v1/auth/token",
            json={"email": "report_user@example.com", "password": "TestPass1!"},
        )
        headers = {"Authorization": f"Bearer {login_resp.json()['access_token']}"}

        # 先週月曜日を計算（デフォルトの week_start と同じロジック）
        today = date.today()
        week_start = today - timedelta(days=today.weekday() + 7)

        await _insert_nutrition_log(
            db_session,
            user_id=user_id,
            log_date=week_start,
            phosphorus_mg=300.0,
            potassium_corrected_mg=700.0,
            sodium_g=2.0,
        )
        await _insert_nutrition_log(
            db_session,
            user_id=user_id,
            log_date=week_start + timedelta(days=1),
            phosphorus_mg=250.0,
            potassium_corrected_mg=600.0,
            sodium_g=1.5,
        )

        resp = await client.get("/v1/report/weekly", headers=headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["weekly_total_phosphorus"] == pytest.approx(550.0, abs=0.1)
        assert data["weekly_total_potassium"] == pytest.approx(1300.0, abs=0.1)
        assert data["weekly_total_sodium"] == pytest.approx(3.5, abs=0.01)

    async def test_weekly_report_custom_week_start(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.get(
            "/v1/report/weekly",
            params={"week_start": "2024-01-01"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["start_date"] == "2024-01-01"
        assert data["end_date"] == "2024-01-07"

    async def test_weekly_report_without_auth(self, client: AsyncClient):
        resp = await client.get("/v1/report/weekly")
        assert resp.status_code in (401, 403)


class TestWeeklyReportPdf:
    async def test_pdf_download(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.get("/v1/report/weekly/pdf", headers=auth_headers)
        assert resp.status_code == 200
        assert resp.headers["content-type"] == "application/pdf"
        assert len(resp.content) > 100  # PDF バイトが存在する

    async def test_pdf_content_disposition(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.get("/v1/report/weekly/pdf", headers=auth_headers)
        assert "attachment" in resp.headers.get("content-disposition", "")
        assert "juro_weekly_report.pdf" in resp.headers.get("content-disposition", "")


class TestReportSend:
    async def test_send_without_consent(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.post(
            "/v1/report/send",
            json={
                "doctor_id": "some-doctor-id",
                "week_start": "2024-01-01",
                "user_consented": False,
            },
            headers=auth_headers,
        )
        assert resp.status_code == 400
        assert "consent" in resp.json()["detail"].lower()

    async def test_send_doctor_not_found(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.post(
            "/v1/report/send",
            json={
                "doctor_id": "nonexistent-doctor-id",
                "week_start": "2024-01-01",
                "user_consented": True,
            },
            headers=auth_headers,
        )
        assert resp.status_code == 404
        assert "Doctor not found" in resp.json()["detail"]

    async def test_send_other_user_doctor(self, client: AsyncClient):
        """他ユーザーの医師 ID を指定しても 404 になること（認可テスト）。"""
        # ユーザー A
        await client.post(
            "/v1/auth/signup",
            json={"email": "rA@example.com", "password": "TestPass1!", "region": "jp"},
        )
        resp_a = await client.post(
            "/v1/auth/token",
            json={"email": "rA@example.com", "password": "TestPass1!"},
        )
        headers_a = {"Authorization": f"Bearer {resp_a.json()['access_token']}"}

        # A が医師を登録
        doc_resp = await client.post(
            "/v1/settings/doctor",
            json={"doctor_name": "A医師", "email": "docA@hospital.jp"},
            headers=headers_a,
        )
        doctor_id = doc_resp.json()["id"]

        # ユーザー B
        await client.post(
            "/v1/auth/signup",
            json={"email": "rB@example.com", "password": "TestPass1!", "region": "jp"},
        )
        resp_b = await client.post(
            "/v1/auth/token",
            json={"email": "rB@example.com", "password": "TestPass1!"},
        )
        headers_b = {"Authorization": f"Bearer {resp_b.json()['access_token']}"}

        # B が A の医師 ID でレポート送信 → 404
        resp = await client.post(
            "/v1/report/send",
            json={
                "doctor_id": doctor_id,
                "week_start": "2024-01-01",
                "user_consented": True,
            },
            headers=headers_b,
        )
        assert resp.status_code == 404

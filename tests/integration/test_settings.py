from __future__ import annotations

import pytest
from httpx import AsyncClient


class TestGetSettings:
    async def test_default_values(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.get("/v1/settings", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["region"] == "jp"
        assert data["preprocessing_correction_enabled"] is True
        limits = data["nutrition_limits"]
        assert limits["phosphorus_limit_mg"] == 800
        assert limits["potassium_limit_mg"] == 2000
        assert limits["sodium_limit_g"] == 6.0


class TestUpdateSettings:
    async def test_update_correction_flag_off(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.patch(
            "/v1/settings",
            json={"preprocessing_correction_enabled": False},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["preprocessing_correction_enabled"] is False

    async def test_update_correction_flag_back_on(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        await client.patch(
            "/v1/settings",
            json={"preprocessing_correction_enabled": False},
            headers=auth_headers,
        )
        resp = await client.patch(
            "/v1/settings",
            json={"preprocessing_correction_enabled": True},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["preprocessing_correction_enabled"] is True

    async def test_update_region(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.patch(
            "/v1/settings",
            json={"region": "us"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        assert resp.json()["region"] == "us"

    async def test_update_invalid_region(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.patch(
            "/v1/settings",
            json={"region": "de"},
            headers=auth_headers,
        )
        assert resp.status_code == 422

    async def test_partial_update_preserves_other_fields(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        """region のみ更新しても correction フラグは変わらないこと。"""
        await client.patch(
            "/v1/settings",
            json={"preprocessing_correction_enabled": False},
            headers=auth_headers,
        )
        resp = await client.patch(
            "/v1/settings",
            json={"region": "uk"},
            headers=auth_headers,
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["region"] == "uk"
        assert data["preprocessing_correction_enabled"] is False


class TestUpdateNutritionLimits:
    async def test_update_limits(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.patch(
            "/v1/settings/nutrition-limits",
            json={
                "phosphorus_limit_mg": 700,
                "potassium_limit_mg": 1800,
                "sodium_limit_g": 5.0,
            },
            headers=auth_headers,
        )
        assert resp.status_code == 200
        data = resp.json()
        assert data["phosphorus_limit_mg"] == 700
        assert data["potassium_limit_mg"] == 1800
        assert data["sodium_limit_g"] == 5.0

    async def test_update_limits_reflected_in_settings(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        await client.patch(
            "/v1/settings/nutrition-limits",
            json={
                "phosphorus_limit_mg": 900,
                "potassium_limit_mg": 2200,
                "sodium_limit_g": 7.0,
            },
            headers=auth_headers,
        )
        resp = await client.get("/v1/settings", headers=auth_headers)
        limits = resp.json()["nutrition_limits"]
        assert limits["phosphorus_limit_mg"] == 900
        assert limits["potassium_limit_mg"] == 2200
        assert limits["sodium_limit_g"] == 7.0

    async def test_update_limits_zero_value_rejected(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.patch(
            "/v1/settings/nutrition-limits",
            json={
                "phosphorus_limit_mg": 0,
                "potassium_limit_mg": 2000,
                "sodium_limit_g": 6.0,
            },
            headers=auth_headers,
        )
        assert resp.status_code == 422


class TestDoctorManagement:
    async def test_list_doctors_empty(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.get("/v1/settings/doctor", headers=auth_headers)
        assert resp.status_code == 200
        assert resp.json() == []

    async def test_add_doctor(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.post(
            "/v1/settings/doctor",
            json={"doctor_name": "山田太郎", "email": "yamada@hospital.jp"},
            headers=auth_headers,
        )
        assert resp.status_code == 201
        data = resp.json()
        assert data["doctor_name"] == "山田太郎"
        assert data["email"] == "yamada@hospital.jp"
        assert "id" in data

    async def test_add_doctor_minimal(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        """email/system_id なしでも追加できること。"""
        resp = await client.post(
            "/v1/settings/doctor",
            json={"doctor_name": "鈴木医師"},
            headers=auth_headers,
        )
        assert resp.status_code == 201
        assert resp.json()["email"] is None

    async def test_list_doctors_after_add(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        await client.post(
            "/v1/settings/doctor",
            json={"doctor_name": "田中先生", "email": "tanaka@clinic.jp"},
            headers=auth_headers,
        )
        resp = await client.get("/v1/settings/doctor", headers=auth_headers)
        assert resp.status_code == 200
        doctors = resp.json()
        assert len(doctors) == 1
        assert doctors[0]["doctor_name"] == "田中先生"

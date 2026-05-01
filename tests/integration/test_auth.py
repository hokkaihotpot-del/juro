from __future__ import annotations

import pytest
from httpx import AsyncClient


class TestSignup:
    async def test_signup_success(self, client: AsyncClient):
        resp = await client.post(
            "/v1/auth/signup",
            json={"email": "new@example.com", "password": "TestPass1!", "region": "jp"},
        )
        assert resp.status_code == 201
        data = resp.json()
        assert data["email"] == "new@example.com"
        assert data["region"] == "jp"
        assert "id" in data
        assert "hashed_password" not in data

    async def test_signup_duplicate_email(self, client: AsyncClient):
        payload = {"email": "dup@example.com", "password": "TestPass1!", "region": "jp"}
        await client.post("/v1/auth/signup", json=payload)
        resp = await client.post("/v1/auth/signup", json=payload)
        assert resp.status_code == 400
        assert "already registered" in resp.json()["detail"]

    async def test_signup_invalid_region(self, client: AsyncClient):
        resp = await client.post(
            "/v1/auth/signup",
            json={"email": "x@example.com", "password": "TestPass1!", "region": "xx"},
        )
        assert resp.status_code == 422

    async def test_signup_short_password(self, client: AsyncClient):
        resp = await client.post(
            "/v1/auth/signup",
            json={"email": "x@example.com", "password": "short", "region": "jp"},
        )
        assert resp.status_code == 422


class TestLogin:
    async def test_login_success(self, client: AsyncClient):
        await client.post(
            "/v1/auth/signup",
            json={"email": "login@example.com", "password": "TestPass1!", "region": "jp"},
        )
        resp = await client.post(
            "/v1/auth/token",
            json={"email": "login@example.com", "password": "TestPass1!"},
        )
        assert resp.status_code == 200
        data = resp.json()
        assert "access_token" in data
        assert data["token_type"] == "bearer"
        assert len(data["access_token"]) > 20

    async def test_login_wrong_password(self, client: AsyncClient):
        await client.post(
            "/v1/auth/signup",
            json={"email": "wp@example.com", "password": "TestPass1!", "region": "jp"},
        )
        resp = await client.post(
            "/v1/auth/token",
            json={"email": "wp@example.com", "password": "WrongPass1!"},
        )
        assert resp.status_code == 401

    async def test_login_unknown_email(self, client: AsyncClient):
        resp = await client.post(
            "/v1/auth/token",
            json={"email": "nobody@example.com", "password": "TestPass1!"},
        )
        assert resp.status_code == 401


class TestAuthGuard:
    async def test_protected_endpoint_no_token(self, client: AsyncClient):
        resp = await client.get("/v1/settings")
        assert resp.status_code in (401, 403)

    async def test_protected_endpoint_with_token(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.get("/v1/settings", headers=auth_headers)
        assert resp.status_code == 200

    async def test_invalid_token_rejected(self, client: AsyncClient):
        resp = await client.get(
            "/v1/settings", headers={"Authorization": "Bearer invalid.token.here"}
        )
        assert resp.status_code == 401

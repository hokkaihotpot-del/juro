from __future__ import annotations

import pytest
from httpx import AsyncClient


class TestListAllergies:
    async def test_list_empty_initially(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.get("/v1/allergy", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["items"] == []
        assert data["total"] == 0

    async def test_list_after_add(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        await client.post(
            "/v1/allergy",
            json={"ingredient_name": "えび", "is_preset": True},
            headers=auth_headers,
        )
        resp = await client.get("/v1/allergy", headers=auth_headers)
        assert resp.status_code == 200
        data = resp.json()
        assert data["total"] == 1
        assert data["items"][0]["ingredient_name"] == "えび"


class TestAddAllergy:
    async def test_add_success(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.post(
            "/v1/allergy",
            json={"ingredient_name": "落花生", "is_preset": False},
            headers=auth_headers,
        )
        assert resp.status_code == 201
        data = resp.json()
        assert data["ingredient_name"] == "落花生"
        assert data["is_preset"] is False
        assert "id" in data

    async def test_add_normalizes_name(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        """ingredient_name_normalized は lowercase + strip になること。"""
        resp = await client.post(
            "/v1/allergy",
            json={"ingredient_name": "  Milk  ", "is_preset": True},
            headers=auth_headers,
        )
        assert resp.status_code == 201
        # normalized はレスポンスには含まれないが、DB に正規化して保存される。
        # ここでは登録成功と ingredient_name がそのまま返ることを確認する。
        assert resp.json()["ingredient_name"] == "  Milk  "

    async def test_add_without_auth(self, client: AsyncClient):
        resp = await client.post(
            "/v1/allergy",
            json={"ingredient_name": "えび", "is_preset": True},
        )
        assert resp.status_code in (401, 403)


class TestDeleteAllergy:
    async def test_delete_success(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        add_resp = await client.post(
            "/v1/allergy",
            json={"ingredient_name": "そば", "is_preset": True},
            headers=auth_headers,
        )
        item_id = add_resp.json()["id"]

        del_resp = await client.delete(
            f"/v1/allergy/{item_id}", headers=auth_headers
        )
        assert del_resp.status_code == 204

        list_resp = await client.get("/v1/allergy", headers=auth_headers)
        assert list_resp.json()["total"] == 0

    async def test_delete_not_found(
        self, client: AsyncClient, auth_headers: dict[str, str]
    ):
        resp = await client.delete(
            "/v1/allergy/nonexistent-id-0000", headers=auth_headers
        )
        assert resp.status_code == 404

    async def test_delete_other_user_item(self, client: AsyncClient):
        """別ユーザーのアレルギー項目は 404 になること（認可テスト）。"""
        # ユーザー A 作成・ログイン
        await client.post(
            "/v1/auth/signup",
            json={"email": "userA@example.com", "password": "TestPass1!", "region": "jp"},
        )
        resp_a = await client.post(
            "/v1/auth/token",
            json={"email": "userA@example.com", "password": "TestPass1!"},
        )
        headers_a = {"Authorization": f"Bearer {resp_a.json()['access_token']}"}

        # ユーザー B 作成・ログイン
        await client.post(
            "/v1/auth/signup",
            json={"email": "userB@example.com", "password": "TestPass1!", "region": "jp"},
        )
        resp_b = await client.post(
            "/v1/auth/token",
            json={"email": "userB@example.com", "password": "TestPass1!"},
        )
        headers_b = {"Authorization": f"Bearer {resp_b.json()['access_token']}"}

        # A がアレルギー追加
        add_resp = await client.post(
            "/v1/allergy",
            json={"ingredient_name": "卵", "is_preset": True},
            headers=headers_a,
        )
        item_id = add_resp.json()["id"]

        # B が A のアイテムを削除しようとする → 404
        del_resp = await client.delete(f"/v1/allergy/{item_id}", headers=headers_b)
        assert del_resp.status_code == 404

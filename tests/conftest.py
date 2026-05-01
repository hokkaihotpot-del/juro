from __future__ import annotations

import os
from collections.abc import AsyncGenerator

# テスト用 SQLite URL を環境変数でセットし、app.database のエンジン生成をオーバーライドする
os.environ.setdefault(
    "DATABASE_URL", "sqlite+aiosqlite:///./test_juro.db"
)

import pytest  # noqa: E402
from httpx import ASGITransport, AsyncClient  # noqa: E402
from sqlalchemy.ext.asyncio import (  # noqa: E402
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

TEST_DATABASE_URL = "sqlite+aiosqlite:///:memory:"


@pytest.fixture(scope="function")
async def db_session() -> AsyncGenerator[AsyncSession, None]:
    engine = create_async_engine(TEST_DATABASE_URL, echo=False)

    # app.models をここで初めてインポートして Base.metadata を確定させる
    import app.models  # noqa: F401
    from app.models.base import Base

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.create_all)

    factory = async_sessionmaker(
        bind=engine,
        class_=AsyncSession,
        expire_on_commit=False,
        autoflush=False,
        autocommit=False,
    )
    async with factory() as session:
        yield session

    async with engine.begin() as conn:
        await conn.run_sync(Base.metadata.drop_all)
    await engine.dispose()


@pytest.fixture(scope="function")
async def client(db_session: AsyncSession) -> AsyncGenerator[AsyncClient, None]:
    # DB セッション確定後に app をインポート
    from app.database import get_db
    from app.main import create_app

    app = create_app()

    async def _override_get_db() -> AsyncGenerator[AsyncSession, None]:
        try:
            yield db_session
            await db_session.flush()
        except Exception:
            await db_session.rollback()
            raise

    app.dependency_overrides[get_db] = _override_get_db

    async with AsyncClient(
        transport=ASGITransport(app=app), base_url="http://test"
    ) as ac:
        yield ac

    app.dependency_overrides.clear()


@pytest.fixture(scope="function")
async def auth_headers(client: AsyncClient) -> dict[str, str]:
    """テストユーザーを作成してアクセストークンを返す共通ヘルパー。"""
    await client.post(
        "/v1/auth/signup",
        json={"email": "test@example.com", "password": "TestPass1!", "region": "jp"},
    )
    resp = await client.post(
        "/v1/auth/token",
        json={"email": "test@example.com", "password": "TestPass1!"},
    )
    token = resp.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}

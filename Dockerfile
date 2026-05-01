# JURO Backend Dockerfile
FROM python:3.12-slim

WORKDIR /app

# システム依存関係
RUN apt-get update && apt-get install -y \
    gcc \
    libpq-dev \
    && rm -rf /var/lib/apt/lists/*

# Python依存関係
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# アプリケーションコード
COPY app/ ./app/
COPY alembic/ ./alembic/
COPY alembic.ini .
COPY data/ ./data/

# 環境変数
ENV PYTHONPATH=/app
ENV PORT=8000

# ヘルスチェック
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8000/health || exit 1

# 起動
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]

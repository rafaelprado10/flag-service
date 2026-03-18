# syntax=docker/dockerfile:1.6

############################
# 1) Builder: cria venv e instala deps
############################
FROM python:3.13-slim-bookworm AS builder

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

WORKDIR /app

# Dependências mínimas para build (caso algum pacote precise compilar)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copia requirements e instala em um venv
COPY requirements.txt ./

RUN python -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip setuptools wheel && \
    /opt/venv/bin/pip install --no-cache-dir -r requirements.txt

############################
# 2) Runtime: imagem final enxuta
############################
FROM python:3.13-slim-bookworm AS runtime

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

WORKDIR /app

# (Opcional/seguro) libs runtime úteis p/ TLS/CA
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copia o venv pronto do builder
COPY --from=builder /opt/venv /opt/venv

# Copia o código da aplicação
COPY . .

# Cria usuário não-root
RUN addgroup --system app && adduser --system --ingroup app app && \
    chown -R app:app /app

USER app

EXPOSE 8002

# Gunicorn (ajuste workers conforme CPU/memória)
CMD ["gunicorn", "--bind", "0.0.0.0:8002", "app:app"]

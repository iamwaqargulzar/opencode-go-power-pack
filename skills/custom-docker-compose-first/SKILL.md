---
name: custom-docker-compose-first
description: Use for local dev infrastructure. Covers docker-compose patterns, multi-stage builds, .dockerignore, non-root users, healthchecks. Trigger on: Docker, docker-compose, container, image, Dockerfile, compose, local dev, dev environment.
---

# Docker Compose First

## Principles

- **`docker compose` (v2)** — not `docker-compose` (v1) unless the repo specifically requires v1.
- **docker-compose for local dev** — every service the app needs (DB, cache, queue) should be in `docker-compose.yml`.
- **One Dockerfile per service** — don't try to make one image serve multiple services.
- **Multi-stage builds** — builder stage compiles, runtime stage is minimal.

## Dockerfile checklist

```dockerfile
# Pin base image version (never :latest)
FROM node:22-alpine AS builder

# Multi-stage: builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --production=false
COPY . .
RUN npm run build

# Multi-stage: minimal runtime
FROM node:22-alpine AS runtime
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./

# Non-root user
USER node

# Healthcheck
HEALTHCHECK --interval=30s --timeout=3s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

EXPOSE 3000
CMD ["node", "dist/index.js"]
```

## .dockerignore (always include)

```
node_modules
.git
.env
*.md
test
coverage
dist
```

## docker-compose.yml patterns

```yaml
services:
  app:
    build: .
    ports: ["3000:3000"]
    environment:
      DATABASE_URL: postgresql://user:pass@db:5432/app
    depends_on:
      db:
        condition: service_healthy
    volumes:
      - ./:/app  # hot reload in dev
      - /app/node_modules  # don't mount over node_modules

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: user
      POSTGRES_PASSWORD: pass
      POSTGRES_DB: app
    ports: ["5432:5432"]
    volumes:
      - pgdata:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U user -d app"]
      interval: 5s
      timeout: 3s
      retries: 5

volumes:
  pgdata:
```

## Verification

- `docker build` succeeds.
- `docker compose up` starts all services.
- `docker compose ps` shows all services healthy.
- `docker scan` (or `trivy image`) passes — no critical vulnerabilities.
- Image size is reasonable (check `docker images`).

# Docker Patterns

## Multi-Stage Dockerfile (Laravel + Node)

```dockerfile
# Stage 1: PHP + Node build
FROM php:8.3-fpm-alpine AS base

RUN apk add --no-cache \
    nodejs npm \
    libpng-dev libjpeg-dev libwebp-dev \
    postgresql-dev

RUN docker-php-ext-install pdo_pgsql gd opcache

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Stage 2: Build dependencies
FROM base AS build

COPY composer.json composer.lock ./
RUN composer install --no-dev --optimize-autoloader --no-interaction

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
RUN npm run build

# Stage 3: Production image
FROM php:8.3-fpm-alpine AS production

RUN apk add --no-cache postgresql-dev nginx supervisor
RUN docker-php-ext-install pdo_pgsql opcache

WORKDIR /app

COPY --from=build /app /app
COPY docker/nginx.conf /etc/nginx/nginx.conf
COPY docker/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/php.ini /usr/local/etc/php/conf.d/custom.ini

RUN chown -R www-data:www-data /app/storage /app/bootstrap/cache

USER www-data

HEALTHCHECK --interval=30s --timeout=3s \
  CMD curl -f http://localhost/health || exit 1

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
```

---

## .dockerignore

```
.git
.github
node_modules
vendor
tests
*.md
.env
.env.*
storage/logs/*
storage/framework/cache/*
docker-compose*.yml
Makefile
```

---

## docker-compose.yml (local dev)

```yaml
services:
  app:
    build:
      context: .
      target: base
    volumes:
      - .:/app
      - /app/vendor
      - /app/node_modules
    ports: ["8000:80"]
    depends_on: [postgres, redis]
    environment:
      APP_ENV: local
      DB_HOST: postgres
      REDIS_HOST: redis

  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: app
      POSTGRES_PASSWORD: secret
    volumes:
      - pgdata:/var/lib/postgresql/data
    ports: ["5432:5432"]

  redis:
    image: valkey/valkey:8-alpine
    ports: ["6379:6379"]

volumes:
  pgdata:
```

---

## Rules

- Production image: always non-root user (`USER www-data`)
- No `.env` file baked into image — inject at runtime
- Multi-stage builds: keep production image lean (no dev tools, no test files)
- Always define `HEALTHCHECK`
- `--no-dev` flag on production Composer install
- Named volumes for databases in dev compose

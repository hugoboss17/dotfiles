# GitHub Actions Patterns

## CI Workflow (ci.yml)

```yaml
name: CI

on:
  push:
    branches: ['**']
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest

    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: password
          POSTGRES_DB: testing
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-retries 5

    steps:
      - uses: actions/checkout@v4

      - name: Setup PHP
        uses: shivammathur/setup-php@v2
        with:
          php-version: '8.3'
          extensions: pdo_pgsql, redis
          coverage: xdebug

      - name: Cache Composer
        uses: actions/cache@v4
        with:
          path: vendor
          key: composer-${{ hashFiles('composer.lock') }}

      - name: Install PHP deps
        run: composer install --no-interaction --prefer-dist

      - name: Setup Node
        uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'

      - name: Install Node deps
        run: npm ci

      - name: Build assets
        run: npm run build

      - name: Run Pint
        run: ./vendor/bin/pint --test

      - name: Run PHPStan
        run: ./vendor/bin/phpstan analyse --memory-limit=512M

      - name: Run Pest
        env:
          DB_CONNECTION: pgsql
          DB_HOST: localhost
          DB_PASSWORD: password
          DB_DATABASE: testing
        run: ./vendor/bin/pest --coverage --min=80

      - name: TypeScript check
        run: npx tsc --noEmit

      - name: ESLint
        run: npx eslint . --ext .ts,.vue
```

---

## CD Workflow (deploy.yml)

```yaml
name: Deploy

on:
  push:
    branches: [main]       # → staging
  push:
    tags: ['*']            # → prod

jobs:
  deploy:
    runs-on: ubuntu-latest
    needs: [test]          # CI must pass first

    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS
        uses: aws-actions/configure-aws-credentials@v4
        with:
          aws-access-key-id: ${{ secrets.AWS_ACCESS_KEY_ID }}
          aws-secret-access-key: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
          aws-region: eu-west-1

      - name: Login to ECR
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build and push image
        run: |
          IMAGE_TAG=${{ github.sha }}
          docker build -t $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG .
          docker push $ECR_REGISTRY/$ECR_REPO:$IMAGE_TAG

      - name: Deploy to ECS
        uses: aws-actions/amazon-ecs-deploy-task-definition@v1
        with:
          task-definition: task-definition.json
          service: ${{ env.ECS_SERVICE }}
          cluster: ${{ env.ECS_CLUSTER }}
          wait-for-service-stability: true

      - name: Notify on failure
        if: failure()
        uses: slackapi/slack-github-action@v1
        with:
          payload: '{"text":"Deploy failed: ${{ github.ref }}"}'
        env:
          SLACK_WEBHOOK_URL: ${{ secrets.SLACK_WEBHOOK }}
```

---

## Rules

- Always pin action versions to a commit SHA in production workflows
- Separate CI and CD workflows — never combine in one file
- Cache dependencies by lockfile hash, not by date
- Use `needs:` to enforce CI before CD
- Secrets via `${{ secrets.NAME }}` — never hardcoded
- `wait-for-service-stability: true` — confirm deploy before marking success

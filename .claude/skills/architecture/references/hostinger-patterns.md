# Hostinger Patterns Reference

## When to Use Hostinger

| Scenario | Recommendation |
|----------|---------------|
| WordPress or CMS site | Shared / Cloud Hosting plan |
| Small Laravel app (< 10k req/day) | KVM VPS + Docker Compose |
| Budget MVP or prototype | KVM VPS |
| Client sites (agency) | Cloud Hosting Business plan |
| High-traffic or auto-scaling | Use Hetzner or cloud provider instead |
| Managed Kubernetes | Not available — use Hetzner or cloud provider |

---

## Plans Overview

| Plan | Type | Best for |
|------|------|----------|
| Shared Hosting | Shared (no root) | WordPress, static sites |
| Cloud Hosting | Shared + more resources | Growing WordPress/PHP apps |
| KVM VPS | Root access | Docker, custom stacks, Laravel |
| Business Email | Email only | Client email hosting |

**Always choose KVM VPS over OpenVZ** — KVM supports Docker and modern kernels.

---

## KVM VPS — Laravel + Docker Compose

**Recommended VPS specs for small production Laravel:**
- 2 vCPU, 4 GB RAM, 80 GB NVMe (~€6-10/mo)
- Ubuntu 24.04 LTS

**docker-compose.yml:**
```yaml
services:
  app:
    image: registry.example.com/myapp:latest
    restart: unless-stopped
    environment:
      APP_ENV: production
      DB_HOST: db
      REDIS_HOST: redis
    depends_on: [db, redis]
    networks: [internal]

  nginx:
    image: nginx:alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - certbot-certs:/etc/letsencrypt
    depends_on: [app]
    networks: [internal]

  db:
    image: postgres:16-alpine
    restart: unless-stopped
    volumes:
      - db-data:/var/lib/postgresql/data
    environment:
      POSTGRES_DB: myapp
      POSTGRES_USER: myapp
      POSTGRES_PASSWORD_FILE: /run/secrets/db_password
    networks: [internal]

  redis:
    image: valkey/valkey:8-alpine
    restart: unless-stopped
    command: valkey-server --requirepass ${REDIS_PASSWORD}
    networks: [internal]

  queue:
    image: registry.example.com/myapp:latest
    restart: unless-stopped
    command: php artisan queue:work --sleep=3 --tries=3
    depends_on: [db, redis]
    networks: [internal]

volumes:
  db-data:
  certbot-certs:

networks:
  internal:
```

---

## Nginx + SSL (Let's Encrypt)

**nginx.conf:**
```nginx
server {
    listen 80;
    server_name example.com www.example.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name example.com www.example.com;

    ssl_certificate     /etc/letsencrypt/live/example.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/example.com/privkey.pem;
    ssl_protocols       TLSv1.2 TLSv1.3;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN";
    add_header X-Content-Type-Options "nosniff";
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains";

    location / {
        proxy_pass         http://app:8080;
        proxy_http_version 1.1;
        proxy_set_header   Host $host;
        proxy_set_header   X-Real-IP $remote_addr;
        proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header   X-Forwarded-Proto $scheme;
    }
}
```

**SSL certificate (Certbot):**
```bash
docker run -it --rm \
  -v certbot-certs:/etc/letsencrypt \
  -v certbot-www:/var/www/certbot \
  certbot/certbot certonly --webroot \
  -w /var/www/certbot \
  -d example.com -d www.example.com \
  --email admin@example.com --agree-tos
```

---

## Cloudflare in Front of Hostinger

Always put Cloudflare in front for production. Free tier gives:
- CDN and edge caching
- DDoS protection
- SSL termination (Full Strict mode)
- DNS management
- Web Application Firewall (basic rules free)

**DNS setup:**
1. Point nameservers to Cloudflare
2. Create A record → Hostinger VPS IP (proxied ✓)
3. In Hostinger: set SSL to Full (not Flexible) to avoid redirect loops
4. In Cloudflare SSL: set to "Full (Strict)"

---

## Object Storage (External)

Hostinger has no native object storage. Use:

| Provider | Price | Notes |
|----------|-------|-------|
| Cloudflare R2 | $0.015/GB/mo, no egress | Best for new projects |
| Backblaze B2 | $0.006/GB/mo | Cheapest storage |
| Hetzner Object Storage | €0.005/GB/mo | Good for EU residency |
| AWS S3 | $0.023/GB/mo | Most compatible |

```env
# Cloudflare R2 in .env
FILESYSTEM_DISK=s3
AWS_ENDPOINT=https://<account-id>.r2.cloudflarestorage.com
AWS_BUCKET=my-bucket
AWS_ACCESS_KEY_ID=your-r2-key
AWS_SECRET_ACCESS_KEY=your-r2-secret
AWS_DEFAULT_REGION=auto
AWS_USE_PATH_STYLE_ENDPOINT=true
```

---

## Queue Workers with Supervisor

```ini
; /etc/supervisor/conf.d/laravel-worker.conf
[program:laravel-worker]
process_name=%(program_name)s_%(process_num)02d
command=php /var/www/artisan queue:work redis --sleep=3 --tries=3 --max-time=3600
autostart=true
autorestart=true
stopasgroup=true
killasgroup=true
user=www-data
numprocs=2
redirect_stderr=true
stdout_logfile=/var/log/worker.log
stopwaitsecs=3600
```

```bash
supervisorctl reread && supervisorctl update && supervisorctl start laravel-worker:*
```

---

## Deployment via GitHub Actions

```yaml
# .github/workflows/deploy.yml
name: Deploy to Hostinger VPS

on:
  push:
    branches: [main]

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build and push Docker image
        run: |
          echo ${{ secrets.REGISTRY_TOKEN }} | docker login registry.example.com -u ${{ secrets.REGISTRY_USER }} --password-stdin
          docker build -t registry.example.com/myapp:${{ github.sha }} .
          docker push registry.example.com/myapp:${{ github.sha }}

      - name: Deploy to VPS
        uses: appleboy/ssh-action@v1
        with:
          host: ${{ secrets.VPS_HOST }}
          username: deploy
          key: ${{ secrets.VPS_SSH_KEY }}
          script: |
            cd /var/www/myapp
            export IMAGE_TAG=${{ github.sha }}
            docker compose pull
            docker compose up -d --remove-orphans
            docker compose exec -T app php artisan migrate --force
            docker image prune -f
```

---

## Backup Strategy for VPS

Hostinger includes weekly backups on some plans, but **do not rely on them**.

**Self-managed backup script:**
```bash
#!/bin/bash
# /etc/cron.daily/backup-db
DATE=$(date +%Y%m%d_%H%M)
docker exec myapp-db-1 pg_dump -U myapp myapp | gzip > /backups/db_${DATE}.sql.gz

# Upload to R2/B2
rclone copy /backups/ r2:my-backups/$(hostname)/

# Keep only last 7 days locally
find /backups -name "*.sql.gz" -mtime +7 -delete
```

---

## Limitations vs Full Cloud

| Feature | Hostinger | Cloud Alternative |
|---------|-----------|------------------|
| Auto-scaling | No | Hetzner/AWS/GCP |
| Managed Kubernetes | No | Hetzner K3s / GKE / AKS |
| Native object storage | No | R2 / GCS / S3 |
| Multi-region | No | Cloud providers |
| SLA | 99.9% | 99.95%+ |
| DDoS protection | Via Cloudflare | Native on cloud |
| Monitoring | Manual setup | CloudWatch / Monitoring |

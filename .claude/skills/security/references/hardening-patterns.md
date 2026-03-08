# Hardening Patterns Reference

## SSH Hardening

```bash
# /etc/ssh/sshd_config
Port 22                          # consider changing to non-standard port
PermitRootLogin no
PasswordAuthentication no
PubkeyAuthentication yes
AuthorizedKeysFile .ssh/authorized_keys
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 2
AllowUsers deploy                 # whitelist specific users
Protocol 2
```

```bash
# Apply changes
systemctl restart sshd

# Test config before restarting (prevents lockout)
sshd -t
```

---

## UFW Firewall

```bash
# Reset and configure
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Allow only what's needed
ufw allow from YOUR_IP to any port 22    # SSH from known IP
ufw allow 80/tcp                          # HTTP
ufw allow 443/tcp                         # HTTPS

# Enable
ufw --force enable
ufw status verbose
```

---

## fail2ban

```bash
# /etc/fail2ban/jail.local
[DEFAULT]
bantime  = 3600     # 1 hour ban
maxretry = 5
findtime = 600

[sshd]
enabled = true
port    = ssh
logpath = %(sshd_log)s

[nginx-http-auth]
enabled = true

[nginx-limit-req]
enabled = true
filter  = nginx-limit-req
logpath = /var/log/nginx/error.log
maxretry = 10
```

```bash
systemctl enable fail2ban
systemctl restart fail2ban
fail2ban-client status
```

---

## Nginx Security Headers

```nginx
# /etc/nginx/conf.d/security-headers.conf
add_header X-Frame-Options "SAMEORIGIN" always;
add_header X-Content-Type-Options "nosniff" always;
add_header X-XSS-Protection "1; mode=block" always;
add_header Referrer-Policy "strict-origin-when-cross-origin" always;
add_header Permissions-Policy "geolocation=(), microphone=(), camera=()" always;
add_header Strict-Transport-Security "max-age=31536000; includeSubDomains; preload" always;

# Content Security Policy — tune per application
add_header Content-Security-Policy "
  default-src 'self';
  script-src 'self' 'nonce-{NONCE}';
  style-src 'self' 'unsafe-inline';
  img-src 'self' data: https:;
  font-src 'self';
  connect-src 'self';
  frame-ancestors 'none';
" always;

# Hide nginx version
server_tokens off;

# Disable unused HTTP methods
if ($request_method !~ ^(GET|POST|PUT|PATCH|DELETE|HEAD|OPTIONS)$) {
    return 405;
}
```

---

## Laravel Application Hardening

```php
// config/session.php
'secure' => env('SESSION_SECURE_COOKIE', true),  // HTTPS only
'http_only' => true,                               // no JS access
'same_site' => 'strict',                           // CSRF protection

// config/app.php
'debug' => env('APP_DEBUG', false),

// Trusted proxies (if behind load balancer)
// app/Http/Middleware/TrustProxies.php
protected $proxies = '*';  // or specific LB IPs
protected $headers = Request::HEADER_X_FORWARDED_FOR
    | Request::HEADER_X_FORWARDED_HOST
    | Request::HEADER_X_FORWARDED_PORT
    | Request::HEADER_X_FORWARDED_PROTO;
```

```php
// Rate limiting (RouteServiceProvider or routes)
Route::middleware(['auth', 'throttle:60,1'])->group(function () {
    // authenticated routes
});

Route::middleware(['throttle:login'])->group(function () {
    Route::post('/login', [AuthController::class, 'login']);
});

// RateLimiter definition
RateLimiter::for('login', function (Request $request) {
    return Limit::perMinute(5)->by($request->ip());
});
```

---

## Docker Hardening

```dockerfile
FROM php:8.3-fpm-alpine AS production

# Run as non-root
RUN addgroup -g 1001 appgroup && adduser -u 1001 -G appgroup -s /bin/sh -D appuser

WORKDIR /var/www

COPY --chown=appuser:appgroup . .

# Drop to non-root
USER appuser

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD php-fpm -t || exit 1

EXPOSE 9000
CMD ["php-fpm"]
```

```yaml
# docker-compose.yml — security options
services:
  app:
    security_opt:
      - no-new-privileges:true
    read_only: true                # read-only root filesystem
    tmpfs:
      - /tmp
      - /var/run
    cap_drop:
      - ALL
    cap_add:
      - NET_BIND_SERVICE            # only if binding to port < 1024
```

---

## Secret Management

### 1Password CLI (recommended for local dev)
```bash
# Install op CLI, then use in scripts
export DB_PASSWORD=$(op read "op://MyVault/DB/password")

# Or in .env files via 1Password secrets references
DB_PASSWORD=op://MyVault/DB/password
# Load with: op run --env-file=.env -- php artisan serve
```

### AWS Secrets Manager
```php
// Fetch secret at boot (cache in memory)
$secret = json_decode(
    app(SecretsManagerClient::class)->getSecretValue([
        'SecretId' => 'myapp/production/db',
    ])['SecretString'],
    true
);
```

### HashiCorp Vault
```bash
# Fetch secret
vault kv get -field=password secret/myapp/db

# App role auth for service accounts
vault write auth/approle/login \
    role_id=$VAULT_ROLE_ID \
    secret_id=$VAULT_SECRET_ID
```

### Environment variable injection (Docker/K8s)
```yaml
# Never bake secrets in image — inject at runtime
env:
  - name: DB_PASSWORD
    valueFrom:
      secretKeyRef:
        name: myapp-secrets
        key: db-password
```

---

## Database Hardening

```sql
-- Least-privilege DB user
CREATE USER myapp WITH PASSWORD 'strong-password';
GRANT CONNECT ON DATABASE myapp TO myapp;
GRANT USAGE ON SCHEMA public TO myapp;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO myapp;
GRANT USAGE, SELECT ON ALL SEQUENCES IN SCHEMA public TO myapp;

-- Never grant superuser to application user
-- Never grant CREATE TABLE to application user in production

-- Force SSL connections
ALTER USER myapp CONNECTION LIMIT 100;
-- In pg_hba.conf: hostssl all all 0.0.0.0/0 md5
```

```sql
-- MySQL equivalent
CREATE USER 'myapp'@'%' IDENTIFIED BY 'strong-password' REQUIRE SSL;
GRANT SELECT, INSERT, UPDATE, DELETE ON myapp.* TO 'myapp'@'%';
FLUSH PRIVILEGES;
```

---

## Server Hardening Checklist

```bash
# Unattended security updates (Ubuntu)
apt install unattended-upgrades
dpkg-reconfigure --priority=low unattended-upgrades

# /etc/apt/apt.conf.d/50unattended-upgrades
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
};
Unattended-Upgrade::Automatic-Reboot "false";
Unattended-Upgrade::Mail "admin@example.com";

# Disable unused services
systemctl disable bluetooth
systemctl disable cups
systemctl list-units --type=service --state=running

# Check open ports
ss -tlnp
netstat -tlnp

# Check for SUID binaries (potential privilege escalation)
find / -perm -4000 -type f 2>/dev/null
```

---

## Security Headers Test

Test your headers at: https://securityheaders.com

Target grade: **A** or **A+**

| Header | Required | Value |
|--------|----------|-------|
| `Strict-Transport-Security` | Yes | `max-age=31536000; includeSubDomains` |
| `Content-Security-Policy` | Yes | Configured per app |
| `X-Frame-Options` | Yes | `SAMEORIGIN` |
| `X-Content-Type-Options` | Yes | `nosniff` |
| `Referrer-Policy` | Yes | `strict-origin-when-cross-origin` |
| `Permissions-Policy` | Recommended | Restrict unused APIs |

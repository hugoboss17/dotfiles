# OWASP Top 10 (2021) Checklist

## A01 — Broken Access Control

**Risk:** Users can act outside their intended permissions — access other users' data, admin functions, or escalate privileges.

**Detection:**
- IDOR: change `?user_id=123` to another ID — do you get their data?
- Check if role middleware is missing on protected routes
- Test unauthenticated access to API endpoints

**Prevention:**
```php
// Bad: no authorisation check
public function show(Order $order): JsonResponse
{
    return response()->json($order);
}

// Good: policy check
public function show(Order $order): JsonResponse
{
    $this->authorize('view', $order);
    return response()->json($order);
}
```

**Checklist:**
- [ ] All routes have appropriate auth middleware
- [ ] Resource policies enforce ownership checks
- [ ] Admin routes require admin role — not just auth
- [ ] API responses don't expose other users' data

---

## A02 — Cryptographic Failures

**Risk:** Sensitive data (passwords, PII, tokens) exposed due to weak or missing encryption.

**Detection:**
- Passwords stored as MD5/SHA1
- HTTP instead of HTTPS in production
- Sensitive data in query strings or logs

**Prevention:**
```php
// Bad: MD5 password
$hash = md5($password);

// Good: bcrypt via Laravel
$hash = Hash::make($password); // bcrypt, cost=12

// Bad: sensitive data in URL
GET /api/users?api_key=secret123

// Good: Authorization header
Authorization: Bearer secret123
```

**Checklist:**
- [ ] HTTPS enforced everywhere (HSTS header set)
- [ ] Passwords hashed with bcrypt/argon2
- [ ] Sensitive fields encrypted at rest (PII, tokens)
- [ ] No secrets in URLs, logs, or error messages
- [ ] TLS 1.2+ only (disable TLS 1.0, 1.1)

---

## A03 — Injection

**Risk:** Attacker-controlled data is executed as a command — SQL, shell, LDAP, etc.

**Detection:**
- Search for raw string concatenation in queries
- Test inputs with `'`, `"`, `;`, `--`

**Prevention:**
```php
// Bad: SQL injection
$users = DB::select("SELECT * FROM users WHERE email = '$email'");

// Good: parameterised query
$users = DB::select("SELECT * FROM users WHERE email = ?", [$email]);

// Good: Eloquent (safe by default)
$user = User::where('email', $email)->first();

// Bad: shell injection
exec("convert " . $filename . " output.jpg");

// Good: escape or avoid shell
$process = new Process(['convert', $filename, 'output.jpg']);
$process->run();
```

**Checklist:**
- [ ] No raw query string concatenation
- [ ] All DB queries use parameterised statements or ORM
- [ ] Shell commands use safe process APIs, not string exec
- [ ] LDAP inputs escaped if applicable

---

## A04 — Insecure Design

**Risk:** Missing security controls baked into the design — rate limiting, account lockout, etc.

**Checklist:**
- [ ] Rate limiting on login, registration, and password reset
- [ ] Account lockout after N failed login attempts
- [ ] Password reset tokens expire and are single-use
- [ ] Business logic validated server-side (not just client-side)
- [ ] Threat modelling done for sensitive features

---

## A05 — Security Misconfiguration

**Risk:** Default credentials, debug mode in prod, verbose error messages, open ports.

**Detection:**
- `APP_DEBUG=true` in production
- Default admin credentials not changed
- Unnecessary services running

**Prevention:**
```bash
# .env production checklist
APP_ENV=production
APP_DEBUG=false
LOG_LEVEL=error

# Nginx: hide server version
server_tokens off;

# PHP: hide version
expose_php = Off
```

**Checklist:**
- [ ] `APP_DEBUG=false` in production
- [ ] Error messages don't expose stack traces to users
- [ ] Server version headers disabled
- [ ] Default credentials changed on all services
- [ ] Unused routes and features disabled
- [ ] Security headers set (CSP, HSTS, X-Frame-Options)

---

## A06 — Vulnerable and Outdated Components

**Risk:** Known CVEs in dependencies exploited.

**Detection:**
```bash
composer audit
npm audit
pip-audit
govulncheck ./...
```

**Checklist:**
- [ ] Dependency audit runs in CI on every PR
- [ ] No Critical or High CVEs unaddressed
- [ ] Dependencies updated monthly (Dependabot or Renovate)
- [ ] Base Docker images regularly updated

---

## A07 — Identification and Authentication Failures

**Risk:** Weak session management, credential stuffing, missing MFA.

**Prevention:**
```php
// Regenerate session after login
session()->regenerate();

// Use secure, httponly cookies
'secure' => true,
'http_only' => true,
'same_site' => 'strict',
```

**Checklist:**
- [ ] Session ID regenerated on login and privilege change
- [ ] Sessions invalidated on logout
- [ ] MFA available for admin accounts
- [ ] No default/weak passwords accepted
- [ ] Brute force protection on login (rate limiting + lockout)
- [ ] "Remember me" tokens hashed, not stored plain

---

## A08 — Software and Data Integrity Failures

**Risk:** Unsigned updates, insecure deserialisation, untrusted CI/CD pipeline.

**Prevention:**
```bash
# Pin GitHub Actions to commit SHA
- uses: actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683  # v4.2.2

# Verify composer package signatures where available
composer validate --strict
```

**Checklist:**
- [ ] GitHub Actions pinned to commit SHA, not `@latest`
- [ ] No deserialisation of untrusted user data
- [ ] Package integrity verified (composer.lock, package-lock.json committed)
- [ ] Supply chain: only use packages from trusted sources

---

## A09 — Security Logging and Monitoring Failures

**Risk:** Breaches go undetected because there's no logging or alerting.

**Prevention:**
```php
// Log authentication events
Log::channel('security')->info('login.success', [
    'user_id' => $user->id,
    'ip' => request()->ip(),
]);

Log::channel('security')->warning('login.failed', [
    'email' => $email,
    'ip' => request()->ip(),
]);
```

**Checklist:**
- [ ] Auth events logged: login, logout, failed login, password reset
- [ ] Admin actions logged with user ID and timestamp
- [ ] Logs shipped to centralised system (not just local files)
- [ ] Alerts on: multiple failed logins, unusual access patterns
- [ ] Log retention ≥ 90 days
- [ ] PII not logged (no passwords, card numbers, tokens)

---

## A10 — Server-Side Request Forgery (SSRF)

**Risk:** Attacker tricks server into making requests to internal services (cloud metadata, internal APIs).

**Detection:**
- Any feature that fetches a user-supplied URL

**Prevention:**
```php
// Bad: fetch user-supplied URL
$response = Http::get($request->input('url'));

// Good: allowlist of permitted domains
$url = $request->input('url');
$allowed = ['api.trusted.com', 'hooks.trusted.com'];
$host = parse_url($url, PHP_URL_HOST);

if (!in_array($host, $allowed, true)) {
    abort(422, 'URL not permitted');
}

$response = Http::get($url);
```

**Checklist:**
- [ ] No user-supplied URLs fetched without validation
- [ ] Internal IP ranges blocked in HTTP client config
- [ ] Cloud metadata endpoint (169.254.169.254) blocked at firewall level

---
name: security
metadata:
  compatible_agents: [claude-code]
  tags: [security, owasp, audit, secrets, hardening, compliance, soc2, gdpr, cve, penetration-testing]
description: >
  Security assistant for application hardening, vulnerability assessment, dependency auditing,
  secret scanning, and compliance checklists. Covers OWASP Top 10, infrastructure hardening,
  and regulatory compliance (SOC2, GDPR, PCI-DSS).
  Trigger with: "security audit", "check vulnerabilities", "OWASP review",
  "scan for secrets", "hardening checklist", "compliance check", "CVE audit".
---

## Commands

| Command | Description |
|---------|-------------|
| `/security audit` | Full security audit of a codebase or feature |
| `/security deps` | Dependency vulnerability scan and remediation |
| `/security secrets` | Scan for exposed secrets and credentials |
| `/security harden` | Infrastructure and application hardening checklist |
| `/security compliance` | Compliance checklist (SOC2, GDPR, PCI-DSS) |

---

## `/security audit`

Perform a security-focused code review against OWASP Top 10 and common vulnerabilities.

**Input:** File path, code snippet, git diff, or feature description.

**Output format:**
```
## Critical
- [vulnerability] → [suggested fix]

## Warnings
- [risk] → [suggested fix]

## Suggestions
- [hardening opportunity] → [improvement]

## Looks Good
- [what is secure]
```

**Review covers:**
- **Injection:** SQL, command, LDAP, XPath injection via unsanitised input
- **Broken authentication:** weak session management, credential exposure, missing MFA hooks
- **Sensitive data exposure:** unencrypted PII, secrets in logs, missing HTTPS enforcement
- **Broken access control:** missing authorisation checks, IDOR, privilege escalation paths
- **Security misconfiguration:** debug mode in prod, default credentials, open CORS, verbose errors
- **XSS:** reflected, stored, DOM-based — missing output encoding
- **Insecure deserialisation:** untrusted data deserialised without validation
- **Known vulnerable components:** outdated deps with CVEs
- **Insufficient logging:** missing audit trail for auth events, data changes, failures

**Rules:**
- Critical = exploitable vulnerabilities, data exposure, auth bypass
- Warnings = hardening gaps, missing controls, weak configurations
- Suggestions = defence-in-depth improvements
- Always provide the fixed code snippet, not just the description

---

## `/security deps`

Scan dependencies for known vulnerabilities and recommend remediation.

**Steps (run all applicable):**

1. **PHP (Composer):**
   ```bash
   composer audit
   ```

2. **Node.js (npm/yarn/pnpm):**
   ```bash
   npm audit
   npm audit fix         # auto-fix safe updates
   npm audit fix --force # force major bumps (review first)
   ```

3. **Python (pip):**
   ```bash
   pip-audit
   # or
   safety check
   ```

4. **Go:**
   ```bash
   govulncheck ./...
   ```

**Output per vulnerability:**
- CVE identifier and severity (Critical/High/Medium/Low)
- Affected package and version range
- Fixed version
- Remediation command
- Whether auto-fix is safe (no breaking changes)

**Rules:**
- Critical and High CVEs must be fixed before merging
- Medium CVEs: fix within sprint
- Low CVEs: track in backlog
- If no fix exists: document risk and add `# audit-ignore` with justification

---

## `/security secrets`

Scan codebase for accidentally committed secrets and credentials.

**Patterns to detect:**
- API keys and tokens (AWS, Stripe, GitHub, SendGrid, etc.)
- Private keys and certificates (BEGIN PRIVATE KEY, BEGIN RSA PRIVATE KEY)
- Database connection strings with credentials
- Hardcoded passwords and passphrases
- JWT secrets and signing keys
- OAuth client secrets

**Files to always check:**
- `.env*` files committed to git
- CI/CD workflow YAML files
- Docker files and compose files
- Config files (`config/`, `settings.py`, `appsettings.json`)
- Test fixtures and seed files

**Detection tools:**
```bash
# trufflehog (recommended)
trufflehog git file://. --only-verified

# git-secrets
git secrets --scan

# gitleaks
gitleaks detect --source .
```

**Output:**
- File path and line number
- Secret type detected
- Severity (committed to git history = Critical)
- Remediation steps (rotate key, git filter-branch or BFG, add to .gitignore)

**Prevention checklist:**
- [ ] `.gitignore` includes `.env`, `*.pem`, `*.key`, `*.p12`
- [ ] Pre-commit hook with secret scanning installed
- [ ] CI pipeline runs secret scan on every push
- [ ] Secrets stored in vault (Secrets Manager, Vault, 1Password CLI)

---

## `/security harden`

Generate a hardening checklist for infrastructure and application.

**Application hardening:**
- [ ] All HTTP responses include security headers (CSP, HSTS, X-Frame-Options, X-Content-Type-Options)
- [ ] CORS restricted to known origins — no wildcard in production
- [ ] Rate limiting on auth endpoints and public APIs
- [ ] All user input validated and sanitised at the boundary
- [ ] Error messages do not leak stack traces or internal paths
- [ ] Session tokens rotated on privilege change (login, role change)
- [ ] Passwords hashed with bcrypt/argon2 (cost factor ≥ 12)
- [ ] `Content-Security-Policy` configured and tested

**Server hardening (Linux):**
- [ ] SSH: `PasswordAuthentication no`, `PermitRootLogin no`, key-based auth only
- [ ] UFW/iptables: only required ports open (80, 443, SSH from known IPs)
- [ ] fail2ban installed and configured for SSH and app
- [ ] Unattended upgrades enabled for security patches
- [ ] No unnecessary services running (`systemctl list-units --type=service`)
- [ ] Separate non-root user for application process

**Docker hardening:**
- [ ] Non-root user defined in Dockerfile (`USER appuser`)
- [ ] Read-only root filesystem where possible (`--read-only`)
- [ ] No `--privileged` containers in production
- [ ] Image scanned for CVEs (`docker scout cves` or `trivy image`)
- [ ] `.dockerignore` excludes `.env`, `.git`, test files
- [ ] Base images pinned to digest, not `latest`

**Database hardening:**
- [ ] Application uses least-privilege DB user (no superuser)
- [ ] DB not accessible from public internet (private subnet only)
- [ ] Connections encrypted (SSL/TLS enforced)
- [ ] Backups encrypted at rest
- [ ] Audit logging enabled for sensitive tables

---

## `/security compliance`

Generate a compliance checklist for the specified standard.

**Input:** Specify SOC2, GDPR, or PCI-DSS (or all).

### SOC2 (Trust Service Criteria)

**CC6 — Logical and Physical Access:**
- [ ] MFA enforced for all production access
- [ ] Access reviewed quarterly and on role change
- [ ] SSH keys rotated annually, unused keys revoked
- [ ] Privileged access monitored and logged

**CC7 — System Operations:**
- [ ] Security events logged and alerts configured
- [ ] Log retention ≥ 90 days (1 year for audit purposes)
- [ ] Incident response plan documented and tested
- [ ] Vulnerability scanning on schedule (monthly minimum)

**CC8 — Change Management:**
- [ ] All changes via PR with review
- [ ] No direct commits to main/production
- [ ] Deployment pipeline enforces tests and scans
- [ ] Rollback procedure documented

### GDPR

- [ ] Data inventory: all personal data mapped (what, where, why, how long)
- [ ] Legal basis documented for each processing activity
- [ ] Privacy policy up to date and accessible
- [ ] Consent management implemented where required
- [ ] Right to access: mechanism to export user data
- [ ] Right to deletion: mechanism to purge user data
- [ ] Data breach notification procedure documented (72-hour window)
- [ ] DPA signed with all third-party processors
- [ ] Data transfer mechanisms for non-EU processors

### PCI-DSS (if handling card data)

- [ ] Never log or store full card numbers, CVV, or magnetic stripe data
- [ ] Card data scoped to PCI-compliant provider (Stripe, Braintree) — do not touch raw card data
- [ ] Network segmentation between cardholder data environment and rest of system
- [ ] Quarterly ASV scans and annual penetration test

---

## Trigger Phrases

`security audit`, `OWASP review`, `check for vulnerabilities`, `security review`,
`scan for secrets`, `secret scan`, `hardening checklist`, `secure this`,
`compliance check`, `SOC2 checklist`, `GDPR compliance`, `PCI-DSS`,
`CVE audit`, `dependency vulnerabilities`, `npm audit`, `composer audit`

---

## Anti-Patterns

| Anti-Pattern | Correct Approach |
|---|---|
| Secrets in `.env` committed to git | Rotate immediately, use Secrets Manager or Vault |
| Wildcard CORS in production | Restrict to known origins explicitly |
| `eval()` with user input | Never — use safe parsing alternatives |
| SQL queries with string concatenation | Always use parameterised queries / ORM |
| Catching all exceptions silently | Log and alert on security-relevant errors |
| Skipping secret scan in CI | Add trufflehog/gitleaks as a required CI step |
| Storing plain-text passwords | bcrypt or argon2 with cost factor ≥ 12 |
| Ignoring CVEs indefinitely | Track and remediate on schedule; document exceptions |
| Root user for application process | Dedicated non-root user with minimal permissions |
| Debug mode in production | `APP_DEBUG=false`, `APP_ENV=production` |

---

## References

| File | Purpose |
|------|---------|
| `references/owasp-checklist.md` | OWASP Top 10 (2021) with detection and prevention per category |
| `references/dependency-audit.md` | Per-ecosystem audit commands, CI integration, remediation workflow |
| `references/hardening-patterns.md` | SSH config, security headers, Docker hardening, secret management |

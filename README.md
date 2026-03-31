# git-safety

Git safety hooks and pre-commit configuration for Backend teams.

Prevents accidental commits of `.env` files, secrets, and destructive force pushes that close open PRs.

## What's inside

```
.pre-commit-config.yaml   # pre-commit framework config (gitleaks + standard hooks)
.gitignore                # blocks .env from this repo itself
.env.example              # safe template — copy to .env and fill in values

scripts/
  setup-git-hooks.sh      # one-command setup for any repo

tools/
  git-hooks/
    pre-commit            # blocks .env files + scans for hardcoded secrets
    pre-push              # blocks force-push to main/master/develop/release

test/
  run-tests.sh            # verifies hooks are working correctly
```

## Setup (run once per repo)

**Step 1 — Clone this repo:**
```bash
git clone git@github.com:<your-org>/git-safety.git
```

**Step 2 — Install hooks into your target repo:**  
Copy `scripts/setup-git-hooks.sh` into your repo and run it:
```bash
bash scripts/setup-git-hooks.sh
```

Or run it directly from this repo pointing at another repo:
```bash
ROOT_DIR=/path/to/your-repo bash scripts/setup-git-hooks.sh
```

**Step 3 — (Recommended) Install the pre-commit framework:**
```bash
brew install pre-commit       # macOS
pre-commit install            # run inside your target repo
```

---

## Testing hooks on this repo

This repo is also a test bed. After setup:

```bash
# Install hooks into this repo itself
bash scripts/setup-git-hooks.sh

# Run all automated tests
bash test/run-tests.sh
```

Expected output:
```
=== Running pre-commit hook tests ===

  ✓ PASS: .env file commit — correctly blocked
  ✓ PASS: .env.local file commit — correctly blocked
  ✓ PASS: .env.production file commit — correctly blocked
  ✓ PASS: Private key in file — correctly blocked
  ✓ PASS: Hardcoded password in source — correctly blocked
  ✓ PASS: Hardcoded API key in source — correctly blocked
  ✓ PASS: .env.example (template, safe) — correctly allowed
  ✓ PASS: Normal Go source file — correctly allowed
  ✓ PASS: README with env var docs — correctly allowed

=== Results: 9 passed, 0 failed ===
```

---

## What each layer blocks

| Layer | Tool | What it stops |
|---|---|---|
| pre-commit hook | `tools/git-hooks/pre-commit` | `.env` files, `.pem`/`.key` files, hardcoded secrets (see patterns below) |
| pre-push hook | `tools/git-hooks/pre-push` | Force push to `main`/`master`/`develop`/`release` |
| pre-commit framework | gitleaks | Deep secret scan using regex patterns across entire diff |
| Branch protection | GitHub settings | Ultimate backstop — cannot be bypassed with `--no-verify` |

### Secret patterns detected by pre-commit hook

The hook catches hardcoded secrets in various naming conventions across different languages:

**Supported patterns:**
- `password`, `db_password`, `dbPassword`, `PASSWORD` 
- `secret`, `secret_key`, `secretKey`, `SECRET_KEY`, `client_secret`, `clientSecret`
- `api_key`, `apiKey`, `API_KEY`, `api_secret`, `apiSecret`
- `access_token`, `accessToken`, `ACCESS_TOKEN`
- `private_key`, `privateKey`, `PRIVATE_KEY`
- `auth_token`, `authToken`, `AUTH_TOKEN`
- `jwt_secret`, `jwtSecret`, `JWT_SECRET`

**Example code that will be blocked:**
```go
const secret_key = "abc123"           // ❌ Blocked
var apiKey = "sk-live-123"            // ❌ Blocked  
clientSecret := "oauth-secret"        // ❌ Blocked
```

```python
SECRET_KEY = "django-secret-123"      # ❌ Blocked
api_key = "prod-api-key"              # ❌ Blocked
```

```javascript
const secretKey = "my-secret"         // ❌ Blocked
let auth_token = "bearer-token"       // ❌ Blocked
```

**Safe alternatives that won't be blocked:**
```go
secret := os.Getenv("SECRET_KEY")     // ✅ Safe - uses env var
apiKey := config.GetAPIKey()          // ✅ Safe - uses config
```

---

## Why this exists

A team member ran this sequence which **closed all open PRs** on GitHub:

```bash
git add .                              # accidentally staged .env
git commit --amend && git push --force # pushed secret to remote
git filter-repo --force --path .env --invert-paths  # rewrote all branch SHAs
git push origin --force --all          # force-pushed every branch → PR base SHAs gone
```

These hooks stop the chain at step 1 and step 4.

---

## Dangerous commands to avoid

```bash
# ❌ These can close all open PRs or leak secrets
git push origin --force --all
git filter-repo --force ...
git add .                     # use: git add -p  or  git add <file>

# ✅ Safe alternatives
git add -p                    # review each hunk interactively  
git add <specific-file>       # explicit staging
git safe-push origin <branch> # alias installed by setup script
```

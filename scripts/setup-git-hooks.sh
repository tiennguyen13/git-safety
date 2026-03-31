#!/usr/bin/env bash
# scripts/setup-git-hooks.sh
# Run once after cloning: bash scripts/setup-git-hooks.sh
# Sets up:
#   1. Git hooks (pre-commit, pre-push)
#   2. pre-commit framework (if available)
#   3. Useful git aliases that warn before dangerous operations

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Get the directory where this script is located (git-safety repo)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_SAFETY_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# ROOT_DIR is the target repository where hooks will be installed
ROOT_DIR="${ROOT_DIR:-$(git rev-parse --show-toplevel)}"

# Validate that ROOT_DIR is a git repository
if [ ! -d "$ROOT_DIR/.git" ]; then
  echo -e "${RED}✗${NC} ERROR: $ROOT_DIR is not a git repository"
  echo "  Make sure you're in a git repository or set ROOT_DIR to a valid git repo path"
  exit 1
fi

# Hooks source is always from the git-safety repo, destination is the target repo
HOOKS_SRC="$GIT_SAFETY_ROOT/tools/git-hooks"
HOOKS_DEST="$ROOT_DIR/.git/hooks"

# Validate that hooks source directory exists
if [ ! -d "$HOOKS_SRC" ]; then
  echo -e "${RED}✗${NC} ERROR: Git hooks directory not found at $HOOKS_SRC"
  echo "  Make sure you're running this script from the git-safety repository"
  exit 1
fi

echo ""
echo "=== Backend Team — Git Safety Setup ==="
echo "  Target repository: $ROOT_DIR"
echo ""

# --- 1. Install git hooks ---
echo "▶ Installing git hooks..."
for HOOK in pre-commit pre-push; do
  if [ -f "$HOOKS_SRC/$HOOK" ]; then
    cp "$HOOKS_SRC/$HOOK" "$HOOKS_DEST/$HOOK"
    chmod +x "$HOOKS_DEST/$HOOK"
    echo -e "  ${GREEN}✓${NC} $HOOK installed"
  fi
done

# --- 2. Install pre-commit framework if available ---
echo ""
echo "▶ Checking for pre-commit framework..."
if command -v pre-commit &>/dev/null; then
  (cd "$ROOT_DIR" && pre-commit install)
  echo -e "  ${GREEN}✓${NC} pre-commit framework installed (runs gitleaks on every commit)"
else
  echo -e "  ${YELLOW}⚠${NC}  pre-commit not found. Recommended:"
  echo "      brew install pre-commit   # macOS"
  echo "      pip install pre-commit    # Python"
  echo "      Then run: pre-commit install"
fi

# --- 3. Set up git aliases for safer operations ---
echo ""
echo "▶ Setting up git safety aliases (repo-local)..."

# Alias: safe-push warns if you're about to --force --all
git -C "$ROOT_DIR" config alias.safe-push '!f() { \
  if echo "$@" | grep -q -- "--force"; then \
    echo ""; \
    echo "⚠️  You are about to force push. This rewrites history and CLOSES all open PRs."; \
    echo "   Are you sure? Type YES to continue:"; \
    read CONFIRM; \
    if [ "$CONFIRM" != "YES" ]; then echo "Aborted."; return 1; fi; \
  fi; \
  git push "$@"; \
}; f'

# Alias: check-env → shows what .env files exist and their gitignore status
git -C "$ROOT_DIR" config alias.check-env '!git ls-files --others --exclude-standard | grep -E "(^|/)\.env($|\\.)" || echo "No untracked .env files found."'

echo -e "  ${GREEN}✓${NC} git safe-push — warns before any --force push"
echo -e "  ${GREEN}✓${NC} git check-env — lists any untracked .env files"

# --- 4. Verify .env is in .gitignore ---
echo ""
echo "▶ Checking .gitignore for .env coverage..."
GITIGNORE="$ROOT_DIR/.gitignore"
if [ -f "$GITIGNORE" ]; then
  if grep -qE "^\.env$|^\.env\." "$GITIGNORE"; then
    echo -e "  ${GREEN}✓${NC} .env is already in .gitignore"
  else
    echo -e "  ${RED}✗${NC} WARNING: .env is NOT in .gitignore — adding..."
    echo "" >> "$GITIGNORE"
    echo "# Secret / environment files — never commit these" >> "$GITIGNORE"
    echo ".env" >> "$GITIGNORE"
    echo ".env.*" >> "$GITIGNORE"
    echo "!.env.example" >> "$GITIGNORE"
    echo -e "  ${GREEN}✓${NC} Added .env rules to .gitignore"
  fi
else
  echo -e "  ${YELLOW}⚠${NC}  No .gitignore found at repo root. Creating one..."
  echo ".env" > "$GITIGNORE"
  echo ".env.*" >> "$GITIGNORE"
  echo "!.env.example" >> "$GITIGNORE"
fi

echo ""
echo -e "${GREEN}=== Setup complete! ===${NC}"
echo ""
echo "  What's protected now:"
echo "  • pre-commit hook: blocks .env files and scans for secrets"
echo "  • pre-push hook:   blocks force-push to main/master/develop/release"
echo "  • git safe-push:   interactive confirmation before any --force"
echo ""
echo "  Team reminder: avoid 'git add .' — use 'git add -p' or 'git add <file>'"
echo ""

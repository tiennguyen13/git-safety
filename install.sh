#!/usr/bin/env bash
# install.sh — standalone installer for git-safety hooks
#
# cd into your project root, then run one of:
#
#   # From git (no prior clone needed):
#   bash <(curl -fsSL https://raw.githubusercontent.com/tiennguyen13/git-safety/main/install.sh)
#
#   # Or pass an explicit target path:
#   bash install.sh /path/to/your-repo
#
# The script clones git-safety into a temp dir, runs setup, then cleans up.

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

GIT_SAFETY_REPO="https://github.com/tiennguyen13/git-safety.git"
TARGET="${1:-$PWD}"

# Validate target is a git repository
if [ ! -d "$TARGET/.git" ]; then
  echo -e "${RED}✗${NC} ERROR: '$TARGET' is not a git repository."
  echo ""
  echo "  Either cd into your project root first:"
  echo "    cd /path/to/your-repo"
  echo "    bash <(curl -fsSL https://raw.githubusercontent.com/tiennguyen13/git-safety/main/install.sh)"
  echo ""
  echo "  Or pass the path as an argument:"
  echo "    bash install.sh /path/to/your-repo"
  exit 1
fi

TMPDIR="$(mktemp -d)"
trap 'rm -rf "$TMPDIR"' EXIT

echo "Fetching git-safety..."
git clone --depth=1 --quiet "$GIT_SAFETY_REPO" "$TMPDIR/git-safety"

ROOT_DIR="$TARGET" bash "$TMPDIR/git-safety/scripts/setup-git-hooks.sh"

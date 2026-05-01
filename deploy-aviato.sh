#!/bin/bash
# ============================================================
# AVIATO — One-shot deploy script for Mac
# Usage: bash deploy-aviato.sh
# ============================================================

set -e  # Stop on any error

# ── COLORS ──────────────────────────────────────────────────
GREEN='\033[0;32m'
GOLD='\033[0;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

echo ""
echo -e "${GOLD}${BOLD}  ██████████████████████████████████████${NC}"
echo -e "${GOLD}${BOLD}  ██  AVIATO — Deploy Script  v1.0   ██${NC}"
echo -e "${GOLD}${BOLD}  ██████████████████████████████████████${NC}"
echo ""

# ── STEP 0: Check dependencies ──────────────────────────────
echo -e "${CYAN}[0/5] Checking dependencies...${NC}"

if ! command -v git &>/dev/null; then
  echo -e "${RED}✗ Git not found. Install via: xcode-select --install${NC}"
  exit 1
fi

if ! command -v node &>/dev/null; then
  echo -e "${RED}✗ Node.js not found. Download from: https://nodejs.org${NC}"
  exit 1
fi

if ! command -v vercel &>/dev/null; then
  echo -e "${GOLD}→ Vercel CLI not found. Installing...${NC}"
  npm install -g vercel
fi

echo -e "${GREEN}✓ All dependencies ready${NC}"
echo ""

# ── STEP 1: Collect inputs ───────────────────────────────────
GITHUB_USERNAME="shyamr97"
REPO_NAME="aviato-website"

echo -e "${CYAN}[1/5] Setup${NC}"
echo -e "GitHub username : ${BOLD}${GITHUB_USERNAME}${NC}"
echo -e "Repo name       : ${BOLD}${REPO_NAME}${NC}"
echo ""

echo -e "${BOLD}Paste your GitHub Personal Access Token (input hidden):${NC}"
read -s GITHUB_TOKEN
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
  echo -e "${RED}✗ Token cannot be empty. Exiting.${NC}"
  exit 1
fi

echo -e "${GREEN}✓ Token received${NC}"
echo ""

# ── STEP 2: Locate website files ────────────────────────────
echo -e "${CYAN}[2/5] Locating your Aviato files...${NC}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Check for required files in the same folder as this script
MISSING=0
for FILE in index.html style.css main.js; do
  if [ ! -f "$SCRIPT_DIR/$FILE" ]; then
    echo -e "${RED}✗ Missing: $FILE${NC}"
    MISSING=1
  else
    echo -e "${GREEN}✓ Found: $FILE${NC}"
  fi
done

if [ "$MISSING" -eq 1 ]; then
  echo ""
  echo -e "${RED}Put index.html, style.css and main.js in the same folder as this script, then re-run.${NC}"
  exit 1
fi

echo ""

# ── STEP 3: Create GitHub repo ───────────────────────────────
echo -e "${CYAN}[3/5] Creating GitHub repository '${REPO_NAME}'...${NC}"

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" \
  -X POST \
  -H "Authorization: token ${GITHUB_TOKEN}" \
  -H "Accept: application/vnd.github.v3+json" \
  https://api.github.com/user/repos \
  -d "{
    \"name\": \"${REPO_NAME}\",
    \"description\": \"Aviato — Website Design Agency\",
    \"private\": false,
    \"auto_init\": false
  }")

if [ "$HTTP_STATUS" -eq 201 ]; then
  echo -e "${GREEN}✓ Repo created: github.com/${GITHUB_USERNAME}/${REPO_NAME}${NC}"
elif [ "$HTTP_STATUS" -eq 422 ]; then
  echo -e "${GOLD}⚠ Repo already exists — continuing with push${NC}"
else
  echo -e "${RED}✗ Failed to create repo (HTTP $HTTP_STATUS). Check your token permissions.${NC}"
  exit 1
fi

echo ""

# ── STEP 4: Push files to GitHub ────────────────────────────
echo -e "${CYAN}[4/5] Pushing files to GitHub...${NC}"

# Work in a temp build folder
BUILD_DIR=$(mktemp -d)
cp "$SCRIPT_DIR/index.html" "$BUILD_DIR/"
cp "$SCRIPT_DIR/style.css"  "$BUILD_DIR/"
cp "$SCRIPT_DIR/main.js"    "$BUILD_DIR/"

cd "$BUILD_DIR"

git init -q
git config user.email "deploy@aviato.design"
git config user.name  "Aviato Deploy"

# Add a minimal vercel.json so Vercel serves index.html correctly
cat > vercel.json << 'VEOF'
{
  "version": 2,
  "builds": [{ "src": "*.html", "use": "@vercel/static" }],
  "routes": [{ "src": "/(.*)", "dest": "/$1" }]
}
VEOF

git add .
git commit -q -m "🚀 Initial deploy — Aviato website"

REMOTE="https://${GITHUB_TOKEN}@github.com/${GITHUB_USERNAME}/${REPO_NAME}.git"
git branch -M main
git remote add origin "$REMOTE"
git push -u origin main -q 2>/dev/null

echo -e "${GREEN}✓ Files pushed to github.com/${GITHUB_USERNAME}/${REPO_NAME}${NC}"
echo ""

# ── STEP 5: Deploy to Vercel ─────────────────────────────────
echo -e "${CYAN}[5/5] Deploying to Vercel...${NC}"
echo -e "${GOLD}→ If Vercel asks questions, press Enter to accept defaults${NC}"
echo -e "${GOLD}→ When asked 'Link to existing project?' → type N${NC}"
echo -e "${GOLD}→ When asked project name → type: aviato-website${NC}"
echo ""

VERCEL_OUTPUT=$(vercel --prod --yes --name aviato-website 2>&1)
VERCEL_URL=$(echo "$VERCEL_OUTPUT" | grep -o 'https://[^[:space:]]*\.vercel\.app' | tail -1)

if [ -n "$VERCEL_URL" ]; then
  echo ""
  echo -e "${GOLD}${BOLD}  ████████████████████████████████████████████${NC}"
  echo -e "${GOLD}${BOLD}  ██                                        ██${NC}"
  echo -e "${GOLD}${BOLD}  ██   🚀 AVIATO IS LIVE!                   ██${NC}"
  echo -e "${GOLD}${BOLD}  ██                                        ██${NC}"
  echo -e "${GREEN}${BOLD}  ██   $VERCEL_URL${NC}"
  echo -e "${GOLD}${BOLD}  ██                                        ██${NC}"
  echo -e "${GOLD}${BOLD}  ████████████████████████████████████████████${NC}"
  echo ""
  echo -e "GitHub repo : ${CYAN}https://github.com/${GITHUB_USERNAME}/${REPO_NAME}${NC}"
  echo -e "Vercel dash : ${CYAN}https://vercel.com/dashboard${NC}"
  echo ""
  echo -e "${BOLD}To add a custom domain:${NC}"
  echo -e "  1. Go to vercel.com/dashboard → your project → Settings → Domains"
  echo -e "  2. Enter your domain and follow the DNS instructions"
  echo ""

  # Open the live site in browser
  open "$VERCEL_URL"
else
  echo -e "${GOLD}⚠ Could not auto-detect URL. Check vercel.com/dashboard for your live link.${NC}"
  echo ""
  echo "$VERCEL_OUTPUT"
fi

# Cleanup temp dir
cd "$SCRIPT_DIR"
rm -rf "$BUILD_DIR"

echo -e "${GREEN}✓ All done. Aviato is live! ✦${NC}"
echo ""

#!/bin/bash
# =============================================================================
# regression_test.sh — Howard D8 Multisite Playwright Regression Tests
# =============================================================================
#
# PURPOSE
#   Runs Playwright visual regression tests comparing a reference environment
#   (default: prod) against a target environment (default: dev) for all sites
#   in the selected Howard Drupal multisite application.
#
#   Screenshots of the reference environment are captured as baselines and
#   stored locally. Subsequent comparison runs diff the target environment's
#   screenshots against those baselines pixel-by-pixel, opening an HTML report
#   to review any differences visually.
#
# WORKFLOW
#   1. Capture prod as the baseline (golden reference):
#        sh regression_test.sh hud8        → choose "Update baselines"
#        sh regression_test.sh hud8 dev prod  → via CLI args
#
#   2. Compare dev against the baseline:
#        sh regression_test.sh hud8        → choose "Run comparison"
#        sh regression_test.sh hud8 dev prod  → via CLI args
#
#   3. Update baselines AND run comparison in one step:
#        sh regression_test.sh hud8        → choose "Both"
#
# CLI MODE
#   sh regression_test.sh [app] [test_env] [baseline_env] [action]
#     app:          hud8 | academicdepartments | howardenterprise | centers | uxws
#     test_env:     dev | test | prod
#     baseline_env: prod | test | dev
#     action:       baseline | compare | both
#
#   Examples:
#     sh regression_test.sh hud8 dev prod compare
#     sh regression_test.sh centers test prod both
#
# DOCS
#   ~/Sites/_hal/docs/scripts/regression_test.md
#
# ENVIRONMENTS
#   dev   → https://dev.<domain>   (Shield: huweb:huweb applied automatically)
#   test  → https://stg.<domain>   (Shield: huweb:huweb applied automatically)
#   prod  → https://<domain>       (no auth required)
#
# LOGIN SUPPORT
#   To test authenticated pages, add a "login" block to a site entry in the
#   generated sites.json after the script writes it. The block is preserved on
#   subsequent runs as long as you do not delete sites.json between runs.
#
#   Login block format:
#     "login": {
#       "path": "/user/login",
#       "username_selector": "#edit-name",
#       "password_selector": "#edit-pass",
#       "submit_selector": "#edit-submit",
#       "username": "your.user@howard.edu",
#       "password": "yourpassword"
#     }
#
# SNAPSHOT STORAGE
#   Baselines are stored in ~/Sites/_hal/playwright/snapshots/<app>/
#   They are gitignored and persist between runs on your local machine.
#   Delete this directory to reset all baselines for an app.
#
# DIFF TOLERANCE
#   Default: 2% of pixels may differ (maxDiffPixelRatio: 0.02).
#   Sites with dynamic content (rotating banners, live timestamps) may need
#   a higher value. Edit playwright/tests/regression.spec.js to adjust.
#
# DEPENDENCIES
#   Node.js  — brew install node
#   Playwright dependencies are installed automatically on first run.
#
# SCOPE
#   Local — Playwright runs on your machine and hits live Acquia URLs.
#   No changes are made to any remote environment.
#
# =============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HAL_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
PLAYWRIGHT_DIR="$HAL_ROOT/playwright"
SITES_JSON="$PLAYWRIGHT_DIR/sites.json"

source "$HAL_ROOT/hal_config.txt"
source "$SCRIPT_DIR/partials/select_app_and_env.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo "=============================================="
echo " HAL Regression Tests"
echo "=============================================="

# =============================================================================
# DEPENDENCY CHECK
# =============================================================================

# Load nvm so we can switch Node versions. Playwright requires Node 20+.
# playwright/.nvmrc pins the required version; nvm use picks it up automatically.
export NVM_DIR="$HOME/.nvm"
if [[ -s "$NVM_DIR/nvm.sh" ]]; then
  source "$NVM_DIR/nvm.sh"
else
  printf "${YELLOW}⚠  nvm not found at $NVM_DIR — using system Node${NC}\n"
fi

if ! command -v node &>/dev/null; then
  printf "${RED}✗ Node.js is not installed.${NC}\n"
  printf "  Install via: brew install node  or  nvm install 22\n"
  exit 1
fi

# Switch to the Node version specified in playwright/.nvmrc (Node 22).
# This ensures Playwright's minimum requirement (Node 20+) is always met.
cd "$PLAYWRIGHT_DIR"
if command -v nvm &>/dev/null; then
  nvm use --silent 2>/dev/null || nvm use 2>/dev/null || true
fi
cd "$HAL_ROOT"

# Capture the active Node bin directory so subprocesses (show-report) use Node 22.
NVM_BIN="$(command -v node | xargs dirname 2>/dev/null)"

NODE_VER=$(node -e "process.stdout.write(process.version)" 2>/dev/null)
printf "Node: %s\n" "$NODE_VER"

if ! command -v npm &>/dev/null; then
  printf "${RED}✗ npm is not installed.${NC}\n"
  exit 1
fi

# Install Playwright and its Chromium browser on first run.
if [[ ! -d "$PLAYWRIGHT_DIR/node_modules" ]]; then
  printf "\n${YELLOW}Installing Playwright (first-time setup)...${NC}\n"
  cd "$PLAYWRIGHT_DIR" && npm install && npx playwright install chromium
  printf "${GREEN}✓ Playwright installed${NC}\n"
  cd "$HAL_ROOT"
fi

# =============================================================================
# APP SELECTION (single app only — running all apps at once would be very slow)
# =============================================================================

APP_NAME=""

if [[ -n "$1" ]]; then
  _arg="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  _arg="${_arg#@}"
  APP_NAME="$_arg"
  SELECTED_APP="@${_arg}"
  printf "App:  $SELECTED_APP\n"
else
  echo ""
  printf "${BOLD}Select a Howard Application:${NC}\n"
  printf "  (regression tests run against one app at a time)\n\n"
  PS3="Enter number: "
  APP_LABELS=("hud8" "academicdepartments" "howardenterprise" "centers" "uxws")
  select _choice in "${APP_LABELS[@]}"; do
    if [[ -z "$_choice" ]]; then
      printf '"%s" is not a valid choice\n' "$REPLY" >&2
    else
      APP_NAME="$_choice"
      SELECTED_APP="@${_choice}"
      break
    fi
  done
fi

LOCAL_FOLDER="$(get_local_folder_for_app "$SELECTED_APP")"
if [[ -z "$LOCAL_FOLDER" || ! -d "$LOCAL_FOLDER" ]]; then
  printf "${RED}✗ Could not find local folder for $SELECTED_APP${NC}\n"
  exit 1
fi

# =============================================================================
# ENVIRONMENT SELECTION
# =============================================================================

TEST_ENV=""
BASELINE_ENV=""

if [[ -n "$2" ]]; then
  TEST_ENV="$2"
fi

if [[ -n "$3" ]]; then
  BASELINE_ENV="$3"
fi

if [[ -z "$TEST_ENV" ]]; then
  echo ""
  printf "${BOLD}Select test environment (the environment to compare):${NC}\n"
  PS3="Enter number: "
  select _env in "dev" "test" "prod"; do
    if [[ -n "$_env" ]]; then TEST_ENV="$_env"; break; fi
  done
fi

if [[ -z "$BASELINE_ENV" ]]; then
  echo ""
  printf "${BOLD}Select baseline environment (the golden reference to compare against):${NC}\n"
  PS3="Enter number: "
  select _env in "prod" "test" "dev"; do
    if [[ -n "$_env" ]]; then BASELINE_ENV="$_env"; break; fi
  done
fi

# =============================================================================
# ACTION SELECTION
# =============================================================================

ACTION=""

if [[ -n "$4" ]]; then
  ACTION="$4"
fi

if [[ -z "$ACTION" ]]; then
  echo ""
  printf "${BOLD}What would you like to do?${NC}\n"
  PS3="Enter number: "
  select _action in \
    "Update baselines (capture $BASELINE_ENV screenshots as reference)" \
    "Run comparison ($TEST_ENV vs $BASELINE_ENV baseline)" \
    "Both (update baselines, then run comparison)"; do
    case "$REPLY" in
      1) ACTION="baseline"; break ;;
      2) ACTION="compare";  break ;;
      3) ACTION="both";     break ;;
      *) printf 'Invalid choice\n' >&2 ;;
    esac
  done
fi

# =============================================================================
# CONFIRMATION
# =============================================================================

echo ""
echo "----------------------------------------------"
printf "  App:       ${BOLD}%s${NC}\n"  "$SELECTED_APP"
printf "  Baseline:  ${BOLD}%s${NC}\n"  "$BASELINE_ENV"
printf "  Test env:  ${BOLD}%s${NC}\n"  "$TEST_ENV"
printf "  Action:    ${BOLD}%s${NC}\n"  "$ACTION"
printf "  Snapshots: %s\n"  "$PLAYWRIGHT_DIR/snapshots/$APP_NAME/"
echo "----------------------------------------------"
echo ""
read -rp "Proceed? [y/N] " _confirm
[[ "$_confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# =============================================================================
# SITE DISCOVERY — matches site_status_check.sh logic
# =============================================================================

SITES_DIR="$LOCAL_FOLDER/docroot/sites"
if [[ ! -d "$SITES_DIR" ]]; then
  printf "${RED}✗ Sites directory not found: $SITES_DIR${NC}\n"
  exit 1
fi

SITE_DOMAINS=()
for _dir in "$SITES_DIR"/*/; do
  _domain="$(basename "$_dir")"
  [[ "$_domain" == *".howard.edu"* ]] || continue
  SITE_DOMAINS+=("$_domain")
done

if [[ ${#SITE_DOMAINS[@]} -eq 0 ]]; then
  printf "${RED}✗ No *.howard.edu sites found in $SITES_DIR${NC}\n"
  exit 1
fi

printf "${BOLD}Discovered %d sites for %s${NC}\n" "${#SITE_DOMAINS[@]}" "$SELECTED_APP"

# =============================================================================
# GENERATE sites.json
# =============================================================================
# Node.js handles JSON generation and preserves existing "login" blocks if
# sites.json already exists. Using node avoids bash 4+ requirements
# (associative arrays, process substitution) that macOS bash 3.2 lacks.

SITES_JSON="$SITES_JSON" node - "${SITE_DOMAINS[@]}" << 'NODEJS'
const fs   = require('fs');
const path = require('path');
const sitesFile = process.env.SITES_JSON;
const domains   = process.argv.slice(2);

// Load existing sites.json to preserve hand-edited login blocks.
let existing = [];
if (fs.existsSync(sitesFile)) {
  try { existing = JSON.parse(fs.readFileSync(sitesFile, 'utf8')); } catch (e) {}
}

const sites = domains.map(domain => {
  const prev  = existing.find(s => s.domain === domain) || {};
  const entry = {
    domain,
    prod_url:  'https://' + domain,
    dev_url:   'https://dev.' + domain,
    test_url:  'https://stg.' + domain,
  };
  if (prev.login) entry.login = prev.login;
  return entry;
});

fs.writeFileSync(sitesFile, JSON.stringify(sites, null, 2) + '\n');
NODEJS

printf "  → %s written\n\n" "$SITES_JSON"

# =============================================================================
# RUN PLAYWRIGHT
# =============================================================================

mkdir -p "$PLAYWRIGHT_DIR/snapshots/$APP_NAME"

cd "$PLAYWRIGHT_DIR"

run_baseline() {
  printf "${YELLOW}━━━ Capturing baselines from: %s ━━━${NC}\n\n" "$BASELINE_ENV"
  HAL_APP_NAME="$APP_NAME" \
  HAL_TARGET_ENV="$BASELINE_ENV" \
  HAL_BASELINE_ENV="$BASELINE_ENV" \
  HAL_SHIELD_USER="huweb" \
  HAL_SHIELD_PASS="huweb" \
  npx playwright test --update-snapshots
  local _exit=$?
  echo ""
  if [[ $_exit -eq 0 ]]; then
    printf "${GREEN}✓ Baselines captured in playwright/snapshots/%s/${NC}\n" "$APP_NAME"
  else
    printf "${YELLOW}⚠  Some baselines could not be captured (sites may be down).${NC}\n"
    printf "   Report: file://%s/playwright-report/index.html\n" "$PLAYWRIGHT_DIR"
  fi
}

run_compare() {
  printf "${YELLOW}━━━ Comparing %s against %s baseline ━━━${NC}\n\n" "$TEST_ENV" "$BASELINE_ENV"
  HAL_APP_NAME="$APP_NAME" \
  HAL_TARGET_ENV="$TEST_ENV" \
  HAL_BASELINE_ENV="$BASELINE_ENV" \
  HAL_SHIELD_USER="huweb" \
  HAL_SHIELD_PASS="huweb" \
  npx playwright test
  local _exit=$?
  echo ""
  if [[ $_exit -eq 0 ]]; then
    printf "${GREEN}✓ All sites passed — no regressions detected${NC}\n"
  else
    printf "${RED}✗ Regressions detected — review the HTML report${NC}\n"
  fi
  # Generate the side-by-side comparison report from screenshots + snapshots.
  # cd first so __dirname-relative paths in the script resolve correctly.
  # Pass env vars explicitly — inline prefixes on the npx command above do not
  # persist in the current shell, so this subshell would otherwise inherit
  # HAL_APP_NAME=unknown and look in screenshots/unknown/ finding nothing.
  (cd "$PLAYWRIGHT_DIR" && \
    HAL_APP_NAME="$APP_NAME" \
    HAL_TARGET_ENV="$TEST_ENV" \
    HAL_BASELINE_ENV="$BASELINE_ENV" \
    node "$PLAYWRIGHT_DIR/generate-report.js")
  printf "\nOpening report...\n"
  open "$PLAYWRIGHT_DIR/playwright-report/comparison.html" 2>/dev/null \
    || printf "  → file://%s/playwright-report/comparison.html\n" "$PLAYWRIGHT_DIR"
}

case "$ACTION" in
  baseline) run_baseline ;;
  compare)  run_compare  ;;
  both)     run_baseline; run_compare ;;
  *)
    printf "${RED}✗ Unknown action: %s${NC}\n" "$ACTION"
    exit 1
    ;;
esac

cd "$HAL_ROOT"

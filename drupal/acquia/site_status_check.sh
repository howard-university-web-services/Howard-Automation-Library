#!/bin/bash
# =============================================================================
# site_status_check.sh — Howard D8 Multisite HTTP Status Checker
# =============================================================================
#
# PURPOSE
#   Performs an HTTP health check against every site in the selected Howard
#   Drupal multisite application(s) and environment(s). Site discovery is
#   driven by local docroot/sites/*.howard.edu folder presence, so results
#   always reflect what is actually deployed rather than what is listed in
#   sites.php.
#
# USAGE
#   sh ~/Sites/_hal/drupal/acquia/site_status_check.sh
#
# SCOPE
#   Remote — all curl requests hit live Acquia URLs. No local file changes.
#
# ENVIRONMENT → URL MAPPING
#   dev   →  https://dev.<domain>
#   test  →  https://stg.<domain>   (Acquia uses "stg" prefix for staging)
#   prod  →  https://<domain>
#
# AUTHENTICATION
#   All requests pass HTTP Basic Auth credentials (huweb:huweb) automatically.
#   This satisfies the Drupal Shield module on dev/test without manual entry.
#
# SSL HANDLING
#   Acquia dev and test environments commonly have self-signed or expired SSL
#   certificates. curl's -k flag (--insecure) is applied to all dev/test
#   requests. Prod requests verify SSL normally — a cert error on prod will
#   result in a connection failure (code 000) and will be flagged.
#
# SHIELD MODULE EXPECTATIONS
#   Shield is a Drupal HTTP Basic Auth layer used to gate non-prod access.
#   The expected state differs by environment:
#
#     dev / test  →  Shield UP   (401 without auth is correct)
#                    Shield DOWN  = ⚠ warning (site is publicly accessible)
#     prod        →  Shield DOWN  (site is live and public, as intended)
#                    Shield UP    = ⚠ warning (site may be accidentally gated)
#
#   Detection: a HEAD request without credentials is made first. A 401
#   response means Shield is UP. Any other status code means Shield is DOWN.
#
# PER-URL CHECKS (homepage of each site)
#   1. HTTP status code  — 2xx/3xx = UP (green ✓), other = flagged (red ✗)
#   2. Response time     — displayed in seconds alongside the status code
#   3. Page <title>      — extracted from the HTML response body
#   4. Shield status     — UP or DOWN, evaluated against per-env expectations
#   5. Maintenance mode  — searches body for "currently under maintenance"
#   6. Drupal error page — searches body for "encountered an unexpected error"
#
# NAV PAGE SAMPLING (optional, prompted at runtime)
#   When enabled, after each successful homepage check the script:
#     1. Parses all href attributes from the homepage body
#     2. Filters to internal relative paths only, excluding system paths
#        (/admin, /user, /node/, /sites/, /modules/, /themes/, /core/) and
#        static asset extensions (.pdf, .jpg, .css, .js, etc.)
#     3. Groups paths by depth:
#          Level 1:  /segment           (top-level nav items)
#          Level 2:  /segment/segment   (sub-nav / dropdown items)
#     4. Randomly selects up to 3 from each level (Fisher-Yates shuffle)
#     5. Checks each selected page for: HTTP status, response time, title,
#        maintenance mode, and Drupal errors (no Shield re-check per page)
#
#   Note: nav sampling adds up to 6 additional requests per site/env. For
#   large sweeps (All Apps + All Envs) this significantly increases runtime.
#   Consider scoping to a single app or prod-only when using nav sampling.
#
# SUMMARY OUTPUT
#   After all checks, the script prints:
#     - Total UP vs flagged counts
#     - Content warnings list (Shield issues, maintenance mode, Drupal errors)
#     - Flagged URLs list (connection failures, HTTP 4xx/5xx responses)
#
# OUTPUT STATUS CODES
#   000  — Connection failure, DNS error, or request timeout
#   401  — Authenticated request was rejected (credential mismatch)
#   4xx  — Client error (404 Not Found, 403 Forbidden, etc.)
#   5xx  — Server error (Drupal crash, PHP fatal, or database issue)
#
# DEPENDENCIES
#   curl  — HTTP requests, response body capture, and timing
#   awk   — Float formatting, Fisher-Yates shuffle for nav sampling
#
# =============================================================================

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

AUTH="huweb:huweb"
TIMEOUT=10
UP=0
DOWN=0
FLAGGED=()
WARNINGS=()
LAST_BODY=""
LAST_STATUS=""

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# check_url — Full homepage health check for a single URL.
#
# Makes two requests per call:
#   1. A HEAD request WITHOUT credentials to detect Shield module state
#   2. A GET request WITH credentials to capture body, status code, and timing
#
# Parameters:
#   $1  url       — Full URL to check (e.g., https://admission.howard.edu)
#   $2  insecure  — Pass "k" to skip SSL cert verification; empty string for prod
#   $3  env       — "dev", "test", or "prod" — controls Shield expectation logic
#
# Side effects:
#   Sets globals LAST_BODY and LAST_STATUS so check_nav_sample() can reuse
#   the already-fetched page body without issuing a second request.
#   Appends to WARNINGS[], FLAGGED[], and increments UP/DOWN counters.
check_url() {
    local url="$1"
    local insecure="$2"
    local env="$3"
    local curl_opts=(-s --max-time "$TIMEOUT" --connect-timeout 5 -L)
    [[ -n "$insecure" ]] && curl_opts+=(-k)

    # --- Shield detection ---
    # Issue a HEAD request without auth credentials and without following
    # redirects (-L omitted) so we see the raw first-hop response code.
    # A 401 means Shield is active and blocking unauthenticated access.
    local no_auth_code
    no_auth_code=$(curl -s --max-time 5 --connect-timeout 3 \
        ${insecure:+-k} -I -o /dev/null -w "%{http_code}" "$url" 2>/dev/null)
    local shield_up=0
    [[ "$no_auth_code" == "401" ]] && shield_up=1

    # Evaluate Shield state against per-environment expectations:
    #   dev/test → Shield UP   is expected (gated from public access)
    #   prod     → Shield DOWN is expected (live and publicly accessible)
    # Unexpected states are surfaced as yellow ⚠ warnings in the summary.
    local shield_label shield_warn=""
    if [[ "$env" == "prod" ]]; then
        if [[ $shield_up -eq 0 ]]; then
            shield_label="${GREEN}Shield: DOWN${NC}"
        else
            shield_label="${YELLOW}Shield: UP (unexpected on prod)${NC}"
            shield_warn="Shield UP on prod"
        fi
    else
        if [[ $shield_up -eq 1 ]]; then
            shield_label="${GREEN}Shield: UP${NC}"
        else
            shield_label="${YELLOW}Shield: DOWN (expected UP on ${env})${NC}"
            shield_warn="Shield DOWN on ${env}"
        fi
    fi

    # --- Main authenticated GET request ---
    # We append a sentinel string to the response via curl's -w write-out
    # option. This lets us extract the HTTP status code and total request time
    # from the same call that returns the body, avoiding a separate request or
    # temp file. The sentinel is stripped from the body before content checks.
    local raw code time_val body title
    raw=$(curl "${curl_opts[@]}" \
        -u "$AUTH" \
        -w "___CURL_END_STATUS:%{http_code}_TIME:%{time_total}___" \
        "$url" 2>/dev/null)

    code=$(echo "$raw" | grep -o 'STATUS:[0-9]*' | cut -d: -f2)
    time_val=$(echo "$raw" | grep -o '_TIME:[0-9.]*' | sed 's/_TIME://')
    body=$(echo "$raw" | sed 's/___CURL_END_STATUS:.*//g')

    # Expose body and status globally so check_nav_sample() can parse internal
    # links from the already-fetched homepage without a second network request.
    LAST_BODY="$body"
    LAST_STATUS="$code"

    # Extract the page <title>. The xargs call trims leading/trailing whitespace.
    # head -1 guards against malformed pages with duplicate <title> elements.
    title=$(echo "$body" | grep -oi '<title>[^<]*</title>' | sed 's/<[^>]*>//g' | head -1 | tr -s ' ' | xargs 2>/dev/null)

    # Format response time as a 2-decimal float using awk. printf "%.2f" is
    # unreliable for floats in macOS bash 3.2, so awk is the safer choice.
    local tf
    tf=$(awk "BEGIN{printf \"%.2fs\", ${time_val:-0}}" 2>/dev/null || echo "${time_val:-?}s")

    # Scan body for known Drupal content warning indicators
    local warns=()
    echo "$body" | grep -qi "currently under maintenance" && warns+=("MAINTENANCE MODE")
    echo "$body" | grep -qi "encountered an unexpected error" && warns+=("DRUPAL ERROR")
    [[ -n "$shield_warn" ]] && warns+=("$shield_warn")

    # Output
    if [[ "$code" =~ ^[23] ]]; then
        printf "  ${GREEN}✓${NC} [%s] %s (%s)\n" "$code" "$url" "$tf"
        [[ -n "$title" ]] && printf "    ↳ Title: %s\n" "$title"
        printf "    ↳ "; printf "$shield_label"; printf "\n"
        for w in "${warns[@]}"; do
            printf "    ${YELLOW}⚠${NC}  %s\n" "$w"
            WARNINGS+=("$w | $url")
        done
        ((UP++))
    elif [[ "$code" == "000" ]]; then
        printf "  ${RED}✗${NC} [TIMEOUT] %s\n" "$url"
        FLAGGED+=("TIMEOUT | $url")
        ((DOWN++))
    else
        printf "  ${RED}✗${NC} [%s] %s\n" "$code" "$url"
        FLAGGED+=("$code | $url")
        ((DOWN++))
    fi
}

# check_url_simple — Lightweight status check for nav-sampled internal pages.
#
# Identical to check_url() in its GET request and body analysis logic, but
# with two differences:
#   - No Shield HEAD request (Shield is assessed once at the homepage level;
#     re-checking it for every sampled page would be noisy and redundant)
#   - Accepts a configurable indentation string ($3) for nested display under
#     the parent homepage entry in the output
#
# Parameters:
#   $1  url       — Full URL to check
#   $2  insecure  — Pass "k" to skip SSL cert verification; empty string for prod
#   $3  indent    — Output line prefix string (default: 4 spaces)
#
# Side effects:
#   Appends to WARNINGS[], FLAGGED[], and increments UP/DOWN counters.
check_url_simple() {
    local url="$1"
    local insecure="$2"
    local indent="${3:-    }"
    local curl_opts=(-s --max-time "$TIMEOUT" --connect-timeout 5 -L)
    [[ -n "$insecure" ]] && curl_opts+=(-k)

    local raw code time_val body title
    raw=$(curl "${curl_opts[@]}" \
        -u "$AUTH" \
        -w "___CURL_END_STATUS:%{http_code}_TIME:%{time_total}___" \
        "$url" 2>/dev/null)

    code=$(echo "$raw" | grep -o 'STATUS:[0-9]*' | cut -d: -f2)
    time_val=$(echo "$raw" | grep -o '_TIME:[0-9.]*' | sed 's/_TIME://')
    body=$(echo "$raw" | sed 's/___CURL_END_STATUS:.*//g')
    title=$(echo "$body" | grep -oi '<title>[^<]*</title>' | sed 's/<[^>]*>//g' | head -1 | tr -s ' ' | xargs 2>/dev/null)

    local tf
    tf=$(awk "BEGIN{printf \"%.2fs\", ${time_val:-0}}" 2>/dev/null || echo "${time_val:-?}s")

    if [[ "$code" =~ ^[23] ]]; then
        printf "${indent}${GREEN}✓${NC} [%s] %s (%s)\n" "$code" "$url" "$tf"
        [[ -n "$title" ]] && printf "${indent}  Title: %s\n" "$title"
        echo "$body" | grep -qi "currently under maintenance" && {
            printf "${indent}  ${YELLOW}⚠ MAINTENANCE MODE${NC}\n"
            WARNINGS+=("MAINTENANCE MODE | $url")
        }
        echo "$body" | grep -qi "encountered an unexpected error" && {
            printf "${indent}  ${YELLOW}⚠ DRUPAL ERROR${NC}\n"
            WARNINGS+=("DRUPAL ERROR | $url")
        }
        ((UP++))
    elif [[ "$code" == "000" ]]; then
        printf "${indent}${RED}✗${NC} [TIMEOUT] %s\n" "$url"
        FLAGGED+=("TIMEOUT | $url")
        ((DOWN++))
    else
        printf "${indent}${RED}✗${NC} [%s] %s\n" "$code" "$url"
        FLAGGED+=("$code | $url")
        ((DOWN++))
    fi
}

# check_nav_sample — Parse, sample, and check internal nav links from a page.
#
# Takes the HTML body already fetched by check_url() (via LAST_BODY) and:
#   1. Extracts all href values, filters to internal relative paths (/...)
#   2. Excludes Drupal system paths (/admin, /user, /node/, /sites/, etc.) and
#      static asset extensions to avoid checking non-page resources
#   3. Groups remaining paths by URL depth:
#        Level 1:  /segment           (top-level nav, e.g. /about)
#        Level 2:  /segment/segment   (sub-nav, e.g. /about/leadership)
#   4. Randomly selects up to 3 from each group (Fisher-Yates in awk)
#   5. Checks each selected URL via check_url_simple()
#
# Parameters:
#   $1  body      — Raw HTML body string (pass $LAST_BODY from the caller)
#   $2  base_url  — Site root URL to prepend to relative paths
#                   (e.g., https://dev.admission.howard.edu)
#   $3  insecure  — Pass "k" to skip SSL cert verification; empty string for prod
check_nav_sample() {
    local body="$1"
    local base_url="$2"
    local insecure="$3"

    # Extract all href values from the HTML body, then filter:
    #   - Keep only paths starting with /  (internal relative links)
    #   - Drop //  (protocol-relative links to external domains)
    #   - Drop /#  (fragment-only anchor links with no real page load)
    #   - Drop Drupal internal/admin paths that are not navigable pages
    #   - Drop common static asset file extensions
    local all_links
    all_links=$(echo "$body" | grep -oi 'href="[^"]*"' | \
        sed 's/href="//;s/"//' | \
        grep '^/' | \
        grep -v '^//' | \
        grep -v '^\/#' | \
        grep -v '^/sites/' | \
        grep -v '^/modules/' | \
        grep -v '^/themes/' | \
        grep -v '^/core/' | \
        grep -v '^/admin' | \
        grep -v '^/user' | \
        grep -v '^/node/' | \
        grep -iEv '\.(pdf|jpg|jpeg|png|gif|svg|css|js|xml|txt)($|\?)' | \
        sort -u)

    # Level 1: /segment  (exactly 1 non-empty path component)
    local level1 level2
    level1=$(echo "$all_links" | awk -F'/' 'NF==2 && length($2)>0')
    # Level 2: /segment/segment  (exactly 2 non-empty path components)
    level2=$(echo "$all_links" | awk -F'/' 'NF==3 && length($3)>0')

    # Randomly sample up to 3 items from each level using a Fisher-Yates
    # shuffle implemented in awk. The algorithm reads all lines into an array,
    # then iterates from the last index downward, swapping each element with a
    # randomly selected earlier element. The first 3 elements after shuffling
    # are printed. Two independent $RANDOM seeds ensure the two level samples
    # are shuffled independently of each other.
    local seed1=$RANDOM seed2=$RANDOM
    local sample1 sample2
    sample1=$(echo "$level1" | awk -v seed="$seed1" \
        'NF>0{lines[++n]=$0} END{if(n==0)exit; srand(seed); for(i=n;i>1;i--){j=int(rand()*(i-1))+1; t=lines[i]; lines[i]=lines[j]; lines[j]=t}; c=(n<3?n:3); for(i=1;i<=c;i++) print lines[i]}')
    sample2=$(echo "$level2" | awk -v seed="$seed2" \
        'NF>0{lines[++n]=$0} END{if(n==0)exit; srand(seed); for(i=n;i>1;i--){j=int(rand()*(i-1))+1; t=lines[i]; lines[i]=lines[j]; lines[j]=t}; c=(n<3?n:3); for(i=1;i<=c;i++) print lines[i]}')

    local found=0

    if [[ -n "$sample1" ]]; then
        printf "    ↳ ${YELLOW}Nav sample (level 1):${NC}\n"
        while IFS= read -r path; do
            [[ -z "$path" ]] && continue
            found=1
            check_url_simple "${base_url}${path}" "$insecure" "      "
        done << NAV1EOF
$sample1
NAV1EOF
    fi

    if [[ -n "$sample2" ]]; then
        printf "    ↳ ${YELLOW}Nav sample (level 2):${NC}\n"
        while IFS= read -r path; do
            [[ -z "$path" ]] && continue
            found=1
            check_url_simple "${base_url}${path}" "$insecure" "      "
        done << NAV2EOF
$sample2
NAV2EOF
    fi

    [[ $found -eq 0 ]] && printf "    ${YELLOW}⚠${NC}  No sampleable nav links found\n"
}

env_prefix() {
    case "$1" in
        dev)  echo "dev." ;;
        test) echo "stg." ;;
        prod) echo "" ;;
    esac
}

# ============================================================
# Optional CLI arguments (skip interactive prompts)
# Usage: sh site_status_check.sh [app] [env] [nav]
#   app: all | hud8 | academicdepartments | howardenterprise | centers | uxws
#   env: dev | test | stg | prod | all  (stg maps to test)
#   nav: y | n  (sample nav pages, default: n)
# Examples:
#   sh site_status_check.sh all prod
#   sh site_status_check.sh all dev n
#   sh site_status_check.sh hud8 prod y
# ============================================================

TARGET_APPS=()
TARGET_ENVS=()

if [[ -n "$1" ]]; then
  _arg="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  _arg="${_arg#@}"
  if [[ "$_arg" == "all" ]]; then
    TARGET_APPS=("${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}")
    echo "App(s): All Applications"
  else
    SELECTED_APP="@${_arg}"
    TARGET_APPS=("$SELECTED_APP")
    echo "App:    $SELECTED_APP"
  fi
fi

if [[ -n "$2" ]]; then
  _env="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
  [[ "$_env" == "stg" ]] && _env="test"
  if [[ "$_env" == "all" ]]; then
    TARGET_ENVS=("dev" "test" "prod")
    echo "Env(s): all (dev, test, prod)"
  else
    SELECTED_ENV="$_env"
    TARGET_ENVS=("$_env")
    echo "Env:    $_env"
  fi
fi

if [[ -n "$3" ]]; then
  DO_NAV_SAMPLE="$(echo "$3" | tr '[:upper:]' '[:lower:]')"
  echo "Nav:    $DO_NAV_SAMPLE"
fi
[[ -n "$1" || -n "$2" || -n "$3" ]] && echo ""

# Choose targeting scope
if [[ ${#TARGET_APPS[@]} -eq 0 ]]; then
  echo "Choose targeting scope:"
  SCOPES=( "Single Application + Single Environment" "Single Application + All Environments" "All Applications + Single Environment" "All Applications + All Environments" )
  select SCOPE in "${SCOPES[@]}"; do
      case $SCOPE in
          "Single Application + Single Environment")
              select_app_and_env
              TARGET_APPS=("$SELECTED_APP")
              TARGET_ENVS=("$SELECTED_ENV")
              break
              ;;
          "Single Application + All Environments")
              select_app_only
              TARGET_APPS=("$SELECTED_APP")
              TARGET_ENVS=("dev" "test" "prod")
              break
              ;;
          "All Applications + Single Environment")
              select_env_only
              TARGET_APPS=("${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}")
              TARGET_ENVS=("$SELECTED_ENV")
              break
              ;;
          "All Applications + All Environments")
              echo "Selected: All Applications + All Environments"
              TARGET_APPS=("${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}")
              TARGET_ENVS=("dev" "test" "prod")
              break
              ;;
          *)
              printf '"%s" is not a valid choice\n' "$REPLY" >&2
              ;;
      esac
  done
fi

echo ""
if [[ -z "$DO_NAV_SAMPLE" ]]; then
  printf "Sample nav pages? (up to 3 level-1 + 3 level-2 per site/env) [y/N]: "
  read -r DO_NAV_SAMPLE
fi

echo ""
echo "Site Status Check — Howard D8 Multisite"
echo "Applications: ${TARGET_APPS[*]}"
echo "Environments: ${TARGET_ENVS[*]}"
echo "Basic auth: huweb/huweb | Timeout: ${TIMEOUT}s"
echo "Checks: HTTP status, title, Shield, maintenance mode, Drupal errors, response time"
echo "========================================"
echo ""

# =============================================================================
# Main Execution Loop
# Iterates over each selected application alias, discovers its sites from the
# local docroot/sites/ folder (glob *.howard.edu), then checks each site URL
# across all selected environments. If nav sampling was requested, the already-
# fetched homepage body is passed to check_nav_sample() after each homepage
# check — no additional fetch is needed for link extraction.
# =============================================================================

for APP in "${TARGET_APPS[@]}"; do
    # Resolve the local codebase folder for this drush alias using the helper
    # from partials/select_app_and_env.sh (reads LOCAL_HOWARD_D8_FOLDERS[] from
    # hal_config.txt to map alias → folder path).
    LOCAL_FOLDER=$(get_local_folder_for_app "$APP")
    SITES_DIR="$LOCAL_FOLDER/docroot/sites"

    SITES=()
    for dir in "$SITES_DIR"/*.howard.edu; do
        [ -d "$dir" ] && SITES+=("$(basename "$dir")")
    done

    if [[ ${#SITES[@]} -eq 0 ]]; then
        echo "[$APP] No site folders found."
        continue
    fi

    echo "--- $APP (${#SITES[@]} sites) ---"
    echo ""

    for SITE in "${SITES[@]}"; do
        echo "=== $SITE ==="
        for ENV in "${TARGET_ENVS[@]}"; do
            PREFIX=$(env_prefix "$ENV")
            URL="https://${PREFIX}${SITE}"
            INSECURE=""
            [[ "$ENV" != "prod" ]] && INSECURE="k"
            check_url "$URL" "$INSECURE" "$ENV"
            if [[ "$DO_NAV_SAMPLE" =~ ^[Yy]$ ]] && [[ "$LAST_STATUS" =~ ^[23] ]]; then
                check_nav_sample "$LAST_BODY" "$URL" "$INSECURE"
            fi
        done
        echo ""
    done
done

echo "========================================"
printf "Summary: ${GREEN}${UP} UP${NC}  |  ${RED}${DOWN} flagged${NC}\n"
echo ""

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
    printf "${YELLOW}Content Warnings:${NC}\n"
    for item in "${WARNINGS[@]}"; do
        printf "  ${YELLOW}⚠${NC}  %s\n" "$item"
    done
    echo ""
fi

if [[ ${#FLAGGED[@]} -gt 0 ]]; then
    printf "${RED}Flagged URLs:${NC}\n"
    for item in "${FLAGGED[@]}"; do
        printf "  ${RED}✗${NC} %s\n" "$item"
    done
fi

exit 0

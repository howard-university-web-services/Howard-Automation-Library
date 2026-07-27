#!/bin/bash
#
# Site status checker for Howard D8 sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh
# Scope: Remote — checks live HTTP responses for Howard multisite URLs
#
# Notes:
# - Checks only sites that have a docroot/sites/ folder in the selected app(s)
# - dev env  → dev.<domain>
# - test env → stg.<domain>  (Acquia staging)
# - prod env → <domain>
# - Passes HTTP basic auth (huweb/huweb) automatically
# - SSL verification skipped for dev/test environments (expired certs)
#
# Dependencies:
# - curl
#

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

AUTH="huweb:huweb"
TIMEOUT=10
UP=0
DOWN=0
FLAGGED=()

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

check_url() {
    local url="$1"
    local insecure="$2"
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" \
        -u "$AUTH" \
        --max-time "$TIMEOUT" \
        --connect-timeout 5 \
        -L \
        ${insecure:+-k} \
        "$url" 2>/dev/null)

    if [[ "$code" =~ ^[23] ]]; then
        printf "  ${GREEN}✓${NC} [%s] %s\n" "$code" "$url"
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

env_prefix() {
    case "$1" in
        dev)  echo "dev." ;;
        test) echo "stg." ;;
        prod) echo "" ;;
    esac
}

# Choose targeting scope
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

echo ""
echo "Site Status Check — Howard D8 Multisite"
echo "Applications: ${TARGET_APPS[*]}"
echo "Environments: ${TARGET_ENVS[*]}"
echo "Basic auth: huweb/huweb | Timeout: ${TIMEOUT}s"
echo "========================================"
echo ""

for APP in "${TARGET_APPS[@]}"; do
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
            if [[ "$ENV" != "prod" ]]; then
                check_url "$URL" k
            else
                check_url "$URL"
            fi
        done
        echo ""
    done
done

echo "========================================"
printf "Summary: ${GREEN}${UP} UP${NC}  |  ${RED}${DOWN} flagged${NC}\n"
echo ""

if [[ ${#FLAGGED[@]} -gt 0 ]]; then
    printf "Flagged URLs:\n"
    for item in "${FLAGGED[@]}"; do
        printf "  ${RED}✗${NC} %s\n" "$item"
    done
fi

exit 0

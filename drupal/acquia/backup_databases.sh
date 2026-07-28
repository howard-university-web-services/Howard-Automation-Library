#!/bin/bash
#
# Creates Acquia database backups for all databases in the selected
# Howard D8 applications and environment.
#
# $ sh ~/Sites/_hal/drupal/acquia/backup_databases.sh
# Scope: Remote — operates on Acquia environments via acli. No local changes.
#
# Notes:
# - Backs up ALL databases for ALL sites in the selected app(s)/env.
# - Backup requests are queued asynchronously on Acquia — allow a few
#   minutes, then verify in the Acquia Cloud UI.
# - Recommended to run against prod at the start of every update cycle
#   before running update_all.sh or deploying code.
#
# Dependencies:
# - Acquia CLI (acli): https://docs.acquia.com/acquia-cli/
#   Install:      brew install acquia/acquia-cli/acli
#   Authenticate: acli auth:login
#

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

# ============================================================
# acli check
# ============================================================

if ! command -v acli &> /dev/null; then
  echo "Error: acli is not installed or not in PATH."
  echo "  Install:      brew install acquia/acquia-cli/acli"
  echo "  Authenticate: acli auth:login"
  exit 2
fi

# ============================================================
# Intro
# ============================================================

echo "Database backup for Howard D8 sites."
echo ""
echo "  Mechanism:  acli api:environments:database-backup-create"
echo "  Scope:      All databases for ALL sites in the selected app(s)/env"
echo ""

# ============================================================
# Optional CLI arguments (skip interactive prompts)
# Usage: sh backup_databases.sh [app] [env]
#   app: all | hud8 | academicdepartments | howardenterprise | centers | uxws
#   env: dev | test | stg | prod  (stg maps to test)
# Examples:
#   sh backup_databases.sh all prod
#   sh backup_databases.sh hud8 prod
# ============================================================

if [[ -n "$1" ]]; then
  _arg="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  _arg="${_arg#@}"
  if [[ "$_arg" == "all" ]]; then
    SCOPE="All Applications"
    TARGET_APPS=("${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}")
    echo "App(s):      All Applications"
  else
    SCOPE="Single Application"
    SELECTED_APP="@${_arg}"
    TARGET_APPS=("$SELECTED_APP")
    echo "App:         $SELECTED_APP"
  fi
fi

if [[ -n "$2" ]]; then
  _env="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
  [[ "$_env" == "stg" ]] && _env="test"
  SELECTED_ENV="$_env"
  TARGET_ENV="$_env"
  echo "Environment: $TARGET_ENV"
fi
[[ -n "$1" || -n "$2" ]] && echo ""

# ============================================================
# Application scope
# ============================================================

if [[ -z "$SCOPE" ]]; then
  echo "Back up which application(s)?"
  SCOPES=( "Single Application" "All Applications" )
  select SCOPE in "${SCOPES[@]}"; do
    if [[ -z "$SCOPE" ]]; then
      printf '"%s" is not a valid choice\n' "$REPLY" >&2
    else
      break
    fi
  done

  if [[ "$SCOPE" == "Single Application" ]]; then
    select_app_only
    TARGET_APPS=("$SELECTED_APP")
  else
    echo "Selected: All Applications"
    TARGET_APPS=("${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}")
  fi
fi

# ============================================================
# Environment
# ============================================================

if [[ -z "$TARGET_ENV" ]]; then
  echo ""
  select_env_only
  TARGET_ENV="$SELECTED_ENV"
fi

# ============================================================
# Confirmation
# ============================================================

echo ""
echo "========================================"
echo "  ABOUT TO RUN:"
echo "    Environment:   $TARGET_ENV"
echo "    Applications:  ${TARGET_APPS[*]}"
echo "    Action:        Create backup of ALL databases"
echo "========================================"
echo ""
echo "Proceed? [y/N]:"
read -r CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Cancelled."
  exit 0
fi

# ============================================================
# Backup
# ============================================================

echo ""
echo "Queuing database backups..."
echo ""

ERRORS=()

for APP in "${TARGET_APPS[@]}"; do
  APP_KEY="${APP#@}"
  echo "=== $APP_KEY: $TARGET_ENV ==="
  APP_FAILED=0

  DATABASES_STR=$(acli api:environments:database-list "${APP_KEY}.${TARGET_ENV}" 2>/dev/null | \
    python3 -c "
import json,sys
data=json.load(sys.stdin)
items = data if isinstance(data,list) else data.get('_embedded',{}).get('items',[])
for db in items:
    n=db.get('name','')
    if n: print(n)
" 2>/dev/null)

  DATABASES=()
  while IFS= read -r db; do
    [[ -n "$db" ]] && DATABASES+=("$db")
  done <<< "$DATABASES_STR"

  if [[ ${#DATABASES[@]} -eq 0 ]]; then
    echo "  ✗ Could not retrieve database list for ${APP_KEY}.${TARGET_ENV}"
    APP_FAILED=1
  else
    echo "  Queuing backups for ${#DATABASES[@]} database(s): ${DATABASES[*]}"
    for DB_NAME in "${DATABASES[@]}"; do
      printf "    %-30s" "${DB_NAME}..."
      if acli api:environments:database-backup-create --no-interaction \
          "${APP_KEY}.${TARGET_ENV}" "$DB_NAME" > /dev/null 2>&1; then
        echo "queued ✓"
      else
        echo "FAILED ✗"
        APP_FAILED=1
      fi
    done
  fi

  if [[ $APP_FAILED -eq 0 ]]; then
    echo "✓ $APP_KEY backups queued"
  else
    echo "✗ $APP_KEY had errors"
    ERRORS+=("$APP_KEY")
  fi
  echo ""
done

# ============================================================
# Summary
# ============================================================

echo "========================================"
if [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo "All backup requests queued successfully."
else
  echo "Finished with errors on: ${ERRORS[*]}"
fi
echo ""
echo "NOTE: Backups are created asynchronously on Acquia."
echo "Allow a few minutes, then verify in the Acquia Cloud UI:"
echo "  https://cloud.acquia.com  → your app → Databases → Backups"
echo "========================================"

exit 0

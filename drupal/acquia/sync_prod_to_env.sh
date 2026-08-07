#!/bin/bash
#
# Syncs Acquia prod databases and/or files to dev for selected
# Howard D8 applications.
#
# $ sh ~/Sites/_hal/drupal/acquia/sync_prod_to_env.sh
# Scope: Remote — operates on Acquia environments via acli. No local changes.
#
# Notes:
# - Docs: ~/Sites/_hal/docs/scripts/sync_prod_to_env.md
# - Databases are copied individually per DB using `acli api:environments:database-copy`
#   so that ALL multisite databases are synced (not just the primary one).
#   e.g. uxws has 4 databases — all four are copied.
# - Files (if requested) are copied via `acli env:mirror --no-databases --no-code --no-config`.
# - Destination is always dev. Test/stg is intentionally excluded to prevent
#   accidental overwrites of the staging environment.
# - Dev codebase is never touched; Acquia platform-level configuration (cron
#   tasks, environment variables, PHP settings) is never overwritten from prod.
# - This is a DESTRUCTIVE operation: destination databases and/or files are
#   fully replaced with prod data. There is no undo.
#
# Recommended follow-up after sync:
#   sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh
#     → command: updb   (run database updates)
#     → command: cr     (rebuild caches)
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

echo "Prod → Dev data sync for Howard D8 sites."
echo ""
echo "  DB mechanism:   acli api:environments:database-copy (per database)"
echo "  File mechanism: acli env:mirror --no-databases --no-code --no-config"
echo "  Destination:    dev only (stg is intentionally excluded)"
echo "  Scope:          ALL databases for the selected app(s), including all"
echo "                  multisite DBs, not just the primary one."
echo ""
echo "  ⚠️  WARNING: This is DESTRUCTIVE. All dev databases (and optionally"
echo "  files) will be fully overwritten with production data. No undo."
echo ""

# ============================================================
# Optional CLI arguments (skip interactive prompts)
# Usage: sh sync_prod_to_env.sh [app] [type]
#   app:  all | hud8 | academicdepartments | howardenterprise | centers | uxws
#   type: databases | files | both
# Examples:
#   sh sync_prod_to_env.sh all databases
#   sh sync_prod_to_env.sh hud8 both
# ============================================================

if [[ -n "$1" ]]; then
  _arg="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  _arg="${_arg#@}"
  if [[ "$_arg" == "all" ]]; then
    SCOPE="All Applications"
    TARGET_APPS=("${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}")
    echo "App(s):  All Applications"
  else
    SCOPE="Single Application"
    SELECTED_APP="@${_arg}"
    TARGET_APPS=("$SELECTED_APP")
    echo "App:     $SELECTED_APP"
  fi
fi

if [[ -n "$2" ]]; then
  _type="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
  case "$_type" in
    databases|db) SYNC_OPT="Databases only" ;;
    files)        SYNC_OPT="Files only" ;;
    both|all)     SYNC_OPT="Databases + Files" ;;
    *)            SYNC_OPT="Databases + Files" ;;
  esac
  echo "Sync:    $SYNC_OPT"
fi
[[ -n "$1" || -n "$2" ]] && echo ""

# ============================================================
# Application scope
# ============================================================

if [[ -z "$SCOPE" ]]; then
  echo "Sync which application(s)?"
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
# Destination is always dev
# ============================================================

DEST_ENV="dev"

# ============================================================
# What to sync
# ============================================================

if [[ -z "$SYNC_OPT" ]]; then
  echo ""
  echo "What to sync from prod?"
  SYNC_OPTS=( "Databases + Files" "Databases only" "Files only" )
  select SYNC_OPT in "${SYNC_OPTS[@]}"; do
    if [[ -z "$SYNC_OPT" ]]; then
      printf '"%s" is not a valid choice\n' "$REPLY" >&2
    else
      break
    fi
  done
fi

# Note: databases are copied individually per DB using api:environments:database-copy
# so that ALL multisite databases are synced (env:mirror only copies the primary DB).
# Files (if requested) still use env:mirror --no-databases --no-code --no-config.

# ============================================================
# Confirmation — require full "yes" for a destructive operation
# ============================================================

echo ""
echo "========================================"
echo "  ABOUT TO RUN:"
echo "    Source env:       prod"
echo "    Destination env:  dev  ⚠️  ALL DEV DATA WILL BE OVERWRITTEN"
echo "    Sync content:     $SYNC_OPT"
echo "    Applications:     ${TARGET_APPS[*]}"
echo "========================================"
echo ""
echo "Type 'yes' to confirm (anything else cancels):"
read -r CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
  echo "Cancelled."
  exit 0
fi

# ============================================================
# Sync
# ============================================================

echo ""
echo "Starting sync..."
echo ""

ERRORS=()

for APP in "${TARGET_APPS[@]}"; do
  APP_KEY="${APP#@}"
  echo "=== $APP_KEY: prod → $DEST_ENV ==="
  APP_FAILED=0

  # --- Databases ---
  if [[ "$SYNC_OPT" != "Files only" ]]; then
    PROD_UUID_VAR="ACQUIA_ENV_UUID_${APP_KEY}_prod"
    PROD_UUID="${!PROD_UUID_VAR}"

    if [[ -z "$PROD_UUID" || "$PROD_UUID" == "UUID_HERE" ]]; then
      echo "  ✗ No prod UUID configured for ${APP_KEY}."
      echo "    Add ACQUIA_ENV_UUID_${APP_KEY}_prod to hal_config.txt"
      APP_FAILED=1
    else
      DATABASES_STR=$(acli api:environments:database-list "${APP_KEY}.prod" 2>/dev/null | \
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
        echo "  ✗ Could not retrieve database list for ${APP_KEY}.prod"
        APP_FAILED=1
      else
        echo "  Copying ${#DATABASES[@]} database(s): ${DATABASES[*]}"
        for DB_NAME in "${DATABASES[@]}"; do
          printf "    %-30s" "${DB_NAME}..."
          if acli api:environments:database-copy --no-interaction \
              "${APP_KEY}.${DEST_ENV}" "$DB_NAME" "$PROD_UUID" > /dev/null 2>&1; then
            echo "queued ✓"
          else
            echo "FAILED ✗"
            APP_FAILED=1
          fi
        done
      fi
    fi
  fi

  # --- Files ---
  if [[ "$SYNC_OPT" != "Databases only" ]]; then
    echo "  Copying files..."
    if acli env:mirror --no-interaction --no-code --no-config --no-databases \
        "${APP_KEY}.prod" "${APP_KEY}.${DEST_ENV}" ; then
      echo "  Files ✓"
    else
      echo "  Files FAILED ✗"
      APP_FAILED=1
    fi
  fi

  if [[ $APP_FAILED -eq 0 ]]; then
    echo "✓ $APP_KEY sync complete"
  else
    echo "✗ $APP_KEY sync had errors"
    ERRORS+=("$APP_KEY")
  fi
  echo ""
done

# ============================================================
# Summary
# ============================================================

echo "========================================"
if [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo "Sync complete — all applications succeeded."
else
  echo "Sync finished with errors on: ${ERRORS[*]}"
fi
echo ""
echo "NOTE: Database copies are queued and run asynchronously on Acquia."
echo "Allow 2-5 minutes per app before running updb/cr."
echo ""
echo "Recommended follow-up (run via update_via_drush.sh):"
echo "  drush updb   → run pending database updates on $DEST_ENV"
echo "  drush cr     → rebuild caches on $DEST_ENV"
echo "========================================"

exit 0

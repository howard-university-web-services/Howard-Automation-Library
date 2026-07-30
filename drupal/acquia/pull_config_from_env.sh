#!/bin/bash
#
# Pull config from an Acquia environment to local codebases.
#
# $ sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh
# Scope: Remote → Local
#
# Notes:
# - Runs `drush cex` on every site in the selected app(s)/env, exporting DB
#   config to the server's sync directories.
# - Rsyncs those config directories from Acquia back to the local codebase(s).
# - Uses --delete, so local config files not present in the remote export are removed.
#   .htaccess and README.txt files are protected from deletion.
# - After running, review changes with `git diff config/` before committing.
# - SSH host/user/root are read dynamically from each app's drush site.yml.
#
# Dependencies:
# - rsync
# - drush (via LOCAL_DRUSH in hal_config.txt)
#
# Usage:
#   sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh [app] [env]
#   app: all | hud8 | academicdepartments | howardenterprise | centers | uxws
#   env: dev | test | stg | prod  (stg maps to test)
# Examples:
#   sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh all prod
#   sh ~/Sites/_hal/drupal/acquia/pull_config_from_env.sh hud8 stg
#

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

echo "Pull config from Acquia environment to local codebases."
echo ""

# ============================================================
# Helper: parse SSH host, user, and root from app's drush site.yml
# Usage: get_ssh_info <app_key> <env>
# Sets: SSH_HOST, SSH_USER, SSH_ROOT
# ============================================================
get_ssh_info() {
  local APP_KEY="$1"
  local ENV="$2"
  local SITE_YML=""

  for dir in "${LOCAL_HOWARD_D8_FOLDERS[@]}"; do
    if [[ -f "$dir/docroot/drush/sites/${APP_KEY}.site.yml" ]]; then
      SITE_YML="$dir/docroot/drush/sites/${APP_KEY}.site.yml"
      break
    fi
  done

  if [[ -z "$SITE_YML" ]]; then
    echo "Error: Could not find site.yml for $APP_KEY" >&2
    SSH_HOST=""
    SSH_USER=""
    SSH_ROOT=""
    return 1
  fi

  # Extract host and user from the env block using awk
  SSH_HOST=$(awk "/^${ENV}:/{f=1} f && /^  host:/{print \$2; exit}" "$SITE_YML")
  SSH_USER=$(awk "/^${ENV}:/{f=1} f && /^  user:/{print \$2; exit}" "$SITE_YML")
  SSH_ROOT=""
}

# ============================================================
# Helper: build local config path from app alias
# Usage: get_local_path <app_alias>  (e.g. @hud8)
# Sets: LOCAL_CONFIG_PATH
# ============================================================
get_local_path() {
  local ALIAS="$1"
  LOCAL_CONFIG_PATH=""
  for i in "${!LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}"; do
    if [[ "${LOCAL_HOWARD_D8_DRUSH_ALIAS[$i]}" == "$ALIAS" ]]; then
      LOCAL_CONFIG_PATH="${LOCAL_HOWARD_D8_FOLDERS[$i]}/config/"
      return 0
    fi
  done
}

# ============================================================
# Optional CLI arguments (skip interactive prompts)
# Usage: sh pull_config_from_prod.sh [app] [env]
#   app: all | hud8 | academicdepartments | howardenterprise | centers | uxws
#   env: dev | test | stg | prod  (stg maps to test)
# ============================================================

TARGET_APPS=()
TARGET_ENV=""

if [[ -n "$1" ]]; then
  _arg="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  _arg="${_arg#@}"
  if [[ "$_arg" == "all" ]]; then
    TARGET_APPS=("${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}")
    echo "App(s):      All Applications"
  else
    SELECTED_APP="@${_arg}"
    TARGET_APPS=("$SELECTED_APP")
    echo "App:         $SELECTED_APP"
  fi
fi

if [[ -n "$2" ]]; then
  _env="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
  [[ "$_env" == "stg" ]] && _env="test"
  TARGET_ENV="$_env"
  echo "Environment: $TARGET_ENV"
fi
[[ -n "$1" || -n "$2" ]] && echo ""

# ============================================================
# Application scope (interactive if not set via CLI)
# ============================================================

if [[ ${#TARGET_APPS[@]} -eq 0 ]]; then
  echo "Pull config for which application(s)?"
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
# Environment (interactive if not set via CLI)
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
echo "    Action:        1. drush cex on all sites (export DB config to server)"
echo "                   2. rsync config dirs from Acquia to local codebases"
echo ""
echo "  ⚠ Local config files will be overwritten with the remote state."
echo "    Run 'git status' in each repo first to preserve in-progress work."
echo "========================================"
echo ""
echo "Proceed? [y/N]:"
read -r CONFIRM
if [[ "$CONFIRM" != "y" && "$CONFIRM" != "Y" ]]; then
  echo "Cancelled."
  exit 0
fi

# ============================================================
# Execute per app
# ============================================================

echo ""
echo "Pulling config..."
echo ""

ERRORS=()

for APP in "${TARGET_APPS[@]}"; do
  APP_KEY="${APP#@}"
  echo "=== $APP_KEY: $TARGET_ENV ==="

  # Resolve SSH info from site.yml
  get_ssh_info "$APP_KEY" "$TARGET_ENV"
  if [[ -z "$SSH_HOST" || -z "$SSH_USER" ]]; then
    echo "  ✗ Could not resolve SSH info for $APP_KEY.$TARGET_ENV — skipping."
    ERRORS+=("$APP_KEY.$TARGET_ENV: SSH info not found")
    echo ""
    continue
  fi

  # Resolve local config path
  get_local_path "$APP"
  if [[ -z "$LOCAL_CONFIG_PATH" ]]; then
    echo "  ✗ Could not resolve local path for $APP — skipping."
    ERRORS+=("$APP_KEY: local path not found")
    echo ""
    continue
  fi

  # Discover AH_SITE_NAME live from the server — more reliable than deriving
  # from the site.yml root, which is stale/non-standard for some apps (uxws, centers)
  echo "  Resolving remote paths..."
  AH_SITE_NAME=$(${LOCAL_DRUSH} ${APP}.${TARGET_ENV} ssh "echo \$AH_SITE_NAME" 2>/dev/null | tr -d '[:space:]')
  if [[ -z "$AH_SITE_NAME" ]]; then
    echo "  ✗ Could not resolve AH_SITE_NAME on $APP_KEY.$TARGET_ENV — skipping."
    ERRORS+=("$APP_KEY.$TARGET_ENV: AH_SITE_NAME not found")
    echo ""
    continue
  fi
  REMOTE_CONFIG="/var/www/html/${AH_SITE_NAME}/config/"

  echo "  Remote: ${SSH_USER}@${SSH_HOST} → /tmp/hal_config_export_${APP_KEY}/"
  echo "  Local:  ${LOCAL_CONFIG_PATH}"
  echo ""

  # Step 1: Export config from DB to a writable temp dir on the server.
  # Note: The git-deployed config sync directory on Acquia is read-only,
  # so we export to /tmp and rsync from there instead.
  # Uses direct SSH (not drush ssh) to avoid drush collapsing multiline
  # commands into one line, which breaks for/do shell syntax.
  REMOTE_TMP="/tmp/hal_config_export_${APP_KEY}"
  echo "  Step 1: Exporting config on $TARGET_ENV for all $APP_KEY sites to $REMOTE_TMP..."
  ssh -o StrictHostKeyChecking=no -o BatchMode=yes "${SSH_USER}@${SSH_HOST}" "
    SITES_DIR=\"/var/www/html/\${AH_SITE_NAME}/docroot/sites\"
    for SITE in \$(ls \"\${SITES_DIR}/\" 2>/dev/null | grep -E '\.howard\.edu$'); do
      DEST=\"${REMOTE_TMP}/\${SITE}\"
      mkdir -p \"\${DEST}\"
      echo \"  Exporting: \${SITE}\"
      drush -l \"\${SITE}\" cex --destination=\"\${DEST}\" -y 2>&1
    done
  "
  echo "  ✓ Config exported to $REMOTE_TMP"
  echo ""

  # Step 2: Rsync from the temp export dir → local
  echo "  Step 2: Rsyncing to local..."
  rsync -avz --delete \
    --filter='protect .htaccess' \
    --filter='protect README.txt' \
    --exclude='default/' \
    -e "ssh -o StrictHostKeyChecking=no -o BatchMode=yes" \
    "${SSH_USER}@${SSH_HOST}:${REMOTE_TMP}/" \
    "${LOCAL_CONFIG_PATH}"

  if [[ $? -eq 0 ]]; then
    echo "  ✓ Synced to: $LOCAL_CONFIG_PATH"
    # Clean up temp dir on server
    ssh -o StrictHostKeyChecking=no -o BatchMode=yes "${SSH_USER}@${SSH_HOST}" "rm -rf ${REMOTE_TMP}" 2>/dev/null
  else
    echo "  ✗ rsync failed for $APP_KEY.$TARGET_ENV"
    ERRORS+=("$APP_KEY.$TARGET_ENV: rsync failed")
  fi
  echo ""
done

# ============================================================
# Summary
# ============================================================

echo "========================================"
if [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo "  ✓ All config pulled successfully."
else
  echo "  ✗ Completed with errors:"
  for ERR in "${ERRORS[@]}"; do
    echo "    - $ERR"
  done
fi
echo ""
echo "  Next steps:"
echo "    1. Review:  cd ~/Sites/{app} && git diff config/"
echo "    2. Commit:  git add config/ && git commit -m 'Sync config from $TARGET_ENV'"
echo "    3. Push:    git push"
echo "========================================"

exit 0

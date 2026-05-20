#!/bin/bash
#
# This script creates a new tag on master and deploys it to Howard Acquia prod environments.
#
# $ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh
# Scope: Remote — deploys to Acquia prod environments via acli
#
# Notes:
# - See README.md for detailed instructions.
# - Always deploys to prod. Other environments stay on master.
#
# Dependencies:
# - Acquia CLI (acli): https://docs.acquia.com/acquia-cli/
#   Install: brew install acquia/acquia-cli/acli
#   Authenticate: acli auth:login
#
# Parameters:
# - Scope | Single application or all applications

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

echo "Code deployment to Acquia PROD for Howard D8 sites."

# Check acli is installed and in PATH
if ! command -v acli &> /dev/null; then
  echo "Error: acli is not installed or not in PATH."
  echo "Install:      brew install acquia/acquia-cli/acli"
  echo "Authenticate: acli auth:login"
  exit 2
fi

# Choose scope
echo "Deploy to:"
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

# Deploy function: tag, push, and acli deploy for one app
deploy_app() {
  local APP="$1"
  local APP_KEY="${APP#@}"
  local LOCAL_FOLDER
  LOCAL_FOLDER=$(get_local_folder_for_app "$APP")

  echo ""
  echo "=== Deploying $APP ==="
  cd "$LOCAL_FOLDER"

  echo "Creating new tag on master..."
  DATE=$( date '+%Y-%m-%d' )
  TAG="$DATE"
  SUFFIX=1
  while [[ -n "$(git tag -l "$TAG")" ]]; do
    TAG="${DATE}.${SUFFIX}"
    ((SUFFIX++))
  done
  git tag -a "$TAG" -m "Creating new Tag"

  git pull origin master
  git push origin master
  git push origin --tags

  VAR_NAME="ACQUIA_ENV_UUID_${APP_KEY}_prod"
  ENV_UUID="${!VAR_NAME}"
  if [ -z "$ENV_UUID" ] || [ "$ENV_UUID" = "UUID_HERE" ]; then
    echo "Error: No prod environment ID configured for ${APP}."
    echo "Add ${VAR_NAME}=\"your-id\" to hal_config.txt."
    return 1
  fi

  echo "Deploying tag ${TAG} to ${APP}.prod..."
  acli api:environments:code-switch "$ENV_UUID" "tags/${TAG}"
}

# Run
for APP in "${TARGET_APPS[@]}"; do
  deploy_app "$APP"
done

echo ""
echo "Deployment complete."
exit 0

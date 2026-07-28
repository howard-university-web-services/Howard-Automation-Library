#!/bin/bash
#
# Flexible drush command runner for Howard D8 Sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh
# Scope: Remote — connects to Acquia environments via drush
#
# Notes:
# - See README.md for detailed instructions.
# - Allows drush commands to be run with flexible targeting:
#   - Single application + single environment
#   - Single application + all environments
#   - All applications + single environment  
#   - All applications + all environments
#
# Dependencies:
# - drush
#
# Parameters:
# - Targeting scope | How to target the command
# - Drush command | ie, pm:enable page_cache
#

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

echo "Flexible drush command runner for Howard D8 sites."

# ============================================================
# Optional CLI arguments (skip interactive prompts)
# Usage: sh update_via_drush.sh [app] [env] [command]
#   app:     all | hud8 | academicdepartments | howardenterprise | centers | uxws
#   env:     dev | test | stg | prod | all  (stg maps to test)
#   command: updb | cr | "pm:enable module_name" | etc.
# Examples:
#   sh update_via_drush.sh all dev updb
#   sh update_via_drush.sh all prod cr
#   sh update_via_drush.sh hud8 dev "pm:enable page_cache"
# ============================================================

TARGET_APPS=()
TARGET_ENVS=()

if [[ -n "$1" ]]; then
  _arg="$(echo "$1" | tr '[:upper:]' '[:lower:]')"
  _arg="${_arg#@}"
  if [[ "$_arg" == "all" ]]; then
    TARGET_APPS=("${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}")
    echo "App(s):  All Applications"
  else
    SELECTED_APP="@${_arg}"
    TARGET_APPS=("$SELECTED_APP")
    echo "App:     $SELECTED_APP"
  fi
fi

if [[ -n "$2" ]]; then
  _env="$(echo "$2" | tr '[:upper:]' '[:lower:]')"
  [[ "$_env" == "stg" ]] && _env="test"
  if [[ "$_env" == "all" ]]; then
    TARGET_ENVS=("dev" "test" "prod")
    echo "Env(s):  all (dev, test, prod)"
  else
    SELECTED_ENV="$_env"
    TARGET_ENVS=("$_env")
    echo "Env:     $_env"
  fi
fi

if [[ -n "$3" ]]; then
  DRUSH_COMMAND="$3"
  echo "Command: $DRUSH_COMMAND"
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

# Get the drush command
if [[ -z "$DRUSH_COMMAND" ]]; then
  echo "Enter the drush command. (e.g. pm:enable page_cache):"
  read DRUSH_COMMAND

  # Check drush command is not empty
  if [ -z "$DRUSH_COMMAND" ]; then
    echo "The drush command cannot be empty!"
    exit 2
  fi
fi

# Confirm before execution
echo ""
echo "About to run: '$DRUSH_COMMAND'"
echo "On applications: ${TARGET_APPS[*]}"
echo "On environments: ${TARGET_ENVS[*]}"
echo ""
echo "Do you want to continue? (y/N)"
read CONFIRM

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

# Execute the command
echo "Executing drush command..."
for APP in "${TARGET_APPS[@]}"; do
    for ENV in "${TARGET_ENVS[@]}"; do
        FULL_ALIAS="$APP.$ENV"
        echo ""
        echo "Running on $FULL_ALIAS..."
        ${LOCAL_DRUSH} $FULL_ALIAS ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh $DRUSH_COMMAND"
        ${LOCAL_DRUSH} $FULL_ALIAS ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh maint:set 0"
        echo "✓ Completed on $FULL_ALIAS"
    done
done

echo ""
echo "All drush commands completed successfully!"

exit 0

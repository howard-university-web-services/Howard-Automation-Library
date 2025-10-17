#!/bin/bash
#
# Flexible drush command runner for Howard D8 Sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh
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

echo "Flexible drush command runner for Howard D8 sites."

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

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

# Get the drush command
echo "Enter the drush command. (e.g. pm:enable page_cache):"
read DRUSH_COMMAND

# Check drush command is not empty
if [ -z "$DRUSH_COMMAND" ]; then
  echo "The drush command cannot be empty!"
  exit 2
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
        echo "✓ Completed on $FULL_ALIAS"
    done
done

echo ""
echo "All drush commands completed successfully!"

exit 0

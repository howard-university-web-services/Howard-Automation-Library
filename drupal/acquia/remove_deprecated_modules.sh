#!/bin/bash
#
# Remove module database references across Howard D8 installs on Acquia.
#
# $ sh ~/Sites/_hal/drupal/acquia/remove_deprecated_modules.sh
# Scope: Remote — connects to Acquia environments via drush
#
# Notes:
# - See README.md for detailed instructions.
# - Removes key_value system.schema entries and config table entries for the given module(s)
# - Flexible targeting options for precise cleanup
#
# Dependencies:
# - drush
#
# Parameters:
# - Module machine name(s) | space-separated list entered at prompt
# - Targeting scope | How to target the removal
#

echo "This script will remove module database references on Howard Acquia environments."

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

# Prompt for module machine name(s)
echo "Enter module machine name(s) to remove, space-separated (e.g. ckeditor tour seven):"
read -r MODULE_INPUT
if [ -z "$MODULE_INPUT" ]; then
  echo "No module names entered. Exiting."
  exit 1
fi
read -ra MODULES_TO_REMOVE <<< "$MODULE_INPUT"

# Choose targeting scope
echo ""
echo "Choose removal scope:"
SCOPES=( "Single Application + Single Environment" "Single Application (all environments)" "All Applications + Single Environment" "All Applications (all environments)" )
select SCOPE in "${SCOPES[@]}"; do
    case $SCOPE in
        "Single Application + Single Environment")
            select_app_and_env
            TARGET_APPS=("$SELECTED_APP")
            TARGET_ENVS=("$SELECTED_ENV")
            break
            ;;
        "Single Application (all environments)")
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
        "All Applications (all environments)")
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

# Confirm before execution
echo ""
echo "About to remove database references for: ${MODULES_TO_REMOVE[*]}"
echo "Applications: ${TARGET_APPS[*]}"
echo "Environments: ${TARGET_ENVS[*]}"
echo ""
echo "Do you want to continue? (y/N)"
read CONFIRM

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

# Execute removal
echo "Starting module database cleanup..."
for APP in "${TARGET_APPS[@]}"; do
    for ENV in "${TARGET_ENVS[@]}"; do
        FULL_ALIAS="$APP.$ENV"
        echo ""
        echo "Cleaning up $FULL_ALIAS..."

        for MODULE in "${MODULES_TO_REMOVE[@]}"; do
            echo "  Removing system.schema entry for $MODULE..."
            ${LOCAL_DRUSH} $FULL_ALIAS ssh "bash /var/www/html/\${AH_SITE_NAME}/scripts/hal_sites.sh sql-query \"DELETE FROM key_value WHERE collection='system.schema' AND name='$MODULE';\" || echo '  No system.schema entry found for $MODULE'"

            echo "  Removing config table entries for $MODULE..."
            ${LOCAL_DRUSH} $FULL_ALIAS ssh "bash /var/www/html/\${AH_SITE_NAME}/scripts/hal_sites.sh sql-query \"DELETE FROM config WHERE name LIKE '${MODULE}.%';\" || true"
        done

        echo "  Clearing cache..."
        ${LOCAL_DRUSH} $FULL_ALIAS ssh "bash /var/www/html/\${AH_SITE_NAME}/scripts/hal_sites.sh cr"

        echo "$FULL_ALIAS cleanup complete."
    done
done

echo ""
echo "All done. Verify sites are functioning properly."

exit 0

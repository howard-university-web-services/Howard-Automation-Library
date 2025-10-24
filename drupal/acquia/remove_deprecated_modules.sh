#!/bin/bash
#
# Remove deprecated module database references across Howard D8 installs on Acquia.
#
# $ sh ~/Sites/_hal/drupal/acquia/remove_deprecated_modules.sh
#
# Notes:
# - See README.md for detailed instructions.
# - Cleans up database references for deprecated modules like ckeditor, mysql57, tour, seven
# - These modules are no longer in Drupal 11 codebase but may have lingering DB entries
# - Flexible targeting options for precise cleanup
#
# Dependencies:
# - drush
#
# Parameters:
# - Targeting scope | How to target the module removal
#

echo "This script will clean up deprecated module database references on Howard Acquia environments with flexible targeting."

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

# Define deprecated modules to remove
DEPRECATED_MODULES=(
    "ckeditor"
    "mysql57" 
    "tour"
    "seven"
    "ckeditor_lts"
)

echo "The following deprecated module database references will be cleaned up:"
printf '%s\n' "${DEPRECATED_MODULES[@]}"
echo ""

# Choose targeting scope
echo "Choose module removal scope:"
SCOPES=( "Single Application (all environments)" "Single Application + Single Environment" "All Applications + Single Environment" "All Applications (all environments)" )
select SCOPE in "${SCOPES[@]}"; do
    case $SCOPE in
        "Single Application (all environments)")
            select_app_only
            TARGET_APPS=("$SELECTED_APP")
            TARGET_ENVS=("dev" "test" "prod")
            break
            ;;
        "Single Application + Single Environment")
            select_app_and_env
            TARGET_APPS=("$SELECTED_APP")
            TARGET_ENVS=("$SELECTED_ENV")
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
echo "About to clean up deprecated module database references from:"
echo "Applications: ${TARGET_APPS[*]}"
echo "Environments: ${TARGET_ENVS[*]}"
echo "Modules: ${DEPRECATED_MODULES[*]}"
echo ""
echo "Do you want to continue? (y/N)"
read CONFIRM

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

# Execute module removal
echo "Starting deprecated module database cleanup..."
for APP in "${TARGET_APPS[@]}"; do
    for ENV in "${TARGET_ENVS[@]}"; do
        FULL_ALIAS="$APP.$ENV"
        echo ""
        echo "🔄 Cleaning up deprecated module database references from $FULL_ALIAS..."
        
        # Clean up deprecated module database references
        # These modules are no longer in the codebase but may have lingering DB entries
        echo "   Cleaning up deprecated module database references..."
        
        # Use sql-query to remove module entries from the database
        for MODULE in "${DEPRECATED_MODULES[@]}"; do
            echo "   Removing database references for $MODULE..."
            ${LOCAL_DRUSH} $FULL_ALIAS ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh sql-query \"DELETE FROM key_value WHERE collection='system.schema' AND name='$MODULE';\" || echo '   No database references found for $MODULE'"
        done
        
        # Also clean up any config entries for these modules
        echo "   Cleaning up config entries..."
        ${LOCAL_DRUSH} $FULL_ALIAS ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh sql-query \"DELETE FROM config WHERE name LIKE 'ckeditor.%' OR name LIKE 'seven.%' OR name LIKE 'tour.%';\" || true"
        
        # Clear cache after removal
        echo "   Clearing cache..."
        ${LOCAL_DRUSH} $FULL_ALIAS ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh cr"
        
        echo "✅ $FULL_ALIAS deprecated module database cleanup complete"
    done
done

echo ""
echo "🎉 All deprecated module database references cleaned up successfully!"
echo ""
echo "Next steps:"
echo "1. Verify sites are functioning properly"
echo "2. Remove deprecated modules from composer.json if needed"
echo "3. Commit and deploy changes"

exit 0

#!/bin/bash
#
# Update database on Howard D8 installs on Acquia.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_db_on_acquia.sh
#
# Notes:
# - See README.md for detailed instructions.
# - Flexible targeting options for precise database updatessh
#
# Update database on Howard D8 installs on Acquia (Improved Version).
#
# $ sh ~/Sites/_hal/drupal/acquia/update_db_on_acquia_improved.sh
#
# Notes:
# - See README.md for detailed instructions.
# - Improved version with flexible targeting options
#
# Dependencies:
# - drush
#
# Parameters:
# - Targeting scope | How to target the database updates
#

echo "This script will update databases on Howard Acquia environments with flexible targeting."

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

# Choose targeting scope
echo "Choose database update scope:"
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
echo "About to run database updates (updb) on:"
echo "Applications: ${TARGET_APPS[*]}"
echo "Environments: ${TARGET_ENVS[*]}"
echo ""
echo "Do you want to continue? (y/N)"
read CONFIRM

if [[ $CONFIRM != "y" && $CONFIRM != "Y" ]]; then
    echo "Cancelled."
    exit 0
fi

# Execute database updates
echo "Starting database updates..."
for APP in "${TARGET_APPS[@]}"; do
    for ENV in "${TARGET_ENVS[@]}"; do
        FULL_ALIAS="$APP.$ENV"
        echo ""
        echo "🔄 Running database updates on $FULL_ALIAS..."
        ${LOCAL_DRUSH} $FULL_ALIAS ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh updb"
        ${LOCAL_DRUSH} $FULL_ALIAS ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh maint:set 0"
        echo "✅ $FULL_ALIAS database updates complete"
    done
done

echo ""
echo "🎉 All database updates completed successfully!"

exit 0

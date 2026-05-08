#!/bin/bash
#
# Partial. Runs a remote list script across all Howard D8 apps on a chosen environment.
# Requires LABEL and REMOTE_SCRIPT to be set before sourcing.
#

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

select_env_only

# Foreach drush alias, go on the server and run the script.
for APP in ${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}; do
  echo "Running $LABEL for $APP.$SELECTED_ENV"
  ${LOCAL_DRUSH} $APP.$SELECTED_ENV ssh "bash /var/www/html/\${AH_SITE_NAME}/scripts/${REMOTE_SCRIPT}"
done

echo "Listing complete."

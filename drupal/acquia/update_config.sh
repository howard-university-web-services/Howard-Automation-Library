#!/bin/bash
#
# Update specific config on Howard D8 Sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_config.sh
#
# Notes:
# - See README.md for detailed instructions.
# - See https://drushcommands.com/drush-8x/config/config-set/
# - Precise application and environment targeting
#
# Dependencies:
# - drush
#
# Parameters:
# - Application | Choose which Howard application
# - Environment | Choose which environment (dev/test/prod)
# - Config Name | ie, system.site
# - Config Key | ie, page.front
# - Config Value | ie, node/123
#

echo "Updating custom config for a specific Howard D8 site and environment."

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

# Use the standardized selection function
select_app_and_env

# Config Name, use as $CONFIG_NAME
echo "Enter the Config Name. (e.g. system.site):"
read CONFIG_NAME

# Check Config Name is not empty
if [ -z "$CONFIG_NAME" ]; then
  echo "The Config Name cannot be empty!"
  exit 2
fi

# Config Key, use as $CONFIG_KEY
echo "Enter the Config Key. (e.g. page.front):"
read CONFIG_KEY

# Check Config Name is not empty
if [ -z "$CONFIG_KEY" ]; then
  echo "The Config Key cannot be empty!"
  exit 2
fi

# Config Value, use as $CONFIG_VALUE
echo "Enter the Config Value. (e.g. node/123):"
read CONFIG_VALUE

# Check Config Name is not empty
if [ -z "$CONFIG_VALUE" ]; then
  echo "The Config Value cannot be empty!"
  exit 2
fi

echo "Running config updates for $FULL_ALIAS"
echo "Setting $CONFIG_NAME:$CONFIG_KEY to '$CONFIG_VALUE'"

# Run the update on the specific application and environment
${LOCAL_DRUSH} $FULL_ALIAS ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh config:set $CONFIG_NAME $CONFIG_KEY '$CONFIG_VALUE'"

echo "Config update complete on $FULL_ALIAS."

exit 0

#!/bin/bash
#
# Update specific config on all howard D8 Sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_config.sh
#
# Notes:
# - See README.md for detailed instructions.
# - See https://drushcommands.com/drush-8x/config/config-set/
#
# Dependencies:
# - drush
#
# Paramaters:
# - Config Name | ie, system.site
# - Config Key | ie, page.front
# - Config Value | ie, node/123
#

echo "Updating custom config for Howard D8 sites."

source ~/Sites/_hal/hal_config.txt

# Choose acquia env for drush aliases
echo "Please choose which acquia env to run this on:"
ENVS=(".dev.dev" ".test.test" ".prod.prod")
select ENV in "${ENVS[@]}"
do
  echo "$ENV selected"
  break
done

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

# Foreach drush alias, go on the server and set.
for APP in ${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}; do
  echo "Running config updates for $APP$ENV"
  ${LOCAL_DRUSH} $APP$ENV ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh cset $CONFIG_NAME $CONFIG_KEY $CONFIG_VALUE"
done

echo "Config updates complete."

exit 0

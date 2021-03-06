#!/bin/bash
#
# Update specific config on all howard D8 Sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh
#
# Notes:
# - See README.md for detailed instructions.
# - Allows drush commands to be run on all sites and environments.
#
# Dependencies:
# - drush
#
# Paramaters:
# - Drush command | ie, pm-uninstall page_cache
#

echo "Updating via drush for Howard D8 sites."

source ~/Sites/_hal/hal_config.txt

# Choose acquia env for drush aliases
echo "Please choose which acquia env to run this on:"
ENVS=(".dev" ".test" ".prod")
select ENV in "${ENVS[@]}"
do
  echo "$ENV selected"
  break
done

# Config Name, use as $DRUSH_COMMAND
echo "Enter the drush command. (e.g. pm:enable page_cache):"
read DRUSH_COMMAND

# Check Config Name is not empty
if [ -z "$DRUSH_COMMAND" ]; then
  echo "The drush command cannot be empty!"
  exit 2
fi

# Foreach drush alias, go on the server and set.
for APP in ${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}; do
  echo "Running config updates for $APP$ENV"
  ${LOCAL_DRUSH} $APP$ENV ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh $DRUSH_COMMAND"
done

echo "drush updates complete on $APP$ENV."

exit 0

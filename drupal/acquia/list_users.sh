#!/bin/bash
#
# Update specific config on all howard D8 Sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/list_users.sh
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

DRUSH_COMMAND = "sqlq 'SELECT users_field_data.uid,users_field_data.name,users_field_data.mail,from_unixtime(users_field_data.login) AS \"lastlogin\",user__roles.roles_target_id,users_field_data.status FROM users_field_data LEFT JOIN user__roles ON users_field_data.uid = user__roles.entity_id WHERE users_field_data.status=\"1\" AND user__roles.roles_target_id=\"site_builder\"'"

# Foreach drush alias, go on the server and set.
for APP in ${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}; do
  echo "Running config updates for $APP$ENV"
  ${LOCAL_DRUSH} $APP$ENV ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh $DRUSH_COMMAND"
done

echo "drush updates complete on $APP$ENV."

exit 0

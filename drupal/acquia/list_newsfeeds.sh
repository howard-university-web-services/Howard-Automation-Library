#!/bin/bash
#
# List News feed widget use on on all howard D8 Sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/list_newsfeeds.sh
#
# Notes:
# - See README.md for detailed instructions.
# - Interacts with /scripts/hal_newsfeed_list.sh on the hud8 and ad servers. If updates needed to that script, must be done in both places.
#
# Dependencies:
# - drush
#
# Paramaters:
# - none
#

echo "Listing News Feeds for Howard D8 sites."

source ~/Sites/_hal/hal_config.txt

# Choose acquia env to run on.
echo "Please choose which acquia env to run this on:"
ENVS=(".dev" ".test" ".prod")
select ENV in "${ENVS[@]}"
do
  echo "$ENV selected"
  break
done

# Foreach drush alias, go on the server and set.
for APP in ${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}; do
  echo "Running news feed lists for $APP$ENV"
  ${LOCAL_DRUSH} $APP$ENV ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_newsfeed_list.sh"
done

echo "drush listing complete on $APP$ENV."

exit 0

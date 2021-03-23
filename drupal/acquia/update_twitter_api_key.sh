#!/bin/bash
#
# Update the twitter API key on all howard D8 Sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_twitter_api_key.sh
#
# Notes:
# - See README.md for detailed instructions.
#
# Dependencies:
# - drush
#
# Paramaters:
# - Twitter Credentials | Can be entered on command, or set defaults | defaults read from hal_config.txt
#

echo "Updating the Twitter API key for Howard D8 sites."

source ~/Sites/_hal/hal_config.txt

# Choose acquia env for drush aliases
echo "Please choose which acquia env to run this on:"
ENVS=(".dev.dev" ".test.test" ".prod.prod")
select ENV in "${ENVS[@]}"
do
  echo "$ENV selected"
  break
done

# API Key
echo "API Key:"
read API_KEY
API_KEY=${API_KEY:-$TWITTER_API_KEY}

# API Secret
echo "API Secret:"
read API_SECRET
API_SECRET=${API_SECRET:-$TWITTER_API_SECRET}

# Access Token
echo "Access Token:"
read ACCESS_TOKEN
ACCESS_TOKEN=${ACCESS_TOKEN:-$TWITTER_ACCESS_TOKEN}

# Access Secret
echo "Access Secret:"
read ACCESS_SECRET
ACCESS_SECRET=${ACCESS_SECRET:-$TWITTER_ACCESS_SECRET}

# Foreach drush alias, go on the server and set.
for APP in ${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}; do
  echo "Running twitter credential updates for $APP$ENV"
  ${LOCAL_DRUSH} $APP$ENV ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh cset hp_twitter_feed.settings api_key $API_KEY"
  ${LOCAL_DRUSH} $APP$ENV ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh cset hp_twitter_feed.settings api_secret $API_SECRET"
  ${LOCAL_DRUSH} $APP$ENV ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh cset hp_twitter_feed.settings access_token $ACCESS_TOKEN"
  ${LOCAL_DRUSH} $APP$ENV ssh "bash /var/www/html/"\${AH_SITE_NAME}"/scripts/hal_sites.sh cset hp_twitter_feed.settings access_secret $ACCESS_SECRET"
done

echo "Updates complete."

exit 0

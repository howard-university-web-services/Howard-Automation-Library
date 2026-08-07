#!/bin/bash
#
# Search for nodes matching a title pattern across all Howard D8 sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/node_search.sh
# Scope: Remote — connects to Acquia environments via drush
#
# Notes:
# - Docs: ~/Sites/_hal/docs/scripts/node_search.md
# - Searches node_field_data.title with a LIKE %term% query on all multisites.
# - Only returns sites that have matching results.
#
# Dependencies:
# - drush
#

echo "Node title search across all Howard D8 sites."

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

# Prompt for search term
echo "Enter the node title search term (partial match, case-insensitive):"
read NODE_SEARCH

if [ -z "$NODE_SEARCH" ]; then
  echo "Search term cannot be empty!"
  exit 2
fi

select_env_only

echo ""
echo "Searching for nodes matching \"${NODE_SEARCH}\" on ${SELECTED_ENV}..."
echo ""

for APP in ${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}; do
  echo "====== ${APP}.${SELECTED_ENV} ======"
  ${LOCAL_DRUSH} ${APP}.${SELECTED_ENV} ssh "NODE_SEARCH='${NODE_SEARCH}' bash /var/www/html/\${AH_SITE_NAME}/scripts/hal_node_search.sh"
done

echo "Search complete."

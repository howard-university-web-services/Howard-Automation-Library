#!/bin/bash
#
# Partial. Runs hal_node_list_csv.sh across all Howard D8 apps on a chosen
# environment, then tallies published/unpublished node totals per app and
# a grand total across all apps.
#

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

select_env_only

GRAND_PUBLISHED=0
GRAND_UNPUBLISHED=0
GRAND_TOTAL=0

declare -a SUMMARY_LINES

# Foreach drush alias, go on the server, dump the node CSV, and tally status.
for APP in ${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}; do
  echo "Counting nodes for $APP.$SELECTED_ENV"
  CSV_OUTPUT=$(${LOCAL_DRUSH} $APP.$SELECTED_ENV ssh "bash /var/www/html/\${AH_SITE_NAME}/scripts/hal_node_list_csv.sh")

  # Only count real CSV rows (site,nid,type,status,title), skip header/log noise.
  APP_PUBLISHED=$(echo "$CSV_OUTPUT" | grep -E '^[a-zA-Z0-9.-]+\.howard\.edu,' | awk -F',' '$4 == 1' | wc -l | tr -d ' ')
  APP_UNPUBLISHED=$(echo "$CSV_OUTPUT" | grep -E '^[a-zA-Z0-9.-]+\.howard\.edu,' | awk -F',' '$4 == 0' | wc -l | tr -d ' ')
  APP_TOTAL=$((APP_PUBLISHED + APP_UNPUBLISHED))

  SUMMARY_LINES+=("$APP.$SELECTED_ENV: published=$APP_PUBLISHED unpublished=$APP_UNPUBLISHED total=$APP_TOTAL")

  GRAND_PUBLISHED=$((GRAND_PUBLISHED + APP_PUBLISHED))
  GRAND_UNPUBLISHED=$((GRAND_UNPUBLISHED + APP_UNPUBLISHED))
  GRAND_TOTAL=$((GRAND_TOTAL + APP_TOTAL))
done

echo ""
echo "======================================"
echo "Node count summary ($SELECTED_ENV):"
echo "======================================"
for LINE in "${SUMMARY_LINES[@]}"; do
  echo "$LINE"
done
echo "--------------------------------------"
echo "GRAND TOTAL published nodes:   $GRAND_PUBLISHED"
echo "GRAND TOTAL unpublished nodes: $GRAND_UNPUBLISHED"
echo "GRAND TOTAL nodes (all sites): $GRAND_TOTAL"
echo "======================================"

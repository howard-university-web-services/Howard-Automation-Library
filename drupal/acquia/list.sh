#!/bin/bash
#
# List various data across all Howard D8 Sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/list.sh
# Scope: Remote — connects to Acquia environments via drush
#
# Notes:
# - Docs: ~/Sites/_hal/docs/scripts/list.md
# - Interacts with remote /scripts/hal_*_list.sh scripts on the app servers.
#
# Dependencies:
# - drush
#
# Parameters:
# - List Type | What to list (users, webforms, newsfeeds, magazinefeeds)
#

echo "List data for Howard D8 sites."

# Choose what to list.
echo "What would you like to list?"
LIST_TYPES=( "users" "webforms" "webform_emails" "newsfeeds" "magazinefeeds" "node_counts" )
select LIST_TYPE in "${LIST_TYPES[@]}"; do
  if [[ -z "$LIST_TYPE" ]]; then
    printf '"%s" is not a valid choice\n' "$REPLY" >&2
  else
    break
  fi
done

case $LIST_TYPE in
  "users")         LABEL="user lists";               REMOTE_SCRIPT="hal_user_list.sh" ;;
  "webforms")      LABEL="webform lists";             REMOTE_SCRIPT="hal_webform_list.sh" ;;
  "webform_emails") LABEL="webform email handler lists"; REMOTE_SCRIPT="hal_webform_email_list.sh" ;;
  "newsfeeds")     LABEL="news feed lists";           REMOTE_SCRIPT="hal_newsfeed_list.sh" ;;
  "magazinefeeds") LABEL="magazine feed lists";       REMOTE_SCRIPT="hal_magazinefeed_list.sh" ;;
  "node_counts")   LABEL="node counts" ;;
esac

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

if [[ "$LIST_TYPE" == "node_counts" ]]; then
  . $DIR/partials/run_node_count.sh
else
  . $DIR/partials/run_remote_list.sh
fi

exit 0

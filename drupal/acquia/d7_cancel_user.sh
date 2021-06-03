#!/bin/bash
#
# Cancel users on all howard D7 Sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/d7_cancel_user.sh
#
# Notes:
# - See README.md for detailed instructions.
# - Allows users to be cancelled via drush.
#
# Dependencies:
# - drush
#
# Paramaters:
# - Username to cancel | ie, ben.collins
#

echo "Canceling users for Howard D7 sites."

source ~/Sites/_hal/hal_config.txt

APPS=("@howard" "@huschools" "@huenterprise" "@huadminunits")
ENVS=(".dev" ".test" ".prod")

# Username, use as $USERNAME
echo "Enter the desired username to cancel. (e.g. ben.collins):"
read USERNAME

# Check Username is not empty
if [ -z "$USERNAME" ]; then
  echo "The username cannot be empty!"
  exit 2
fi

# Foreach drush alias, go on the server and set.
for APP in ${APPS[@]}; do
  for ENV in ${ENVS[@]}; do
    echo "Running user cancel for $APP$ENV"
    ${LOCAL_DRUSH} $APP$ENV ssh "drush @sites ucan "$USERNAME" -y"
  done
done

echo "drush user cancel complete on $APP$ENV."

exit 0

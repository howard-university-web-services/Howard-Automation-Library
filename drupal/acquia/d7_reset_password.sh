#!/bin/bash
#
# Reset a users password on all howard D7 Sites.
#
# $ sh ~/Sites/_hal/drupal/acquia/d7_reset_password.sh
#
# Notes:
# - See README.md for detailed instructions.
# - Allows a password for a local user to be set accross all d7 env's.
#
# Dependencies:
# - drush
#
# Paramaters:
# - Username to reset | ie, ben.collins
# - Password | New password to use
#

echo "Updating user password via drush for Howard D7 sites."

source ~/Sites/_hal/hal_config.txt

APPS=("@howard" "@huschools" "@huenterprise" "@huadminunits")
ENVS=(".dev" ".test" ".prod")

# Username, use as $USERNAME
echo "Enter the desired username. (e.g. ben.collins):"
read USERNAME

# Check Username is not empty
if [ -z "$USERNAME" ]; then
  echo "The username cannot be empty!"
  exit 2
fi

# Password, use as $PASSWORD
echo "Enter the desired password. (e.g. MY_PASS):"
read PASSWORD

# Check password is not empty
if [ -z "$PASSWORD" ]; then
  echo "The password cannot be empty!"
  exit 2
fi

# Foreach drush alias, go on the server and set.
for APP in ${APPS[@]}; do
  for ENV in ${ENVS[@]}; do
    echo "Running user password change for $APP$ENV"
    ${LOCAL_DRUSH} $APP$ENV ssh 'drush @sites user-password '$USERNAME' --password="'$PASSWORD'" -y'
  done
done

echo "drush user password change complete on $APP$ENV."

exit 0

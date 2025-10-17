#!/bin/bash
#
# This script creates a new tag and deploys it to Howard Acquia environments.

# $ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh
#
# Notes:
# - See README.md for detailed instructions.
#
# Dependencies:
# - Drush: https://www.drush.org/
#
# Parameters:
# - Application | The Howard application to deploy to
# - Environment | The environment to deploy to (dev, test, prod)
# - E-mail | Acquia E-mail
# - Private Key | Acquia private key

source ~/Sites/_hal/hal_config.txt
source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh

# Use standardized app and environment selection
echo "Code deployment for Howard D8 sites."
select_app_and_env

# Navigate to the selected application's local folder
LOCAL_FOLDER=$(get_local_folder_for_app "$SELECTED_APP")
cd "$LOCAL_FOLDER"

echo 'Creating new tag on the master branch'


DATE=$( date '+%Y-%m-%d' )
ADD_TAG=$( git tag -a $DATE -m "Creating new Tag" 2>&1 )

if [[ $ADD_TAG == *"already exists"* ]]
then
  TAG=$( git tag 2>&1 )
  IFS=$'\n' read -ra array <<< $TAG
  VERSION_NUMBER=$(grep -o $DATE  <<< ${array[@]} | wc -l 2>&1 )
  let "VERSION_NUMBER=VERSION_NUMBER-1"
  TAG=$DATE.$VERSION_NUMBER
  git tag -a $TAG -m "Creating new Tag"
else
  TAG=$DATE
fi

# Check if Acquia E-mail and Private Key are not empty
if [ -z "$ACQUIA_EMAIL" ] || [ -z "$ACQUIA_PRIVATE_KEY" ]; then
  echo "You are missing either your Acquia e-mail or Acquia private key. Please update your credienatials"
  exit 2
else
  git pull origin master
  git push origin master
  git push origin --tags
fi

echo "Deploying tag ${TAG} to ${FULL_ALIAS}..."
${LOCAL_DRUSH} ${SELECTED_APP}.prod ssh "drush ${FULL_ALIAS} ac-code-path-deploy tags/${TAG} --email=${ACQUIA_EMAIL} --key=${ACQUIA_PRIVATE_KEY} && exit"

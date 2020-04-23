#!/bin/bash
#
# This script creates a new tag and deploys it to either HUD8 or Academic Departments Acquia Prod environments.

# $ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh
#
# Notes:
# - See README.md for detailed instructions.
#
# Dependencies:
# - Drush: https://www.drush.org/
#
# Paramaters:
# - Acquia Env | The environment to create the site on
# - E-mail | Acquia E-mail
# - Private Key | Acquia private key

source ~/Sites/_hal/hal_config.txt

#Select desired Acquia Enviroment
echo "Select a Acquia Enviroment"
TO_ACQUIA_ENVS=( "@hud8" "@academicdepartments" )
select ACQUIA_ENV in "${TO_ACQUIA_ENVS[@]}"; do
  if [[ -z "$" ]]; then
    printf '"%s" is not a valid choice\n' "$REPLY" >&2
  else
    break
  fi
done

#select  dev docroot folder
if [ $ACQUIA_ENV = "@hud8" ]
then
  cd ${LOCAL_HOWARD_D8_FOLDERS[0]}/docroot/
elif [ $ACQUIA_ENV = "@academicdepartments" ]
then
  cd ${LOCAL_HOWARD_D8_FOLDERS[1]}/docroot/
fi

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

git pull origin master
git push origin master
git push origin --tags

drush @hud8.prod ssh "drush $ACQUIA_ENV.prod ac-code-path-deploy tags/${TAG} --email=${E_MAIL} --key=${PRIVATE_KEY} && exit"
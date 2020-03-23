#!/bin/bash
#
# This script creates a new multisite install locally, adjusts settings.php and sites.php with needed parameters,
# create a new multisite DB on acquia, clone the dev.coasdept.howard.edu DB and Files into it.
#
# $ sh ~/Sites/_hal/drupal/acquia/create_new_multisite.sh
#
# Notes:
# - See README.md for detailed instructions.
#
# Dependencies:
# - Drush: https://www.drush.org/
#
# Paramaters:
# - Acquia Env | The environment to create the site on
# - HR Name | 'Example Site' | 'Example School'
# - Site Name | 'example.howard.edu' | 'school.howard.edu'
# - Database Name | 'example' | The machine name of the DB added to acquia
#

echo "This script will create the local sites folder, commit and push to acquia."
echo "Be sure you are on the correct branch to deploy to DEV env."

source ~/Sites/_hal/hal_config.txt

# Acquia ENV to create site on, use as $ACQUIA_ENV
TO_ACQUIA_ENVS=( "@hud8.dev" "@academicdepartments.dev" )
select ACQUIA_ENV in "${TO_ACQUIA_ENVS[@]}"; do
  if [[ -z "$" ]]; then
    printf '"%s" is not a valid choice\n' "$REPLY" >&2
  else
    break
  fi
done

# Human Readable Name, use as $HR_NAME
echo "Enter the Human Readable Name. The Human Readable name of the site (e.g. Example Site):"
read HR_NAME

# Check Human Readable name is not empty
if [ -z "$HR_NAME" ]; then
  echo "The HR name cannot be empty!"
  exit 2
fi

# Site Name, use as $SITE_NAME
echo "Enter the Site Name. The folder that will be created in /sites. This should follow the URL pattern(e.g. example.howard.edu):"
read SITE_NAME

# Check site name is not empty
if [ -z "$SITE_NAME" ]; then
  echo "The site name cannot be empty!"
  exit 2
fi

# Database Name, use as $DATABASE_NAME
echo "Enter the Database Name. The name of the database that was created on acquia (e.g. example_howard):"
read DATABASE_NAME

# Check database name is not empty
if [ -z "$DATABASE_NAME" ]; then
  echo "The database name cannot be empty!"
  exit 2
fi

# Move to proper folder
echo "Moving to proper folder..."
if [ $ACQUIA_ENV = "@hud8.dev" ]
then
  cd ${LOCAL_HOWARD_D8_FOLDERS[0]}/docroot/sites
elif [ $ACQUIA_ENV = "@academicdepartments.dev" ]
then
  cd ${LOCAL_HOWARD_D8_FOLDERS[1]}/docroot/sites
fi

# Check to ensure we are master git branch, and things are up to date.
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. $DIR/partials/check_git_status.sh

#If this site folder already exists, remove it
if [ -d "$SITE_NAME" ]; then
    echo "$SITE_NAME is a directory that exists, overwritting..."
    rm -R $SITE_NAME
fi

# Copy _starter folder, which is our stock starter
echo "Copying starter site folder locally..."
cp -R _starter_ $SITE_NAME
chmod -R 777 $SITE_NAME

# Adjust sites.php for dev, stg, prod URL's
# Insert at line 3, line break at the end
echo "Adding dev, stg, and prod URL's to sites.php..."
sed -i '' '3i\'$'\n'" \ \ \ \ 'dev.${SITE_NAME}' => '${SITE_NAME}',"$'\\\n' sites.php
sed -i '' '3i\'$'\n'" \ \ \ \ 'stg.${SITE_NAME}' => '${SITE_NAME}',"$'\\\n' sites.php
sed -i '' '3i\'$'\n'" \ \ \ \ '${SITE_NAME}' => '${SITE_NAME}',"$'\\\n' sites.php

# Move to new sites folder
cd $SITE_NAME

# Reconfigure settings.php
echo "Reconfiguring settings.php..."
find . -type f -exec sed -i '' -e "s/SITENAME/${SITE_NAME}/g" {} \;
find . -type f -exec sed -i '' -e "s/DATABASENAME/${DATABASE_NAME}/g" {} \;

# Git commit and push
echo "commiting to git, and pushing..."
cd ../
git add .
git commit -m 'Adding new multisite, via Howard Automation Library'
git push origin master

# Clone database
echo "cloning database..."
drush @hud8.dev --uri=dev.coasdept.howard.edu sql-dump --result-file= > hal_coasdept_dump.sql
drush $ACQUIA_ENV --uri=dev.$SITE_NAME sql-drop
drush $ACQUIA_ENV --uri=dev.$SITE_NAME sql-cli < hal_coasdept_dump.sql
rm hal_coasdept_dump.sql

# Copy Files
echo "copying files..."
if [ $ACQUIA_ENV = "@hud8.dev" ]
then
  scp -3 -r hud8.dev@staging-14271.prod.hosting.acquia.com:/mnt/files/hud8.dev/sites/coasdept.howard.edu/files hud8.dev@staging-14271.prod.hosting.acquia.com:/mnt/files/academicdepartments.dev/sites/$SITE_NAME
elif [ $ACQUIA_ENV = "@academicdepartments.dev" ]
then
  scp -3 -r hud8.dev@staging-14271.prod.hosting.acquia.com:/mnt/files/hud8.dev/sites/coasdept.howard.edu/files academicdepartments.dev@staging-14271.prod.hosting.acquia.com:/mnt/files/academicdepartments.dev/sites/$SITE_NAME
fi

# Clear cache
drush $ACQUIA_ENV --uri=dev.$SITE_NAME cr

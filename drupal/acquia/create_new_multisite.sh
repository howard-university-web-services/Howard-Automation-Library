#!/bin/bash
#
# This script creates a new multisite install locally, adjusts settings.php and sites.php with needed parameters,
# create a new multisite DB on acquia, clone the dev.coasdept.howard.edu DB and Files into it.
#
# Notes:
# - Be sure hal_config.txt is set up and working
# - Refresh all drush aliases via dev desktop or similar
# - Be sure you are on master branch, and that the env in question has DEV ENV set to MASTER.
# - Be sure you run from ~/Sites/devdesktop/DESIRED_CODEBASE/docroot/sites
#
# Dependencies:
# - Drush: https://www.drush.org/
# - Acquia CLI: https://github.com/typhonius/acquia_cli
#
# Parameters:
# - HR Name | 'Example Site' | 'Example School'
# - Site Name | 'example.howard.edu' | 'school.howard.edu'
# - Database Name | 'example' | 'school'
# - Acquia API Email | 'your.email@howard.edu' | read from hal_config.txt
# - Acquia API Key | 'xxxxxxxxxxxxxxxxxxxxxxxx' | read from hal_config.txt
#

echo "This script will create the local sites folder, commit and push to acquia."
echo "Be sure you are on the correct branch to deploy to DEV env."

source ~/Sites/_hal/hal_config.txt

# Human Readable Name, use as $HR_NAME
echo "Enter the Human Readable Name. The Human Readable name of the site (e.g. Example Site):"
read HR_NAME

# Check database name is not empty
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
echo "Enter the Database Name. The name of the database that will be created on acquia (e.g. example):"
read DATABASE_NAME

# Check database name is not empty
if [ -z "$DATABASE_NAME" ]; then
  echo "The database name cannot be empty!"
  exit 2
fi

#If this site folder already exists, remove it
if [ -d "$SITE_NAME" ]; then
    echo "$SITE_NAME is a directory that exists, overwritting..."
    rm -R $SITE_NAME
fi

# Copy _starter folder, which is our starter
echo "Copying starter site folder locally..."
cp -R _starter_ $SITE_NAME

# Adjust sites.php for dev, stg, prod
# Insert at line 3, line break at the end
echo "Adding dev, stg, and prod URL's to settings.php..."
sed -i '' '3i\'$'\n'" \ \ \ \ 'dev.${SITE_NAME}' => '${SITE_NAME}',"$'\\\n' sites.php
sed -i '' '3i\'$'\n'" \ \ \ \ 'stg.${SITE_NAME}' => '${SITE_NAME}',"$'\\\n' sites.php
sed -i '' '3i\'$'\n'" \ \ \ \ '${SITE_NAME}' => '${SITE_NAME}',"$'\\\n' sites.php

# Move to new sites folder
cd $SITE_NAME

# Reconfigure settings.php
echo "Reconfiguring settings.php..."
find . -type f -exec sed -i '' -e "s/SITENAME/${SITE_NAME}/g" {} \;
find . -type f -exec sed -i '' -e "s/DATABASENAME/${DATABASE_NAME}/g" {} \;

echo "commiting to git, and pushing..."
git add .
git commit -m 'Adding $HR_NAME ($SITE_NAME), via Howard Automation Library'
git push origin master --force

# Acquia notes, to be finalized/tested:
# drush ac-api-login --email=dan.rogers@idfive.com --key=a55e882d-00bc-4764-b750-9cefd7446738 --endpoint=https://cloudapi.acquia.com/v1
# look at api v1 vs v2 look at drush commands, they seem to be about EOL
# ~/Sites/_hal/acquia_cli/bin/acquiacli list

# drush @hud8.dev --uri=dev.coasdept.howard.edu sql-dump --result-file= > hal_coasdept_dump.sql
# drush @academicdepartments.dev --uri=dev.$SITE_NAME sql-drop
# drush @academicdepartments.dev --uri=dev.$SITE_NAME sql-cli < hal_coasdept_dump.sql
# rm hal_coasdept_dump.sql
# NOT YET WORKING drush @academicdepartments.dev --uri=dev.coas.howard.edu cset system.site name "${HR_NAME}"
# scp -3 -r hud8.dev@staging-14271.prod.hosting.acquia.com:/mnt/files/hud8.dev/sites/coasdept.howard.edu/files academicdepartments.dev@staging-14271.prod.hosting.acquia.com:/mnt/files/academicdepartments.dev/sites/$SITE_NAME
# drush @academicdepartments.dev --uri=dev.$SITE_NAME cr

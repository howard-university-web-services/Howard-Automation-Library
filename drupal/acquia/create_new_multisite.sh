#!/bin/bash
#
# This script creates a new multisite install locally, adjusts settings.php and sites.php with needed parameters, 
# create a new multisite DB on acquia, clone the dev.coasdept.howard.edu DB and Files into it.
#
# $ sh ~/Sites/_ial/drupal/pantheon/create_new_pantheon_site.sh
#
# Dependencies:
# - Drush: https://www.drush.org/
# - Acquia CLI: https://github.com/typhonius/acquia_cli
#
# Paramaters:
# - Site Name | 'example.howard.edu'
# - Database Name | 'example'
#

echo "This script will create the local sites folder, commit and push to acquia."
echo "Be sure you are on the correct branch to deploy to DEV env."

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

# Move to the sites folder
# cd ~/Sites/devdesktop/docroot/sites

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
cd $site_name

# Reconfigure settings.php
echo "Reconfiguring settings.php..."
find . -type f -exec sed -i '' -e "s/SITENAME/${SITE_NAME}/g" {} \;
find . -type f -exec sed -i '' -e "s/DATABASENAME/${DATABASE_NAME}/g" {} \;
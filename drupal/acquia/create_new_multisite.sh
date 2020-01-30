
#!/bin/bash
#
# This script creates a new multisite install locally, adjusts settings.php and sites.php with needed parameters,
# create a new multisite DB on acquia, clone the dev.coasdept.howard.edu DB and Files into it.
#
# $ sh ~/Sites/_hal/drupal/acquia/create_new_multisite.sh
#
# Notes:
# - Be sure hal_config.txt is set up and working
# - Refresh all drush aliases via dev desktop or similar
# - Be sure you are on master branch, and that the env in question has DEV ENV set to MASTER.
# - Be sure you run from ~/Sites/devdesktop/DESIRED_CODEBASE/docroot/sites
# - Be sure you have created a database on the desired acquia install, and that you have the machine name handy.
#
# Dependencies:
# - Drush: https://www.drush.org/
# - Acquia CLI: https://github.com/typhonius/acquia_cli
#
# Paramaters:
# - Acquia Env | The environment to create the site on
# - HR Name | 'Example Site' | 'Example School'
# - Site Name | 'example.howard.edu' | 'school.howard.edu'
# - Database Name | 'example' | 'school'
# - Acquia API Email | 'your.email@howard.edu' | read from hal_config.txt
# - Acquia API Key | 'xxxxxxxxxxxxxxxxxxxxxxxx' | read from hal_config.txt
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

>>>>>>> master
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

# Move to proper folder
echo "Moving to proper folder..."
if [ $ACQUIA_ENV = "@hud8.dev" ]
then
  cd ${LOCAL_HOWARD_D8_FOLDERS[0]}/docroot/sites
elif [ $ACQUIA_ENV = "@academicdepartments.dev" ]
then
  cd ${LOCAL_HOWARD_D8_FOLDERS[1]}/docroot/sites
fi

# Copy _starter folder, which is our starter
echo "Copying starter site folder locally..."
cp -R _starter_ $SITE_NAME
chmod -R 777 $SITE_NAME

# Adjust sites.php for dev, stg, prod
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
git commit -m 'Adding ${HR_NAME} (${SITE_NAME}), via Howard Automation Library'
git push origin master --force

# Acquia notes, to be finalized/tested:
# drush ac-api-login --email=$ACQUIA_API_EMAIL --key=$ACQUIA_API_KEY --endpoint=https://cloudapi.acquia.com/v1
# look at api v1 vs v2 look at drush commands, they seem to be about EOL
# ~/Sites/_hal/acquia_cli/bin/acquiacli list

# Clone database
echo "cloning database..."
drush @hud8.dev --uri=dev.coasdept.howard.edu sql-dump --result-file= > hal_coasdept_dump.sql
drush $ACQUIA_ENV --uri=dev.$SITE_NAME sql-drop
drush $ACQUIA_ENV --uri=dev.$SITE_NAME sql-cli < hal_coasdept_dump.sql
rm hal_coasdept_dump.sql

# NOT YET WORKING drush @academicdepartments.dev --uri=dev.coas.howard.edu cset system.site name "${HR_NAME}"

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

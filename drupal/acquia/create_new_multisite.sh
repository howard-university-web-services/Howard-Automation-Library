#!/bin/bash
#
# This script creates a new multisite install locally, adjusts settings.php and sites.php with needed parameters,
# create a new multisite DB on acquia, clone the stg.coasdept.howard.edu DB and Files into it.
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
# - Push Git | Defines whether to commit and push code
# - Copy DB | Defines whether to copy stg.coasdept DB
# - Copy Files | Defines whether to copy stg.coasdept files
#

echo "This script will create the local sites folder, commit and push to acquia."
echo "Be sure you are on the correct branch to deploy to DEV env."

source ~/Sites/_hal/hal_config.txt
YES_NO=( "YES" "NO" )

# Acquia ENV to create site on, use as $ACQUIA_ENV
TO_ACQUIA_ENVS=( "${LOCAL_HOWARD_D8_DRUSH_ALIAS[0]}.test" "${LOCAL_HOWARD_D8_DRUSH_ALIAS[1]}.test" )
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

# See if user wishes to automatically commit and push.
echo "Do you wish to automatically commit these changes and push to master branch?"
select PUSH_GIT in "${YES_NO[@]}"; do
  if [[ -z "$" ]]; then
    printf '"%s" is not a valid choice\n' "$REPLY" >&2
  else
    break
  fi
done

# See if user wishes to automatically copy database.
echo "Do you wish to automatically copy the stg.coasdept DB to this new site?"
select COPY_DB in "${YES_NO[@]}"; do
  if [[ -z "$" ]]; then
    printf '"%s" is not a valid choice\n' "$REPLY" >&2
  else
    break
  fi
done

# See if user wishes to automatically copy files.
echo "Do you wish to automatically copy the stg.coasdept files to this new site?"
select COPY_FILES in "${YES_NO[@]}"; do
  if [[ -z "$" ]]; then
    printf '"%s" is not a valid choice\n' "$REPLY" >&2
  else
    break
  fi
done

# Move to proper folder
echo "Moving to proper folder..."
if [[ $ACQUIA_ENV = "@hud8.test" ]]
then
  cd ${LOCAL_HOWARD_D8_FOLDERS[0]}/docroot/sites
elif [[ $ACQUIA_ENV = "@academicdepartments.test" ]]
then
  cd ${LOCAL_HOWARD_D8_FOLDERS[1]}/docroot/sites
fi

# Check to ensure we are master git branch, and things are up to date.
DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi
. $DIR/partials/check_git_status.sh

# If not automating git ops, create new branch.
if [[ $PUSH_GIT = "NO" ]]
then
  echo "Creating new git branch, since automatic pushes not chosen."
  STAMP="$(date '+%Y_%m_%d_%H_%M_%S')"
  BRANCH="new_howard_multisite_$STAMP"
  echo "$BRANCH"
  git branch $BRANCH
  git checkout $BRANCH
else
  echo "GIT commits and push enabled, staying on master branch."
fi

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
if [[ $PUSH_GIT = "YES" ]]
then
  echo "commiting to git, and pushing..."
  cd ../
  git add .
  git commit -m 'Adding new multisite, via Howard Automation Library'
  git push origin master
else
  echo "GIT commits and push skipped. Site will not work on acquia untill manually commited and pushed."
fi

# Clone database
if [[ $COPY_DB = "YES" ]]
then
  echo "cloning database..."
  ${LOCAL_DRUSH} -Dssh.tty=0 ${LOCAL_HOWARD_D8_DRUSH_ALIAS[0]}.test --uri=stg.coasdept.howard.edu sql:dump > hal_coasdept_dump.sql
  ${LOCAL_DRUSH} $ACQUIA_ENV --uri=stg.$SITE_NAME sql:drop
  ${LOCAL_DRUSH} $ACQUIA_ENV --uri=stg.$SITE_NAME sql:cli < hal_coasdept_dump.sql
  rm hal_coasdept_dump.sql
else
  echo "Copy Database skipped. All database configuration must be manually done."
fi

# Copy Files
if [[ $COPY_FILES = "YES" ]]
then
  echo "copying files..."
  if [ $ACQUIA_ENV = "${LOCAL_HOWARD_D8_DRUSH_ALIAS[0]}.test" ]
  then
    scp -3 -r hud8.test@staging-14271.prod.hosting.acquia.com:/mnt/files/hud8.test/sites/coasdept.howard.edu/files hud8.test@staging-14271.prod.hosting.acquia.com:/mnt/files/hud8.test/sites/$SITE_NAME
  elif [ $ACQUIA_ENV = "${LOCAL_HOWARD_D8_DRUSH_ALIAS[1]}.test" ]
  then
    scp -3 -r hud8.test@staging-14271.prod.hosting.acquia.com:/mnt/files/hud8.test/sites/coasdept.howard.edu/files academicdepartments.test@staging-14271.prod.hosting.acquia.com:/mnt/files/academicdepartments.test/sites/$SITE_NAME
  fi
else
  echo "Copy files skipped. New site will not have starter images/etc."
fi

# Clear cache
${LOCAL_DRUSH} $ACQUIA_ENV --uri=stg.$SITE_NAME cr

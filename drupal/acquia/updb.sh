#!/bin/bash
#
# This script updates all HUD8 and Academic Dempartment Dev Enviroment databases.
#
#
# $ sh ~/Sites/_hal/drupal/acquia/commit_push_branch_dev.sh
#
# Notes
# - Be sure you run from ~/Sites/devdesktop/DESIRED_CODEBASE/docroot/sites
#
#
# Dependencies:
# - Drush: https://www.drush.org/
# - Acquia CLI: https://github.com/typhonius/acquia_cli


echo "This script will update all databases."

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

# Move to proper folder
echo "Moving to proper folder..."
if [ $ACQUIA_ENV = "@hud8.dev" ]
then
  cd ${LOCAL_HOWARD_D8_FOLDERS[0]}/docroot/sites
elif [ $ACQUIA_ENV = "@academicdepartments.dev" ]
then
  cd ${LOCAL_HOWARD_D8_FOLDERS[1]}/docroot/sites
fi

shopt -s nullglob dotglob
array=(*)

for i in ${array[@]}
do
   if [[ $i == *".edu"* ]]
   then
      printf "drush $ACQUIA_ENV --uri='$i' updb\n" >> "update_db.sh"
   fi
done

echo 'running updates...'
chmod 755 update_db.sh
echo 'yes' | ./update_db.sh
rm update_db.sh
echo 'Databases successfully updated'
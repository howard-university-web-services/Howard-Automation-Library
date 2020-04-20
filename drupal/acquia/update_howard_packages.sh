#!/bin/bash
#
# Update all Howard packagist repos, on all Howard D8 sites, commit, and push to acquia.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_howard_packages.sh
#
# Notes:
# - See README.md for detailed instructions.
#
# Dependencies:
# - Git
# - Composer
#
# Paramaters:
# - Local Howard D8 Folders | an array of absolute paths to folders on your local machine | read from hal_config.txt
# - Push Git | Defines whether to commit and push code
#

echo "This script will update all Howard packagist projects in all local folders specified in hal_config.txt, commit and push to acquia."

source ~/Sites/_hal/hal_config.txt
YES_NO=( "YES" "NO" )

# See if user wishes to automatically commit and push.
echo "Do you wish to automatically commit these changes and push to master branch for each repository?"
select PUSH_GIT in "${YES_NO[@]}"; do
  if [[ -z "$" ]]; then
    printf '"%s" is not a valid choice\n' "$REPLY" >&2
  else
    break
  fi
done

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

composer clearcache

for app in ${LOCAL_HOWARD_D8_FOLDERS[@]}; do
  echo "Running update in $app"
  cd $app
  # Check to ensure we are master git branch, and things are up to date.
  . $DIR/partials/check_git_status.sh

  # If not automating git ops, create new branch.
  if [ $PUSH_GIT = "NO" ]
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

  composer update 'howard/*'

  # If git ops automated, commit and push.
  if [ $PUSH_GIT = "YES" ]
  then
    echo "commiting to git, and pushing..."
    git add .
    git commit -m 'Updating all Howard Packagist themes and modules, via Howard Automation Library'
    git push origin master
  else
    echo "GIT commits and push skipped. Site will not update on acquia untill manually commited and pushed."
  fi

done

exit 0

#!/bin/bash
#
# Partial. To be included in scripts to help ensure we are on master git branch, and up to date.
#
# $ sh ~/Sites/_hal/drupal/acquia/partials/check_git_status.sh
#

# Check to ensure we are master git branch.
BRANCH=$(git rev-parse --abbrev-ref HEAD)
if [[ "$BRANCH" != "master" ]]; then
  echo 'ERROR: Aborting script. Please ensure you are on master git branch, and it is up to date.';
  exit 1;
else
  echo "Git repo is on master branch, continuing..."
fi

# Check to ensure we are all up to date.
UPSTREAM=${1:-'@{u}'}
LOCAL=$(git rev-parse @)
REMOTE=$(git rev-parse "$UPSTREAM")
BASE=$(git merge-base @ "$UPSTREAM")

if [ $LOCAL = $REMOTE ]; then
  echo "Git repo up to date, continuing..."
elif [ $LOCAL = $BASE ]; then
  echo 'ERROR: Aborting script. Please ensure you are on master git branch, and it is up to date.';
  exit 1;
else
  echo 'ERROR: Aborting script. Please ensure you are on master git branch, and it is up to date.';
  exit 1;
fi

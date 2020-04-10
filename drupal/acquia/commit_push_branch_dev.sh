#!/bin/bash
#
# This script checks to see if a user's working tree is not clean
# Next is adds, commits and pushes all working changes to the Dev Enviroment
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
#
# Paramaters:
# - BRANCH_NAME  | 'Branch Name'



echo "This script will add, commit and push all selected branches to acquia."
echo "Please Enter the  Branch name"
read BRANCH_NAME

# Stores the output of git commands in string variables
ref_check=$( git show-ref --verify refs/heads/$BRANCH_NAME 2>&1 )
set_upstream_check=$( git push 2>&1 )

# Checks  Desired Branch is not empty
if [ -z "$BRANCH_NAME" ]
then
    echo "The desired branch name cannot be empty!"
elif [[ $ref_check == *"fatal:"* ]]
then
    echo "$BRANCH_NAME is not a valid branch"
else
    echo "Checking the working tree's status..."
    #Determine if Working tree is clean.
    if test -z "$( git status  --porcelain )"
    then
        echo "Working tree is clean"
    else
        echo "Adding files to index ... "
        git add -A
        git commit -m "Pushing current working changes"
        if [[ $set_upstream_check == *"--set-upstream"*  ]]
        then
            git push --set-upstream origin $BRANCH_NAME
        else
            git push
        fi
    fi
fi

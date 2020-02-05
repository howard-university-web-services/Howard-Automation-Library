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
# - Acquia CLI: https://github.com/typhonius/acquia_cli
#
# Paramaters:
# - Branch_Name  | 'Branch Name'



echo "This script will add, commit and push all selected branches to acquia."
echo "Please Enter the  Branch name"
read Branch_Name

# Stores the output of git commands in string variables
ref_check=$( git show-ref  --verify -- refs/heads/$Branch_Name 2>&1 )
set_upstream_check=$( git push 2>&1 )

# Check Desired Branch is not empty
if [ -z "$Branch_Name" ]
then
    echo "The desired branch name cannot be empty!"
elif [[ $ref_check == *"fatal:"* ]]
then
    echo "$Branch_Name is not a valid branch"
else
    echo "Checking the working tree's status..."
    #Determine if Working tree is clean.
    if test -z "$( git status --porcelain )"
    then
        echo "Working tree is clean"
        exit 2;
    else
        echo "Adding files to index ... "
        git add .
        git commit -m "Pushing current woking changes to Dev enviroment."
        if [[ $set_upstream_check == *"--set-upstream"*  ]]
        then
            git push --set-upstream origin $Branch_Name
        else
            git push
        fi
        exit 2;
    fi
fi






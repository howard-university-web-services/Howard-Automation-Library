#!/bin/bash
#
# Run a full update (Drupal core, all contrib modules/themes, and Howard packages)
# on all Howard D8 sites, commit, and push to acquia.
#
# $ sh ~/Sites/_hal/drupal/acquia/update_all.sh
# Scope: Local — modifies local files and git branches via composer
#
# Notes:
# - See README.md for detailed instructions.
# - Runs in order per site:
#   1. composer update drupal/core drupal/core-recommended drupal/core-composer-scaffold drupal/core-project-message --with-all-dependencies
#   2. composer update "drupal/*" --with-all-dependencies
#   3. composer update "howard/*"
#
# Dependencies:
# - Git
# - Composer
#
# Parameters:
# - Local Howard D8 Folders | an array of absolute paths to folders on your local machine | read from hal_config.txt
# - Push Git | Defines whether to commit and push code
#

echo "This script will run a full update (core, contrib, and Howard packages) in all local folders specified in hal_config.txt, commit and push to acquia."

source ~/Sites/_hal/hal_config.txt
YES_NO=( "YES" "NO" )

# See if user wants a dry run (shows what would change, no files modified).
echo "Do you wish to do a dry run? (Shows what would be updated without making any changes)"
select DRY_RUN in "${YES_NO[@]}"; do
  if [[ -z "$DRY_RUN" ]]; then
    printf '"%s" is not a valid choice\n' "$REPLY" >&2
  else
    break
  fi
done

# Only ask about git push when not doing a dry run.
if [ "$DRY_RUN" = "NO" ]; then
  echo "Do you wish to automatically commit these changes and push to master branch for each repository?"
  select PUSH_GIT in "${YES_NO[@]}"; do
    if [[ -z "$PUSH_GIT" ]]; then
      printf '"%s" is not a valid choice\n' "$REPLY" >&2
    else
      break
    fi
  done
fi

DIR="${BASH_SOURCE%/*}"
if [[ ! -d "$DIR" ]]; then DIR="$PWD"; fi

for app in "${LOCAL_HOWARD_D8_FOLDERS[@]}"; do
  echo "------------------------------------------------------------"
  if [ "$DRY_RUN" = "YES" ]; then
    echo "[DRY RUN] Checking all updates in $app"
  else
    echo "Running full update in $app"
  fi
  cd "$app" || { echo "ERROR: Could not cd into $app, skipping."; continue; }

  if [ "$DRY_RUN" = "NO" ]; then
    composer clearcache

    # Check to ensure we are on master git branch, and things are up to date.
    . "$DIR/partials/check_git_status.sh"

    # If not automating git ops, create a new branch.
    if [ "$PUSH_GIT" = "NO" ]; then
      echo "Creating new git branch, since automatic pushes not chosen."
      STAMP="$(date '+%Y_%m_%d_%H_%M_%S')"
      BRANCH="full_update_$STAMP"
      echo "$BRANCH"
      git branch "$BRANCH"
      git checkout "$BRANCH"
    else
      echo "GIT commits and push enabled, staying on master branch."
    fi
  fi

  # Step 1: Drupal core
  echo "--- Step 1/3: Updating Drupal core ---"
  if [ "$DRY_RUN" = "YES" ]; then
    composer update drupal/core drupal/core-recommended drupal/core-composer-scaffold drupal/core-project-message --with-all-dependencies --dry-run
  else
    composer update drupal/core drupal/core-recommended drupal/core-composer-scaffold drupal/core-project-message --with-all-dependencies
  fi

  # Step 2: Drupal contrib
  echo "--- Step 2/3: Updating Drupal contrib modules and themes ---"
  if [ "$DRY_RUN" = "YES" ]; then
    composer update "drupal/*" --with-all-dependencies --dry-run
  else
    composer update "drupal/*" --with-all-dependencies
  fi

  # Step 3: Howard packages
  echo "--- Step 3/3: Updating Howard packages ---"
  if [ "$DRY_RUN" = "YES" ]; then
    composer update "howard/*" --dry-run
  else
    composer update "howard/*"
  fi

  # If git ops automated, commit and push.
  if [ "$DRY_RUN" = "NO" ] && [ "$PUSH_GIT" = "YES" ]; then
    echo "Committing to git and pushing..."
    git add .
    git commit -m 'Full update: Drupal core, contrib modules/themes, and Howard packages, via Howard Automation Library'
    git push origin master
  elif [ "$DRY_RUN" = "NO" ]; then
    echo "GIT commits and push skipped. Site will not update on acquia until manually committed and pushed."
  fi

done

echo "------------------------------------------------------------"
if [ "$DRY_RUN" = "YES" ]; then
  echo "Dry run complete. No files were modified."
else
  echo "Full update complete for all sites."
fi

exit 0

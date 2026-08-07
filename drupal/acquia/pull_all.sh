#!/bin/bash
#
# Pulls the latest code (git pull) for all local Howard D8 application folders.
#
# $ sh ~/Sites/_hal/drupal/acquia/pull_all.sh
# Scope: Local — runs git pull in each folder defined in hal_config.txt
#
# Notes:
# - Docs: ~/Sites/_hal/docs/scripts/update_all.md
# - Expects each folder to be on master branch and up to date.
# - If a folder has uncommitted changes or is on a non-master branch,
#   git pull may fail or produce unexpected results for that repo.
#
# Dependencies:
# - Git
#
# Parameters:
# - Local Howard D8 Folders | an array of absolute paths | read from hal_config.txt

source ~/Sites/_hal/hal_config.txt

echo "Pulling latest code for all local Howard D8 applications..."
echo ""

ERRORS=()

for APP_FOLDER in "${LOCAL_HOWARD_D8_FOLDERS[@]}"; do
  echo "--- $APP_FOLDER ---"

  if [[ ! -d "$APP_FOLDER" ]]; then
    echo "  ✗ Directory not found — skipping"
    ERRORS+=("$APP_FOLDER")
    echo ""
    continue
  fi

  cd "$APP_FOLDER" || { echo "  ✗ Could not cd into $APP_FOLDER"; ERRORS+=("$APP_FOLDER"); echo ""; continue; }

  BRANCH=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
  if [[ "$BRANCH" != "master" ]]; then
    echo "  ⚠ Warning: currently on branch '$BRANCH' (expected master)"
  fi

  if git pull; then
    echo "  ✓ Done"
  else
    echo "  ✗ git pull failed"
    ERRORS+=("$APP_FOLDER")
  fi
  echo ""
done

echo "========================================"
if [[ ${#ERRORS[@]} -eq 0 ]]; then
  echo "All repositories pulled successfully."
else
  echo "Pull failed or skipped for:"
  for E in "${ERRORS[@]}"; do echo "  - $E"; done
fi
echo "========================================"

exit 0

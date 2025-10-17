#!/bin/bash
#
# Reusable function for selecting application and environment
# Source this file in other scripts to get standardized selection
#
# Usage:
# source ~/Sites/_hal/drupal/acquia/partials/select_app_and_env.sh
# select_app_and_env
# # Now you have $SELECTED_APP and $SELECTED_ENV available
#

select_app_and_env() {
    # First select the application
    echo "Select a Howard Application (@hud8, @academicdepartments, etc.):"
    AVAILABLE_APPS=( "${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}" )
    select SELECTED_APP in "${AVAILABLE_APPS[@]}"; do
        if [[ -z "$SELECTED_APP" ]]; then
            printf '"%s" is not a valid choice\n' "$REPLY" >&2
        else
            echo "Selected application: $SELECTED_APP"
            break
        fi
    done

    # Then select the environment
    echo "Select an Environment (dev, test, prod):"
    AVAILABLE_ENVS=( "dev" "test" "prod" )
    select SELECTED_ENV in "${AVAILABLE_ENVS[@]}"; do
        if [[ -z "$SELECTED_ENV" ]]; then
            printf '"%s" is not a valid choice\n' "$REPLY" >&2
        else
            echo "Selected environment: $SELECTED_ENV"
            break
        fi
    done

    # Create the full drush alias
    FULL_ALIAS="$SELECTED_APP.$SELECTED_ENV"
    echo "Full alias: $FULL_ALIAS"
}

select_app_only() {
    echo "Select a Howard Application (@hud8, @academicdepartments, etc.):"
    AVAILABLE_APPS=( "${LOCAL_HOWARD_D8_DRUSH_ALIAS[@]}" )
    select SELECTED_APP in "${AVAILABLE_APPS[@]}"; do
        if [[ -z "$SELECTED_APP" ]]; then
            printf '"%s" is not a valid choice\n' "$REPLY" >&2
        else
            echo "Selected application: $SELECTED_APP"
            break
        fi
    done
}

select_env_only() {
    echo "Select an Environment (dev, test, prod):"
    AVAILABLE_ENVS=( "dev" "test" "prod" )
    select SELECTED_ENV in "${AVAILABLE_ENVS[@]}"; do
        if [[ -z "$SELECTED_ENV" ]]; then
            printf '"%s" is not a valid choice\n' "$REPLY" >&2
        else
            echo "Selected environment: $SELECTED_ENV"
            break
        fi
    done
}

get_local_folder_for_app() {
    local app=$1
    case $app in
        "@hud8")
            echo "${LOCAL_HOWARD_D8_FOLDERS[0]}"
            ;;
        "@academicdepartments")
            echo "${LOCAL_HOWARD_D8_FOLDERS[1]}"
            ;;
        "@howardenterprise")
            echo "${LOCAL_HOWARD_D8_FOLDERS[2]}"
            ;;
        "@centers")
            echo "${LOCAL_HOWARD_D8_FOLDERS[3]}"
            ;;
        "@uxws")
            echo "${LOCAL_HOWARD_D8_FOLDERS[4]}"
            ;;
        *)
            echo "Unknown application: $app" >&2
            return 1
            ;;
    esac
}

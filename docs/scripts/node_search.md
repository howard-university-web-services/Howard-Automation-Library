# `node_search.sh` — Search Node and Menu Link Titles

**Purpose**: Search for a node title or menu link title (partial match) across all Howard D8 apps and environments.

**Scope**: Remote — queries Acquia databases via drush. No local file changes.

## Usage

```bash
$ sh ~/Sites/_hal/drupal/acquia/node_search.sh
# 1. Enter search term (partial match, case-insensitive)
# 2. Choose environment: dev, test, or prod
```

## Features

- Case-insensitive partial match against both `node_field_data` and `menu_link_content_data` tables
- Only outputs sites with matches (clean output)
- Runs across all five Howard applications for the selected environment

## Use Cases

- Locate where a specific page or piece of content lives across the multisite ecosystem
- Find which sites have a nav link pointing to a given path
- Audit duplicate content titles across apps

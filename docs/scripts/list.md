# `list.sh` — Data Listing Across Sites

**Purpose**: Retrieve and display lists of users, webforms, webform email handlers, news feeds, or magazine feeds across all Howard D8 sites.

**Scope**: Remote — relies on remote `hal_*_list.sh` scripts on the Acquia app servers.

## Usage

```bash
$ sh ~/Sites/_hal/drupal/acquia/list.sh
# 1. Choose list type
# 2. Choose environment: dev, test, or prod
```

## List Types

| Type | What it shows |
|------|--------------|
| `users` | All user accounts per site |
| `webforms` | All webforms with submission counts and embed pages |
| `webform_emails` | All webform email handler configs (to, from, reply-to) — useful for auditing where form submissions go |
| `newsfeeds` | News feed content |
| `magazinefeeds` | Magazine feed content |
| `node_counts` | Published/unpublished node totals per app, plus a grand total across all Howard D8 apps |

## Notes

- Runs across all Howard applications for the chosen environment
- Output is per-site; only sites with results are shown
- `node_counts` is the exception: it aggregates the per-site `hal_node_list_csv.sh` output into published/unpublished/total counts per app and an overall grand total (does not print the raw per-node CSV — use `node_search.sh` or a direct drush call if you need the full node listing)

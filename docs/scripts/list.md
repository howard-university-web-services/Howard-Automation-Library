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

## Notes

- Runs across all Howard applications for the chosen environment
- Output is per-site; only sites with results are shown

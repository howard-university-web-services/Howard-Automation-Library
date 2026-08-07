# `update_via_drush.sh` — Universal Drush Command Runner

**Purpose**: Execute any drush command with flexible targeting across Howard applications and environments.

**Scope**: Remote — connects to Acquia environments via drush. No local file changes.

## Usage

```bash
# Interactive mode:
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh

# CLI mode — skip all prompts:
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh [app] [env] [command]
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all dev cr
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh hud8 prod "pm:enable page_cache"
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all dev updb <<< "y"
```

## Common Commands

| Goal | Drush command |
|------|---------------|
| Clear all caches | `cr` |
| Run database updates | `updb` |
| Import configuration | `config:import` |
| Enable a module | `pm:enable module_name` |
| Uninstall a module | `pm:uninstall module_name` |
| Check site status | `status` |
| Disable a user | `user:cancel first.last` |

## Targeting Options

All four scopes available:

1. **Single App + Single Env** — e.g., `hud8 dev cr`
2. **Single App + All Envs** — e.g., `hud8 all updb`
3. **All Apps + Single Env** — e.g., `all prod cr`
4. **All Apps + All Envs** — use with extreme caution

## Notes

- Enter only the drush command itself — `drush` and `-y` are added automatically.
- Use full command names, not aliases: `pm:enable` not `en`. See [drush issue #3025](https://github.com/drush-ops/drush/issues/3025).
- Runs via `hal_sites.sh` on the server, which loops all `*.howard.edu` sites in the install.

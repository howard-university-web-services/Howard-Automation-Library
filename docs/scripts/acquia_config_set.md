# `acquia_config_set.sh` — Precise Configuration Updates

**Purpose**: Update specific Drupal configuration values on targeted Howard sites using `drush config:set`.

**Scope**: Remote — connects to Acquia environments via drush. No local file changes.

## Usage

```bash
# Interactive mode (recommended — prompts for config name, key, and value):
$ sh ~/Sites/_hal/drupal/acquia/acquia_config_set.sh
# 1. Choose targeting scope
# 2. Select application(s) and environment(s)
# 3. Enter config name (e.g., "system.site")
# 4. Enter config key (e.g., "page.front")
# 5. Enter new value (e.g., "/node/123")
# 6. Confirm execution
```

## Examples

- Set front page on a single app: choose option 1, target specific app+env, set `system.site` / `page.front` / `/node/123`
- Update site name across all environments: choose option 2, single app + all envs
- Change maintenance mode system-wide: choose option 4, all apps + all envs, set `system.maintenance_mode` / `value` / `1`

## Finding Config Names and Keys

- `drush config:get system.site` — lists all keys for a config object
- `drush config:edit system.site` — opens config in editor
- See also: [idfive developer documentation on config overrides](https://developers.idfive.com/#/back-end/drupal/drupal-config-management?id=one-time-config-overrides-via-drush)

## Notes

- Changes are applied directly to the active config in the database — not to exported YAML files
- To make changes permanent in code, export config afterwards with `pull_config_from_env.sh` and commit

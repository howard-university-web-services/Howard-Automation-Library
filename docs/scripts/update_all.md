# Composer Update Scripts

Scripts for updating Drupal core, contrib modules, and Howard packages across all local Howard D8 applications.

**Scope**: Local — operates on your local machine, modifying `composer.json`/`composer.lock` files and committing/pushing to git. Acquia dev picks up the push automatically.

---

## `update_all.sh` — Full Update (Recommended)

Runs all three update operations in sequence per app: Drupal core, all contrib modules/themes, and all Howard packages.

```bash
$ sh ~/Sites/_hal/drupal/acquia/update_all.sh
```

When prompted, say **YES** to commit and push to master. If git automation is declined, a new branch `full_update_TIMESTAMP` is created locally.

---

## `pull_all.sh` — Pull Latest Code

Pulls the latest master branch for all local Howard D8 app folders before running updates.

```bash
$ sh ~/Sites/_hal/drupal/acquia/pull_all.sh
```

Always run this before any composer update to avoid conflicts.

---

## `update_drupal_core.sh` — Drupal Core Only

Updates `drupal/core`, `drupal/core-recommended`, `drupal/core-composer-scaffold`, and `drupal/core-project-message` with all dependencies.

```bash
$ sh ~/Sites/_hal/drupal/acquia/update_drupal_core.sh
```

---

## `update_drupal_contrib.sh` — Contrib Modules/Themes Only

Runs `composer update "drupal/*" --with-all-dependencies` across all local apps, updating all contrib modules and themes within existing version constraints.

```bash
$ sh ~/Sites/_hal/drupal/acquia/update_drupal_contrib.sh
```

---

## `update_howard_packages.sh` — Howard Packages Only

Updates all `howard/*` packagist repos across all local apps.

```bash
$ sh ~/Sites/_hal/drupal/acquia/update_howard_packages.sh
```

---

## Prerequisites (all composer scripts)

- HAL is up to date (`git pull` in `~/Sites/_hal`)
- All desired local folders are configured in `hal_config.txt`
- You are on the `master` branch and it is up to date
- Composer is installed and functional

## After Running

```bash
# Run database updates and cache rebuild on dev:
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all dev updb
$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh all dev cr

# Check dev status:
$ sh ~/Sites/_hal/drupal/acquia/site_status_check.sh all dev
```

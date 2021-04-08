# Howard Automation Library (HAL)

This repo holds bash scripts and other files to help in the automation of Howard University Drupal projects.

## Installation

Clone this repo into your ~/Sites folder, as "_hal"

- `$ cd ~/Sites`
- `$ git clone https://https://github.com/howard-university-web-services/Howard-Automation-Library.git _hal`

### Add Local Config

- `$ cd ~/Sites/_hal`
- `$ cp hal_config.default.txt hal_config.txt`
- Edit hal_config.txt to use the desired drush.
- Edit hal_config.txt to use the absolute path to any local Howard D8 repos you wish to update/use.
- Edit hal_config.txt to use the local drush aliases you have.

#### Setting a local drush

- Navigate to the Drush 9 installed in the hud8 folder as a dependency, and adjust the path to match your local machine in config.
- `LOCAL_DRUSH="/Users/YOUR_USER/Sites/devdesktop/hud8-dev/docroot/vendor/bin/drush"`

#### Finding your local Howard D8 folders

- LOCAL_HOWARD_D8_FOLDERS[0] = Your local hud8 root folder.
- LOCAL_HOWARD_D8_FOLDERS[1] = Your local academicdepartments root folder.
- Navigate to your DevDesktop sites folder.
- Find the folder you wish to use, ie "hud8-dev"
- `cd hud8-dev`
- `pwd`: The out put of this would go into hal_config.txt as `LOCAL_HOWARD_D8_FOLDERS[0]="/PATH/TO/YOUR/FOLDER/hud8-dev"` (NOTICE THE "0" HERE).
- Subsequent paths, Academic Departments,for additional Howard D8 environments you wish to update would go into hal_config.txt as `LOCAL_HOWARD_D8_FOLDERS[1]="/PATH/TO/YOUR/OTHER/FOLDER/academicdepartments-dev"` (NOTICE THE "1" HERE).

#### Finding your local drush aliases

- Run `drush sa` for a list of current drush aliases.
- You should see `@cl.prod_academicdepartments.dev.dev` or `academicdepartments.dev` and `@cl.prod_hud8.dev.dev` or `hud8.dev`, with others for stg and prod installs of each. These would be added as `@cl.prod_academicdepartments`, leaving off the env connotation, as we set that in a choice per script, so that you may choose in the script which env to run them on.

### Requirements

Be sure the following are up and running correctly on your local machine:

- [Acquia DevDesktop](https://www.acquia.com/drupal/acquia-dev-desktop)
- [Drush](https://docs.drush.org/en/master/install/) -- Already present if using DevDesktop

## Updating HAL

Use git to keep this library up date on your local machine.

- `cd ~/Sites/_hal`
- `git pull`

## Usage

- Ensure you are in the proper folder, if the script requires it, especially for partials
- `$ sh your_desired_script.sh`
- Do not use sudo

## How this interacts with the acquia server

Since drush 9 and above does away with the @sites alias, we needed to create a script on the server that essentially loops through all sites on an install, and runs drush commands/etc. This script is located in each codebase, under `scripts/hal_sites.sh`. It is interacted with, both through this library, and via CRON scheduled jobs on acquia. For scheduled jobs, see the [acquia documentation](https://docs.acquia.com/cloud-platform/manage/cron/#cloud-execute-shell-script). At its essence, it provides a way to run the same drush command on all multi-sites within an environment.

### Example script on server, scripts/hal_sites.sh

```sh
  #!/bin/bash

  # Provide the absolute path to the sites directory.
  SITES="/var/www/html/${AH_SITE_NAME}/docroot/sites"

  # Validate and hint if no argument provided.
  if [ "${#}" -eq 0 ]; then
    echo "drush: missing argument(s). Please add the drush command you wish to run on all sites."
    echo "The 'drush' will be added automatically, please only add the actual command desired. EXAMPLE: cex -y"
  else
    cd "${SITES}"
    # Loop:
    for SITE in $(ls -d */ | cut -f1 -d'/'); do
      # Skip default sites, only run for howard url's.
      if [[ "${SITE}" == *".howard.edu"* ]]; then
        echo "======================================"
        echo "Running command: drush -l ${SITE} ${@} -y"
        echo "======================================"
        drush -l "${SITE}" "${@}" -y | awk '{print "["strftime("\%Y-\%m-\%d \%H:\%M:\%S \%Z")"] "$0}' &>> /var/log/sites/${AH_SITE_NAME}/logs/$(hostname -s)/drush-cron.log
      fi
    done
  fi
```

### Usage of server hal_sites.sh

When running this script, 'drush' and the '-y' flag, are automatically added to the drush command you wish to run. It is quite important to "not use command aliases" with this script. Ie, use "pm:enable" not "en". Related too [this issue](https://github.com/drush-ops/drush/issues/3025) if curious as to why.

- From root folder on acquia server, check status: `bash scripts/hal_sites.sh status`. In this instance, 'status' is the drush command to run.
- From root folder on acquia server, clear cache: `bash scripts/hal_sites.sh cr`. In this instance, 'cr' is the drush command to run.
- From scheduled task runner on acquia: `bash /var/www/html/${AH_SITE_NAME}/scripts/hal_sites.sh cr`. Clears caches on all sites in install, to run hourly or whatever desired.

## Drupal 8

The following full scripts are available:

### Acquia

#### Initial spin-up of a multi-site site, and clone dev.coasdept

- This script creates a new multi-site install locally (copies the _starter_ folder), adjusts settings.php and sites.php with needed parameters, adds connection data to a multi-site DB on acquia, Commits to master, and pushes to Acquia. The script then clones the stg.coasdept.howard.edu DB and Files into it, directly on acquia STG. A video overview can be seen on [vimeo](https://vimeo.com/400050607/0f830ca20d).

##### Manual Steps (to be completed first)

- Create database in desired environment (hud8 or academicdepartments), and note machine name.
- Add URLs for new site into dev/stg/live URL fields in acquia.
- BOTH of these steps must be completed, as the drush scripts depend on both URL, and database being set up for the environment.

##### Automated Steps (done by script after manual steps complete)

You will also be given the option to commit/push immediately, and whether you wish to copy database and files from stg.coasdept.howard. Choosing "NO" on any, will skip these steps, and they will subsequently need to be performed manually. If git automation is not chosen, a new git branch will be created and used locally: "new_howard_multisite_TIMESTAMP".

- Be sure that HAL is up to date.
- Be sure that all desired local folders, and drush aliases are set up in hal_config.txt.
- Be sure that you are on master branch, and it is up to date.
- Be sure you have the database machine name you added in acquia.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/create_new_multisite.sh`

#### Update all Howard packagist repos, on all Howard D8 sites, commit, and push to acquia

You will also be given the option to commit/push immediately. If git automation is not chosen, a new git branch will be created and used locally: "new_howard_multisite_TIMESTAMP".

- Be sure that HAL is up to date.
- Be sure that all desired local folders are set up in hal_config.txt.
- Be sure that you are on master branch, and it is up to date.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/update_howard_packages.sh`

#### Update the twitter API key on all sites

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Be sure that you are on master branch, and it is up to date.
- You may set twitter credentials in hal_config.txt and simply hit enter through the prompts, or paste them in as the prompts arise.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/update_twitter_api_key.sh`

#### Update config item on all sites

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Paste in Name, Key, and Value as the prompts arise.
- Relies on [drush cset](https://drushcommands.com/drush-8x/config/config-set/), please ensure this is understood before using.
- `$ sh ~/Sites/_hal/drupal/acquia/update_config.sh`
- See [idfive developer documentation](https://developers.idfive.com/#/back-end/drupal/drupal-config-management?id=one-time-config-overrides-via-drush) for overview of approach, and finding Name, Key, and Values desired.

#### Run drush command on all sites

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Paste in desired drush command at the prompt.
- Add the desired command only, ie "pm-uninstall page_cache", as things like "drush" and "@sites" are added by the script.
- `$ sh ~/Sites/_hal/drupal/acquia/update_via_drush.sh`

#### Update database on all acquia D8 sites

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Be sure all acquia drush aliases are up to date.
- You may choose either hud8 or academicdepartments. The script then runs drush updb on all multi-sites on dev, stg, and prod.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/update_db_on_acquia.sh`

#### Push master branch, creates new Tag and deploys new Tag to Acquia Prod Environment

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Be sure all acquia drush aliases are up to date.
- Be sure either the HUD8 or the academicdepartments master branch is up-to-date
- Be sure Acquia Private Key and Acquia E-mail are up to date.
- You may choose either hud8 or academicdepartments Prod Environment.
- This script will push master branch, create new Tag  and deploy code to the selected Prod environment.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/acquia_code_deploy.sh`

## Roadmap

### All Howard D8 acquia codebases

- Run composer add on all local codebases. "add the seckit module on all local D8 codebases" **In Progress**
- Commit and push to DEV for all local codebases
- Deploy to prod for all codebases

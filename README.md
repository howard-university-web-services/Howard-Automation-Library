# Howard Automation Library (HAL)

This repo holds bash scripts and other files to help in the automation of Howard University Drupal projects.

## Installation

Clone this repo into your ~/Sites folder, as "_hal"

- `$ cd ~/Sites`
- `$ git clone https://https://github.com/howard-university-web-services/Howard-Automation-Library.git _hal`

### Add Local Config

- `$ cd ~/Sites/_hal`
- `$ cp hal_config.default.txt hal_config.txt`
- Edit hal_config.txt to use the absolute path to any local Howard D8 repos you wish to update/use.
- Edit hal_config.txt to use the local drush aliases you have.

#### Finding your local Howard D8 folders

- LOCAL_HOWARD_D8_FOLDERS[0] = Your local hud8 root folder.
- LOCAL_HOWARD_D8_FOLDERS[1] = Your local academicdepartments root folder.
- E_MAIL = Your Acquia E-mail.
- PRIVATE_KEY= Acquia Private Key.
- Navigate to your DevDesktop sites folder.
- Find the folder you wish to use, ie "hud8-dev"
- `cd hud8-dev`
- `pwd`: The out put of this would go into hal_config.txt as `LOCAL_HOWARD_D8_FOLDERS[0]="/PATH/TO/YOUR/FOLDER/hud8-dev"` (NOTICE THE "0" HERE).
- Subsequent paths, Academic Departments,for additional Howard D8 environments you wish to update would go into hal_config.txt as `LOCAL_HOWARD_D8_FOLDERS[1]="/PATH/TO/YOUR/OTHER/FOLDER/academicdepartments-dev"` (NOTICE THE "1" HERE).

#### Finding your Acquia Private Key and E-mail

- Log into your Acquia account
- Go to your Account settings
- Select the "Credentials" menu item
- Confirm your current password
- Retrieve both your Private Key and E-mail from the "Cloud API" section

#### Finding your local drush aliases

- Run `drush sa` for a list of current drush aliases.
- You should see `@cl.prod_academicdepartments.dev.dev` and `@cl.prod_hud8.dev.dev`, with others for stg and prod installs of each. These would be added as `@cl.prod_academicdepartments`, leaving off the env connotation, as we set that in a choice per script, so that you may choose in the script which env to run them on.

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

## Drupal 8

The following full scripts are available:

### Acquia

#### Initial spin-up of a multi-site site, and clone dev.coasdept

- This script creates a new multi-site install locally (copies the _starter_ folder), adjusts settings.php and sites.php with needed parameters, adds connection data to a multi-site DB on acquia, Commits to master, and pushes to Acquia. The script then clones the dev.coasdept.howard.edu DB and Files into it, directly on acquia DEV. A video overview can be seen on [vimeo](https://vimeo.com/400050607/0f830ca20d).

##### Manual Steps (to be completed first)

- Create database in desired environment (hud8 or academicdepartments), and note machine name.
- Add URLs for new site into dev/stg/live URL fields in acquia.

##### Automated Steps (done by script after manual steps complete)

You will also be given the option to commit/push immediately, and whether you wish to copy database and files from dev.coasdept.howard. Choosing "NO" on any, will skip these steps, and they will subsequently need to be performed manually. If git automation is not chosen, a new git branch will be created and used locally: "new_howard_multisite_TIMESTAMP".

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

#### Update database on all acquia D8 sites

- Be sure that HAL is up to date.
- Be sure that all desired local drush aliases are set up in hal_config.txt.
- Be sure all acquia drush aliases are up to date.
- You may choose either hud8 or academicdepartments. The script then runs drush updb on all multi-sites on dev, stg, and prod.
- You will need to keep a loose eye on the terminal to put in passwords/etc occasionally.
- `$ sh ~/Sites/_hal/drupal/acquia/update_db_on_acquia.sh`

#### Push master branch, create Tag and deploy to Acquia Prod Environment
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


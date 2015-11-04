# [Ladle](https://af-ladle.herokuapp.com/)

Serving stew to stewards.

## Mission

An application for assisting in Appfolio's implementation of code stewardship. Stewards are folks that look after a section of code. Stewardship is opt-in and open to anyone.

To opt-in, add your GitHub username to a `stewards.yml` file anywhere in the directory structure of a repository monitored by Ladle; for example:

  _in app/stewards.yml:_
  ```yaml
  stewards:
    - dhh
  ```

This entry states that `dhh` is a steward of everything under _app/_.

To get notifications anytime any Pull Requests are opened that modify files in _app/_, login to [Ladle](https://af-ladle.herokuapp.com/) using your the GitHub user you used in the `stewards.yml` file.

To remove notifications remove your name from the `stewards.yml` file.

## Architecture

### Authentication

Users are authenticated using [omniauth-github](https://github.com/intridea/omniauth-github). The GitHub [scopes](https://developer.github.com/v3/oauth/#scopes) requested as part of authentication are necessary for Ladle to notify the user. Access is restricted to the [list of configured organizations.](#restricted-access)

### Observing Repositories

Repositories are observed via GitHub [webhooks](https://developer.github.com/v3/repos/hooks/). The code for repositories is accessed via an authorization token associated with a user of the repository. 

Currently, repositories are added manually via the below. In the future, we could build a flow within Ladle for this.

1. Login to Ladle using the GitHub user you want to use to access the repository. The authentication process will create a token that can be used for login, but not for accessing the contents of repositories.

2. Create a [Personal Access Token](https://help.github.com/articles/creating-an-access-token-for-command-line-use/) for the user that will be used to access the repository.

3. Via the [Rails console on Heroku](https://devcenter.heroku.com/articles/getting-started-with-rails4#console), save the token created in the previous step for the user from step 1:

  ```ruby
  user = User.find_by_github_username('dhh')
  user.token = '<personal_access_token>'
  user.save!
  ```
4. Create a [webhook](https://developer.github.com/webhooks/creating/) on the repository listening for the `pull_request` event and using `/github_events/payload` as the payload URL.

5. Via the [Rails console on Heroku](https://devcenter.heroku.com/articles/getting-started-with-rails4#console) create a new `Repository` model:

  ```ruby
    Repository.create!(name: 'dhh/f-bombs', webhook_secret: '<webhook_secret>', user: User.find_by_github_username('dhh'))
  ```

## Deployment

This section describes how Ladle is configured and deployed.

### Heroku

Ladle is built to be deployed on Heroku.

### GitHub Application

Ladle runs as a GitHub Application. The following ENV variables must be set:

  - `GH_APPLICATION_ID`
  - `GH_APPLICATION_SECRET`

### Email Notifications

Ladle uses SendGrid for sending email notifications to stewards. The following ENV variables must be set:

  - `SENDGRID_USERNAME`
  - `SENDGRID_PASSWORD`

### Restricted Access

Access to a deployed instance is permitted only if the user has access to an organization in the `ALLOWED_ORGANIZATIONS` ENV variable.

### Appfolio Specific Instances 

The Ladle source code contains no Appfolio specifics. Ladle can be deployed for any repository or organization.

Appfolio currently uses 2 deployed instances:

  - Production: https://af-ladle.herokuapp.com/
  - Stage: https://af-ladle-stage.herokuapp.com/
  
To deploy either instance, you need to find someone that has [collaborator privileges](https://devcenter.heroku.com/articles/sharing), currently:

  - Production: @dtognazzini
  - Stage: @dtognazzini, @xanderstrike

#### Production
https://af-ladle.herokuapp.com/

Appfolio's production instance of Ladle uses the @ladle-appfolio user to access the contents of repositories. The @ladle-appfolio user has access to all repositories within the [Appfolio organization.](https://github.com/appfolio)

#### Staging
https://af-ladle-stage.herokuapp.com/

Appfolio's stage instance of Ladle uses the @ladle-appfolio-stage user to access the contents of repositories. The @ladle-appfolio-stage user has access to single repository: https://github.com/appfolio/ladle-stage.

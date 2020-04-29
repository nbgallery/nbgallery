# nbgallery configuration

## Configuration files

General configuration is stored in `config/settings.yml` and `config/settings/#{environment}.yml`.  Precedence of these files is defined by the [config gem](https://github.com/railsconfig/config#accessing-the-settings-object).  These files are under version control, so we recommend creating `config/settings.local.yml` and/or `config/settings/#{environment}.local.yml`, especially if you plan to contribute to the project.  You can also override any setting with an appropriately named environment variable -- if you're running nbgallery with docker, this is usually the easiest way to change settings.  For example, `GALLERY__MYSQL__DATABASE` will override the `mysql/database` value in `settings.yml`.

At a minimum, you'll need to configure the mysql section to match your database server.  Within the mysql server, make sure you've [created the user account](https://dev.mysql.com/doc/refman/8.0/en/adding-users.html) and database that nbgallery will use.

If you're running a standalone [Solr server](solr.md), you'll need to configure that section as well.  If you're just using the bundled sunspot solr server, the defaults should work fine.

## Email configuration

nbgallery sends emails for various actions, including username/password account registration.  You'll need to set some environment variables:

 * EMAIL_ADDRESS - The value that shows up in the 'from' field for e-mail confirmation
 * EMAIL_USERNAME - The username used to authenticate to your SMTP server
 * EMAIL_PASSWORD - The passwword used to authenticate to your SMTP server
 * EMAIL_DOMAIN - The actual domain for your server (such as nb.gallery)
 * EMAIL_SERVER - The SMTP server (may not be the same as EMAIL_DOMAIN, such as if you are running in AWS)
 * EMAIL_DEFAULT_URL_OPTIONS_HOST - Often the same value as EMAIL_DOMAIN

## User authentication methods

nbgallery supports username/password authentication and/or OAuth login for [GitHub](https://developer.github.com/apps/building-oauth-apps/creating-an-oauth-app/), [Facebook](https://developers.facebook.com/docs/facebook-login/), and [Google](https://developers.google.com/identity/sign-in/web/sign-in).  (This is implemented with [omniauth](https://github.com/omniauth/omniauth) and [devise](https://github.com/plataformatec/devise).)  If you use any of the OAuth login options, you'll need to set up a project with that provider and then set the appropriate environment variables:

 * GITHUB_ID - OAuth ID for Github authentication
 * GITHUB_SECRET - OAuth secret for Github authentication
 * FACEBOOK_ID - OAuth ID for Facebook authentication
 * FACEBOOK_SECRET - OAuth secret for Facebook authentication
 * GOOGLE_ID - OAuth ID for Google authentication
 * GOOGLE_SECRET - OAuth secret for Google authentication

If you use some other authentication method, you can implement your own Devise strategy using nbgallery's [extension system](extensions.md).  [Sample skeleton here](../samples/external_auth).

## Creating an admin user

While not strictly necessary, you'll probably want one of your user accounts to have admin powers within nbgallery.

Option 1: You can have an admin user created at startup by setting the `NBGALLERY_ADMIN_USER`, `NBGALLERY_ADMIN_PASSWORD`(minimum of 6 chars), and `NBGALLERY_ADMIN_EMAIL` environment variables before starting up the server.

Option 2: Register the account through the normal web UI process, then toggle the admin field.  You can toggle the admin field directly in mysql, through the `rails console`, or using [this script](../script/make_admin_user.rb).

Admin users can then modify other user accounts from the `/users` endpoint, available from the Admin page under the user silhouette icon.

## Scheduled jobs

nbgallery has a number of computational and cleanup tasks that should run on a periodic basis.  [More detail here](scheduled_jobs.md).

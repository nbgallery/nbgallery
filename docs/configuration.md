# nbgallery configuration

## Configuration files

General configuration is stored in `config/settings.yml` and `config/settings/#{environment}.yml`.  Precedence of these files is defined by the [config gem](https://github.com/railsconfig/config#accessing-the-settings-object).  These files are under version control, so we recommend creating `config/settings.local.yml` and/or `config/settings/#{environment}.local.yml`, especially if you plan to contribute to the project.  You can also override any setting with an appropriately named environment variable -- if you're running nbgallery with docker, this is usually the easiest way to change settings.  For example, `GALLERY__MYSQL__DATABASE` will override the `mysql/database` value in `settings.yml`.

At a minimum, you'll need to configure the mysql section to match your database server.  Within the mysql server, make sure you've [created the user account](https://dev.mysql.com/doc/refman/8.0/en/adding-users.html) and database that nbgallery will use.

If you're running a standalone [Solr server](solr.md), you'll need to configure that section as well.  If you're just using the bundled sunspot solr server, the defaults should work fine.

## Notebook Storage Configuration
nbgallery now supports storing the actual notebooks in the database rather than on local disk.  This is ideal for cloud environments and higher availability but may experience a slight performance impact.  By setting the environment varible GALLERY__STORAGE__DATABASE_NOTEBOOKS to true or changing the value in `conifig/settings.yml` to true it will store all notebooks in the database rather than on disk.  Please see the migrating to database storage section of the [database storage](database_storage.md) documentation.

## Email configuration

nbgallery sends emails for various actions, including username/password account registration.  You'll need to set some environment variables:

 * EMAIL_ADDRESS - The value that shows up in the 'from' field for e-mail confirmation
 * EMAIL_USERNAME - The username used to authenticate to your SMTP server
 * EMAIL_PASSWORD - The passwword used to authenticate to your SMTP server
 * EMAIL_DOMAIN - The actual domain for your server (such as nb.gallery)
 * EMAIL_SERVER - The SMTP server (may not be the same as EMAIL_DOMAIN, such as if you are running in AWS)
 * EMAIL_PORT - Port the SMTP server is listening on (default is 587)
 * EMAIL_DEFAULT_URL_OPTIONS_HOST - Often the same value as EMAIL_DOMAIN
 * GALLERY__EMAIL__GENERAL_FROM - FROM address used for emails (Maps to config.email.general_form)
 * GALLERY__EMAIL__EXCEPTIONS_FROM - From address for sending emails on exceptions (if desired)
 * GALLERY__EMAIL__EXCEPTIONS_TO - To address for sending emails on exceptions (if desired)

## User authentication methods

nbgallery supports username/password authentication and/or OAuth login for [GitHub](https://developer.github.com/apps/building-oauth-apps/creating-an-oauth-app/), [GitLab](https://docs.gitlab.com/ee/integration/oauth_provider.html), [Facebook](https://developers.facebook.com/docs/facebook-login/),[Google](https://developers.google.com/identity/sign-in/web/sign-in) and [Microsoft](https://learn.microsoft.com/en-us/azure/app-service/configure-authentication-provider-aad).  (This is implemented with [omniauth](https://github.com/omniauth/omniauth) and [devise](https://github.com/plataformatec/devise).)  If you use any of the OAuth login options, you'll need to set up a project with that provider and then set the appropriate environment variables:

 * GITHUB_ID - OAuth ID for Github authentication
 * GITHUB_SECRET - OAuth secret for Github authentication
 * GITLAB_ID - OAuth ID for Gitlab authentication
 * GITLAB_SECRET - OAuth secret for Gitlab authentication
 * GITLAB_URL - URL for Gitlab server (ex http://gitlab.com/api/v4) for Gitlab authentication
 * FACEBOOK_ID - OAuth ID for Facebook authentication
 * FACEBOOK_SECRET - OAuth secret for Facebook authentication
 * GOOGLE_ID - OAuth ID for Google authentication
 * GOOGLE_SECRET - OAuth secret for Google authentication
 * AZURE_ID - Azure application ID
 * AZURE_SECRET - Azure application secret
 * AZURE_TENANT - Azure Tenant ID of the AD Application
If you use some other authentication method, you can implement your own Devise strategy using nbgallery's [extension system](extensions.md).  [Sample skeleton here](../samples/external_auth).

## Creating users/admin user
While not strictly necessary, you'll probably want one of your user accounts to have admin powers within nbgallery.

Admin users can then modify other user accounts from the `/users` endpoint, available from the Admin page under the user silhouette icon.
### OAuth
OAuth authenticated users automatically have an account created for them.

### As part of Application Startup
You can have an admin user created at startup by setting the `NBGALLERY_ADMIN_USER`, `NBGALLERY_ADMIN_PASSWORD`(minimum of 6 chars), and `NBGALLERY_ADMIN_EMAIL` environment variables before starting up the server.

### Using provided scripts
Use the [create_user](../script/create_user.rb) script to create a user
`bundle exec rails runner script/create_user.rb`

### Toggle existing user to an Admin
For accounts created using the create_user script or registered through the normal web UI process, you can turn them into an admin multiple ways.  You can toggle the admin field directly in mysql, through the `rails console`, or using [this script](../script/make_admin_user.rb).


## Scheduled jobs

nbgallery has a number of computational and cleanup tasks that should run on a periodic basis.  [More detail here](scheduled_jobs.md).

## Federated Search

nbgallery can be configured to perform federated search across a number of galleries. To do this, the following configuration needs to be set:
```yaml
search:
  federated:
    - url: http://myurl.com
      name: My External Gallery
      tagline: |
        <div>This is optional but can contain raw HTML</div>
```

The external gallery will need to accept cross origin requests from the connecting gallery. This can be done in the external gallery's configuration
as follows:
```yaml
search:
  allowed_cors:
    - myurl.com
```
This value may be a regex.  At this time, it is not possible to allow all origins as it will use authentication in the cors requests.

## Seed the nbgallery with Notebooks

There are now two ways this can be accomplished.  Through the admin import interface or through the command-line bulk import interface.

### Admin Import Notebooks interface

There is now a page in the Admin section of nbgallery that allows you to upload a .tar.gz of notebooks and an associated metadata.json file.  Users and groups specified in the metadata must already exist in the database.  The directory structure must be completely flat and the metadata.json file populated as outlined below.

Sample .tar.gz contents:

    /
    |-- example1.ipynb
    |-- example2.ipynb
    |-- metadata.json

The metadata.json should be an object with keys for each file (absent the .ipynb part) and look something like the below.

     {
       "example1":{ // Sample with all possible fields
         "updated":"2021-02-12T10:50:23.000Z", // Optional - Would default to current date/time
         "created":"2021-02-12T10:49:00.000Z", // Optional - Would default to current date/time
         "title":"Example Notebook",
         "description":"This is an example notebook to show how the exported notebooks look",
         "uuid":"5bc058c7-f651-4e39-a94c-cd5676fc676c", // Optional - Only required if the import needs to overwrite existing notebooks
         "public":true, // Optional - Defaults to setting above if not specified
         "updater":"sample_user5", // Optional But will appear as "Unknown" in the UI if not specified
         "creator":"sample_user1", // Optional But will appear as "Unknown" in the UI if not specified
         "owner":"sample_user5", // Username must exist in the database
         "owner_type":"User",  // "User" or "Group"
         "tags":["tag1","tag2","tag3"]
      },
      "example2":{ //Sample with minimum required data
         "title":"Example Notebook 2",
         "description":"This is the second example notebook",
         "owner":"Sample Group Name", //Group Name must match the name of the group
         "owner_type":"Group"
      },
    }

### Command Line

You can now side-load the gallery from the command line using the bulk_import script.  Place a collection of ipynb files in a directory and ensure the user you want to own the notebooks exists in the database. From the root directory of the gallery, run `bundle exec rails runner script/bulk_import.rb`. The script will prompt you for the username of the creator, optionally the username or group name for the owner, and directory for the notebooks to import.

The title of the imported notebook will be based on the name of the file with any underscores (_) replaced by a space and the extension removed.
The description of the notebook will default to "Automatically Uploaded" but then the script will look for the first markdown field with at least 20 characters excluding any headings. It will truncate the description to the first 250 characters with and ellipses added to the end if it was over 250 characters.

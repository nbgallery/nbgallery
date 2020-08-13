# Using NBGallery as an OAuth provider for Jupyter Hub

For the NBGallery  extensions in Jupyter to function properly, the user must be
logged in to NBGallery before loading up the Jupyter interface.  By using
NBGallery as your OAuth provider for JuptyerHub, you force that login to happen
before they are able to bring up the Juptyer Notebook UI, while also limiting
the number of places that user accounts must be managed.  Here is a sample
configuration to integrate JupyterHub and NBGallery.  This will be based on the
[Zero to JupyterHub with Kubernetes](https://zero-to-jupyterhub.readthedocs.io/en/latest/) documentation.

## Notebook Gallery Changes
You must enable the OAuth provider code in NBGallery by either changing
oauth_provider_enabled to true in config/settings.yml or by setting the
environment variable GALLERY__OAUTH_PROVIDER_ENABLED to "true".  Once this is
done, NBGallery administrators will be able to configure OAuth applications to
obtain the client token and client secret under "Admin->Manage OAuth
Applications."

Once there, click "New Application", and fill out the form.
 - Name: Any name you want to use, it is only used on this screen as a label
 - Redirect URI: `https://path.to.your.hub/hub/oauth_callback` - This must be HTTPS
 - Confidential: Leave Checked
 - Scopes: read

![Screenshot of Application Info in OAuth Configuration](images/oauth_new_application.png?raw=true)

Once you click submit, you will see a screen that provides the Application UID
and Secret.  These are the values you will need when setting up JupyterHub.

![Screenshot of Application Info in OAuth Configuration](images/oauth_example_hub.png?raw=true)

## Jupyterhub Configuration
Again, this is based on the [Zero to JupyterHub with Kubernetes](https://zero-to-jupyterhub.readthedocs.io/en/latest/) documentation and assumes you
have hub up and running.  These changes would apply to the local config.yaml
file that you use when deploying the helm chart.

```
hub:
  extraEnv:
    OAUTH2_AUTHORIZE_URL: https://path.to.nbgallery/oauth/authorize
    OAUTH2_TOKEN_URL: https://path.to.nbgallery/oauth/token
    OAUTH2_TLS_VERIFY: False
auth:
  type: custom
  custom:
    className: oauthenticator.generic.GenericOAuthenticator
    config:
      login_service: "Name of your Gallery"
      client_id: "APPLICATION UID FROM NBGALLERY"
      client_secret: "SECRET FROM NBGALLERY"
      token_url: "https://path.to.nbgallery/oauth/token"
      userdata_url: "https://path.to.nbgallery/oauth/userinfo.json"
      userdata_method: GET
      userdata_params: {"state": "state"}
      username_key: user_name  # or email
```

Run the helm upgrade, visit the hub, log out if you aren't already, and you should now see "Login with Name of your Gallery"

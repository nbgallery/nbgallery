# Extension system

The code has an [extension system](../extensions) that enables you to add custom/proprietary modules that may be specific to your enterprise environment.  For example, nbgallery has a basic group management system for sharing notebooks, but if your environment has some other mechanism, you can implement a custom [GroupService](../lib/extension_points/group_service.rb) as an extension.  Models can be extended with additional fields; for example, you could add fields to both `notebook` and `user` to implement additional visibility restrictions beyond just public/private.

Extensions in the [extensions directory](../extensions) will be loaded by default, and some other sample extensions can be found in [samples](../samples).

## File/directory structure

By default, nbgallery looks for extensions in any subdirectory ending with `extensions`.  Any extensions found there will be automatically loaded, unless specifically disabled in settings.  The file structure for extensions looks something like this:

 * `nbgallery/`: top-level directory for the project
   * `extensions/`: directory for extensions, configurable in [settings.yml](../config/settings.yml)
     * `my_cool_extension/`: subdirectory for an individual extension
       * `my_cool_extension.rb` **(required)**: This file is executed when the extension is loaded.  See [GalleryLib](../lib/gallery_lib.rb) and the [gallery initializer](../config/initializers/gallery.rb).
       * `my_cool_extension.yml` (optional): Settings here override default `settings.yml` files but not the `local` settings files.  See [config/application.rb](../config/application.rb).
       * `Gemfile` (optional): Additional gems required for this extension.  See the bottom of the [top-level Gemfile](../Gemfile).
       * `migrate/` (optional): Additional migrations; for example, if you need to add fields to models.  See the [gallery initializer](../config/initializers/gallery.rb).
       * `cronic.d/` (optional): Additional scheduled jobs.  See [`scheduled_jobs.rb`](../lib/scheduled_jobs.rb).

If extensions need to be loaded in any particular order, then an order value can be given in settings. Extensions with the lowest values are loaded first. By default, each extension gets an order value of 100.

For example:
```yaml
extensions:
  order:
    my_cool_extension: 1
    my_other_cool_extensions: 5
```       

## Model extensions

Several of nbgallery's models (such as `User` and `Notebook`) include `ExtendableModel`, which is similar to `ActiveSupport::Concern`.  This enables you to add new fields to a model.  You'll probably need a migration in the extension, and the `yml` file for your extension must explicitly add your extension to the model in question.  See [ExtendableModel](../lib/extendable_model.rb).

## Controller Observers

It is possible to hook into controllers by creating your own observers that can get called before or after controller actions. To do this, create a
class that implements methods that follow the format before/after_controller_action and attach it to the application controller. An example is given below.


```ruby
class MyObserver
  def before_notebook_show(controller, request)
  end

  def after_notebook_show(controller, request, response)
  end
end

observer = MyObserver.new
ApplicationController.add_observer(observer)
```

## Design rationale

Our goal with the extension system is to keep all extension behavior in completely separate files from the base repository.  We chose not to rely on git and merging local changes into files in the upstream repository.  In our experience, it can be error-prone to have two versions of the same file, i.e. the original upstream version and the local version with extensions merged in -- developers may accidentally make changes in the wrong version, and they have to make sure the merge always works cleanly.  Maintaining extensions in separate files helps minimize those problems.

Why not rely on Ruby's ability to re-open classes?  The Rails auto-loader makes that challenging.  In production, all classes are loaded at startup, so you have to make sure the default class is loaded before your extension that re-opens it.  In development, classes can be reloaded on the fly, which means you also need to reload your extension every time that happens.  Our approach avoids the difficulty with production mode, but it does require restarting the server whenever you modify an extension in development.

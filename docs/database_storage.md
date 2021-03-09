# nbgallery database_storage
nbgallery now supports storing notebooks in the database rather than on disk.  
This allows for easier migration from host->host in a cloud environments as well
as providing a single item that must be backed up.


## Configuration
This setting can be set with the environment variable GALLERY__STORAGE__NOTEBOOK_FILE_CLASS
or by changing the setting in `config/settings.yml` to true.  This will ensure
all notebooks are stored in the notebook_files table in the database including
change requests, staged notebooks, and if enabled, previous revisions.

This mimics the behavior of the git repo, but is not actually a git repository.

## Migration
If you currently are using disk-storage of your notebooks, there is a migration
script to migrate your notebooks to the database.  The first step is to change the
appropriate configuration setting to allow database storage.  At this point, the application
will not work correctly until you migrate the notebooks so you will want to schedule some downtime.

Next, on the command line run `bundle exec rails runner script/migrate_to_db_storage.rb`

The output of this command will tell you if any notebooks were unable to be migrated, this is usually caused by
a revision or a notebook being missing from the file system. This means content is actually missing
and migration would not be possible for those specific notebooks or revisions.

**NOTE: These notebooks and revisions are already inaccessible and attempts should be made to purge them from the system**

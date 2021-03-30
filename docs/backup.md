# Backing up nbgallery data

We anticipate that backup strategies will be specific to your enterprise, so we haven't provided a backup script by default.  Instead, you can add your own using the [extension system](extensions.md).  There is a sample skeleton [here](../samples/backup).

## Things you may want to back up

 * Mysql database: We suggest mysqldump.
 * Solr database: We don't back this up, because it only takes a few minutes to reindex several thousand notebooks.
 * Configuration dependent
   * Data directories:
     * cache: This is the important one -- this holds the primary copy of all the notebooks.
     * change_requests: Not critical but possibly desired -- this holds the proposed content for any pending change requests.
     * staging: Not critical -- this holds notebooks between stage 1 and 2 of the upload process.  Only "orphaned" notebooks will be here longer than a few seconds.
   * Git repo: If you have [revision tracking](revisions.md) enabled, the repo is underneath either the cache (current) or repo (soon) directory.  You may want to tar up the `.git` directory, or set up a remote and `git push`.

 ## Things to do after restoring a backup

  * If you don't include solr in your backup, you will need to run `Notebook.reindex` and `Group.reindex` from the rails console or use the Search Reindex link in the admin section of NBGallery.
  * If you have the git repo enabled and are using on-disk storage but don't back it up, you'll need to [manually reset the git repo and `revisions` table](https://github.com/nbgallery/nbgallery/blob/master/docs/revisions.md#manually-creatingresetting-the-git-repo) after restoring a database backup, or else the database and the repo won't be in sync.

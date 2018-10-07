# Notebook revision tracking

In summer 2018, we added an internal git repository for notebook storage.  This enables us to show old versions of a notebook, diffs between versions, etc.  When nbgallery starts up, it will create a git repository in the notebook cache directory.  Each notebook creation, update, and deletion will be a separate commit in the repo.

As of October 2018, the git repo can be disabled using `storage.track_revisions` in [settings.yml](https://github.com/nbgallery/nbgallery/blob/master/config/settings.yml).

## Database

Revision metadata for each notebook is also stored in the `revisions` table in the database.  This table tracks the git commit hash as well as the type of revision:

 * `initial`: If you already had notebooks in the cache before upgrading nbgallery to a version with the git repo, we snapshot the initial state of all existing notebooks.
 * `create`: A new notebook was uploaded.
 * `update`: A notebook was updated.
 * `metadata`: The notebook itself wasn't changed, but metadata affecting visibility was changed.  For example, a private notebook was made public.  The git repo itself has no record of this change, so the revision hash from the previous revision is carried forward.
 
Deletes are not reflected in the database because notebooks deletions cascade to the `revisions` table.  When a notebook is deleted, all records about it will be removed from `revisions`, but it will still be in the git log.

## Visibility

Owners (including groups and shares) of notebooks can view *all* revisions, even from before they became owner.  Non-owners can only view revisions that are later than the most recent revision that they *cannot* see.  For example, suppose a notebook was public, then private, then public again. Non-owners can only view revisions from the most recent public period; they cannot see revisons from the earlier public period or the private period.

## Storage

The json representation of notebooks is not ideal for storage in git.  If the notebook is represented as a single line of json text, then each update to the notebook is effectively a full change in git.  This causes nbgallery's disk usage to increase very quickly.  In October 2018, we changed notebook storage to partially pretty-print the notebooks with extra newlines before writing to disk.  This adds a small overhead (less than 1% in our tests) to raw notebook storage but should be more efficient for git.

When the git repo is created the first time, any extisting notebooks will be pretty-printed and rewritten to disk before committing the initial snapshot.  If you already had the git repo active with the earlier code that *didn't* pretty-print, notebooks will *not* be pretty-printed until the next time they get updated by the author.

## Reset the git repo

If you want to recreate the git repo from scratch, delete the `.git` directory from the cache directory and drop all rows from the `revisions` table in the database.  The git repo will be recreated next time nbgallery starts up.

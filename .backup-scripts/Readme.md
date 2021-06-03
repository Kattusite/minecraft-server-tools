# Customizing backups

This script supports multiple backends which you can use to
create server backups depending on your preferences.

These include:
- `borgbackup`
- `bup`
- `tar`

You can also disable backups entirely, though this isn't recommended.

If your backup solution of choice isn't present in this directory,
you can always add your own!

## Available backends

### borg

Backs up the active world directory and configuration files to
a borg repository. Borg uses compression and deduplication to keep
backup sizes small.

### bup

Similar to borg, but less mature. The backup script for bup is highly
experimental at the moment and I don't recommend using it as-is.

### tar

Back up the active world directory as a tar archive. This is a simple
and straightforward approach, but can be a bit of a storage hog.

### no

The `no` backend is a dummy backup script that disables backups entirely.
It can be used as a template for creating other backup scripts,
but it should not be used in production.

## Adding custom backends

The script swaps between storage backends by sourcing a backend-specific
helper script each time `server.sh` runs.

This helper script "imports" a number of key functions that the main
script will invoke as needed to create backups.

Each of these helper scripts adheres to a particular interface and
must define the following functions:

### init_backups

This function is intended to be called exactly once,
when the environment is initialized for the first time.

It's useful for installing dependencies, initializing repositories,
creating directories, or whatever other one-time setup might be needed.

It's not defined what happens if this is called subsequent times
after the first initialization. If you're lucky, that storage backend
will realize what's happened and fail with a nice error,
but it might also decide that "re-initialize" means
"overwrite all your backups", so be extremely careful with this one.

### create_backup

This is the function that will be invoked to create a single
point-in-time snapshot of the server at a given moment.

This function can run whether the server is running or stopped.

The caller will have already concerned itself with asking the
Minecraft server to flush any pending writes and disable auto-save,
so this function need only concern itself with reading the relevant
files and backing them up to their new location.

### pre_backup_hook

Any arbitrary actions to take before a `create_backup` has begun.

This will take place before the server is asked to flush pending writes
and disable auto-save.

### post_backup_hook

Any arbitrary actions to take after a `create_backup` has completed.

This will take place after the server is asked to re-enable auto-save.
It will not execute at all if `create_backup` has non-zero exit status.

### ls_backups

This is the function that will be invoked in order to display the
backups that currently exist.

It accepts a single argument, which can be used to filter the results
however desired.

### restore_backup

This is the function that will be invoked in order to restore a single
named backup to the filesystem.

The server must be stopped before this function can be run.

It accepts a single argument, which will almost always be used
to specify which backup should be restored.

It's not defined what happens to pre-existing files after a restore;
implementations are free to handle this case however they like.
Common actions include overwriting existing files, or stashing them
somewhere else for safekeeping.

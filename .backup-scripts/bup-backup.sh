#!/usr/bin/env bash
#
#   bup-backup.sh
#
# This backup backend archives the entire world directory using bup,
# writing them into a bup repository.
#
# This is a more sophisticated backup strategy using deduplication
# to keep backup sizes low.
#
# WARNING: bup backups are still _highly_ experimental.
#          This script hasn't been run yet, let alone tested.
#          This script does not support $WORLDS_TO_BACKUP or
#          $CONFIG_TO_BACKUP _at all_.
#          If you intend to use `bup` I recommend rewriting this entire file yourself.

CUR_YEAR=`date +"%Y"`
CUR_BACKUP_DIR="$BACKUP_DIR/$CUR_YEAR"

function init_backups() {
  $INSTALL_PKG build-dep bup
}

function create_backup() {
	if [ ! -d "$CUR_BACKUP_DIR" ]; then
	   mkdir -p "$CUR_BACKUP_DIR"
	fi

	bup -d "$CUR_BACKUP_DIR" index "$WORLD_NAME"
	if [ $? -eq 1 ]; then
  	bup -d "$CUR_BACKUP_DIR" init
  	bup -d "$CUR_BACKUP_DIR" index "$WORLD_NAME"
	fi

	bup -d "$CUR_BACKUP_DIR" save -n "$WORLD_BACKUP_NAME" "$WORLD_NAME"

	echo "Backup using bup to $CUR_BACKUP_DIR is complete"
}

function pre_backup_hook() {
  return 0
}

function post_backup_hook() {
  bup -d $CUR_BACK_DIR ls -l $WORLD_BACKUP_NAME/latest/var/minecraft
}

function ls_backups() {
  bup -d "$CUR_BACKUP_DIR" ls "mc-sad-squad/$1"
}

function restore_backup() {
  # TODO: Implement bup restore.
  echo "Automatic restore through bup is not yet supported."
}

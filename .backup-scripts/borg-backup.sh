#!/usr/bin/env bash
#
#   borg-backup.sh
#
# This backup backend archives the entire world directory using borg,
# writing them into a borg repository.
#
# This is a more sophisticated backup strategy using deduplication
# to keep backup sizes low.
#
# This backend backs up both the currently active world, and common
# server configuration files, like server.properties.

WORLD_BACKUP_REPO="$BACKUP_DIR/$WORLD_BACKUP_NAME"
CONFIG_BACKUP_REPO="$BACKUP_DIR/$CONFIG_BACKUP_NAME"

# A helper function to initialize a borg repo in the backups directory,
# given the name provided as an argument.
function _create_borg_repo() {
  local REPO_NAME=$1
  local REPO_PATH=$BACKUP_DIR/$REPO_NAME

  # Exit quietly if the repo already exists.
  if [ -d "$REPO_PATH" ]; then
    return
  fi

  mkdir -p $BACKUP_DIR
  if [ -z "$BACKUP_PASSWORD" ]; then
    echo "Empty password detected, proceeding without authentication or encryption."
    echo "WARNING: Your data will be stored unencrypted."
    borg init --encryption=none $REPO_PATH
  else
    echo "By default, borg repos require a password."
    echo "Please enter one when prompted."
    echo
    borg-init --encryption=repokey $REPO_PATH
  fi
}

function init_backups() {
  $INSTALL_PKG borgbackup
  mkdir -p $BACKUP_DIR
  _create_borg_repo "$CONFIG_BACKUP_NAME"
  _create_borg_repo "$WORLD_BACKUP_NAME"
}

function create_backup() {
  # In case this is a different world than we initialized with,
  # make sure a valid borg repo exists for this world.
  _create_borg_repo "$WORLD_BACKUP_NAME"

  local DATESTR=`date +%Y-%m-%d-%H%M%S`

  local WORLD_BACKUP="${WORLD_BACKUP_REPO}::${WORLD_BACKUP_NAME}-${DATESTR}"
  local CONFIG_BACKUP="${CONFIG_BACKUP_REPO}::${CONFIG_BACKUP_NAME}-${DATESTR}"

  borg create -v "$WORLD_BACKUP" $WORLD_NAME
  borg create -v "$CONFIG_BACKUP" `eval ls -d $CONFIG_BACKUP_FILES`
}

function pre_backup_hook() {
  return 0
}

function post_backup_hook() {
  # Apply a retention policy to gradually delete older backups.
  borg prune --keep-within  3d   \
             --keep-daily    7   \
             --keep-weekly   4   \
             --keep-monthly -1   \
             "$WORLD_BACKUP_REPO"

 borg prune --keep-within  3d   \
            --keep-daily    7   \
            --keep-weekly   4   \
            --keep-monthly -1   \
            "$CONFIG_BACKUP_REPO"
}

function ls_backups() {
  REPO_TO_LIST=$WORLD_BACKUP_REPO
  if [ "$1" = "config" ]; then
    REPO_TO_LIST=$CACHE_BACKUP_REPO
  fi
  borg list "$REPO_TO_LIST"
  borg info "$REPO_TO_LIST"
}

function restore_backup() {
  echo "Restoring a backup of the active world ($WORLD_NAME)..."
  borg extract "$WORLD_BACKUP_REPO::$1"

  # NOTE: Automatic restores of server configuration aren't yet supported.
  # echo "Restoring a backup of server configuration..."
  # borg extract "$CONFIG_BACKUP_REPO::$1"
}

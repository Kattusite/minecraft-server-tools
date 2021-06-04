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
#
# Note: This script doesn't respect $WORLD_BACKUP_NAME;
#       instead backups are named after the world name directly.

function _backup_repo_path() {
  local REPO_NAME=$1
  echo $BACKUP_DIR/$REPO_NAME
}

# A helper function to initialize a borg repo in the backups directory,
# given the name provided as an argument.
function _create_borg_repo() {
  local REPO_NAME=$1
  local REPO_PATH=`_backup_repo_path $REPO_NAME`

  # Exit quietly if the repo already exists.
  if [ -d "$REPO_PATH" ]; then
    return
  fi

  echo "Creating borg repository $REPO_PATH..."
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

function _create_borg_repos {
  mkdir -p $BACKUP_DIR
  _create_borg_repo "$CONFIG_BACKUP_NAME"
  for world in $WORLDS_TO_BACKUP; do
    _create_borg_repo "$world"
  done
}

function init_backups() {
  $INSTALL_PKG borgbackup
  _create_borg_repos
}

function create_backup() {
  # In case this is a different world than we initialized with,
  # make sure a valid borg repo exists for this world.
  _create_borg_repos

  local DATESTR=`date +%Y-%m-%d-%H%M%S`

  local CONFIG_BACKUP_REPO=`_backup_repo_path $CONFIG_BACKUP_NAME`
  local CONFIG_BACKUP="${CONFIG_BACKUP_REPO}::${CONFIG_BACKUP_NAME}-${DATESTR}"
  borg create -v "$CONFIG_BACKUP" `eval ls -d $CONFIG_BACKUP_FILES`

  for world in $WORLDS_TO_BACKUP; do
    local WORLD_BACKUP_REPO=`_backup_repo_path $world`
    local WORLD_BACKUP="${WORLD_BACKUP_REPO}::${world}-${DATESTR}"
    borg create -v "$WORLD_BACKUP" $world
  done
}

function pre_backup_hook() {
  return 0
}

function post_backup_hook() {
  # Apply a retention policy to gradually delete older backups.
  # Iterate over all worlds, then the config backup.
  for world in $WORLDS_TO_BACKUP $CONFIG_BACKUP_NAME; do
    borg prune --keep-within  3d   \
               --keep-daily    7   \
               --keep-weekly   4   \
               --keep-monthly -1   \
               `_backup_repo_path $world`
  done
}


# These helpers assume that $WORLDS_TO_BACKUP is formatted like:
#   "OVERWORLD NETHER END"

# Given $WORLDS_TO_BACKUP, return the first world. We assume it's the overworld.
function _overworld() {
  LS_WORLD=$1
}

# Given $WORLDS_TO_BACKUP, return the second world. We assume it's the nether.
function _nether() {
  LS_WORLD=$2
}

# Given $WORLDS_TO_BACKUP, return the third world. We assume it's the end.
function _end() {
  LS_WORLD=$3
}

function ls_backups() {
  LS_WORLD=""
  case $1 in
    ""|"overworld"|"$WORLD_NAME")
      _overworld $WORLDS_TO_BACKUP
      ;;
    "nether")
      _nether $WORLDS_TO_BACKUP
      ;;
    "end")
      _end $WORLDS_TO_BACKUP
      ;;
    "config")
      LS_WORLD=$CONFIG_BACKUP_NAME
      ;;
    "all")
      LS_WORLD="$WORLDS_TO_BACKUP $CONFIG_BACKUP_NAME"
      ;;
    *)
      echo "Usage: $0 ls [overworld|$WORLD_NAME|nether|end|config|all]"
      return
      ;;
  esac

  for world in $LS_WORLD; do
    local REPO_TO_LIST=`_backup_repo_path $world`
    echo "======= Listing backups for $world ======="
    borg list $REPO_TO_LIST
    echo
    echo "======= Summary info for $world ======="
    borg info $REPO_TO_LIST
    echo
  done
}

function restore_backup() {
  # This function accepts two arguments:
  #   $1 specifies which worlds (or config) should be overwritten
  #     Options include:
  #       - overworld
  #       - nether
  #       - end
  #       - config
  #       - all
  #   $2 specifies which version of that backup should be restored
  #     This must be either:
  #       - A specific named backup, as shown by `ls`.
  #       - The "DATESTR" suffix of such a backup.
  #     For example, if you have a backup named "world-2020-12-31-115959",
  #     then "world-2020-12-31-115959" and "2020-12-31-115959" would be
  #     completely equivalent.
  #     If the specific named backup given is not from the repo specified in $1,
  #     we will use the backup from the repo specified in $1 which was created
  #     with the same timestamp as the backup specified in $2.
  USAGE_STR="Usage: $0 restore <overworld|$WORLD_NAME|nether|end|config|all> <backupname or datestr>"

  LS_WORLD=""
  case $1 in
    "overworld"|"$WORLD_NAME")
      _overworld $WORLDS_TO_BACKUP
      ;;
    "nether")
      _nether $WORLDS_TO_BACKUP
      ;;
    "end")
      _end $WORLDS_TO_BACKUP
      ;;
    "config")
      LS_WORLD=$CONFIG_BACKUP_NAME
      ;;
    "all")
      LS_WORLD="$WORLDS_TO_BACKUP $CONFIG_BACKUP_NAME"
      ;;
    *)
      echo $USAGE_STR
      return
      ;;
  esac

  if [ -z "$2" ]; then
    echo $USAGE_STR
    return
  fi

  for world in $LS_WORLD; do
    # Compute a human readable title for prettier logging
    local DIMENSION_STR="dimension $world"
    if [ "$world" = "$CONFIG_BACKUP_NAME" ]; then
      DIMENSION_STR="server configuration files"
    fi

    # Strip out just the datetime suffix from $2 and ignore the backup prefix.
    DATESTR_SUFFIX=$(grep -Eo '[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}' <<< $2)

    echo "Restoring a backup of $DIMENSION_STR from $DATESTR_SUFFIX"
    local BACKUP_REPO=`_backup_repo_path $world`
    echo "Extracting from borg repo $BACKUP_REPO..."
    borg extract "$BACKUP_REPO::$world-$DATESTR_SUFFIX"
    echo
  done
}

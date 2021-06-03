#!/usr/bin/env bash
#
#   tar-backup.sh
#
# This backup backend archives the entire world directory using tar,
# writing them into a backup directory named by their date.
#
# This is a very simple, portable backup strategy,
# but unfortunately not the most efficient since each backup will
# contain a complete copy of _all_ the data, every time.


function init_backups() {
  $INSTALL_PKG tar
  mkdir $BACKUP_DIR
}

function create_backup() {
  local CUR_BACKUP_DIR=${BACKUP_DIR}/${WORLD_NAME}
  mkdir -p $CUR_BACKUP_DIR

  local DATESTR=`date +%Y-%m-%d-%H%M%S`
  local ARCHNAME="${CUR_BACKUP_DIR}/${WORLD_BACKUP_NAME}_${DATESTR}.tar.gz"
  tar -czf "$ARCHNAME" "./$WORLD_NAME"

  if [ ! $? -eq 0 ]; then
    echo "TAR failed. No Backup created."
    rm $ARCHNAME # remove (probably faulty) archive
    return 1
  else
    echo $ARCHNAME created.
  fi
}

function pre_backup_hook() {
  return 0
}

function post_backup_hook() {
  return 0
}

function ls_backups() {
  echo "Showing backups for active world ($WORLD_NAME):"
  ls -lrt ${BACKUP_DIR}/${WORLD_NAME}
}

function restore_backup() {
  local BACKUP_FILE=$1
  local ARCHNAME="${BACKUP_DIR}/${WORLD_NAME}/${BACKUP_FILE}"

  if [ ! -f "${ARCHNAME}" ]; then
    echo "No such backup: $ARCHNAME"
    return 1
  fi

  echo "Backing up current files to avoid losing data..."
  create_backup

  echo "Extracting backup from ${ARCHNAME}..."
  tar -xzvf "$ARCHNAME"
}
